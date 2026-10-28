import argparse
import sys
import os
import time
from datetime import date, datetime, timedelta

import psycopg2
from psycopg2 import sql
from playwright.sync_api import sync_playwright

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from utils.keyvault import get_db_dsn
from utils.etl_job import get_job_config, set_job_status, log_run_start, log_run_end
from utils.db import execute_values_counted

JOB_NAME = "mcx_bhavcopy_ingest"
BHAVCOPY_PAGE_URL = "https://www.mcxindia.com/market-data/bhavcopy"
DEFAULT_BACKFILL_START = date(2003, 11, 1)  # MCX's own stated bhavcopy history start
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"
# How many days to fetch on one page load before reloading the bhavcopy page
# fresh - a long backfill run (thousands of days) on one page risks whatever
# session/cookie state the site keeps going stale; periodic reload bounds
# the blast radius of that to this many days instead of the whole run.
RELOAD_EVERY_N_DAYS = 200


# -----------------------------
# 1. Connect to Supabase PostgreSQL
# -----------------------------
def connect_to_postgres(environment):
    return psycopg2.connect(
        get_db_dsn(environment),
        connect_timeout=15,
        options="-c statement_timeout=30000",
    )


# -----------------------------
# 2. Last loaded trade date (drives incremental resume)
# -----------------------------
def fetch_last_trade_date(cursor, target_schema, target_table):
    query = sql.SQL('SELECT MAX("TradeDate") FROM {}.{}').format(
        sql.Identifier(target_schema), sql.Identifier(target_table)
    )
    cursor.execute(query)
    return cursor.fetchone()[0]


# -----------------------------
# 3. Browser session (MCX blocks plain HTTP and headless Chromium - only a
#    genuinely headed browser, driving the page's own date-filter UI, gets
#    real data back; see GetDateWiseBhavCopy below)
# -----------------------------
def open_bhavcopy_page(playwright):
    browser = playwright.chromium.launch(
        headless=False, args=["--disable-blink-features=AutomationControlled"]
    )
    context = browser.new_context(user_agent=USER_AGENT, viewport={"width": 1280, "height": 900})
    page = context.new_page()
    page.goto(BHAVCOPY_PAGE_URL, wait_until="networkidle", timeout=45000)
    page.wait_for_timeout(1000)
    return browser, page


# A mid-run reopen (after a failure, or the periodic RELOAD_EVERY_N_DAYS
# refresh) can itself fail - observed in production as
# net::ERR_TOO_MANY_REDIRECTS after ~130 consecutive requests in one run,
# which previously crashed the whole script uncaught. Retries a few times
# with backoff (MCX may just need a short cooldown); returns (None, None)
# if it still can't get back in, so the caller can stop gracefully instead
# of the process dying mid-loop.
def reopen_bhavcopy_page_with_retry(playwright, attempts=3, backoff_seconds=(15, 45, 90)):
    for attempt in range(attempts):
        try:
            return open_bhavcopy_page(playwright)
        except Exception as exc:
            print(f"Reopen attempt {attempt + 1}/{attempts} failed: {exc}")
            if attempt < attempts - 1:
                time.sleep(backoff_seconds[attempt])
    return None, None


# -----------------------------
# 4. One day's bhavcopy - every instrument, every expiry, every strike -
#    via the page's own date-wise lookup (GetDateWiseBhavCopy), triggered by
#    filling the real date input and clicking the real button. A bare fetch
#    to this same URL (even same-origin) 404s - it only responds to a
#    request the page's own click handler issues.
# -----------------------------
# Route interception, not page.expect_response().json() - the latter reads
# the body back from Chrome DevTools Protocol's network inspector cache
# after the fact, which has a size limit observed in production: days with
# an unusually large contract list (confirmed: one day returned 64,172 rows,
# ~4-6x a typical day) deterministically fail with "Protocol error
# (Network.getResponseBody): Request content was evicted from inspector
# cache" on every retry, even a fresh browser session. route.fetch() instead
# makes the request through Playwright's own HTTP layer, reading the body
# directly rather than recalling it from that cache - confirmed to
# successfully fetch the exact dates that failed the old way.
def fetch_bhavcopy(page, d):
    captured = {}

    def handle_route(route):
        response = route.fetch()
        try:
            captured["payload"] = response.json()
        except Exception as exc:
            captured["error"] = exc
        route.fulfill(response=response)

    page.route("**/GetDateWiseBhavCopy*", handle_route)
    try:
        page.locator("#bhavCopyDateWise").fill(d.isoformat())
        page.locator("#btnDateWise").click()
        deadline = time.monotonic() + 20
        while "payload" not in captured and "error" not in captured:
            if time.monotonic() > deadline:
                raise TimeoutError(f"Timed out waiting for GetDateWiseBhavCopy response on {d}")
            page.wait_for_timeout(100)
    finally:
        page.unroute("**/GetDateWiseBhavCopy*", handle_route)

    if "error" in captured:
        raise captured["error"]
    payload = captured["payload"]
    if not payload.get("IsSuccess") or not payload.get("Data"):
        return None
    return payload["Data"]


# -----------------------------
# 5. Transform + upsert into Commodities.McxBhavCopy
# -----------------------------
def safe_numeric(value):
    if value is None or value == "":
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def transform_rows(raw_rows):
    rows = []
    for row in raw_rows:
        trade_date = datetime.strptime(row["Date"], "%m/%d/%Y").date()
        expiry_date = datetime.strptime(row["ExpiryDate"], "%d%b%Y").date()
        rows.append((
            trade_date,
            row["Symbol"].strip(),
            row["InstrumentName"],
            expiry_date,
            row["OptionType"],
            safe_numeric(row["StrikePrice"]) or 0,
            safe_numeric(row["Open"]),
            safe_numeric(row["High"]),
            safe_numeric(row["Low"]),
            safe_numeric(row["Close"]),
            safe_numeric(row["PreviousClose"]),
            safe_numeric(row["Volume"]),
            row.get("VolumeInThousands"),
            safe_numeric(row["Value"]),
            safe_numeric(row["OpenInterest"]),
        ))
    return rows


# Index of each tuple field transform_rows produces above, named just for
# dedupe_rows below rather than unpacking every field.
_KEY_IDX = (0, 1, 2, 3, 4, 5)  # TradeDate, Commodity, InstrumentType, ExpiryDate, OptionType, StrikePrice
_VOLUME_IDX = 11


def dedupe_rows(rows):
    """Observed in production (2004-10-26): MCX's own feed occasionally
    returns two rows for the exact same contract (same TradeDate, Commodity,
    InstrumentType, ExpiryDate, OptionType, StrikePrice) on one day - and
    Postgres's ON CONFLICT DO UPDATE can't touch the same conflict target
    twice in one statement, which aborted that entire day's upsert (not just
    the duplicate row). Keeps whichever copy has the higher Volume (the more
    "real" of the two on a day with an otherwise-identical duplicate), or
    whichever was seen first on a tie.
    """
    best: dict[tuple, tuple] = {}
    for row in rows:
        key = tuple(row[i] for i in _KEY_IDX)
        existing = best.get(key)
        if existing is None or (row[_VOLUME_IDX] or 0) > (existing[_VOLUME_IDX] or 0):
            best[key] = row
    return list(best.values())


def upsert_bhavcopy(cursor, target_schema, target_table, rows):
    upsert_sql = sql.SQL(
        """
        INSERT INTO {}.{} (
            "TradeDate", "Commodity", "InstrumentType", "ExpiryDate", "OptionType", "StrikePrice",
            "OpenPrice", "HighPrice", "LowPrice", "ClosePrice", "PreviousClosePrice",
            "Volume", "VolumeDisplay", "ValueInLakhs", "OpenInterest"
        )
        VALUES %s
        ON CONFLICT ("Commodity", "TradeDate", "InstrumentType", "ExpiryDate", "OptionType", "StrikePrice")
        DO UPDATE SET
            "OpenPrice" = EXCLUDED."OpenPrice",
            "HighPrice" = EXCLUDED."HighPrice",
            "LowPrice" = EXCLUDED."LowPrice",
            "ClosePrice" = EXCLUDED."ClosePrice",
            "PreviousClosePrice" = EXCLUDED."PreviousClosePrice",
            "Volume" = EXCLUDED."Volume",
            "VolumeDisplay" = EXCLUDED."VolumeDisplay",
            "ValueInLakhs" = EXCLUDED."ValueInLakhs",
            "OpenInterest" = EXCLUDED."OpenInterest";
        """
    ).format(sql.Identifier(target_schema), sql.Identifier(target_table))
    return execute_values_counted(cursor, upsert_sql, rows)


# -----------------------------
# 6. Calendar-day range - unlike NSE/BSE equities, MCX occasionally runs
#    special commodity sessions on weekends (e.g. Muhurat trading), so every
#    calendar day is checked rather than just Mon-Fri; non-trading days just
#    come back IsSuccess: false from fetch_bhavcopy and are skipped cheaply.
# -----------------------------
def calendar_days(start, end):
    d = start
    while d <= end:
        yield d
        d += timedelta(days=1)


# -----------------------------
# 7. Main
# -----------------------------
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--environment",
        default=None,
        help="dev or prod; defaults to the ENVIRONMENT env var (prod if unset)",
    )
    parser.add_argument(
        "--start-date",
        default=None,
        help="YYYY-MM-DD (optional). Defaults to the day after the last loaded "
             f"trade date, or {DEFAULT_BACKFILL_START.isoformat()} if empty.",
    )
    parser.add_argument(
        "--end-date",
        default=None,
        help="YYYY-MM-DD (optional). Defaults to today.",
    )
    parser.add_argument(
        "--limit-days",
        type=int,
        default=None,
        help="Only process the first N calendar days in range (for testing, or to "
             "chunk a long backfill across multiple runs)",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=float,
        default=1.0,
        help="Delay between MCX requests",
    )
    args = parser.parse_args()

    conn = connect_to_postgres(args.environment)
    cursor = conn.cursor()
    log_id = None

    try:
        config = get_job_config(cursor, JOB_NAME)

        start_time = datetime.utcnow()
        log_id = log_run_start(cursor, JOB_NAME, start_time)
        conn.commit()

        if not config["enabled"]:
            print(f"Job '{JOB_NAME}' is disabled in ETL.ETL_CONFIG, skipping.")
            set_job_status(cursor, JOB_NAME, "skipped")
            log_run_end(cursor, log_id, "skipped")
            conn.commit()
            return

        if args.start_date:
            start_date = datetime.strptime(args.start_date, "%Y-%m-%d").date()
        else:
            last_trade_date = fetch_last_trade_date(cursor, config["target_schema"], config["target_table"])
            start_date = last_trade_date + timedelta(days=1) if last_trade_date else DEFAULT_BACKFILL_START

        end_date = (
            datetime.strptime(args.end_date, "%Y-%m-%d").date() if args.end_date else date.today()
        )

        days = list(calendar_days(start_date, end_date))
        if args.limit_days is not None:
            days = days[:args.limit_days]

        print(f"Trade days to sync: {len(days)} ({start_date} to {end_date})")

        total_rows = 0
        last_loaded_date = None
        skipped_days = []
        failed_days = []

        with sync_playwright() as playwright:
            browser, page = reopen_bhavcopy_page_with_retry(playwright)
            if page is None:
                raise Exception("Could not open MCX bhavcopy page after retries - site may be blocking this run")
            try:
                for i, d in enumerate(days, start=1):
                    if i > 1 and (i - 1) % RELOAD_EVERY_N_DAYS == 0:
                        page.close()
                        browser.close()
                        browser, page = reopen_bhavcopy_page_with_retry(playwright)
                        if page is None:
                            print(f"Giving up at {d} - couldn't reopen the page for the periodic refresh.")
                            break

                    try:
                        raw_rows = fetch_bhavcopy(page, d)
                        if not raw_rows:
                            skipped_days.append(d)
                            print(f"[{i}/{len(days)}] {d}: no data (non-trading day or not yet published), skipped")
                        else:
                            rows = dedupe_rows(transform_rows(raw_rows))
                            rows_upserted = upsert_bhavcopy(cursor, config["target_schema"], config["target_table"], rows)
                            conn.commit()
                            total_rows += rows_upserted
                            last_loaded_date = d
                            print(f"[{i}/{len(days)}] {d}: {rows_upserted} rows upserted")
                    except Exception as exc:
                        failed_days.append(d)
                        print(f"[{i}/{len(days)}] {d} FAILED: {exc}")
                        try:
                            conn.rollback()
                        except Exception:
                            pass
                        # A failure here might mean the page/browser itself is in a
                        # bad state (closed tab, crashed renderer, stuck session) -
                        # reopen it so one bad day can't poison the rest of the run,
                        # same reasoning as NSE bhavcopy's DB-reconnect-on-failure.
                        try:
                            page.close()
                            browser.close()
                        except Exception:
                            pass
                        browser, page = reopen_bhavcopy_page_with_retry(playwright)
                        if page is None:
                            # Observed in production: MCX started returning
                            # net::ERR_TOO_MANY_REDIRECTS after ~130 consecutive
                            # requests in one run - looks like a bot-detection
                            # cooldown, not a one-off glitch. Retrying harder
                            # right now just gets blocked again; stop here and
                            # let a later, fresh dispatch (different runner,
                            # cooled-down session) pick up where this left off -
                            # this script is resumable by design (see start_date
                            # defaulting to the day after MAX(TradeDate)).
                            print(
                                f"Giving up after repeated reopen failures at {d} - "
                                "likely blocked by MCX; remaining days left for a later run."
                            )
                            break

                    if args.sleep_seconds:
                        time.sleep(args.sleep_seconds)
            finally:
                # browser can be None here if the last reopen attempt
                # (periodic refresh or post-failure recovery) itself failed
                # and the loop broke out before getting a fresh one.
                if browser is not None:
                    browser.close()

        status = "success" if not failed_days else "success_with_errors"
        error_message = None
        if failed_days:
            shown = [d.isoformat() for d in failed_days[:20]]
            suffix = ", ..." if len(failed_days) > 20 else ""
            error_message = f"{len(failed_days)} day(s) failed: {shown}{suffix}"

        set_job_status(cursor, JOB_NAME, status)
        log_run_end(
            cursor,
            log_id,
            status,
            rows_updated=total_rows,
            watermark_value=str(last_loaded_date) if last_loaded_date else None,
            error_message=error_message,
        )
        conn.commit()

        print(
            f"Sync completed. Rows upserted: {total_rows}. "
            f"Skipped: {len(skipped_days)}. Failed: {len(failed_days)}."
        )
    except Exception as exc:
        conn.rollback()
        set_job_status(cursor, JOB_NAME, "failed")
        if log_id is not None:
            log_run_end(cursor, log_id, "failed", error_message=str(exc))
        conn.commit()
        raise
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    main()

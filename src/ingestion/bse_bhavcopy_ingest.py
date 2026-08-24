import argparse
import csv
import io
import sys
import os
import time
import zipfile
from datetime import date, datetime, timedelta

import psycopg2
import requests
from psycopg2 import sql

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from utils.keyvault import get_db_dsn
from utils.etl_job import get_job_config, set_job_status, log_run_start, log_run_end
from utils.db import execute_values_counted

JOB_NAME = "bse_bhavcopy_ingest"
EXCHANGE_CODE = "BSE"
MARKET_SEGMENT = "CM"
DATA_SOURCE = "BHAVCOPY"
INSTRUMENT_TYPE = "EQ"
DEFAULT_BACKFILL_START = date(2016, 1, 1)
UDIFF_CUTOVER = date(2024, 7, 8)
SCRIP_MASTER_URL = "https://api.bseindia.com/BseIndiaAPI/api/LitsOfScripCSVDownload/w"
REQUEST_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    "Referer": "https://www.bseindia.com/",
    "Origin": "https://www.bseindia.com",
}


# -----------------------------
# 1. Connect to Supabase PostgreSQL
# -----------------------------
def connect_to_postgres(environment):
    return psycopg2.connect(get_db_dsn(environment))


# -----------------------------
# 2. Active equity scrip master (SC_CODE -> ISIN/symbol/name).
#    BSE's own daily files don't reliably carry ISIN (the pre-UDiFF
#    format has none at all), so identity fields always come from here,
#    keyed by BSE's stable numeric security code - not from the daily file.
# -----------------------------
def fetch_active_scrip_master():
    session = requests.Session()
    session.get("https://www.bseindia.com/", headers=REQUEST_HEADERS, timeout=30)  # warm cookies

    response = session.get(
        SCRIP_MASTER_URL,
        params={"segment": "Equity", "status": "Active", "Group": "", "Scripcode": ""},
        headers=REQUEST_HEADERS,
        timeout=30,
    )
    response.raise_for_status()

    reader = csv.DictReader(io.StringIO(response.text))
    master = {}
    for row in reader:
        if row.get("Instrument", "").strip() != "Equity" or row.get("Status", "").strip() != "Active":
            continue
        try:
            sc_code = int(row["Security Code"].strip())
        except (KeyError, ValueError):
            continue
        isin = row.get("ISIN No", "").strip()
        if not isin:
            continue
        master[sc_code] = {
            "isin": isin,
            "symbol": row.get("Security Id", "").strip(),
            "name": row.get("Security Name", "").strip(),
            "group": row.get("Group", "").strip(),
        }
    return master


# -----------------------------
# 3. Last loaded trade date (drives incremental resume)
# -----------------------------
def fetch_last_trade_date(cursor, target_schema, target_table):
    query = sql.SQL(
        """
        SELECT MAX("TradeDate")
        FROM {}.{}
        WHERE "StockExchangeCode" = %s AND "DataSource" = %s
        """
    ).format(sql.Identifier(target_schema), sql.Identifier(target_table))
    cursor.execute(query, (EXCHANGE_CODE, DATA_SOURCE))
    return cursor.fetchone()[0]


# -----------------------------
# 4a. Old CSV zip format (Jan 2016 -> 5 Jul 2024)
# -----------------------------
def fetch_old_format(base_url, d):
    url = f"{base_url.rstrip('/')}/download/BhavCopy/Equity/EQ{d.strftime('%d%m%y')}_CSV.ZIP"
    response = requests.get(url, headers=REQUEST_HEADERS, timeout=20)
    if response.status_code != 200:
        return None

    try:
        archive = zipfile.ZipFile(io.BytesIO(response.content))
    except zipfile.BadZipFile:
        return None  # BSE returns a 200 HTML page instead of a 404 for missing files

    with archive:
        with archive.open(archive.namelist()[0]) as f:
            reader = csv.DictReader(io.TextIOWrapper(f, encoding="utf-8"))
            rows = []
            for row in reader:
                if row["SC_TYPE"].strip() != "Q":  # 'Q' = equity quote; excludes bonds/debentures mixed into the file
                    continue
                try:
                    sc_code = int(row["SC_CODE"].strip())
                except ValueError:
                    continue
                rows.append({
                    "sc_code": sc_code,
                    "open": row["OPEN"],
                    "high": row["HIGH"],
                    "low": row["LOW"],
                    "close": row["CLOSE"],
                    "last": row["LAST"],
                    "prevclose": row["PREVCLOSE"],
                })
            return rows


# -----------------------------
# 4b. UDiFF format (8 Jul 2024 -> today) - plain CSV, not zipped
# -----------------------------
def fetch_udiff_format(base_url, d):
    ymd = d.strftime("%Y%m%d")
    url = f"{base_url.rstrip('/')}/download/BhavCopy/Equity/BhavCopy_BSE_CM_0_0_0_{ymd}_F_0000.CSV"
    response = requests.get(url, headers=REQUEST_HEADERS, timeout=20)
    if response.status_code != 200 or not response.text.strip():
        return None

    reader = csv.DictReader(io.StringIO(response.text))
    rows = []
    for row in reader:
        if row["FinInstrmTp"].strip() != "STK":
            continue
        try:
            sc_code = int(row["FinInstrmId"].strip())
        except ValueError:
            continue
        rows.append({
            "sc_code": sc_code,
            "open": row["OpnPric"],
            "high": row["HghPric"],
            "low": row["LwPric"],
            "close": row["ClsPric"],
            "last": row["LastPric"],
            "prevclose": row["PrvsClsgPric"],
        })
    return rows


def fetch_bhavcopy(base_url, d):
    return fetch_udiff_format(base_url, d) if d >= UDIFF_CUTOVER else fetch_old_format(base_url, d)


# -----------------------------
# 5. Join to active scrip master + map to Stocks.StockData columns
# -----------------------------
def safe_numeric(value):
    if value is None or value == "":
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def transform_rows(d, raw_rows, scrip_master):
    rows = []
    for row in raw_rows:
        scrip = scrip_master.get(row["sc_code"])
        if scrip is None:
            continue

        rows.append((
            EXCHANGE_CODE,
            d,
            d,
            MARKET_SEGMENT,
            DATA_SOURCE,
            INSTRUMENT_TYPE,
            row["sc_code"],
            scrip["isin"],
            scrip["symbol"],
            scrip["group"],
            scrip["name"],
            safe_numeric(row["open"]),
            safe_numeric(row["high"]),
            safe_numeric(row["low"]),
            safe_numeric(row["close"]),
            safe_numeric(row["last"]),
            safe_numeric(row["prevclose"]),
        ))
    return rows


# -----------------------------
# 6. Upsert into Stocks.StockData
# -----------------------------
def upsert_stock_data(cursor, target_schema, target_table, rows):
    upsert_sql = sql.SQL(
        """
        INSERT INTO {}.{} (
            "StockExchangeCode", "TradeDate", "BusinessDate", "MarketSegment",
            "DataSource", "InstrumentType", "InstrumentId", "IsinCode",
            "TickerSymbol", "SecuritySeries", "InstrumentName",
            "OpenPrice", "HighPrice", "LowPrice", "ClosePrice",
            "LastTradedPrice", "PreviousClosePrice"
        )
        VALUES %s
        ON CONFLICT ("StockExchangeCode", "TradeDate", "InstrumentId") DO UPDATE SET
            "IsinCode" = EXCLUDED."IsinCode",
            "TickerSymbol" = EXCLUDED."TickerSymbol",
            "SecuritySeries" = EXCLUDED."SecuritySeries",
            "InstrumentName" = EXCLUDED."InstrumentName",
            "OpenPrice" = EXCLUDED."OpenPrice",
            "HighPrice" = EXCLUDED."HighPrice",
            "LowPrice" = EXCLUDED."LowPrice",
            "ClosePrice" = EXCLUDED."ClosePrice",
            "LastTradedPrice" = EXCLUDED."LastTradedPrice",
            "PreviousClosePrice" = EXCLUDED."PreviousClosePrice";
        """
    ).format(sql.Identifier(target_schema), sql.Identifier(target_table))

    return execute_values_counted(cursor, upsert_sql, rows)


# -----------------------------
# 7. Business day range
# -----------------------------
def business_days(start, end):
    d = start
    while d <= end:
        if d.weekday() < 5:
            yield d
        d += timedelta(days=1)


# -----------------------------
# 8. Main
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
        help="Only process the first N business days in range (for testing)",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=float,
        default=0.5,
        help="Delay between BSE requests",
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

        days = list(business_days(start_date, end_date))
        if args.limit_days is not None:
            days = days[:args.limit_days]

        print(f"Trade days to sync: {len(days)} ({start_date} to {end_date})")

        print("Fetching active equity scrip master...")
        scrip_master = fetch_active_scrip_master()
        print(f"Active equity scrips: {len(scrip_master)}")

        total_rows = 0
        last_loaded_date = None
        skipped_days = []
        failed_days = []

        for i, d in enumerate(days, start=1):
            try:
                raw_rows = fetch_bhavcopy(config["source_url"], d)
                if not raw_rows:
                    skipped_days.append(d)
                    print(f"[{i}/{len(days)}] {d}: no data (holiday or not yet published), skipped")
                else:
                    rows = transform_rows(d, raw_rows, scrip_master)
                    if not rows:
                        skipped_days.append(d)
                        print(f"[{i}/{len(days)}] {d}: no active equity matches, skipped")
                    else:
                        rows_upserted = upsert_stock_data(cursor, config["target_schema"], config["target_table"], rows)
                        conn.commit()
                        total_rows += rows_upserted
                        last_loaded_date = d
                        print(f"[{i}/{len(days)}] {d}: {rows_upserted} rows upserted")
            except Exception as exc:
                failed_days.append(d)
                print(f"[{i}/{len(days)}] {d} FAILED: {exc}")
                # A rollback alone doesn't recover a connection stuck in a bad
                # state (observed on the NSE job: Supabase's transaction
                # pooler silently failed a long-running session over to a
                # read-only replica partway through a multi-hour backfill,
                # and every remaining day failed the same way for the rest
                # of the run). Reconnect so one bad connection can't poison
                # everything after it.
                try:
                    conn.rollback()
                except Exception:
                    pass
                try:
                    cursor.close()
                    conn.close()
                except Exception:
                    pass
                conn = connect_to_postgres(args.environment)
                cursor = conn.cursor()

            if args.sleep_seconds:
                time.sleep(args.sleep_seconds)

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

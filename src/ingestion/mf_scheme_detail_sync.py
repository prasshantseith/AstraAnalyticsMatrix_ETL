import argparse
import os
import sys
import time
from datetime import datetime

import psycopg2
import requests
from psycopg2 import sql

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from utils.keyvault import get_db_dsn
from utils.etl_job import get_job_config, set_job_status, log_run_start, log_run_end
from utils.db import execute_values_counted

JOB_NAME = "mf_scheme_detail_sync"
PEER_TABLE = "MFSchemeComparisonPeer"


# -----------------------------
# 1. Connect to Supabase PostgreSQL
# -----------------------------
def connect_to_postgres(environment):
    return psycopg2.connect(get_db_dsn(environment))


# -----------------------------
# 2. Active funds + their ISINs from MF.MF
# -----------------------------
def fetch_active_funds(cursor):
    cursor.execute(
        """
        SELECT "MFID", "isinGrowth", "isinDivPayout", "isinDivReinvestment"
        FROM "MF"."MF"
        WHERE "IsActive" = true
        ORDER BY "MFID"
        """
    )
    return cursor.fetchall()


def fetch_fund_by_mfid(cursor, mfid):
    cursor.execute(
        """
        SELECT "MFID", "isinGrowth", "isinDivPayout", "isinDivReinvestment"
        FROM "MF"."MF"
        WHERE "MFID" = %s
        """,
        (mfid,)
    )
    return cursor.fetchall()


# -----------------------------
# 3. Fetch scheme detail, falling back across ISINs
# -----------------------------
def fetch_scheme_detail(base_url, isin):
    url = f"{base_url.rstrip('/')}/{isin}"
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    payload = response.json()

    if isinstance(payload, list) and payload:
        return payload[0]

    return None


def resolve_scheme_detail(base_url, isins):
    for isin in isins:
        if not isin:
            continue
        try:
            detail = fetch_scheme_detail(base_url, isin)
        except Exception:
            continue
        if detail:
            return detail

    return None


# -----------------------------
# 4. Value coercion helpers (API mixes Y/N flags, stringified
#    numbers, and real numbers across fields)
# -----------------------------
def yn_to_bool(value):
    if value is None:
        return None
    return value == "Y"


def safe_float(value):
    if value is None or value == "":
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def safe_int(value):
    if value is None or value == "":
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def safe_date(value):
    if not value:
        return None
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError:
        return None


# -----------------------------
# 5. Transform + update MF.MF
# -----------------------------
def transform_detail(detail):
    sips = detail.get("sips") or []
    sip_frequencies = [s.get("sip_frequency") for s in sips if s.get("sip_frequency")]

    return {
        "external_code": detail.get("code"),
        "short_name": detail.get("short_name"),
        "amc_name": detail.get("fund_name"),
        "category": detail.get("category"),
        "fund_category": detail.get("fund_category"),
        "plan": detail.get("plan"),
        "is_direct": yn_to_bool(detail.get("direct")),
        "maturity_type": detail.get("maturity_type"),
        "launch_date": safe_date(detail.get("start_date")),
        "lock_in_period_days": safe_int(detail.get("lock_in_period")),
        "risk_rating": detail.get("crisil_rating"),
        "star_rating": safe_int(detail.get("fund_rating")),
        "star_rating_date": safe_date(detail.get("fund_rating_date")),
        "expense_ratio": safe_float(detail.get("expense_ratio")),
        "expense_ratio_date": safe_date(detail.get("expense_ratio_date")),
        "aum_cr": safe_float(detail.get("aum")),
        "volatility": safe_float(detail.get("volatility")),
        "fund_manager": detail.get("fund_manager"),
        "investment_objective": detail.get("investment_objective"),
        "scheme_doc_url": detail.get("detail_info"),
        "tags": detail.get("tags") or [],
        "lump_available": yn_to_bool(detail.get("lump_available")),
        "lump_min": safe_float(detail.get("lump_min")),
        "lump_min_additional": safe_float(detail.get("lump_min_additional")),
        "sip_available": yn_to_bool(detail.get("sip_available")),
        "sip_min": safe_float(detail.get("sip_min")),
        "sip_frequencies": sip_frequencies,
        "redemption_allowed": yn_to_bool(detail.get("redemption_allowed")),
        "redemption_min_amount": safe_float(detail.get("redemption_amount_minimum")),
        "switch_allowed": yn_to_bool(detail.get("switch_allowed")),
        "stp_available": yn_to_bool(detail.get("stp_flag")),
        "swp_available": yn_to_bool(detail.get("swp_flag")),
        "instant_redemption": yn_to_bool(detail.get("instant")),
        "instant_redeem_min": safe_float(detail.get("insta_redeem_min_amount")),
        "instant_redeem_max": safe_float(detail.get("insta_redeem_max_amount")),
        "tax_long_term_after_days": safe_int(detail.get("tax_period")),
    }


def update_mf_details(cursor, target_schema, target_table, mfid, detail):
    values = transform_detail(detail)
    values["mfid"] = mfid

    update_sql = sql.SQL(
        """
        UPDATE {}.{}
        SET
            external_code = %(external_code)s,
            short_name = %(short_name)s,
            amc_name = %(amc_name)s,
            category = %(category)s,
            fund_category = %(fund_category)s,
            plan = %(plan)s,
            is_direct = %(is_direct)s,
            maturity_type = %(maturity_type)s,
            launch_date = %(launch_date)s,
            lock_in_period_days = %(lock_in_period_days)s,
            risk_rating = %(risk_rating)s,
            star_rating = %(star_rating)s,
            star_rating_date = %(star_rating_date)s,
            expense_ratio = %(expense_ratio)s,
            expense_ratio_date = %(expense_ratio_date)s,
            aum_cr = %(aum_cr)s,
            volatility = %(volatility)s,
            fund_manager = %(fund_manager)s,
            investment_objective = %(investment_objective)s,
            scheme_doc_url = %(scheme_doc_url)s,
            tags = %(tags)s,
            lump_available = %(lump_available)s,
            lump_min = %(lump_min)s,
            lump_min_additional = %(lump_min_additional)s,
            sip_available = %(sip_available)s,
            sip_min = %(sip_min)s,
            sip_frequencies = %(sip_frequencies)s,
            redemption_allowed = %(redemption_allowed)s,
            redemption_min_amount = %(redemption_min_amount)s,
            switch_allowed = %(switch_allowed)s,
            stp_available = %(stp_available)s,
            swp_available = %(swp_available)s,
            instant_redemption = %(instant_redemption)s,
            instant_redeem_min = %(instant_redeem_min)s,
            instant_redeem_max = %(instant_redeem_max)s,
            tax_long_term_after_days = %(tax_long_term_after_days)s,
            detail_modifieddate = now()
        WHERE "MFID" = %(mfid)s;
        """
    ).format(sql.Identifier(target_schema), sql.Identifier(target_table))

    cursor.execute(update_sql, values)


# -----------------------------
# 6. Upsert peer comparison rows
# -----------------------------
def fetch_external_code_map(cursor):
    cursor.execute(
        """
        SELECT external_code, "MFID"
        FROM "MF"."MF"
        WHERE external_code IS NOT NULL
        """
    )
    return dict(cursor.fetchall())


def upsert_peer_performance(cursor, target_schema, mfid, comparison, external_code_map):
    now = datetime.utcnow()
    rows = [
        (mfid, external_code_map.get(peer["code"]), peer["code"], sort_order, safe_float(peer.get("info_ratio")), now)
        for sort_order, peer in enumerate(comparison, start=1)
        if peer.get("code")
    ]

    if not rows:
        return 0

    upsert_sql = sql.SQL(
        """
        INSERT INTO {}.{} (source_mfid, peer_mfid, peer_code, sort_order, info_ratio, rowinsertdatetime)
        VALUES %s
        ON CONFLICT (source_mfid, peer_code) DO UPDATE SET
            peer_mfid = EXCLUDED.peer_mfid,
            sort_order = EXCLUDED.sort_order,
            info_ratio = EXCLUDED.info_ratio,
            rowinsertdatetime = EXCLUDED.rowinsertdatetime;
        """
    ).format(sql.Identifier(target_schema), sql.Identifier(PEER_TABLE))

    return execute_values_counted(cursor, upsert_sql, rows)


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
        "--limit",
        type=int,
        default=None,
        help="Only sync the first N active funds (for testing)",
    )
    parser.add_argument(
        "--mfid",
        type=int,
        default=None,
        help="Only sync this single MFID (for testing), skips the active-fund lookup",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=float,
        default=0.2,
        help="Delay between mf.captnemo.in requests",
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

        if args.mfid is not None:
            funds = fetch_fund_by_mfid(cursor, args.mfid)
        else:
            funds = fetch_active_funds(cursor)
            if args.limit is not None:
                funds = funds[:args.limit]

        print(f"Active funds to sync: {len(funds)}")

        external_code_map = fetch_external_code_map(cursor)

        total_updated = 0
        total_peer_rows = 0
        skipped_funds = []
        failed_funds = []

        for i, (mfid, isin_growth, isin_div_payout, isin_div_reinvestment) in enumerate(funds, start=1):
            try:
                detail = resolve_scheme_detail(
                    config["source_url"],
                    [isin_growth, isin_div_payout, isin_div_reinvestment],
                )

                if detail is None:
                    skipped_funds.append(mfid)
                    print(f"[{i}/{len(funds)}] MFID {mfid}: no valid ISIN found, skipped")
                else:
                    update_mf_details(cursor, config["target_schema"], config["target_table"], mfid, detail)
                    peer_rows = upsert_peer_performance(
                        cursor, config["target_schema"], mfid, detail.get("comparison") or [], external_code_map
                    )
                    conn.commit()

                    total_updated += 1
                    total_peer_rows += peer_rows
                    print(f"[{i}/{len(funds)}] MFID {mfid}: updated, {peer_rows} peer rows")
            except Exception as exc:
                conn.rollback()
                failed_funds.append(mfid)
                print(f"[{i}/{len(funds)}] MFID {mfid} FAILED: {exc}")

            if args.sleep_seconds:
                time.sleep(args.sleep_seconds)

        status = "success" if not failed_funds else "success_with_errors"
        error_message = None
        if failed_funds or skipped_funds:
            parts = []
            if failed_funds:
                shown = failed_funds[:20]
                suffix = ", ..." if len(failed_funds) > 20 else ""
                parts.append(f"{len(failed_funds)} failed: {shown}{suffix}")
            if skipped_funds:
                shown = skipped_funds[:20]
                suffix = ", ..." if len(skipped_funds) > 20 else ""
                parts.append(f"{len(skipped_funds)} skipped (no valid ISIN): {shown}{suffix}")
            error_message = "; ".join(parts)

        set_job_status(cursor, JOB_NAME, status)
        log_run_end(
            cursor,
            log_id,
            status,
            rows_updated=total_updated,
            watermark_value=str(total_peer_rows),
            error_message=error_message,
        )
        conn.commit()

        print(f"Sync completed. Funds updated: {total_updated}. Peer rows: {total_peer_rows}. "
              f"Skipped: {len(skipped_funds)}. Failed: {len(failed_funds)}.")
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

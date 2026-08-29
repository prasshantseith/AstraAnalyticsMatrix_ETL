import argparse
import os
import sys
from datetime import date, datetime, timedelta, timezone

import psycopg2
import requests
from psycopg2 import sql

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from utils.db import execute_values_counted
from utils.etl_job import get_job_config, log_run_end, log_run_start, set_job_status
from utils.keyvault import get_db_dsn

JOB_NAME = "bse_index_ingest"
REQUEST_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    "Accept": "application/json, text/plain, */*",
    "Origin": "https://www.bseindia.com",
    "Referer": "https://www.bseindia.com/",
}
IST = timezone(timedelta(hours=5, minutes=30))


def connect_to_postgres(environment):
    return psycopg2.connect(get_db_dsn(environment), connect_timeout=15)


def parse_number(value):
    if value in (None, "", "-"):
        return None
    try:
        return float(str(value).replace(",", "").strip())
    except (TypeError, ValueError):
        return None


def parse_volume(value):
    number = parse_number(value)
    return int(number) if number is not None else None


def fetch_snapshot(source_url, snapshot_date):
    date_str = snapshot_date.strftime("%d/%m/%Y")
    response = requests.get(
        f"{source_url.rstrip('/')}/IndexArchDailyAll/w",
        params={"fmdt": date_str, "todt": date_str, "index": "All", "period": "D"},
        headers=REQUEST_HEADERS,
        timeout=60,
    )
    response.raise_for_status()
    return response.json()


def parse_snapshot(payload, snapshot_date):
    rows_by_name = {}
    for item in (payload.get("Table") or []):
        index_name = (item.get("I_name") or "").strip()
        if not index_name:
            continue
        # Same "last write wins" dedupe as nse_index_daily_snapshot_ingest,
        # in case an index appears more than once in one day's response.
        rows_by_name[index_name] = (
            index_name,
            snapshot_date,
            parse_number(item.get("I_open")),
            parse_number(item.get("I_high")),
            parse_number(item.get("I_low")),
            parse_number(item.get("I_close")),
            parse_volume(item.get("Volume")),
            parse_number(item.get("Turnover")),
        )
    return list(rows_by_name.values())


def upsert_rows(cursor, target_schema, target_table, rows, source_ref):
    statement = sql.SQL(
        """
        INSERT INTO {}.{}
            ("IndexName", "TradeDate", "OpenPrice", "HighPrice", "LowPrice",
             "ClosePrice", "Volume", "TurnoverInrCr", "DataSource", "SourceFile")
        VALUES %s
        ON CONFLICT ("IndexName", "TradeDate") DO UPDATE SET
            "OpenPrice" = EXCLUDED."OpenPrice",
            "HighPrice" = EXCLUDED."HighPrice",
            "LowPrice" = EXCLUDED."LowPrice",
            "ClosePrice" = EXCLUDED."ClosePrice",
            "Volume" = EXCLUDED."Volume",
            "TurnoverInrCr" = EXCLUDED."TurnoverInrCr",
            "DataSource" = EXCLUDED."DataSource",
            "SourceFile" = EXCLUDED."SourceFile",
            "CreatedAt" = now();
        """
    ).format(sql.Identifier(target_schema), sql.Identifier(target_table))
    values = [row + ("BSE", source_ref) for row in rows]
    return execute_values_counted(cursor, statement, values)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--environment", default=None)
    parser.add_argument(
        "--snapshot-date",
        type=date.fromisoformat,
        default=datetime.now(IST).date() - timedelta(days=1),
        help="Snapshot date in YYYY-MM-DD format; defaults to the most recent IST trading day (yesterday, IST)",
    )
    args = parser.parse_args()

    conn = connect_to_postgres(args.environment)
    cursor = conn.cursor()
    log_id = None
    try:
        config = get_job_config(cursor, JOB_NAME)
        log_id = log_run_start(cursor, JOB_NAME, datetime.utcnow())
        conn.commit()
        if not config["enabled"]:
            set_job_status(cursor, JOB_NAME, "skipped")
            log_run_end(cursor, log_id, "skipped")
            conn.commit()
            return

        payload = fetch_snapshot(config["source_url"], args.snapshot_date)
        rows = parse_snapshot(payload, args.snapshot_date)
        source_ref = f"IndexArchDailyAll fmdt={args.snapshot_date}"
        rows_updated = upsert_rows(
            cursor, config["target_schema"], config["target_table"], rows, source_ref
        ) if rows else 0
        set_job_status(cursor, JOB_NAME, "success")
        log_run_end(
            cursor,
            log_id,
            "success",
            rows_updated=rows_updated,
            watermark_value=str(args.snapshot_date),
        )
        conn.commit()
        print(f"Snapshot: {source_ref}")
        print(f"BSE index rows parsed: {len(rows)}, rows upserted: {rows_updated}")
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

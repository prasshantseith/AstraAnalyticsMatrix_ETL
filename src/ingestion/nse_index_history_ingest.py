import argparse
import os
import sys
import time
from datetime import date, datetime, timedelta

import psycopg2
import requests
from psycopg2 import sql

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from utils.db import execute_values_counted
from utils.etl_job import get_job_config, log_run_end, log_run_start, set_job_status
from utils.keyvault import get_db_dsn

JOB_NAME = "nse_index_history_ingest"
INDEX_ENDPOINT = "/api/historical/indicesHistory"
REQUEST_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    "Accept": "application/json,text/plain,*/*",
    "Referer": "https://www.nseindia.com/",
}


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


def parse_date(value):
    for format_string in ("%d-%b-%Y", "%d-%m-%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(str(value).strip(), format_string).date()
        except ValueError:
            continue
    return None


def response_rows(payload):
    if isinstance(payload, list):
        return payload
    for key in ("data", "indexCloseOnlineRecords", "dataRecords"):
        if isinstance(payload.get(key), list):
            return payload[key]
    return []


def field(row, *names):
    for name in names:
        if row.get(name) is not None:
            return row[name]
    return None


def fetch_history(session, base_url, index_type, start_date, end_date):
    response = session.get(
        f"{base_url.rstrip('/')}{INDEX_ENDPOINT}",
        params={
            "indexType": index_type,
            "from": start_date.strftime("%d-%m-%Y"),
            "to": end_date.strftime("%d-%m-%Y"),
        },
        timeout=60,
    )
    response.raise_for_status()
    return response.json()


def transform_rows(index_name, payload):
    rows = []
    for item in response_rows(payload):
        trade_date = parse_date(field(item, "HistoricalDate", "Date", "DATE", "TIMESTAMP"))
        if trade_date is None:
            continue
        rows.append((
            index_name,
            trade_date,
            parse_number(field(item, "OPEN", "Open", "open")),
            parse_number(field(item, "HIGH", "High", "high")),
            parse_number(field(item, "LOW", "Low", "low")),
            parse_number(field(item, "CLOSE", "Close", "close")),
            parse_volume(field(item, "Volume", "VOLUME", "volume")),
            parse_number(field(item, "Turnover", "TURNOVER", "Turnover (Rs. Cr)", "turnover")),
        ))
    return rows


def upsert_rows(cursor, target_schema, target_table, rows):
    statement = sql.SQL(
        """
        INSERT INTO {}.{}
            ("IndexName", "TradeDate", "OpenPrice", "HighPrice", "LowPrice",
             "ClosePrice", "Volume", "TurnoverInrCr")
        VALUES %s
        ON CONFLICT ("IndexName", "TradeDate") DO UPDATE SET
            "OpenPrice" = EXCLUDED."OpenPrice",
            "HighPrice" = EXCLUDED."HighPrice",
            "LowPrice" = EXCLUDED."LowPrice",
            "ClosePrice" = EXCLUDED."ClosePrice",
            "Volume" = EXCLUDED."Volume",
            "TurnoverInrCr" = EXCLUDED."TurnoverInrCr",
            "CreatedAt" = now();
        """
    ).format(sql.Identifier(target_schema), sql.Identifier(target_table))
    return execute_values_counted(cursor, statement, rows)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--environment", default=None)
    parser.add_argument("--index", dest="index_name", default=None)
    parser.add_argument("--start-date", type=date.fromisoformat, default=None)
    parser.add_argument("--end-date", type=date.fromisoformat, default=date.today())
    parser.add_argument("--sleep-seconds", type=float, default=0.5)
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

        query = 'SELECT "IndexName", "NseIndexType", "StartDate" FROM "Indices"."IndexConfig" WHERE "Enabled" = true'
        parameters = ()
        if args.index_name:
            query += ' AND "IndexName" = %s'
            parameters = (args.index_name,)
        query += ' ORDER BY "IndexName"'
        cursor.execute(query, parameters)
        indexes = cursor.fetchall()
        session = requests.Session()
        session.headers.update(REQUEST_HEADERS)
        total_rows = 0
        for index_name, index_type, configured_start in indexes:
            current = args.start_date or configured_start
            while current <= args.end_date:
                chunk_end = min(current + timedelta(days=364), args.end_date)
                payload = fetch_history(session, config["source_url"], index_type, current, chunk_end)
                rows = transform_rows(index_name, payload)
                if rows:
                    total_rows += upsert_rows(cursor, config["target_schema"], config["target_table"], rows)
                    conn.commit()
                print(f"{index_name}: {current} to {chunk_end}, {len(rows)} rows")
                current = chunk_end + timedelta(days=1)
                if args.sleep_seconds:
                    time.sleep(args.sleep_seconds)

        set_job_status(cursor, JOB_NAME, "success")
        log_run_end(cursor, log_id, "success", rows_updated=total_rows)
        conn.commit()
        print(f"Index history ingest completed. Rows upserted: {total_rows}")
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
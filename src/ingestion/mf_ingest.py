import argparse
import os
import sys
from datetime import datetime

import psycopg2
import requests
from psycopg2 import sql

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from utils.keyvault import get_db_dsn
from utils.etl_job import get_job_config, set_job_status, log_run_start, log_run_end
from utils.db import execute_values_counted

JOB_NAME = "mf_nav_ingest"


# -----------------------------
# 1. Connect to Supabase PostgreSQL
# -----------------------------
def connect_to_postgres(environment):
    return psycopg2.connect(get_db_dsn(environment))


# -----------------------------
# 3. Fetch AMFI NAV File
# -----------------------------
def fetch_amfi_nav_file(source_url):
    response = requests.get(source_url, timeout=60)

    if response.status_code != 200:
        raise Exception(f"AMFI NAV file fetch failed: {response.status_code}")

    return response.text


# -----------------------------
# 4. Transform AMFI Rows
# -----------------------------
def transform_rows(text):
    rows = []

    for line in text.splitlines():
        line = line.strip()

        if not line:
            continue

        fields = [field.strip() for field in line.split(";")]

        if len(fields) != 8 or not fields[0].isdigit():
            # Category headers, AMC headers, and the header row itself all
            # fail one of these checks and are skipped.
            continue

        scheme_code, _isin_payout_growth, _isin_div_reinvestment, scheme_name, _plan, _option, nav, nav_date = fields

        try:
            nav_date_pg = datetime.strptime(nav_date, "%d-%b-%Y").date()
        except ValueError:
            continue

        try:
            nav_numeric = float(nav)
        except (TypeError, ValueError):
            continue

        nav_date_key = int(nav_date_pg.strftime("%Y%m%d"))

        rows.append((
            int(scheme_code),
            scheme_name,
            nav_date_pg,
            nav_numeric,
            nav_date_key
        ))

    return rows


# -----------------------------
# 5. Insert into Supabase PostgreSQL
# -----------------------------
def insert_into_postgres(cursor, target_schema, target_table, rows):
    insert_sql = sql.SQL(
        """
        INSERT INTO {}.{}
        ("SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey")
        VALUES %s
        ON CONFLICT ("SchemeCode", "NavDate") DO NOTHING;
        """
    ).format(sql.Identifier(target_schema), sql.Identifier(target_table))

    return execute_values_counted(cursor, insert_sql, rows)


# -----------------------------
# 6. Main
# -----------------------------
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--environment",
        default=None,
        help="dev or prod; defaults to the ENVIRONMENT env var (prod if unset)",
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

        print("Fetching AMFI NAV file...")
        text = fetch_amfi_nav_file(config["source_url"])

        rows = transform_rows(text)

        print(f"Rows parsed: {len(rows)}")

        rows_updated = insert_into_postgres(cursor, config["target_schema"], config["target_table"], rows)
        watermark_value = max((row[2] for row in rows), default=None)

        set_job_status(cursor, JOB_NAME, "success")
        log_run_end(
            cursor,
            log_id,
            "success",
            rows_updated=rows_updated,
            watermark_value=str(watermark_value) if watermark_value else None,
        )
        conn.commit()

        print("Insert completed.")
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

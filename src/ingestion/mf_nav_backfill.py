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

JOB_NAME = "mf_nav_backfill"


# -----------------------------
# 1. Connect to Supabase PostgreSQL
# -----------------------------
def connect_to_postgres(environment):
    return psycopg2.connect(get_db_dsn(environment))


# -----------------------------
# 2. Active scheme codes from MF.MF
# -----------------------------
def fetch_active_scheme_codes(cursor, after_scheme_code=None):
    query = """
        SELECT "SchemeCode"
        FROM "MF"."MF"
        WHERE "IsActive" = true AND "SchemeCode" IS NOT NULL
    """
    parameters = ()
    if after_scheme_code is not None:
        query += ' AND "SchemeCode" > %s'
        parameters = (after_scheme_code,)
    query += ' ORDER BY "SchemeCode"'
    cursor.execute(query, parameters)
    return [row[0] for row in cursor.fetchall()]


# -----------------------------
# 3. Fetch full NAV history for one scheme
# -----------------------------
def fetch_scheme_history(base_url, scheme_code):
    url = f"{base_url.rstrip('/')}/{scheme_code}"
    response = requests.get(url, timeout=30)

    if response.status_code != 200:
        raise Exception(f"MFAPI failed for scheme {scheme_code}: {response.status_code}")

    return response.json()


# -----------------------------
# 4. Transform history rows
# -----------------------------
def transform_history(scheme_code, payload):
    rows = []
    scheme_name = (payload.get("meta") or {}).get("scheme_name")

    for item in payload.get("data", []):
        nav = item.get("nav")
        nav_date = item.get("date")

        if nav is None or nav_date is None:
            continue

        try:
            nav_date_pg = datetime.strptime(nav_date, "%d-%m-%Y").date()
        except ValueError:
            continue

        try:
            nav_numeric = float(nav)
        except (TypeError, ValueError):
            continue

        nav_date_key = int(nav_date_pg.strftime("%Y%m%d"))

        rows.append((
            scheme_code,
            scheme_name,
            nav_date_pg,
            nav_numeric,
            nav_date_key
        ))

    return rows


# -----------------------------
# 5. Insert into MF.MF_NAV
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
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Only backfill the first N active schemes (for testing)",
    )
    parser.add_argument(
        "--scheme-code",
        type=int,
        default=None,
        help="Only backfill this single scheme code (for testing), skips the MF.MF lookup",
    )
    parser.add_argument(
        "--scheme-codes",
        default=None,
        help="Comma-separated scheme codes to backfill (e.g. for retrying failures), skips the MF.MF lookup",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=float,
        default=0.2,
        help="Delay between mfapi.in requests",
    )
    parser.add_argument(
        "--resume-after-scheme-code",
        type=int,
        default=None,
        help="Resume the MF.MF lookup after this scheme code (e.g. to continue a run cut off by the job timeout)",
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

        if args.scheme_codes is not None:
            scheme_codes = [int(code.strip()) for code in args.scheme_codes.split(",") if code.strip()]
        elif args.scheme_code is not None:
            scheme_codes = [args.scheme_code]
        else:
            scheme_codes = fetch_active_scheme_codes(cursor, args.resume_after_scheme_code)
            if args.limit is not None:
                scheme_codes = scheme_codes[:args.limit]

        print(f"Active schemes to backfill: {len(scheme_codes)}")

        total_rows_updated = 0
        max_nav_date = None
        failed_schemes = []

        for i, scheme_code in enumerate(scheme_codes, start=1):
            try:
                payload = fetch_scheme_history(config["source_url"], scheme_code)
                rows = transform_history(scheme_code, payload)
                rows_updated = 0

                if rows:
                    rows_updated = insert_into_postgres(cursor, config["target_schema"], config["target_table"], rows)
                    conn.commit()
                    total_rows_updated += rows_updated

                    scheme_max_date = max(row[2] for row in rows)
                    if max_nav_date is None or scheme_max_date > max_nav_date:
                        max_nav_date = scheme_max_date

                print(f"[{i}/{len(scheme_codes)}] scheme {scheme_code}: {len(rows)} rows fetched, {rows_updated} inserted")
            except Exception as exc:
                conn.rollback()
                failed_schemes.append(scheme_code)
                print(f"[{i}/{len(scheme_codes)}] scheme {scheme_code} FAILED: {exc}")

            if args.sleep_seconds:
                time.sleep(args.sleep_seconds)

        status = "success" if not failed_schemes else "success_with_errors"
        error_message = None
        if failed_schemes:
            shown = failed_schemes[:20]
            suffix = ", ..." if len(failed_schemes) > 20 else ""
            error_message = f"{len(failed_schemes)} scheme(s) failed: {shown}{suffix}"

        set_job_status(cursor, JOB_NAME, status)
        log_run_end(
            cursor,
            log_id,
            status,
            rows_updated=total_rows_updated,
            watermark_value=str(max_nav_date) if max_nav_date else None,
            error_message=error_message,
        )
        conn.commit()

        print(f"Backfill completed. Rows inserted: {total_rows_updated}. Failed schemes: {len(failed_schemes)}")
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

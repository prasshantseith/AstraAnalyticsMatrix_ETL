import argparse
import os
import sys
from datetime import datetime

import psycopg2
import requests
from psycopg2 import sql
from psycopg2.extras import execute_values

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from utils.keyvault import get_db_dsn
from utils.etl_job import get_job_config, set_job_status, log_run_start, log_run_end

JOB_NAME = "mf_metadata_sync"
STALE_AFTER_DAYS = 5


# -----------------------------
# 1. Connect to Supabase PostgreSQL
# -----------------------------
def connect_to_postgres(environment):
    return psycopg2.connect(get_db_dsn(environment))


# -----------------------------
# 2. Fetch AMFI NAV File
# -----------------------------
def fetch_amfi_file(source_url):
    response = requests.get(source_url, timeout=60)

    if response.status_code != 200:
        raise Exception(f"AMFI NAV file fetch failed: {response.status_code}")

    return response.text


# -----------------------------
# 3. Parse AMFI Rows
# -----------------------------
def parse_amfi_rows(text):
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

        scheme_code, isin_payout_growth, isin_div_reinvestment, scheme_name, plan, option, nav, date_str = fields

        try:
            nav_date = datetime.strptime(date_str, "%d-%b-%Y").date()
        except ValueError:
            continue

        isin_payout_growth = None if isin_payout_growth in ("-", "") else isin_payout_growth
        isin_div_reinvestment = None if isin_div_reinvestment in ("-", "") else isin_div_reinvestment

        is_growth = "growth" in option.lower()
        isin_growth = isin_payout_growth if is_growth else None
        isin_div_payout = None if is_growth else isin_payout_growth

        rows.append((
            int(scheme_code),
            scheme_name,
            isin_growth,
            isin_div_payout,
            isin_div_reinvestment,
            nav_date,
        ))

    return rows


# -----------------------------
# 4. Upsert MF Metadata
# -----------------------------
def upsert_mf_metadata(cursor, target_schema, target_table, rows):
    upsert_sql = sql.SQL(
        """
        INSERT INTO {}.{}
            ("SchemeCode", "SchemeName", "isinGrowth", "isinDivPayout", "isinDivReinvestment", latest_nav_date, "IsActive")
        VALUES %s
        ON CONFLICT ("SchemeCode") DO UPDATE SET
            "SchemeName" = EXCLUDED."SchemeName",
            "isinGrowth" = COALESCE(EXCLUDED."isinGrowth", "isinGrowth"),
            "isinDivPayout" = COALESCE(EXCLUDED."isinDivPayout", "isinDivPayout"),
            "isinDivReinvestment" = COALESCE(EXCLUDED."isinDivReinvestment", "isinDivReinvestment"),
            latest_nav_date = EXCLUDED.latest_nav_date,
            "IsActive" = true;
        """
    ).format(sql.Identifier(target_schema), sql.Identifier(target_table))

    values = [row + (True,) for row in rows]
    execute_values(cursor, upsert_sql, values)
    return cursor.rowcount


def deactivate_stale_schemes(cursor, target_schema, target_table):
    update_sql = sql.SQL(
        """
        UPDATE {}.{}
        SET "IsActive" = false
        WHERE "IsActive" IS DISTINCT FROM false
          AND (latest_nav_date IS NULL OR latest_nav_date < CURRENT_DATE - %s::interval);
        """
    ).format(sql.Identifier(target_schema), sql.Identifier(target_table))

    cursor.execute(update_sql, (f"{STALE_AFTER_DAYS} days",))
    return cursor.rowcount


# -----------------------------
# 5. Main
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
        text = fetch_amfi_file(config["source_url"])

        rows = parse_amfi_rows(text)
        print(f"Scheme rows parsed: {len(rows)}")

        rows_updated = upsert_mf_metadata(cursor, config["target_schema"], config["target_table"], rows)
        deactivated = deactivate_stale_schemes(cursor, config["target_schema"], config["target_table"])
        print(f"Rows upserted: {rows_updated}, schemes marked inactive: {deactivated}")

        watermark_value = max((row[5] for row in rows), default=None)

        set_job_status(cursor, JOB_NAME, "success")
        log_run_end(
            cursor,
            log_id,
            "success",
            rows_updated=rows_updated,
            watermark_value=str(watermark_value) if watermark_value else None,
        )
        conn.commit()

        print("Metadata sync completed.")
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

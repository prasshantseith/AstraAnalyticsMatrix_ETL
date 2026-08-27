import argparse
import os
import sys
from datetime import datetime

import psycopg2
import requests
from psycopg2 import sql

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from utils.etl_job import get_job_config, set_job_status, log_run_start, log_run_end

JOB_NAME = "mf_latest_nav_date_sync"


def connect_to_postgres(environment):
    from utils.keyvault import get_db_dsn

    return psycopg2.connect(get_db_dsn(environment))


def fetch_latest_nav(source_url):
    response = requests.get(source_url, timeout=60)
    response.raise_for_status()
    return response.json()


def transform_latest_nav(data):
    rows = []

    for item in data:
        scheme_code = item.get("schemeCode")
        nav_date = item.get("date")

        if scheme_code is None or not nav_date:
            continue

        try:
            rows.append((int(scheme_code), datetime.strptime(nav_date, "%d-%m-%Y").date()))
        except (TypeError, ValueError):
            continue

    return rows


def update_latest_nav_dates(cursor, target_schema, target_table, rows):
    update_sql = sql.SQL(
        """
        UPDATE {}.{} AS mf
        SET latest_nav_date = latest.nav_date
        FROM (VALUES %s) AS latest(scheme_code, nav_date)
        WHERE mf."SchemeCode" = latest.scheme_code
          AND mf.latest_nav_date IS DISTINCT FROM latest.nav_date;
        """
    ).format(sql.Identifier(target_schema), sql.Identifier(target_table))

    from psycopg2.extras import execute_values

    execute_values(cursor, update_sql, rows, template="(%s, %s)")
    return cursor.rowcount


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
        log_id = log_run_start(cursor, JOB_NAME, datetime.utcnow())
        conn.commit()

        if not config["enabled"]:
            print(f"Job '{JOB_NAME}' is disabled in ETL.ETL_CONFIG, skipping.")
            set_job_status(cursor, JOB_NAME, "skipped")
            log_run_end(cursor, log_id, "skipped")
            conn.commit()
            return

        data = fetch_latest_nav(config["source_url"])
        rows = transform_latest_nav(data)
        rows_updated = update_latest_nav_dates(
            cursor, config["target_schema"], config["target_table"], rows
        )

        set_job_status(cursor, JOB_NAME, "success")
        log_run_end(
            cursor,
            log_id,
            "success",
            rows_updated=rows_updated,
            watermark_value=str(max((row[1] for row in rows), default=None)),
        )
        conn.commit()
        print(f"Latest NAV records received: {len(data)}")
        print(f"Valid scheme dates: {len(rows)}, MF rows updated: {rows_updated}")
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
import argparse
import os
import sys
from datetime import datetime

import psycopg2
from psycopg2 import sql

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from utils.etl_job import get_job_config, log_run_end, log_run_start, set_job_status
from utils.keyvault import get_db_dsn


def connect_to_postgres(environment):
    return psycopg2.connect(get_db_dsn(environment), connect_timeout=15)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--environment", default=None)
    parser.add_argument("--job-name", required=True, dest="job_name", help="ETL_CONFIG job_name for status/log tracking")
    parser.add_argument(
        "--procedure",
        required=True,
        help='Schema-qualified procedure name, e.g. "MF.usp_RefreshMFPerformance"',
    )
    parser.add_argument(
        "--statement-timeout-seconds",
        type=int,
        default=600,
        dest="statement_timeout_seconds",
        help="Overrides Postgres's statement_timeout for just this CALL (default: 600). "
             "The connection role has a short default (observed: ~120s) meant for quick "
             "pooled queries, too short for these analytical refresh procedures on "
             "tables that keep growing.",
    )
    args = parser.parse_args()

    schema, name = args.procedure.split(".", 1)

    conn = connect_to_postgres(args.environment)
    cursor = conn.cursor()
    log_id = None
    try:
        config = get_job_config(cursor, args.job_name)
        log_id = log_run_start(cursor, args.job_name, datetime.utcnow())
        conn.commit()
        if not config["enabled"]:
            set_job_status(cursor, args.job_name, "skipped")
            log_run_end(cursor, log_id, "skipped")
            conn.commit()
            return

        # SET LOCAL scopes this to the current transaction only, so it
        # can't leak into any later statement on this connection. SET
        # doesn't accept bind parameters ("$1" isn't valid there), so the
        # value is embedded as a safely-quoted SQL literal instead - safe
        # here regardless, since argparse already guarantees it's an int.
        cursor.execute(
            sql.SQL("SET LOCAL statement_timeout = {}").format(
                sql.Literal(f"{args.statement_timeout_seconds}s")
            )
        )
        cursor.execute(sql.SQL("CALL {}.{}()").format(sql.Identifier(schema), sql.Identifier(name)))
        conn.commit()

        set_job_status(cursor, args.job_name, "success")
        log_run_end(cursor, log_id, "success")
        conn.commit()
        print(f"Called {args.procedure} successfully")
    except Exception as exc:
        conn.rollback()
        set_job_status(cursor, args.job_name, "failed")
        if log_id is not None:
            log_run_end(cursor, log_id, "failed", error_message=str(exc))
        conn.commit()
        raise
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    main()

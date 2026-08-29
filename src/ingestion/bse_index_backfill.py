import argparse
import os
import sys
import time
from datetime import date, datetime, timedelta

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from src.ingestion.bse_index_ingest import (
    connect_to_postgres,
    fetch_snapshot,
    parse_snapshot,
    upsert_rows,
)
from utils.etl_job import get_job_config, log_run_end, log_run_start, set_job_status

JOB_NAME = "bse_index_backfill"
# Empirically confirmed available back to at least 1990-01-01 (BSE's
# IndexArchDailyAll returns real rows for that date); not exhaustively
# verified earlier than that.
DEFAULT_START_DATE = date(1990, 1, 1)


def daterange(start_date, end_date):
    current = start_date
    while current <= end_date:
        yield current
        current += timedelta(days=1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--environment", default=None)
    parser.add_argument(
        "--start-date",
        type=date.fromisoformat,
        default=DEFAULT_START_DATE,
        help="Backfill start date in YYYY-MM-DD format; defaults to 1990-01-01",
    )
    parser.add_argument(
        "--end-date",
        type=date.fromisoformat,
        default=date.today() - timedelta(days=1),
        help="Backfill end date in YYYY-MM-DD format; defaults to yesterday",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=float,
        default=0.5,
        help="Delay between bseindia.com requests",
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

        total_rows = 0
        no_data_dates = []
        failed_dates = []
        last_success_date = None

        for snapshot_date in daterange(args.start_date, args.end_date):
            if snapshot_date.weekday() >= 5:
                continue

            try:
                payload = fetch_snapshot(config["source_url"], snapshot_date)
                rows = parse_snapshot(payload, snapshot_date)
            except Exception as exc:
                conn.rollback()
                failed_dates.append(snapshot_date)
                print(f"{snapshot_date}: FAILED ({exc})")
                if args.sleep_seconds:
                    time.sleep(args.sleep_seconds)
                continue

            if not rows:
                # Weekend already filtered above; an empty response here
                # means a public holiday or a date before this index existed.
                no_data_dates.append(snapshot_date)
            else:
                source_ref = f"IndexArchDailyAll fmdt={snapshot_date}"
                rows_updated = upsert_rows(
                    cursor, config["target_schema"], config["target_table"], rows, source_ref
                )
                conn.commit()
                total_rows += rows_updated
                last_success_date = snapshot_date
                print(f"{snapshot_date}: {len(rows)} rows parsed, {rows_updated} upserted")

            if args.sleep_seconds:
                time.sleep(args.sleep_seconds)

        status = "success" if not failed_dates else "success_with_errors"
        error_message = None
        if failed_dates:
            shown = [str(d) for d in failed_dates[:20]]
            suffix = ", ..." if len(failed_dates) > 20 else ""
            error_message = f"{len(failed_dates)} date(s) failed: {shown}{suffix}"

        set_job_status(cursor, JOB_NAME, status)
        log_run_end(
            cursor,
            log_id,
            status,
            rows_updated=total_rows,
            watermark_value=str(last_success_date) if last_success_date else None,
            error_message=error_message,
        )
        conn.commit()
        print(
            f"Backfill completed. Rows upserted: {total_rows}. "
            f"Holidays/no-data days: {len(no_data_dates)}. Failed: {len(failed_dates)}"
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

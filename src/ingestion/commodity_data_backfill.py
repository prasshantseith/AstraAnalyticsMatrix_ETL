import argparse
import os
import sys
from datetime import date, datetime, timedelta

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from src.ingestion.commodity_data_ingest import connect_to_postgres, upsert_rows
from utils.etl_job import get_job_config, log_run_end, log_run_start, set_job_status
from utils.yahoo_finance import fetch_ohlc

JOB_NAME = "commodity_data_backfill"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--environment", default=None)
    parser.add_argument(
        "--start-date",
        type=date.fromisoformat,
        default=None,
        help="Backfill start date in YYYY-MM-DD format; defaults to each "
             "commodity's configured StartDate (earliest Yahoo Finance history)",
    )
    parser.add_argument(
        "--end-date",
        type=date.fromisoformat,
        default=date.today() - timedelta(days=1),
        help="Backfill end date in YYYY-MM-DD format; defaults to yesterday",
    )
    parser.add_argument(
        "--commodity",
        dest="commodity_name",
        default=None,
        help="Only backfill this single commodity (optional, e.g. for retrying one)",
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

        query = (
            'SELECT "CommodityName", "YahooSymbol", "StartDate" '
            'FROM "Commodities"."CommodityConfig" WHERE "Enabled" = true'
        )
        parameters = ()
        if args.commodity_name:
            query += ' AND "CommodityName" = %s'
            parameters = (args.commodity_name,)
        query += ' ORDER BY "CommodityName"'
        cursor.execute(query, parameters)
        commodities = cursor.fetchall()

        total_rows = 0
        for commodity_name, yahoo_symbol, configured_start in commodities:
            start_date = args.start_date or configured_start
            rows = fetch_ohlc(yahoo_symbol, start_date=start_date, end_date=args.end_date)
            if rows:
                total_rows += upsert_rows(
                    cursor, config["target_schema"], config["target_table"],
                    commodity_name, yahoo_symbol, rows,
                )
                conn.commit()
            print(f"{commodity_name}: {start_date} to {args.end_date}, {len(rows)} rows upserted")

        set_job_status(cursor, JOB_NAME, "success")
        log_run_end(cursor, log_id, "success", rows_updated=total_rows)
        conn.commit()
        print(f"Commodity data backfill completed. Rows upserted: {total_rows}")
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

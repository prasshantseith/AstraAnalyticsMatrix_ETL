import argparse
import os
import sys
from datetime import date, datetime, timedelta

import psycopg2
from psycopg2 import sql

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from utils.db import execute_values_counted
from utils.etl_job import get_job_config, log_run_end, log_run_start, set_job_status
from utils.keyvault import get_db_dsn
from utils.yahoo_finance import fetch_ohlc

JOB_NAME = "commodity_data_ingest"


def connect_to_postgres(environment):
    return psycopg2.connect(get_db_dsn(environment), connect_timeout=15)


def upsert_rows(cursor, target_schema, target_table, commodity_name, source_symbol, rows):
    values = [
        (
            commodity_name,
            row["trade_date"],
            row["open"],
            row["high"],
            row["low"],
            row["close"],
            row["volume"],
            "YAHOO",
            source_symbol,
        )
        for row in rows
    ]
    statement = sql.SQL(
        """
        INSERT INTO {}.{}
            ("CommodityName", "TradeDate", "OpenPrice", "HighPrice", "LowPrice",
             "ClosePrice", "Volume", "DataSource", "SourceSymbol")
        VALUES %s
        ON CONFLICT ("CommodityName", "TradeDate") DO UPDATE SET
            "OpenPrice" = EXCLUDED."OpenPrice",
            "HighPrice" = EXCLUDED."HighPrice",
            "LowPrice" = EXCLUDED."LowPrice",
            "ClosePrice" = EXCLUDED."ClosePrice",
            "Volume" = EXCLUDED."Volume",
            "DataSource" = EXCLUDED."DataSource",
            "SourceSymbol" = EXCLUDED."SourceSymbol",
            "CreatedAt" = now();
        """
    ).format(sql.Identifier(target_schema), sql.Identifier(target_table))
    return execute_values_counted(cursor, statement, values)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--environment", default=None)
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

        cursor.execute(
            'SELECT "CommodityName", "YahooSymbol", "StartDate" '
            'FROM "Commodities"."CommodityConfig" WHERE "Enabled" = true ORDER BY "CommodityName"'
        )
        commodities = cursor.fetchall()

        today = date.today()
        total_rows = 0
        for commodity_name, yahoo_symbol, configured_start in commodities:
            cursor.execute(
                'SELECT MAX("TradeDate") FROM "Commodities"."CommodityData" WHERE "CommodityName" = %s',
                (commodity_name,),
            )
            last_loaded = cursor.fetchone()[0]
            start_date = (last_loaded + timedelta(days=1)) if last_loaded else configured_start

            if start_date > today:
                print(f"{commodity_name}: up to date")
                continue

            rows = fetch_ohlc(yahoo_symbol, start_date=start_date, end_date=today)
            if rows:
                total_rows += upsert_rows(
                    cursor, config["target_schema"], config["target_table"],
                    commodity_name, yahoo_symbol, rows,
                )
                conn.commit()
            print(f"{commodity_name}: {start_date} to {today}, {len(rows)} rows upserted")

        set_job_status(cursor, JOB_NAME, "success")
        log_run_end(cursor, log_id, "success", rows_updated=total_rows)
        conn.commit()
        print(f"Commodity data ingest completed. Rows upserted: {total_rows}")
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

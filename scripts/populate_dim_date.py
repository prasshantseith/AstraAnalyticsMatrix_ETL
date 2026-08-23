import argparse
import calendar
import os
import sys
from datetime import date, timedelta

import psycopg2

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.keyvault import get_db_dsn
from utils.db import execute_values_counted


def connect_to_postgres(environment):
    return psycopg2.connect(get_db_dsn(environment))


def quarter_of(month):
    return (month - 1) // 3 + 1


def quarter_bounds(year, quarter):
    start_month = (quarter - 1) * 3 + 1
    end_month = start_month + 2
    q_start = date(year, start_month, 1)
    q_end = date(year, end_month, calendar.monthrange(year, end_month)[1])
    return q_start, q_end


def build_row(d, today):
    year, month, day = d.year, d.month, d.day
    quarter = quarter_of(month)

    weekday = d.weekday()  # Monday=0 .. Sunday=6 (ISO)
    day_of_week = weekday + 1  # Monday=1 .. Sunday=7
    week_number = d.isocalendar()[1]

    month_start = date(year, month, 1)
    month_end = date(year, month, calendar.monthrange(year, month)[1])
    year_start = date(year, 1, 1)
    year_end = date(year, 12, 31)
    qtr_start, qtr_end = quarter_bounds(year, quarter)
    week_start = d - timedelta(days=weekday)
    week_end = week_start + timedelta(days=6)

    is_weekend = day_of_week in (6, 7)

    return (
        int(d.strftime("%Y%m%d")),
        d,
        year,
        quarter,
        month,
        calendar.month_name[month],
        day,
        calendar.day_name[weekday],
        day_of_week,
        week_number,
        year * 100 + month,
        f"{calendar.month_abbr[month]}-{year}",
        year_start,
        year_end,
        qtr_start,
        qtr_end,
        month_start,
        month_end,
        week_start,
        week_end,
        d == today,
        week_start <= today <= week_end,
        year == today.year and month == today.month,
        year == today.year,
        is_weekend,
        False,
        None,
        not is_weekend,
    )


def build_rows(start_year, end_year):
    today = date.today()
    current = date(start_year, 1, 1)
    end = date(end_year, 12, 31)
    rows = []

    while current <= end:
        rows.append(build_row(current, today))
        current += timedelta(days=1)

    return rows


def upsert_dim_date(cursor, rows):
    upsert_sql = """
        INSERT INTO "Report"."dimDate" (
            "DateKey", "Date", "Year", "Quarter", "Month", "MonthName", "Day", "DayName",
            "DayOfWeek", "WeekNumber", "MonthYearKey", "MonthYearName",
            "YearStartDate", "YearEndDate", "QtrStartDate", "QtrEndDate",
            "MonthStartDate", "MonthEndDate", "WeekStartDate", "WeekEndDate",
            "IsCurrentDate", "IsCurrentWeek", "IsCurrentMonth", "IsCurrentYear",
            "IsWeekend", "IsPublicHoliday", "HolidayName", "IsWorkingday"
        )
        VALUES %s
        ON CONFLICT ("DateKey") DO UPDATE SET
            "Year" = EXCLUDED."Year",
            "Quarter" = EXCLUDED."Quarter",
            "Month" = EXCLUDED."Month",
            "MonthName" = EXCLUDED."MonthName",
            "Day" = EXCLUDED."Day",
            "DayName" = EXCLUDED."DayName",
            "DayOfWeek" = EXCLUDED."DayOfWeek",
            "WeekNumber" = EXCLUDED."WeekNumber",
            "MonthYearKey" = EXCLUDED."MonthYearKey",
            "MonthYearName" = EXCLUDED."MonthYearName",
            "YearStartDate" = EXCLUDED."YearStartDate",
            "YearEndDate" = EXCLUDED."YearEndDate",
            "QtrStartDate" = EXCLUDED."QtrStartDate",
            "QtrEndDate" = EXCLUDED."QtrEndDate",
            "MonthStartDate" = EXCLUDED."MonthStartDate",
            "MonthEndDate" = EXCLUDED."MonthEndDate",
            "WeekStartDate" = EXCLUDED."WeekStartDate",
            "WeekEndDate" = EXCLUDED."WeekEndDate",
            "IsCurrentDate" = EXCLUDED."IsCurrentDate",
            "IsCurrentWeek" = EXCLUDED."IsCurrentWeek",
            "IsCurrentMonth" = EXCLUDED."IsCurrentMonth",
            "IsCurrentYear" = EXCLUDED."IsCurrentYear",
            "IsWeekend" = EXCLUDED."IsWeekend",
            "IsWorkingday" = EXCLUDED."IsWorkingday";
    """

    return execute_values_counted(cursor, upsert_sql, rows)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--environment",
        default=None,
        help="dev or prod; defaults to the ENVIRONMENT env var (prod if unset)",
    )
    parser.add_argument("--start-year", type=int, default=1995)
    parser.add_argument("--end-year", type=int, default=2040)
    args = parser.parse_args()

    rows = build_rows(args.start_year, args.end_year)
    print(f"Dates to load: {len(rows)} ({args.start_year}-01-01 to {args.end_year}-12-31)")

    conn = connect_to_postgres(args.environment)
    cursor = conn.cursor()

    try:
        rows_updated = upsert_dim_date(cursor, rows)
        conn.commit()
        print(f"dimDate rows upserted: {rows_updated}")
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    main()

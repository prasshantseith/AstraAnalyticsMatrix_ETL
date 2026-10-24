-- MCX equivalent of Commodities.CommodityPerformance / usp_RefreshCommodityPerformance
-- (see 20260917010000_create_index_commodity_performance.sql for the
-- established pattern this mirrors exactly): a full-snapshot performance
-- table, refreshed by a stored procedure using the same LATERAL "closest
-- trading day on/before latest_date - N" lookback per period.
--
-- McxBhavCopy holds every contract (every expiry, every strike) per day,
-- not one row per commodity per day like CommodityData - so this procedure
-- first collapses it to the same near-month (nearest-unexpired futures
-- contract) continuous series app/routers/index_data.py's chart endpoint
-- already uses, then runs the identical performance calculation against
-- that series.
CREATE TABLE IF NOT EXISTS "Commodities"."McxPerformance"
(
    "Commodity" character varying(30),
    "LatestClose" numeric(18,4),
    "AsOfDate" date,
    "Day" numeric,
    "Week" numeric,
    "Month" numeric,
    "ThreeMon" numeric,
    "SixMon" numeric,
    "Year" numeric,
    "ThreeYear" numeric,
    "FiveYear" numeric,
    "Close_Day" numeric(18,4),
    "Close_Week" numeric(18,4),
    "Close_Month" numeric(18,4),
    "Close_3Mon" numeric(18,4),
    "Close_6Mon" numeric(18,4),
    "Close_Year" numeric(18,4),
    "Close_3Year" numeric(18,4),
    "Close_5Year" numeric(18,4),
    "HighestClose" numeric(18,4),
    "HighestCloseDate" date,
    "R_Day" bigint,
    "R_Week" bigint,
    "R_Month" bigint,
    "R_3Mon" bigint,
    "R_6Mon" bigint,
    "R_Year" bigint,
    "R_3Year" bigint,
    "R_5Year" bigint
);

ALTER TABLE IF EXISTS "Commodities"."McxPerformance" OWNER to postgres;

do $$
begin
    if not exists (select from pg_roles where rolname = 'app_user') then
        create role app_user nologin;
    end if;
end $$;

REVOKE ALL ON TABLE "Commodities"."McxPerformance" FROM app_user;
GRANT SELECT ON TABLE "Commodities"."McxPerformance" TO app_user;
GRANT ALL ON TABLE "Commodities"."McxPerformance" TO postgres;

CREATE OR REPLACE PROCEDURE "Commodities"."usp_RefreshMcxPerformance"(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_row_count INT;
BEGIN
    DELETE FROM "Commodities"."McxPerformance";

    INSERT INTO "Commodities"."McxPerformance" (
        "Commodity", "LatestClose", "AsOfDate",
        "Day", "Week", "Month", "ThreeMon", "SixMon", "Year", "ThreeYear", "FiveYear",
        "Close_Day", "Close_Week", "Close_Month", "Close_3Mon", "Close_6Mon", "Close_Year", "Close_3Year", "Close_5Year",
        "HighestClose", "HighestCloseDate",
        "R_Day", "R_Week", "R_Month", "R_3Mon", "R_6Mon", "R_Year", "R_3Year", "R_5Year"
    )
    WITH report_date AS (
        SELECT "Date" AS as_of_date
        FROM "Report"."dimDate"
        WHERE "IsWorkingday"   = TRUE
          AND "IsCurrentDate"  = TRUE
          AND "IsCurrentWeek"  = TRUE
          AND "IsCurrentMonth" = TRUE
          AND "IsCurrentYear"  = TRUE
    ),

    -- Near-month (nearest-unexpired futures) continuous series - one row
    -- per Commodity per TradeDate, same selection app/routers/index_data.py
    -- uses for the chart endpoint.
    mcx_near_month AS (
        SELECT "Commodity", "TradeDate", "ClosePrice"
        FROM (
            SELECT
                "Commodity", "TradeDate", "ClosePrice",
                row_number() OVER (PARTITION BY "Commodity", "TradeDate" ORDER BY "ExpiryDate" ASC) AS rn
            FROM "Commodities"."McxBhavCopy"
            WHERE "InstrumentType" IN ('FUTCOM', 'FUTIDX')
              AND "ExpiryDate" >= "TradeDate"
        ) x
        WHERE rn = 1
    ),

    latest AS (
        SELECT
            s."Commodity",
            s."TradeDate"  AS latest_date,
            s."ClosePrice" AS latest_close
        FROM mcx_near_month s
        JOIN report_date rd
          ON s."TradeDate" = rd.as_of_date
    ),

    highest AS (
        SELECT DISTINCT ON ("Commodity")
            "Commodity",
            "ClosePrice" AS max_close,
            "TradeDate"  AS max_close_date
        FROM mcx_near_month
        ORDER BY "Commodity", "ClosePrice" DESC, "TradeDate" DESC
    ),

    returns AS (
        SELECT
            l."Commodity",
            l.latest_date,
            l.latest_close,

            d."ClosePrice"   AS close_1d,
            w."ClosePrice"   AS close_1w,
            m1."ClosePrice"  AS close_1m,
            m3."ClosePrice"  AS close_3m,
            m6."ClosePrice"  AS close_6m,
            y1."ClosePrice"  AS close_1y,
            y3."ClosePrice"  AS close_3y,
            y5."ClosePrice"  AS close_5y,

            h.max_close,
            h.max_close_date

        FROM latest l

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM mcx_near_month
            WHERE "Commodity" = l."Commodity" AND "TradeDate" <= l.latest_date - INTERVAL '1 day'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) d ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM mcx_near_month
            WHERE "Commodity" = l."Commodity" AND "TradeDate" <= l.latest_date - INTERVAL '1 week'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) w ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM mcx_near_month
            WHERE "Commodity" = l."Commodity" AND "TradeDate" <= l.latest_date - INTERVAL '1 month'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) m1 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM mcx_near_month
            WHERE "Commodity" = l."Commodity" AND "TradeDate" <= l.latest_date - INTERVAL '3 months'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) m3 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM mcx_near_month
            WHERE "Commodity" = l."Commodity" AND "TradeDate" <= l.latest_date - INTERVAL '6 months'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) m6 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM mcx_near_month
            WHERE "Commodity" = l."Commodity" AND "TradeDate" <= l.latest_date - INTERVAL '1 year'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) y1 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM mcx_near_month
            WHERE "Commodity" = l."Commodity" AND "TradeDate" <= l.latest_date - INTERVAL '3 years'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) y3 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM mcx_near_month
            WHERE "Commodity" = l."Commodity" AND "TradeDate" <= l.latest_date - INTERVAL '5 years'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) y5 ON true

        LEFT JOIN highest h
          ON h."Commodity" = l."Commodity"
    ),

    calc AS (
        SELECT
            "Commodity",
            latest_date,
            latest_close,

            close_1d, close_1w, close_1m, close_3m, close_6m, close_1y, close_3y, close_5y,
            max_close, max_close_date,

            ROUND(((latest_close - close_1d) / NULLIF(close_1d,0)) * 100, 2) AS ret_1d,
            ROUND(((latest_close - close_1w) / NULLIF(close_1w,0)) * 100, 2) AS ret_1w,
            ROUND(((latest_close - close_1m) / NULLIF(close_1m,0)) * 100, 2) AS ret_1m,
            ROUND(((latest_close - close_3m) / NULLIF(close_3m,0)) * 100, 2) AS ret_3m,
            ROUND(((latest_close - close_6m) / NULLIF(close_6m,0)) * 100, 2) AS ret_6m,
            ROUND(((latest_close - close_1y) / NULLIF(close_1y,0)) * 100, 2) AS ret_1y,
            ROUND((POWER(latest_close / NULLIF(close_3y,0), 1.0/3) - 1) * 100, 2) AS cagr_3y,
            ROUND((POWER(latest_close / NULLIF(close_5y,0), 1.0/5) - 1) * 100, 2) AS cagr_5y

        FROM returns
    )

    SELECT
        "Commodity",
        latest_close    AS "LatestClose",
        latest_date     AS "AsOfDate",

        ret_1d   AS "Day",
        ret_1w   AS "Week",
        ret_1m   AS "Month",
        ret_3m   AS "ThreeMon",
        ret_6m   AS "SixMon",
        ret_1y   AS "Year",
        cagr_3y  AS "ThreeYear",
        cagr_5y  AS "FiveYear",

        close_1d   AS "Close_Day",
        close_1w   AS "Close_Week",
        close_1m   AS "Close_Month",
        close_3m   AS "Close_3Mon",
        close_6m   AS "Close_6Mon",
        close_1y   AS "Close_Year",
        close_3y   AS "Close_3Year",
        close_5y   AS "Close_5Year",

        max_close      AS "HighestClose",
        max_close_date AS "HighestCloseDate",

        RANK() OVER (ORDER BY ret_1d  DESC NULLS LAST) AS "R_Day",
        RANK() OVER (ORDER BY ret_1w  DESC NULLS LAST) AS "R_Week",
        RANK() OVER (ORDER BY ret_1m  DESC NULLS LAST) AS "R_Month",
        RANK() OVER (ORDER BY ret_3m  DESC NULLS LAST) AS "R_3Mon",
        RANK() OVER (ORDER BY ret_6m  DESC NULLS LAST) AS "R_6Mon",
        RANK() OVER (ORDER BY ret_1y  DESC NULLS LAST) AS "R_Year",
        RANK() OVER (ORDER BY cagr_3y DESC NULLS LAST) AS "R_3Year",
        RANK() OVER (ORDER BY cagr_5y DESC NULLS LAST) AS "R_5Year"

    FROM calc;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    RAISE NOTICE 'McxPerformance refreshed with % rows', v_row_count;
END;
$BODY$;
ALTER PROCEDURE "Commodities"."usp_RefreshMcxPerformance"() OWNER TO postgres;

INSERT INTO "ETL"."ETL_CONFIG"
    (job_name, source_url, target_schema, target_table, enabled)
VALUES
    ('refresh_mcx_performance', 'internal:Commodities.usp_RefreshMcxPerformance', 'Commodities', 'usp_RefreshMcxPerformance', true)
ON CONFLICT (job_name) DO UPDATE SET
    source_url = EXCLUDED.source_url,
    target_schema = EXCLUDED.target_schema,
    target_table = EXCLUDED.target_table;

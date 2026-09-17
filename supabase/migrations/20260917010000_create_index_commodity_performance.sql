-- Adds the Indices/Commodities equivalent of Stocks.StockPerformance /
-- usp_RefreshStockPerformance (see that procedure + MF.usp_RefreshMFPerformance
-- for the established pattern this mirrors): a full-snapshot performance
-- table per domain, refreshed by a stored procedure using the same
-- LATERAL "closest trading day on/before latest_date - N" lookback per
-- period and the same RANK() OVER (ORDER BY ... DESC NULLS LAST)
-- unpartitioned per-period ranking.
--
-- Two tables (Indices.IndexPerformance, Commodities.CommodityPerformance)
-- rather than one shared table, matching how the underlying price history
-- already lives in two separate schemas/tables (Indices.IndexData vs.
-- Commodities.CommodityData) with different natural keys (IndexName vs.
-- CommodityName) and different concerns (indices carry an NSE/BSE
-- "Exchange"; commodities are always USD futures, no such concept). The API
-- layer UNIONs the two into one "Symbol" list, the same way
-- app/routers/index_data.py already UNIONs IndexDataCanonical and
-- CommodityData for the existing list/detail endpoints.
CREATE TABLE IF NOT EXISTS "Indices"."IndexPerformance"
(
    "IndexName" character varying(100),
    "Exchange" character varying(20),
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

ALTER TABLE IF EXISTS "Indices"."IndexPerformance" OWNER to postgres;

CREATE TABLE IF NOT EXISTS "Commodities"."CommodityPerformance"
(
    "CommodityName" character varying(30),
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

ALTER TABLE IF EXISTS "Commodities"."CommodityPerformance" OWNER to postgres;

-- app_user may not exist yet in every environment.
do $$
begin
    if not exists (select from pg_roles where rolname = 'app_user') then
        create role app_user nologin;
    end if;
end $$;

REVOKE ALL ON TABLE "Indices"."IndexPerformance" FROM app_user;
GRANT SELECT ON TABLE "Indices"."IndexPerformance" TO app_user;
GRANT ALL ON TABLE "Indices"."IndexPerformance" TO postgres;

REVOKE ALL ON TABLE "Commodities"."CommodityPerformance" FROM app_user;
GRANT SELECT ON TABLE "Commodities"."CommodityPerformance" TO app_user;
GRANT ALL ON TABLE "Commodities"."CommodityPerformance" TO postgres;

-- Procedures: reads from IndexDataCanonical (rebrand-continuous) / CommodityData.
CREATE OR REPLACE PROCEDURE "Indices"."usp_RefreshIndexPerformance"(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_row_count INT;
BEGIN
    DELETE FROM "Indices"."IndexPerformance";

    INSERT INTO "Indices"."IndexPerformance" (
        "IndexName", "Exchange", "LatestClose", "AsOfDate",
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

    latest AS (
        SELECT
            s."IndexName",
            CASE WHEN s."DataSource" = 'BSE' THEN 'BSE' ELSE 'NSE' END AS exchange,
            s."TradeDate"  AS latest_date,
            s."ClosePrice" AS latest_close
        FROM "Indices"."IndexDataCanonical" s
        JOIN report_date rd
          ON s."TradeDate" = rd.as_of_date
    ),

    highest AS (
        SELECT DISTINCT ON ("IndexName")
            "IndexName",
            "ClosePrice" AS max_close,
            "TradeDate"  AS max_close_date
        FROM "Indices"."IndexDataCanonical"
        ORDER BY "IndexName", "ClosePrice" DESC, "TradeDate" DESC
    ),

    returns AS (
        SELECT
            l."IndexName",
            l.exchange,
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
            SELECT "ClosePrice" FROM "Indices"."IndexDataCanonical"
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '1 day'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) d ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM "Indices"."IndexDataCanonical"
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '1 week'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) w ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM "Indices"."IndexDataCanonical"
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '1 month'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) m1 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM "Indices"."IndexDataCanonical"
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '3 months'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) m3 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM "Indices"."IndexDataCanonical"
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '6 months'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) m6 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM "Indices"."IndexDataCanonical"
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '1 year'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) y1 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM "Indices"."IndexDataCanonical"
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '3 years'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) y3 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM "Indices"."IndexDataCanonical"
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '5 years'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) y5 ON true

        LEFT JOIN highest h
          ON h."IndexName" = l."IndexName"
    ),

    calc AS (
        SELECT
            "IndexName",
            exchange,
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
        "IndexName",
        exchange        AS "Exchange",
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
    RAISE NOTICE 'IndexPerformance refreshed with % rows', v_row_count;
END;
$BODY$;
ALTER PROCEDURE "Indices"."usp_RefreshIndexPerformance"() OWNER TO postgres;

CREATE OR REPLACE PROCEDURE "Commodities"."usp_RefreshCommodityPerformance"(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_row_count INT;
BEGIN
    DELETE FROM "Commodities"."CommodityPerformance";

    INSERT INTO "Commodities"."CommodityPerformance" (
        "CommodityName", "LatestClose", "AsOfDate",
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

    latest AS (
        SELECT
            s."CommodityName",
            s."TradeDate"  AS latest_date,
            s."ClosePrice" AS latest_close
        FROM "Commodities"."CommodityData" s
        JOIN report_date rd
          ON s."TradeDate" = rd.as_of_date
    ),

    highest AS (
        SELECT DISTINCT ON ("CommodityName")
            "CommodityName",
            "ClosePrice" AS max_close,
            "TradeDate"  AS max_close_date
        FROM "Commodities"."CommodityData"
        ORDER BY "CommodityName", "ClosePrice" DESC, "TradeDate" DESC
    ),

    returns AS (
        SELECT
            l."CommodityName",
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
            SELECT "ClosePrice" FROM "Commodities"."CommodityData"
            WHERE "CommodityName" = l."CommodityName" AND "TradeDate" <= l.latest_date - INTERVAL '1 day'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) d ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM "Commodities"."CommodityData"
            WHERE "CommodityName" = l."CommodityName" AND "TradeDate" <= l.latest_date - INTERVAL '1 week'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) w ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM "Commodities"."CommodityData"
            WHERE "CommodityName" = l."CommodityName" AND "TradeDate" <= l.latest_date - INTERVAL '1 month'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) m1 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM "Commodities"."CommodityData"
            WHERE "CommodityName" = l."CommodityName" AND "TradeDate" <= l.latest_date - INTERVAL '3 months'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) m3 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM "Commodities"."CommodityData"
            WHERE "CommodityName" = l."CommodityName" AND "TradeDate" <= l.latest_date - INTERVAL '6 months'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) m6 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM "Commodities"."CommodityData"
            WHERE "CommodityName" = l."CommodityName" AND "TradeDate" <= l.latest_date - INTERVAL '1 year'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) y1 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM "Commodities"."CommodityData"
            WHERE "CommodityName" = l."CommodityName" AND "TradeDate" <= l.latest_date - INTERVAL '3 years'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) y3 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM "Commodities"."CommodityData"
            WHERE "CommodityName" = l."CommodityName" AND "TradeDate" <= l.latest_date - INTERVAL '5 years'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) y5 ON true

        LEFT JOIN highest h
          ON h."CommodityName" = l."CommodityName"
    ),

    calc AS (
        SELECT
            "CommodityName",
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
        "CommodityName",
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
    RAISE NOTICE 'CommodityPerformance refreshed with % rows', v_row_count;
END;
$BODY$;
ALTER PROCEDURE "Commodities"."usp_RefreshCommodityPerformance"() OWNER TO postgres;

-- Register both as ETL_CONFIG jobs, same convention as
-- 20260829030000_add_refresh_procedure_jobs.sql.
INSERT INTO "ETL"."ETL_CONFIG"
    (job_name, source_url, target_schema, target_table, enabled)
VALUES
    ('refresh_index_performance', 'internal:Indices.usp_RefreshIndexPerformance', 'Indices', 'usp_RefreshIndexPerformance', true),
    ('refresh_commodity_performance', 'internal:Commodities.usp_RefreshCommodityPerformance', 'Commodities', 'usp_RefreshCommodityPerformance', true)
ON CONFLICT (job_name) DO UPDATE SET
    source_url = EXCLUDED.source_url,
    target_schema = EXCLUDED.target_schema,
    target_table = EXCLUDED.target_table;

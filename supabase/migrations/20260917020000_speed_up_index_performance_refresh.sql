-- Mirrors Stocks.usp_RefreshStockPerformance exactly (same report_date/
-- highest/returns/calc CTE shape, same LATERAL "closest trading day on or
-- before latest_date - N" lookback per period, same unpartitioned RANK()
-- OVER (ORDER BY ... DESC NULLS LAST) per-period ranking), with two
-- adaptations:
--   - No OptionType/ExpiryDate filter (an equity/F&O-only concept that
--     doesn't apply to indices) — replaced with "Exchange", captured
--     straight from the joined row's own DataSource.
--   - Rebrand continuity: a materialized, indexed tmp_index_data_canonical
--     (built once per run from IndexData + IndexNameAlias) stands in for
--     the IndexDataCanonical view. Filtering the view's own COALESCE(...)
--     expression inside each of the ~2,300 per-period LATERAL lookups
--     (291 indices x 8 periods) can't use IndexData's own (IndexName,
--     TradeDate) primary key — Postgres has no way to push an equality
--     filter through a LEFT JOIN + COALESCE back onto the underlying
--     indexed column — so it degenerated to a 50s+ run (confirmed locally;
--     worse in prod) versus Commodities' equivalent procedure (no such
--     view in its path) finishing in under a second. Rebrand history is
--     tiny (48 aliased rows total across all of IndexNameAlias), so
--     materializing it once per run is cheap; every lookup after that hits
--     a real, indexed temp table instead of re-evaluating the join.
CREATE OR REPLACE PROCEDURE "Indices"."usp_RefreshIndexPerformance"(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_row_count INT;
BEGIN
    DELETE FROM "Indices"."IndexPerformance";

    DROP TABLE IF EXISTS tmp_index_data_canonical;
    CREATE TEMP TABLE tmp_index_data_canonical AS
    SELECT
        coalesce(alias."CanonicalName", d."IndexName") AS "IndexName",
        d."TradeDate",
        d."ClosePrice",
        d."DataSource"
    FROM "Indices"."IndexData" d
    LEFT JOIN "Indices"."IndexNameAlias" alias
        ON lower(alias."AliasName") = lower(d."IndexName");

    CREATE INDEX ON tmp_index_data_canonical ("IndexName", "TradeDate" DESC);
    ANALYZE tmp_index_data_canonical;

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
        FROM tmp_index_data_canonical s
        JOIN report_date rd
          ON s."TradeDate" = rd.as_of_date
    ),

    highest AS (
        SELECT DISTINCT ON ("IndexName")
            "IndexName",
            "ClosePrice" AS max_close,
            "TradeDate"  AS max_close_date
        FROM tmp_index_data_canonical
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
            SELECT "ClosePrice" FROM tmp_index_data_canonical
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '1 day'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) d ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM tmp_index_data_canonical
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '1 week'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) w ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM tmp_index_data_canonical
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '1 month'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) m1 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM tmp_index_data_canonical
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '3 months'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) m3 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM tmp_index_data_canonical
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '6 months'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) m6 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM tmp_index_data_canonical
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '1 year'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) y1 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM tmp_index_data_canonical
            WHERE "IndexName" = l."IndexName" AND "TradeDate" <= l.latest_date - INTERVAL '3 years'
            ORDER BY "TradeDate" DESC LIMIT 1
        ) y3 ON true

        LEFT JOIN LATERAL (
            SELECT "ClosePrice" FROM tmp_index_data_canonical
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

    DROP TABLE IF EXISTS tmp_index_data_canonical;

    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    RAISE NOTICE 'IndexPerformance refreshed with % rows', v_row_count;
END;
$BODY$;
ALTER PROCEDURE "Indices"."usp_RefreshIndexPerformance"()
    OWNER TO postgres;

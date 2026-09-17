-- Mirrors Stocks.usp_RefreshStockPerformance / Indices.usp_RefreshIndexPerformance
-- exactly, reading straight from CommodityData (no rebrand-alias view needed
-- here — commodity names don't get renamed the way NSE indices did) and
-- keyed by CommodityName instead of InstrumentId/IndexName. No Exchange
-- column — every row is implicitly 'Commodity', applied by the API at query
-- time rather than stored here.
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
ALTER PROCEDURE "Commodities"."usp_RefreshCommodityPerformance"()
    OWNER TO postgres;

CREATE OR REPLACE PROCEDURE "MF"."usp_RefreshMFPerformance"(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_row_count INT;
BEGIN
    -- Clear existing data (table always holds latest snapshot only)
    DELETE FROM "MF"."MF_Performance";

    -- Recalculate and insert fresh rankings
    INSERT INTO "MF"."MF_Performance" (
        "MFCode", "MFName", "LatestNAV", "AsOfDate",
        "Day", "Week", "Month", "ThreeMon", "SixMon", "Year", "ThreeYear", "FiveYear",
        "NAV_Day", "NAV_Week", "NAV_Month", "NAV_3Mon", "NAV_6Mon", "NAV_Year", "NAV_3Year", "NAV_5Year",
        "HighestNAV", "HighestNAVDate",
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
            n."SchemeCode",
            n."SchemeName",
            n."NavDate" AS latest_date,
            n."NAV"     AS latest_nav
        FROM "MF"."MF_NAV" n
        JOIN report_date rd
          ON n."NavDate" = rd.as_of_date
    ),

    -- All-time high NAV per scheme; ties broken by most recent date
    highest AS (
        SELECT DISTINCT ON ("SchemeCode")
            "SchemeCode",
            "NAV"     AS max_nav,
            "NavDate" AS max_nav_date
        FROM "MF"."MF_NAV"
        ORDER BY "SchemeCode", "NAV" DESC, "NavDate" DESC
    ),

    returns AS (
        SELECT
            l."SchemeCode",
            l."SchemeName",
            l.latest_date,
            l.latest_nav,

            d."NAV"  AS nav_1d,
            w."NAV"  AS nav_1w,
            m1."NAV" AS nav_1m,
            m3."NAV" AS nav_3m,
            m6."NAV" AS nav_6m,
            y1."NAV" AS nav_1y,
            y3."NAV" AS nav_3y,
            y5."NAV" AS nav_5y,

            h.max_nav,
            h.max_nav_date

        FROM latest l

        LEFT JOIN LATERAL (
            SELECT "NAV" FROM "MF"."MF_NAV"
            WHERE "SchemeCode" = l."SchemeCode" AND "NavDate" <= l.latest_date - INTERVAL '1 day'
            ORDER BY "NavDate" DESC LIMIT 1
        ) d ON true

        LEFT JOIN LATERAL (
            SELECT "NAV" FROM "MF"."MF_NAV"
            WHERE "SchemeCode" = l."SchemeCode" AND "NavDate" <= l.latest_date - INTERVAL '1 week'
            ORDER BY "NavDate" DESC LIMIT 1
        ) w ON true

        LEFT JOIN LATERAL (
            SELECT "NAV" FROM "MF"."MF_NAV"
            WHERE "SchemeCode" = l."SchemeCode" AND "NavDate" <= l.latest_date - INTERVAL '1 month'
            ORDER BY "NavDate" DESC LIMIT 1
        ) m1 ON true

        LEFT JOIN LATERAL (
            SELECT "NAV" FROM "MF"."MF_NAV"
            WHERE "SchemeCode" = l."SchemeCode" AND "NavDate" <= l.latest_date - INTERVAL '3 months'
            ORDER BY "NavDate" DESC LIMIT 1
        ) m3 ON true

        LEFT JOIN LATERAL (
            SELECT "NAV" FROM "MF"."MF_NAV"
            WHERE "SchemeCode" = l."SchemeCode" AND "NavDate" <= l.latest_date - INTERVAL '6 months'
            ORDER BY "NavDate" DESC LIMIT 1
        ) m6 ON true

        LEFT JOIN LATERAL (
            SELECT "NAV" FROM "MF"."MF_NAV"
            WHERE "SchemeCode" = l."SchemeCode" AND "NavDate" <= l.latest_date - INTERVAL '1 year'
            ORDER BY "NavDate" DESC LIMIT 1
        ) y1 ON true

        LEFT JOIN LATERAL (
            SELECT "NAV" FROM "MF"."MF_NAV"
            WHERE "SchemeCode" = l."SchemeCode" AND "NavDate" <= l.latest_date - INTERVAL '3 years'
            ORDER BY "NavDate" DESC LIMIT 1
        ) y3 ON true

        LEFT JOIN LATERAL (
            SELECT "NAV" FROM "MF"."MF_NAV"
            WHERE "SchemeCode" = l."SchemeCode" AND "NavDate" <= l.latest_date - INTERVAL '5 years'
            ORDER BY "NavDate" DESC LIMIT 1
        ) y5 ON true

        LEFT JOIN highest h
          ON h."SchemeCode" = l."SchemeCode"
    ),

    calc AS (
        SELECT
            "SchemeCode",
            "SchemeName",
            latest_date,
            latest_nav,

            nav_1d, nav_1w, nav_1m, nav_3m, nav_6m, nav_1y, nav_3y, nav_5y,
            max_nav, max_nav_date,

            ROUND(((latest_nav - nav_1d) / NULLIF(nav_1d,0)) * 100, 2) AS ret_1d,
            ROUND(((latest_nav - nav_1w) / NULLIF(nav_1w,0)) * 100, 2) AS ret_1w,
            ROUND(((latest_nav - nav_1m) / NULLIF(nav_1m,0)) * 100, 2) AS ret_1m,
            ROUND(((latest_nav - nav_3m) / NULLIF(nav_3m,0)) * 100, 2) AS ret_3m,
            ROUND(((latest_nav - nav_6m) / NULLIF(nav_6m,0)) * 100, 2) AS ret_6m,
            ROUND(((latest_nav - nav_1y) / NULLIF(nav_1y,0)) * 100, 2) AS ret_1y,
            ROUND((POWER(latest_nav / NULLIF(nav_3y,0), 1.0/3) - 1) * 100, 2) AS cagr_3y,
            ROUND((POWER(latest_nav / NULLIF(nav_5y,0), 1.0/5) - 1) * 100, 2) AS cagr_5y

        FROM returns
    )

    SELECT
        "SchemeCode"::BIGINT       AS "MFCode",
        "SchemeName"               AS "MFName",
        latest_nav                 AS "LatestNAV",
        latest_date                AS "AsOfDate",

        ret_1d   AS "Day",
        ret_1w   AS "Week",
        ret_1m   AS "Month",
        ret_3m   AS "ThreeMon",
        ret_6m   AS "SixMon",
        ret_1y   AS "Year",
        cagr_3y  AS "ThreeYear",
        cagr_5y  AS "FiveYear",

        nav_1d   AS "NAV_Day",
        nav_1w   AS "NAV_Week",
        nav_1m   AS "NAV_Month",
        nav_3m   AS "NAV_3Mon",
        nav_6m   AS "NAV_6Mon",
        nav_1y   AS "NAV_Year",
        nav_3y   AS "NAV_3Year",
        nav_5y   AS "NAV_5Year",

        max_nav      AS "HighestNAV",
        max_nav_date AS "HighestNAVDate",

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
    RAISE NOTICE 'MF_Performance refreshed with % rows', v_row_count;
END;
$BODY$;
ALTER PROCEDURE "MF"."usp_RefreshMFPerformance"()
    OWNER TO postgres;

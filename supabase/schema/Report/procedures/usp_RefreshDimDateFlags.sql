CREATE OR REPLACE PROCEDURE "Report"."usp_RefreshDimDateFlags"(
    )
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Reset all "current" flags first (cheap, avoids stale TRUEs lingering)
    UPDATE "Report"."dimDate"
    SET "IsCurrentDate"  = FALSE,
        "IsCurrentWeek"  = FALSE,
        "IsCurrentMonth" = FALSE,
        "IsCurrentYear"  = FALSE
    WHERE "IsCurrentDate" = TRUE
       OR "IsCurrentWeek" = TRUE
       OR "IsCurrentMonth" = TRUE
       OR "IsCurrentYear" = TRUE;

    -- Set IsCurrentDate
    UPDATE "Report"."dimDate"
    SET "IsCurrentDate" = TRUE
    WHERE "Date" = CURRENT_DATE;

    -- Set IsCurrentWeek
    UPDATE "Report"."dimDate"
    SET "IsCurrentWeek" = TRUE
    WHERE DATE_TRUNC('week', "Date") = DATE_TRUNC('week', CURRENT_DATE);

    -- Set IsCurrentMonth
    UPDATE "Report"."dimDate"
    SET "IsCurrentMonth" = TRUE
    WHERE DATE_TRUNC('month', "Date") = DATE_TRUNC('month', CURRENT_DATE);

    -- Set IsCurrentYear
    UPDATE "Report"."dimDate"
    SET "IsCurrentYear" = TRUE
    WHERE DATE_TRUNC('year', "Date") = DATE_TRUNC('year', CURRENT_DATE);

    -- Recompute IsWorkingday for ALL rows (depends on IsWeekend + IsPublicHoliday,
    -- and IsPublicHoliday may have changed via your separate holiday script)
    UPDATE "Report"."dimDate"
    SET "IsWorkingday" = NOT ("IsWeekend" OR "IsPublicHoliday")
    WHERE "IsWorkingday" <> NOT ("IsWeekend" OR "IsPublicHoliday");

    RAISE NOTICE 'dimDate flags refreshed as of %', CURRENT_DATE;
END;
$BODY$;
ALTER PROCEDURE "Report"."usp_RefreshDimDateFlags"()
    OWNER TO postgres;

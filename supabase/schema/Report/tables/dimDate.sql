create table "Report"."dimDate"
(
    "DateKey" integer NOT NULL,
    "Date" date NOT NULL,
    "Year" smallint NOT NULL,
    "Quarter" smallint NOT NULL,
    "Month" smallint NOT NULL,
    "MonthName" character varying(20) COLLATE pg_catalog."default" NOT NULL,
    "Day" smallint NOT NULL,
    "DayName" character varying(20) COLLATE pg_catalog."default" NOT NULL,
    "DayOfWeek" smallint NOT NULL,
    "WeekNumber" smallint NOT NULL,
    "MonthYearKey" integer NOT NULL,
    "MonthYearName" character varying(10) COLLATE pg_catalog."default" NOT NULL,
    "YearStartDate" date NOT NULL,
    "YearEndDate" date NOT NULL,
    "QtrStartDate" date NOT NULL,
    "QtrEndDate" date NOT NULL,
    "MonthStartDate" date NOT NULL,
    "MonthEndDate" date NOT NULL,
    "WeekStartDate" date NOT NULL,
    "WeekEndDate" date NOT NULL,
    "IsCurrentDate" boolean NOT NULL DEFAULT false,
    "IsCurrentWeek" boolean NOT NULL DEFAULT false,
    "IsCurrentMonth" boolean NOT NULL DEFAULT false,
    "IsCurrentYear" boolean NOT NULL DEFAULT false,
    "IsWeekend" boolean NOT NULL DEFAULT false,
    "IsPublicHoliday" boolean NOT NULL DEFAULT false,
    "HolidayName" character varying(100) COLLATE pg_catalog."default",
    "IsWorkingday" boolean NOT NULL DEFAULT true,
    CONSTRAINT "dimDate_pkey" PRIMARY KEY ("DateKey"),
    CONSTRAINT "dimDate_Date_key" UNIQUE ("Date")
);

CREATE INDEX idx_dimdate_date
    ON "Report"."dimDate" USING btree ("Date" ASC NULLS LAST);

CREATE INDEX idx_dimdate_iscurrent
    ON "Report"."dimDate" USING btree
    ("IsCurrentDate" ASC NULLS LAST, "IsCurrentWeek" ASC NULLS LAST, "IsCurrentMonth" ASC NULLS LAST, "IsCurrentYear" ASC NULLS LAST);

CREATE INDEX idx_dimdate_monthyear
    ON "Report"."dimDate" USING btree ("MonthYearKey" ASC NULLS LAST);

CREATE INDEX idx_dimdate_year_month
    ON "Report"."dimDate" USING btree ("Year" ASC NULLS LAST, "Month" ASC NULLS LAST);

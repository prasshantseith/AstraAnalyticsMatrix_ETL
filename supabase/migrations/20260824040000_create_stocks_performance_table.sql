CREATE TABLE IF NOT EXISTS "Stocks"."StockPerformance"
(
    "InstrumentId" bigint,
    "TickerSymbol" character varying(30) COLLATE pg_catalog."default",
    "InstrumentName" character varying COLLATE pg_catalog."default",
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
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "Stocks"."StockPerformance"
    OWNER to postgres;

-- app_user may not exist yet in every environment (e.g. it wasn't present
-- in dev). Create it as a permissions-only role so the grants below don't
-- fail; it grants no login/connect capability on its own.
do $$
begin
    if not exists (select from pg_roles where rolname = 'app_user') then
        create role app_user nologin;
    end if;
end $$;

REVOKE ALL ON TABLE "Stocks"."StockPerformance" FROM app_user;

GRANT SELECT ON TABLE "Stocks"."StockPerformance" TO app_user;

GRANT ALL ON TABLE "Stocks"."StockPerformance" TO postgres;

create schema if not exists "Commodities";

-- One row per tracked commodity: which Yahoo Finance futures symbol backs
-- it, and how far back its history goes (used as the backfill/incremental
-- start date when there's no data loaded yet).
CREATE TABLE IF NOT EXISTS "Commodities"."CommodityConfig" (
    "CommodityName" varchar(30) PRIMARY KEY,
    "YahooSymbol" varchar(20) NOT NULL,
    "StartDate" date NOT NULL,
    "Enabled" boolean NOT NULL DEFAULT true
);

INSERT INTO "Commodities"."CommodityConfig" ("CommodityName", "YahooSymbol", "StartDate")
VALUES
    ('Gold', 'GC=F', DATE '2000-08-30'),
    ('Silver', 'SI=F', DATE '2000-08-30'),
    ('Copper', 'HG=F', DATE '2000-08-30')
ON CONFLICT ("CommodityName") DO UPDATE SET
    "YahooSymbol" = EXCLUDED."YahooSymbol",
    "StartDate" = EXCLUDED."StartDate";

-- Daily OHLC in USD, partitioned by year on TradeDate (same pattern as
-- Stocks.StockData) since this table accumulates one row per commodity per
-- trading day going back to 2000.
CREATE TABLE IF NOT EXISTS "Commodities"."CommodityData"
(
    "CommodityName" varchar(30) NOT NULL,
    "TradeDate" date NOT NULL,
    "OpenPrice" numeric(18,4),
    "HighPrice" numeric(18,4),
    "LowPrice" numeric(18,4),
    "ClosePrice" numeric(18,4),
    "Volume" bigint,
    "DataSource" varchar(30) NOT NULL DEFAULT 'YAHOO',
    "SourceSymbol" varchar(20),
    "CreatedAt" timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT "CommodityData_pkey" PRIMARY KEY ("CommodityName", "TradeDate")
)
PARTITION BY RANGE ("TradeDate");

-- Catches any row whose TradeDate falls outside the explicit yearly
-- partitions below.
CREATE TABLE IF NOT EXISTS "Commodities"."CommodityData_default"
    PARTITION OF "Commodities"."CommodityData" DEFAULT;

-- Pre-create one partition per calendar year, 2000 (earliest available
-- Yahoo Finance history for these futures) through 5 years from now, so
-- daily ingestion never hits a missing partition. Extend this range with a
-- new migration before it runs out.
do $$
declare
    end_year int := extract(year from now())::int + 5;
    y int;
    partition_name text;
begin
    for y in 2000..end_year loop
        partition_name := 'CommodityData_' || y::text;

        execute format(
            'create table if not exists "Commodities".%I partition of "Commodities"."CommodityData" for values from (%L) to (%L);',
            partition_name, make_date(y, 1, 1), make_date(y + 1, 1, 1)
        );
    end loop;
end $$;

do $$
begin
    if not exists (select from pg_roles where rolname = 'app_user') then
        create role app_user nologin;
    end if;
end $$;

REVOKE ALL ON TABLE "Commodities"."CommodityData" FROM app_user;
REVOKE ALL ON TABLE "Commodities"."CommodityConfig" FROM app_user;

GRANT SELECT ON TABLE "Commodities"."CommodityData" TO app_user;
GRANT SELECT ON TABLE "Commodities"."CommodityConfig" TO app_user;

GRANT ALL ON TABLE "Commodities"."CommodityData" TO postgres;
GRANT ALL ON TABLE "Commodities"."CommodityConfig" TO postgres;

-- Indexes on the partitioned parent propagate to every partition
-- (existing and future).
CREATE INDEX IF NOT EXISTS "IX_CommodityData_TradeDate"
    ON "Commodities"."CommodityData" USING btree
    ("TradeDate" ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS "IX_CommodityData_CommodityName"
    ON "Commodities"."CommodityData" USING btree
    ("CommodityName" COLLATE pg_catalog."default" ASC NULLS LAST);

INSERT INTO "ETL"."ETL_CONFIG"
    (job_name, source_url, target_schema, target_table, enabled)
VALUES
    ('commodity_data_ingest', 'https://query1.finance.yahoo.com', 'Commodities', 'CommodityData', true),
    ('commodity_data_backfill', 'https://query1.finance.yahoo.com', 'Commodities', 'CommodityData', true)
ON CONFLICT (job_name) DO UPDATE SET
    source_url = EXCLUDED.source_url,
    target_schema = EXCLUDED.target_schema,
    target_table = EXCLUDED.target_table;

-- Convert "Stocks"."StockData" to a table partitioned by year on
-- "TradeDate", mirroring "MF"."MF_NAV"'s pattern. Postgres can't ALTER a
-- plain table into a partitioned one in place, so: rename the existing
-- table (and everything on it - constraints AND plain indexes, so their
-- names are free for reuse below) aside as "_legacy", create the new
-- partitioned table under the original name, then copy the legacy rows
-- back in.
do $$
declare
    r record;
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'Stocks' and c.relname = 'StockData' and c.relkind = 'r'
    ) then
        alter table "Stocks"."StockData" rename to "StockData_legacy";

        for r in
            select conname
            from pg_constraint
            where conrelid = '"Stocks"."StockData_legacy"'::regclass
        loop
            if r.conname !~ '^legacy_' then
                execute format('alter table "Stocks"."StockData_legacy" rename constraint %I to %I', r.conname, 'legacy_' || r.conname);
            end if;
        end loop;

        for r in
            select indexname
            from pg_indexes
            where schemaname = 'Stocks' and tablename = 'StockData_legacy'
        loop
            if r.indexname !~ '^legacy_' then
                execute format('alter index "Stocks".%I rename to %I', r.indexname, 'legacy_' || r.indexname);
            end if;
        end loop;
    end if;
end $$;

CREATE TABLE IF NOT EXISTS "Stocks"."StockData"
(
    "Id" bigint NOT NULL DEFAULT nextval('"Stocks"."StockData_Id_seq"'::regclass),
    "StockExchangeCode" character varying(10) COLLATE pg_catalog."default" NOT NULL,
    "TradeDate" date NOT NULL,
    "BusinessDate" date NOT NULL,
    "MarketSegment" character varying(10) COLLATE pg_catalog."default" NOT NULL,
    "DataSource" character varying(10) COLLATE pg_catalog."default" NOT NULL,
    "InstrumentType" character varying(10) COLLATE pg_catalog."default" NOT NULL,
    "InstrumentId" bigint NOT NULL,
    "IsinCode" character varying(12) COLLATE pg_catalog."default" NOT NULL,
    "TickerSymbol" character varying(30) COLLATE pg_catalog."default" NOT NULL,
    "SecuritySeries" character varying(10) COLLATE pg_catalog."default",
    "ExpiryDate" date,
    "ActualExpiryDate" date,
    "StrikePrice" numeric(18,4),
    "OptionType" character varying(5) COLLATE pg_catalog."default",
    "InstrumentName" character varying(255) COLLATE pg_catalog."default" NOT NULL,
    "OpenPrice" numeric(18,4),
    "HighPrice" numeric(18,4),
    "LowPrice" numeric(18,4),
    "ClosePrice" numeric(18,4),
    "LastTradedPrice" numeric(18,4),
    "PreviousClosePrice" numeric(18,4),
    CONSTRAINT "StockData_pkey" PRIMARY KEY ("Id", "TradeDate"),
    CONSTRAINT "UQ_StockData_Exchange_TradeDate_Instrument" UNIQUE ("StockExchangeCode", "TradeDate", "InstrumentId")
)

PARTITION BY RANGE ("TradeDate");

-- StockData_Id_seq was OWNED BY the original table's "Id" column. That
-- ownership follows the rename to StockData_legacy, not this new table -
-- reassign it here so a future cleanup of the legacy table doesn't drop
-- the sequence out from under the live one.
ALTER SEQUENCE "Stocks"."StockData_Id_seq" OWNED BY "Stocks"."StockData"."Id";

-- Catches any row whose TradeDate falls outside the explicit yearly
-- partitions below.
create table if not exists "Stocks"."StockData_default"
    partition of "Stocks"."StockData" default;

-- Pre-create one partition per calendar year, 2016 (both ingestion jobs'
-- historical backfill start) through 5 years from now, so daily ingestion
-- never hits a missing partition. Extend this range with a new migration
-- before it runs out.
do $$
declare
    end_year int := extract(year from now())::int + 5;
    y int;
    partition_name text;
begin
    for y in 2016..end_year loop
        partition_name := 'StockData_' || y::text;

        execute format(
            'create table if not exists "Stocks".%I partition of "Stocks"."StockData" for values from (%L) to (%L);',
            partition_name, make_date(y, 1, 1), make_date(y + 1, 1, 1)
        );
    end loop;
end $$;

-- Copy any data from the legacy (pre-partitioning) table into the new
-- partitioned table. "Id" is a plain DEFAULT nextval (not GENERATED
-- ALWAYS AS IDENTITY), and every legacy row was already inserted through
-- that same sequence, so no OVERRIDING SYSTEM VALUE / sequence realignment
-- is needed here.
do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'Stocks' and c.relname = 'StockData_legacy' and c.relkind = 'r'
    ) then
        insert into "Stocks"."StockData" (
            "Id", "StockExchangeCode", "TradeDate", "BusinessDate", "MarketSegment",
            "DataSource", "InstrumentType", "InstrumentId", "IsinCode",
            "TickerSymbol", "SecuritySeries", "ExpiryDate", "ActualExpiryDate",
            "StrikePrice", "OptionType", "InstrumentName",
            "OpenPrice", "HighPrice", "LowPrice", "ClosePrice",
            "LastTradedPrice", "PreviousClosePrice"
        )
        select
            "Id", "StockExchangeCode", "TradeDate", "BusinessDate", "MarketSegment",
            "DataSource", "InstrumentType", "InstrumentId", "IsinCode",
            "TickerSymbol", "SecuritySeries", "ExpiryDate", "ActualExpiryDate",
            "StrikePrice", "OptionType", "InstrumentName",
            "OpenPrice", "HighPrice", "LowPrice", "ClosePrice",
            "LastTradedPrice", "PreviousClosePrice"
        from "Stocks"."StockData_legacy";
    end if;
end $$;

ALTER TABLE IF EXISTS "Stocks"."StockData"
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

REVOKE ALL ON TABLE "Stocks"."StockData" FROM app_user;

GRANT SELECT ON TABLE "Stocks"."StockData" TO app_user;

GRANT ALL ON TABLE "Stocks"."StockData" TO postgres;

-- Indexes defined on the partitioned parent automatically propagate to
-- every partition (existing and future).

CREATE INDEX IF NOT EXISTS "IX_StockData_ExchangeCode"
    ON "Stocks"."StockData" USING btree
    ("StockExchangeCode" COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS "IX_StockData_Exchange_Ticker_Date"
    ON "Stocks"."StockData" USING btree
    ("StockExchangeCode" COLLATE pg_catalog."default" ASC NULLS LAST, "TickerSymbol" COLLATE pg_catalog."default" ASC NULLS LAST, "TradeDate" ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS "IX_StockData_InstrumentId"
    ON "Stocks"."StockData" USING btree
    ("InstrumentId" ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS "IX_StockData_IsinCode"
    ON "Stocks"."StockData" USING btree
    ("IsinCode" COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS "IX_StockData_SecuritySeries"
    ON "Stocks"."StockData" USING btree
    ("SecuritySeries" COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS "IX_StockData_TickerSymbol"
    ON "Stocks"."StockData" USING btree
    ("TickerSymbol" COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX IF NOT EXISTS "IX_StockData_TradeDate"
    ON "Stocks"."StockData" USING btree
    ("TradeDate" ASC NULLS LAST);

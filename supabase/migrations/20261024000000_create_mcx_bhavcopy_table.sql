-- MCX (Multi Commodity Exchange of India) daily bhav copy — one row per
-- traded instrument (futures and options, on both individual commodities
-- and MCX's own indices, every expiry, every strike), sourced from
-- mcxindia.com's own GetDateWiseBhavCopy endpoint. A much finer grain than
-- Commodities.CommodityData (one row per commodity per day, from Yahoo's
-- international spot price) — this is India's own exchange-traded futures/
-- options prices in INR, keyed by the actual contract, matching
-- Stocks.StockData's architecture (one row per listing, not per underlying)
-- far more than CommodityData's.
--
-- Partitioned by year on TradeDate, same pattern as Commodities.CommodityData
-- / Stocks.StockData — this accumulates every contract traded every day
-- back to MCX's own stated history start (November 2003), at roughly
-- 16,000+ rows/day (futures + options, every strike), so it's by far the
-- largest table this partitioning convention has backed yet.
CREATE TABLE IF NOT EXISTS "Commodities"."McxBhavCopy"
(
    "TradeDate" date NOT NULL,
    -- The underlying commodity or index (e.g. "GOLD", "CRUDEOIL",
    -- "MCXBULLDEX") — MCX's own feed pads this to a fixed width with
    -- trailing spaces; trimmed on ingest. The raw API has only this one
    -- identifying field (no separate "Symbol" distinct from it).
    "Commodity" character varying(30) COLLATE pg_catalog."default" NOT NULL,
    -- MCX's own instrument-type codes: FUTCOM/FUTIDX (futures on a
    -- commodity / on an MCX index) or OPTFUT/OPTIDX (options on either).
    "InstrumentType" character varying(10) COLLATE pg_catalog."default" NOT NULL,
    "ExpiryDate" date NOT NULL,
    -- "-" for futures; "CE"/"PE" for options.
    "OptionType" character varying(5) COLLATE pg_catalog."default" NOT NULL DEFAULT '-',
    "StrikePrice" numeric(18,4) NOT NULL DEFAULT 0,
    "OpenPrice" numeric(18,4),
    "HighPrice" numeric(18,4),
    "LowPrice" numeric(18,4),
    "ClosePrice" numeric(18,4),
    "PreviousClosePrice" numeric(18,4),
    "Volume" bigint,
    -- Free-text unit label MCX includes alongside Volume (e.g. "3005.000
    -- KGS") - units vary by commodity (KGS/GM/BBL/MT/...), not worth
    -- normalizing into a separate numeric+unit pair for what's effectively
    -- a display-only figure already covered by Volume (lots) above.
    "VolumeDisplay" character varying(30) COLLATE pg_catalog."default",
    "ValueInLakhs" numeric(18,4),
    "OpenInterest" bigint,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT now(),
    -- Natural composite key, no surrogate id — a partitioned table's
    -- primary key must include the partition column (TradeDate); matches
    -- CommodityData's own (CommodityName, TradeDate) convention, led by
    -- Commodity since "one commodity's history" is the more common lookup
    -- than "everything on one date" (which the separate TradeDate index
    -- below covers instead).
    CONSTRAINT "McxBhavCopy_pkey" PRIMARY KEY
        ("Commodity", "TradeDate", "InstrumentType", "ExpiryDate", "OptionType", "StrikePrice")
)
PARTITION BY RANGE ("TradeDate");

-- Catches any row whose TradeDate falls outside the explicit yearly
-- partitions below.
CREATE TABLE IF NOT EXISTS "Commodities"."McxBhavCopy_default"
    PARTITION OF "Commodities"."McxBhavCopy" DEFAULT;

-- Pre-create one partition per calendar year, 2003 (MCX's own stated
-- bhavcopy history start) through 5 years from now, so daily ingestion
-- never hits a missing partition. Extend this range with a new migration
-- before it runs out.
do $$
declare
    end_year int := extract(year from now())::int + 5;
    y int;
    partition_name text;
begin
    for y in 2003..end_year loop
        partition_name := 'McxBhavCopy_' || y::text;

        execute format(
            'create table if not exists "Commodities".%I partition of "Commodities"."McxBhavCopy" for values from (%L) to (%L);',
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

-- app_user (the API's own connection role) only ever reads this table -
-- ingestion writes via the ETL's own privileged connection, same
-- SELECT-only convention as Stocks.StockData / Commodities.CommodityData.
REVOKE ALL ON TABLE "Commodities"."McxBhavCopy" FROM app_user;
GRANT SELECT ON TABLE "Commodities"."McxBhavCopy" TO app_user;
GRANT ALL ON TABLE "Commodities"."McxBhavCopy" TO postgres;

-- Indexes on the partitioned parent propagate to every partition (existing
-- and future). Not ("Commodity", "TradeDate") again - that's already the
-- primary key's own leftmost prefix.
CREATE INDEX IF NOT EXISTS ix_mcxbhavcopy_tradedate
    ON "Commodities"."McxBhavCopy" USING btree
    ("TradeDate" DESC NULLS LAST);

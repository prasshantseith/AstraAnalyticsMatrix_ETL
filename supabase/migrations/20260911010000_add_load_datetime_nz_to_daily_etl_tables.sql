-- Adds a "when was this row (re)loaded" NZ wall-clock column to every table
-- the daily incremental orchestrator writes to (see PIPELINES in
-- src/orchestration/daily_incremental_orchestrator.py): Stocks.StockData,
-- Indices.IndexData, Commodities.CommodityData, MF.MF_NAV. Lets a human
-- glance at MAX("LoadDateTimeNZ") per table to see how fresh the data
-- actually is, without converting from UTC by hand, informing whether the
-- job needs to keep running as often as it does.
--
-- Same trigger approach as ETL_LOG's start/end _ist/_nz columns (see
-- 20260829040000_add_etl_log_local_time_columns.sql) rather than a
-- GENERATED ALWAYS column, for the same reason: `timestamptz AT TIME ZONE
-- text` is STABLE not IMMUTABLE (a named zone's rules could change with a
-- tzdata update), which generated columns require. A BEFORE INSERT OR
-- UPDATE trigger gets the same "always correct, zero ingestion-script
-- changes" result instead, and works for every existing and future write
-- path (the daily incremental scripts, the one-off backfill scripts, and
-- any manual writes) without having to touch each one individually.
--
-- The column is plain "timestamp" (no time zone), not timestamptz -
-- timestamptz's displayed value always depends on the READING session's own
-- timezone setting, so it can't guarantee "NZ time" to every viewer the way
-- a naive column holding the NZ wall-clock value directly can.
--
-- No DEFAULT expression on the column itself (kept nullable) and no
-- backfill UPDATE for existing rows - StockData/IndexData in particular are
-- large, yearly-partitioned tables going back to 1996/2016, and either a
-- volatile DEFAULT or a bulk UPDATE would force a full rewrite of every
-- partition. Existing rows just read NULL here until the next incremental
-- run re-touches them (which happens naturally for the recent trade dates
-- that matter for this), rather than risk a slow/locking migration against
-- production for rows nobody needs a freshness reading on anyway.
CREATE OR REPLACE FUNCTION "ETL"."trg_set_load_datetime_nz"()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW."LoadDateTimeNZ" := (now() AT TIME ZONE 'Pacific/Auckland');
    RETURN NEW;
END;
$$;

ALTER TABLE "Stocks"."StockData"
    ADD COLUMN IF NOT EXISTS "LoadDateTimeNZ" timestamp;

DROP TRIGGER IF EXISTS set_stockdata_load_datetime_nz ON "Stocks"."StockData";
CREATE TRIGGER set_stockdata_load_datetime_nz
    BEFORE INSERT OR UPDATE ON "Stocks"."StockData"
    FOR EACH ROW
    EXECUTE FUNCTION "ETL"."trg_set_load_datetime_nz"();

ALTER TABLE "Indices"."IndexData"
    ADD COLUMN IF NOT EXISTS "LoadDateTimeNZ" timestamp;

DROP TRIGGER IF EXISTS set_indexdata_load_datetime_nz ON "Indices"."IndexData";
CREATE TRIGGER set_indexdata_load_datetime_nz
    BEFORE INSERT OR UPDATE ON "Indices"."IndexData"
    FOR EACH ROW
    EXECUTE FUNCTION "ETL"."trg_set_load_datetime_nz"();

ALTER TABLE "Commodities"."CommodityData"
    ADD COLUMN IF NOT EXISTS "LoadDateTimeNZ" timestamp;

DROP TRIGGER IF EXISTS set_commoditydata_load_datetime_nz ON "Commodities"."CommodityData";
CREATE TRIGGER set_commoditydata_load_datetime_nz
    BEFORE INSERT OR UPDATE ON "Commodities"."CommodityData"
    FOR EACH ROW
    EXECUTE FUNCTION "ETL"."trg_set_load_datetime_nz"();

-- MF.MF_NAV already has a "LoadDateTime" column, but it's timestamptz
-- (DEFAULT now(), only set on fresh INSERT - mf_nav_ingest's ON CONFLICT is
-- DO NOTHING, so it's never refreshed on a re-touch) - same
-- reader-timezone-dependent display problem, so this adds the NZ-guaranteed
-- column here too rather than risk rewriting that existing column's type on
-- a table partitioned back to 1996.
ALTER TABLE "MF"."MF_NAV"
    ADD COLUMN IF NOT EXISTS "LoadDateTimeNZ" timestamp;

DROP TRIGGER IF EXISTS set_mfnav_load_datetime_nz ON "MF"."MF_NAV";
CREATE TRIGGER set_mfnav_load_datetime_nz
    BEFORE INSERT OR UPDATE ON "MF"."MF_NAV"
    FOR EACH ROW
    EXECUTE FUNCTION "ETL"."trg_set_load_datetime_nz"();

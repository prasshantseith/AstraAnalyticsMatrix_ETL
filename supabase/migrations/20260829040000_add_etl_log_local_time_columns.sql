-- Adds IST and NZ wall-clock columns to ETL_LOG, so support can see when a
-- job ran without manually converting from UTC. These can't be GENERATED
-- ALWAYS AS columns - `timestamptz AT TIME ZONE text` is STABLE, not
-- IMMUTABLE (Postgres requires IMMUTABLE for generated columns), since a
-- named zone's rules could in principle change with a tzdata update. A
-- BEFORE INSERT OR UPDATE trigger gets the same "always correct,
-- zero app-code changes" result instead.
ALTER TABLE "ETL"."ETL_LOG"
    ADD COLUMN IF NOT EXISTS start_time_ist timestamp,
    ADD COLUMN IF NOT EXISTS start_time_nz timestamp,
    ADD COLUMN IF NOT EXISTS end_time_ist timestamp,
    ADD COLUMN IF NOT EXISTS end_time_nz timestamp;

CREATE OR REPLACE FUNCTION "ETL"."trg_set_etl_log_local_times"()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.start_time_ist := NEW.start_time AT TIME ZONE 'Asia/Kolkata';
    NEW.start_time_nz  := NEW.start_time AT TIME ZONE 'Pacific/Auckland';
    NEW.end_time_ist   := NEW.end_time AT TIME ZONE 'Asia/Kolkata';
    NEW.end_time_nz    := NEW.end_time AT TIME ZONE 'Pacific/Auckland';
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_etl_log_local_times ON "ETL"."ETL_LOG";
CREATE TRIGGER set_etl_log_local_times
    BEFORE INSERT OR UPDATE OF start_time, end_time ON "ETL"."ETL_LOG"
    FOR EACH ROW
    EXECUTE FUNCTION "ETL"."trg_set_etl_log_local_times"();

-- Backfill existing rows (the trigger only covers future inserts/updates).
UPDATE "ETL"."ETL_LOG"
SET start_time_ist = start_time AT TIME ZONE 'Asia/Kolkata',
    start_time_nz  = start_time AT TIME ZONE 'Pacific/Auckland',
    end_time_ist   = end_time AT TIME ZONE 'Asia/Kolkata',
    end_time_nz    = end_time AT TIME ZONE 'Pacific/Auckland';

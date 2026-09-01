-- Captures an index already created directly on the live database (not
-- through a migration) while chasing down why the Panchang month-calendar
-- endpoint was slow. Note: this is functionally redundant with the
-- existing UQ_FactPanchang_City_Date_Time unique constraint (see
-- 20260823070000_create_astro_fact_tables.sql), which already backs an
-- identical btree index on the same (City, Date, Time) columns in the same
-- order — kept here only so the live schema and migrations stay in sync,
-- not because it adds query-plan value on its own.
CREATE INDEX IF NOT EXISTS "FactPanchang_City_Date_Time_idx"
    ON "Astro"."FactPanchang" USING btree
    ("City", "Date", "Time");

-- Adopts the classical nakshatra classifications added in 20261121020000 as
-- the official values: copies swabhava_new / mukha_position_new /
-- eyesight_new into swabhava / mukha_position / eyesight, then drops the
-- *_new columns.
--
-- The user reviewed both sets side by side and chose the new ones. They
-- match the classical lists (Muhurta Chintamani), and also match the
-- code-defined NAKSHATRA_SWABHAVA / NAKSHATRA_MUKHA maps in the API's
-- app/panchang_score.py, which drive the Panchang calendar. The old values
-- had several errors (e.g. eyesight 'Sama' for 26 of 27 rows, Chitra as
-- Tikshna, Ashwini empty). No application code reads these three columns,
-- so nothing displayed changes.
--
-- Guarded so it is a no-op if the *_new columns are already gone.
do $$
begin
    if exists (
        select 1 from information_schema.columns
        where table_schema = 'Astro' and table_name = 'DimNakshtra' and column_name = 'swabhava_new'
    ) then
        UPDATE "Astro"."DimNakshtra" SET
            swabhava = swabhava_new,
            mukha_position = mukha_position_new,
            eyesight = eyesight_new
        WHERE swabhava_new IS NOT NULL;
    end if;
end $$;

ALTER TABLE "Astro"."DimNakshtra"
    DROP COLUMN IF EXISTS swabhava_new,
    DROP COLUMN IF EXISTS mukha_position_new,
    DROP COLUMN IF EXISTS eyesight_new;

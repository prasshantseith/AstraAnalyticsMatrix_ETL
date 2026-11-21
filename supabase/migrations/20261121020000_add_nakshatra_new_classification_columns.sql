-- Adds swabhava_new / mukha_position_new / eyesight_new to
-- Astro.DimNakshtra, holding the classical classifications from Dr Suresh
-- Chandra Mishra's nakshatra lecture (the same values appended to
-- attributes by 20261121010000). The existing swabhava / mukha_position /
-- eyesight columns are left untouched so both can be compared side by side
-- on KP Kundli's "Nakshatra Data" tab before the user decides which values
-- are correct.
--
-- Uses the existing columns' vocabulary so values compare directly:
-- Sthira = Dhruva, Laghu = Kshipra, Madhyaksha = Kana (one weak eye),
-- Andhaksha = Andha, Mandaksha = Manda.
ALTER TABLE "Astro"."DimNakshtra"
    ADD COLUMN IF NOT EXISTS swabhava_new text COLLATE pg_catalog."default",
    ADD COLUMN IF NOT EXISTS mukha_position_new text COLLATE pg_catalog."default",
    ADD COLUMN IF NOT EXISTS eyesight_new text COLLATE pg_catalog."default";

UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Laghu', mukha_position_new = 'Tiryanga Mukha', eyesight_new = 'Mandaksha' WHERE "NakshatraNumber" = 1;  -- Ashwini
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Ugra', mukha_position_new = 'Adho Mukha', eyesight_new = 'Madhyaksha' WHERE "NakshatraNumber" = 2;  -- Bharani
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Mishra', mukha_position_new = 'Adho Mukha', eyesight_new = 'Sulochana' WHERE "NakshatraNumber" = 3;  -- Krittika
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Sthira', mukha_position_new = 'Urdhwa Mukha', eyesight_new = 'Andhaksha' WHERE "NakshatraNumber" = 4;  -- Rohini
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Mridu', mukha_position_new = 'Tiryanga Mukha', eyesight_new = 'Mandaksha' WHERE "NakshatraNumber" = 5;  -- Mrigashira
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Tikshna', mukha_position_new = 'Urdhwa Mukha', eyesight_new = 'Madhyaksha' WHERE "NakshatraNumber" = 6;  -- Ardra
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Chara', mukha_position_new = 'Tiryanga Mukha', eyesight_new = 'Sulochana' WHERE "NakshatraNumber" = 7;  -- Punarvasu
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Laghu', mukha_position_new = 'Urdhwa Mukha', eyesight_new = 'Andhaksha' WHERE "NakshatraNumber" = 8;  -- Pushya
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Tikshna', mukha_position_new = 'Adho Mukha', eyesight_new = 'Mandaksha' WHERE "NakshatraNumber" = 9;  -- Ashlesha
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Ugra', mukha_position_new = 'Adho Mukha', eyesight_new = 'Madhyaksha' WHERE "NakshatraNumber" = 10;  -- Magha
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Ugra', mukha_position_new = 'Adho Mukha', eyesight_new = 'Sulochana' WHERE "NakshatraNumber" = 11;  -- Purva Phalguni
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Sthira', mukha_position_new = 'Urdhwa Mukha', eyesight_new = 'Andhaksha' WHERE "NakshatraNumber" = 12;  -- Uttara Phalguni
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Laghu', mukha_position_new = 'Tiryanga Mukha', eyesight_new = 'Mandaksha' WHERE "NakshatraNumber" = 13;  -- Hasta
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Mridu', mukha_position_new = 'Tiryanga Mukha', eyesight_new = 'Madhyaksha' WHERE "NakshatraNumber" = 14;  -- Chitra
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Chara', mukha_position_new = 'Tiryanga Mukha', eyesight_new = 'Sulochana' WHERE "NakshatraNumber" = 15;  -- Swati
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Mishra', mukha_position_new = 'Adho Mukha', eyesight_new = 'Andhaksha' WHERE "NakshatraNumber" = 16;  -- Vishakha
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Mridu', mukha_position_new = 'Tiryanga Mukha', eyesight_new = 'Mandaksha' WHERE "NakshatraNumber" = 17;  -- Anuradha
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Tikshna', mukha_position_new = 'Tiryanga Mukha', eyesight_new = 'Madhyaksha' WHERE "NakshatraNumber" = 18;  -- Jyeshtha
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Tikshna', mukha_position_new = 'Adho Mukha', eyesight_new = 'Sulochana' WHERE "NakshatraNumber" = 19;  -- Mula
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Ugra', mukha_position_new = 'Adho Mukha', eyesight_new = 'Andhaksha' WHERE "NakshatraNumber" = 20;  -- Purva Ashadha
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Sthira', mukha_position_new = 'Urdhwa Mukha', eyesight_new = 'Mandaksha' WHERE "NakshatraNumber" = 21;  -- Uttara Ashadha
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Chara', mukha_position_new = 'Urdhwa Mukha', eyesight_new = 'Sulochana' WHERE "NakshatraNumber" = 22;  -- Shravana
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Chara', mukha_position_new = 'Urdhwa Mukha', eyesight_new = 'Andhaksha' WHERE "NakshatraNumber" = 23;  -- Dhanishta
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Chara', mukha_position_new = 'Urdhwa Mukha', eyesight_new = 'Mandaksha' WHERE "NakshatraNumber" = 24;  -- Shatabhisha
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Ugra', mukha_position_new = 'Adho Mukha', eyesight_new = 'Madhyaksha' WHERE "NakshatraNumber" = 25;  -- Purva Bhadrapada
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Sthira', mukha_position_new = 'Urdhwa Mukha', eyesight_new = 'Sulochana' WHERE "NakshatraNumber" = 26;  -- Uttara Bhadrapada
UPDATE "Astro"."DimNakshtra" SET swabhava_new = 'Mridu', mukha_position_new = 'Tiryanga Mukha', eyesight_new = 'Andhaksha' WHERE "NakshatraNumber" = 27;  -- Revati

-- Fixes two pre-existing data gaps in Astro.DimYoga / Astro.DimKarana,
-- discovered while building birth-moment Panchang computation (Horo page):
-- both tables were missing their first cyclical entry (same shape of gap
-- as DimTithi's missing Shukla Pratipada / DimNakshtra's missing Ashwini),
-- and DimYoga had a likely typo ("Varigha" for what should be "Variyana",
-- yoga #18 in the standard 27-yoga list).
--
-- Unlike those two prior gaps (left alone - affect only one rare tithi/
-- nakshatra each), Bava recurs ~8 times per lunar month (~1-in-7 birth
-- charts would hit it), so it's fixed here rather than left as a gap.

UPDATE "Astro"."DimYoga" SET yoga_name = 'Variyana' WHERE yoga_name = 'Varigha';

INSERT INTO "Astro"."DimYoga" (id, yoga_name, is_auspicious, "YogaScore")
VALUES (1, 'Vishkumbha', false, 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO "Astro"."DimKarana" (id, karan_name, is_auspicious, "KaranScore")
VALUES (1, 'Bava', true, 0)
ON CONFLICT (id) DO NOTHING;

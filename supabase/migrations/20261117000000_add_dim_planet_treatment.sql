-- KP Kundli's Treatment suggestion: classical planet-wise treatment-type
-- associations, keyed by the 5th cusp's own Sub Lord. Added as a column
-- on the existing Astro.DimPlanet table (introduced for Health Info)
-- rather than a new table, since it's keyed the same way. Unlike
-- HealthInfo, Rahu/Ketu DO have their own fixed entries here - no
-- sign-lord/star-lord substitution needed for this one.

ALTER TABLE "Astro"."DimPlanet" ADD COLUMN IF NOT EXISTS "TreatmentInfo" text;

UPDATE "Astro"."DimPlanet" SET "TreatmentInfo" = 'Allopathic' WHERE "PlanetName" = 'Sun';
UPDATE "Astro"."DimPlanet" SET "TreatmentInfo" = 'Homeopathy' WHERE "PlanetName" = 'Moon';
UPDATE "Astro"."DimPlanet" SET "TreatmentInfo" = 'Homeopathy' WHERE "PlanetName" = 'Venus';
UPDATE "Astro"."DimPlanet" SET "TreatmentInfo" = 'Ayurvedic' WHERE "PlanetName" = 'Jupiter';
UPDATE "Astro"."DimPlanet" SET "TreatmentInfo" = 'Physiotherapy, mud therapy, acupuncture, or traditional/old-style home remedies' WHERE "PlanetName" = 'Saturn';
UPDATE "Astro"."DimPlanet" SET "TreatmentInfo" = 'Injection, surgery, or cuts (invasive treatment)' WHERE "PlanetName" = 'Mars';
UPDATE "Astro"."DimPlanet" SET "TreatmentInfo" = 'Naturopathy' WHERE "PlanetName" = 'Mercury';
UPDATE "Astro"."DimPlanet" SET "TreatmentInfo" = 'Unani treatment, or remedial/spiritual practices (nazar utarna, jhaad-phook)' WHERE "PlanetName" = 'Rahu';
UPDATE "Astro"."DimPlanet" SET "TreatmentInfo" = 'Ayurvedic - mantra chanting is also beneficial; stitching might also be involved' WHERE "PlanetName" = 'Ketu';

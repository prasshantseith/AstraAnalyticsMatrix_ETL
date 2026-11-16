-- KP Kundli's Health analysis: classical planet-wise disease/health
-- associations, keyed by planet name - same reference-table pattern as
-- Astro.DimNakshtra/DimTithi/DimYoga/DimKarana. Rahu/Ketu have no fixed
-- association of their own (NULL "HealthInfo") - classically you "pick"
-- their Rashi owner (sign lord) and Nakshatra owner (star lord) instead,
-- resolved in application code the same way their House Significators
-- already borrow both (see app.kp_astrology's effective_lords).

CREATE TABLE IF NOT EXISTS "Astro"."DimPlanet"
(
    "PlanetName" character varying(10) PRIMARY KEY,
    "HealthInfo" text
);

INSERT INTO "Astro"."DimPlanet" ("PlanetName", "HealthInfo") VALUES
    ('Sun', 'Heart disease, cholesterol, acidity, immunity-related or white blood cell problems. Bones might be weak, Vitamin D deficiency.'),
    ('Mars', 'Surgery, injuries/cuts especially on legs, multiple cuts, blood disorders, piles, BP problems, blood cancer, red blood cell issues, thalassemia (a genetic blood disorder causing fewer functioning red blood cells).'),
    ('Moon', 'Depression, anxiety attacks, cold & cough, short-term memory loss, digestive juice problems, breast disease/cancer.'),
    ('Mercury', 'Bed-ridden conditions, nervous system and spinal cord issues, indigestion, paralysis, seizures (मिरगी का दौरा), varicose veins in feet/ankles, Parkinson''s disease. (Tends to keep changing doctors.)'),
    ('Jupiter', 'Swelling, cholesterol, tumors, excess fat, liver issues, cancer, enlargement of body organs, internal allergies.'),
    ('Saturn', 'Leprosy (कुष्ठ), joint pain, arthritis, chronic cold/cough, recurring/repeated diseases.'),
    ('Venus', 'PCOD, diabetes, reproductive organ issues, low sperm count, skin allergies, white spots on body, uterus problems, irregular periods.'),
    ('Rahu', NULL),
    ('Ketu', NULL)
ON CONFLICT ("PlanetName") DO NOTHING;

do $$
begin
    if not exists (select from pg_roles where rolname = 'app_user') then
        create role app_user nologin;
    end if;
end $$;

REVOKE ALL ON TABLE "Astro"."DimPlanet" FROM app_user;
GRANT SELECT ON TABLE "Astro"."DimPlanet" TO app_user;
GRANT ALL ON TABLE "Astro"."DimPlanet" TO postgres;

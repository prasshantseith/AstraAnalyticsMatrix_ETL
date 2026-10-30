-- Adds the two rows that were deliberately left out earlier in this
-- conversation (Shukla Pratipada in DimTithi, Ashwini in DimNakshtra) -
-- confirmed to silently drop any day landing on either one from the
-- existing daily Panchang calendar (app.panchang_score), not just the new
-- Horo feature, so worth filling despite not having source score values
-- for every field.
--
-- Shukla Pratipada: NOT a copy of Krishna Pratipada's values - every other
-- Shukla/Krishna pair in this table skews more auspicious on the Shukla
-- side for the same tithi number (e.g. Dwitiya: Shukla is_auspicious=true/
-- score=2 vs Krishna is_auspicious=false/score=0), and Krishna Pratipada's
-- own description text says so explicitly ("Less auspicious than Shukla
-- Pratipada"). Scored/colored to match that pattern (TithiScore=2,
-- '#2ECC71', same as Shukla Dwitiya) rather than mirroring Krishna's
-- inauspicious -1/red. swami and keyword ARE shared identically across
-- every other pair observed, so those are copied from Krishna Pratipada.
INSERT INTO "Astro"."DimTithi" (
    id, tithi_name, tithi_name_full, "number", paksha, swami, nature,
    is_masa_shunya, is_auspicious, auspicious_text, highlight_color,
    description, "TithiScore", keyword, attributes, remedy
) VALUES (
    1, 'Pratipada', 'Shukla Pratipada', 1, 'Shukla', 'Agni', 'Auspicious',
    false, true, 'Auspicious', '#2ECC71',
    'First tithi of the bright fortnight - traditionally auspicious for new beginnings.',
    2, 'Prosperity',
    'Lord of Fire. Does not forgive easily. Sleeps little. Struggles to sustain long relationships. Overly sentimental. Has a strong appetite for food. On Shukla Pratipada specifically: also prone to being overly emotional, like a volcano beneath the surface.',
    'Perform Hawan (fire ritual) and light a lamp. Do puja. Do not interrupt any good work in progress. Observe fasts. Avoid being overly aggressive. Help with cremation/death rites when needed. Do not waste fire (Agni).'
)
ON CONFLICT (id) DO NOTHING;

-- Ashwini: NakshatraLord=Ketu matches the standard 9-planet Vimshottari
-- cycle (Ketu,Venus,Sun,Moon,Mars,Rahu,Jupiter,Saturn,Mercury) already
-- visible starting at Bharani(2)=Venus through Ashlesha(9)=Mercury in this
-- table - Ashwini(1) completing that cycle at Ketu is not a guess.
-- NakshatraElement left NULL (no single source for it, unlike Lord).
-- NakshatraScore is a neutral 0 placeholder - the user's own call, since
-- (unlike Lord) there's no table pattern or source value to derive it
-- from; correct it directly when a real value is available.
INSERT INTO "Astro"."DimNakshtra" (
    "NakshatraKey", "NakshatraNumber", "NakshatraName", "NakshatraLord", "NakshatraDevta",
    is_auspicious, "NakshatraScore", attributes
) VALUES (
    1, 1, 'Ashwini', 'Ketu', 'Ashwini Kumaras',
    true, 0,
    'Inclined toward the medical field. Walks/runs quickly, thinks quickly. Dislikes slow-moving people. Drawn to healthcare. Spends time on grooming/beautification. Always focused on their goal. Beautiful eyes. Fearless. Likes white or light colors. Full of self-respect. Sociable and easy to connect with. Doesn''t feel the effects of aging; likes to maintain a youthful appearance. Fond of medicine. A fast decision-maker.'
)
ON CONFLICT ("NakshatraKey") DO NOTHING;

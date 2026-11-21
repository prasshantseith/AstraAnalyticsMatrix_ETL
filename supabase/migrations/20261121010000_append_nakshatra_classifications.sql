-- Appends three classical nakshatra classifications to each row's
-- Astro.DimNakshtra.attributes text (existing text kept, new block added
-- after a blank line), shown on KP Kundli's Panchang and Custom Panchang
-- Nakshatra cards. Sourced from Dr Suresh Chandra Mishra's lecture "Nakshatra
-- Ka Asli Gyaan Kya Hai?" (youtube.com/watch?v=StjsP2B9wz4), translated from
-- the Hindi transcript:
--   * Nature (7 groups: Dhruva, Chara, Ugra, Mishra, Kshipra, Mridu, Tikshna).
--     The lecture does not name the Mishra members; Krittika and Vishakha
--     are the standard classical pair.
--   * Head posture (Urdhva / Adho / Tiryak Mukha) with suitable careers.
--   * Vision (Andha / Manda / Kana / Sulochana), a repeating cycle of four
--     starting at Rohini with Abhijit counted as the 28th nakshatra.
--   * Single-star (no companion) note for Ardra, Chitra and Swati.
--
-- Deliberately does NOT touch the existing swabhava / mukha_position /
-- eyesight columns, several of which disagree with these classical lists
-- (e.g. eyesight is 'Sama' for almost every row) - the user asked only to
-- append to attributes.
--
-- Idempotent: each UPDATE skips a row whose attributes already contain the
-- "Nature - " marker.

-- Ashwini: Kshipra / Tiryak Mukha / Manda
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Kshipra (Swift): fast-paced and impatient, lose patience quickly; skilled at enlarging or exaggerating things.
Head posture - Tiryak Mukha (head slanted): glance sideways, head moves about. Suited to work with animals, vehicles and transport, road building, sports, racing and driving, printing, publishing and writing, dealing in medicines, beauty work, wedding and event management, traffic control, digging, machinery and engineering, herbs, knowledge of species, acting and drama, long journeys, archaeology, history and scriptures.
Vision - Manda (weak sight): somewhat weak physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 1 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Bharani: Ugra / Adho Mukha / Kana
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Ugra (Fierce): sharp-tongued and quick to anger; blunt, with little sentiment. Thorough professionals focused on profit; listen to the head over the heart and can reject things outright, even to the boss.
Head posture - Adho Mukha (head bent): talk or work with the head lowered. Suited to handicrafts, desk and office work, medical diagnosis, surgery, legal investigation and law, editing, occult sciences and astrology, mind-related work, geology, swimming and diving, sea-related work, submarines, borewells, caves and bunkers, and preserving legal records.
Vision - Kana (one weak eye): uneven physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 2 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Krittika: Mishra / Adho Mukha / Sulochana
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Mishra (Mixed): a blend of all qualities and faults; mix easily with people of every age group.
Head posture - Adho Mukha (head bent): talk or work with the head lowered. Suited to handicrafts, desk and office work, medical diagnosis, surgery, legal investigation and law, editing, occult sciences and astrology, mind-related work, geology, swimming and diving, sea-related work, submarines, borewells, caves and bunkers, and preserving legal records.
Vision - Sulochana (good sight): good physical and inner vision (foresight).'
WHERE "NakshatraNumber" = 3 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Rohini: Dhruva / Urdhva Mukha / Andha
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Dhruva (Fixed): firm and stable in their views, with strong determination; once they decide something, they will not rest until it is done.
Head posture - Urdhva Mukha (head raised): look people in the eye when talking. Suited to promotion and sales, presentations, climbing, travel, astronomy, high-rise construction and maintenance, teaching, writing, medicine and healing, preaching, social welfare, religious work, remedial work and fortune-telling.
Vision - Andha (blind): weak physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 4 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Mrigashira: Mridu / Tiryak Mukha / Manda
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Mridu (Soft): tender, emotional and innocent, full of compassion; will give everything for a little affection, even at their own loss - self-sacrificing in love.
Head posture - Tiryak Mukha (head slanted): glance sideways, head moves about. Suited to work with animals, vehicles and transport, road building, sports, racing and driving, printing, publishing and writing, dealing in medicines, beauty work, wedding and event management, traffic control, digging, machinery and engineering, herbs, knowledge of species, acting and drama, long journeys, archaeology, history and scriptures.
Vision - Manda (weak sight): somewhat weak physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 5 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Ardra: Tikshna / Urdhva Mukha / Kana
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Tikshna (Sharp): penetrating - their words wound more than weapons. Aggressive with hidden anger; strike exactly where it hurts. Will not quietly accept anything unjust and are often discontent with the system or administration.
Head posture - Urdhva Mukha (head raised): look people in the eye when talking. Suited to promotion and sales, presentations, climbing, travel, astronomy, high-rise construction and maintenance, teaching, writing, medicine and healing, preaching, social welfare, religious work, remedial work and fortune-telling.
Vision - Kana (one weak eye): uneven physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.
Single star with no companion: few friends and less team spirit; prefers to work at the top rather than under someone.'
WHERE "NakshatraNumber" = 6 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Punarvasu: Chara / Tiryak Mukha / Sulochana
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Chara (Movable): restless, adventurous and proactive; work continuously without rest and plan ahead. Need constant novelty and change - rearranging the house, switching brands, shops or helpers.
Head posture - Tiryak Mukha (head slanted): glance sideways, head moves about. Suited to work with animals, vehicles and transport, road building, sports, racing and driving, printing, publishing and writing, dealing in medicines, beauty work, wedding and event management, traffic control, digging, machinery and engineering, herbs, knowledge of species, acting and drama, long journeys, archaeology, history and scriptures.
Vision - Sulochana (good sight): good physical and inner vision (foresight).'
WHERE "NakshatraNumber" = 7 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Pushya: Kshipra / Urdhva Mukha / Andha
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Kshipra (Swift): fast-paced and impatient, lose patience quickly; skilled at enlarging or exaggerating things.
Head posture - Urdhva Mukha (head raised): look people in the eye when talking. Suited to promotion and sales, presentations, climbing, travel, astronomy, high-rise construction and maintenance, teaching, writing, medicine and healing, preaching, social welfare, religious work, remedial work and fortune-telling.
Vision - Andha (blind): weak physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 8 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Ashlesha: Tikshna / Adho Mukha / Manda
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Tikshna (Sharp): penetrating - their words wound more than weapons. Aggressive with hidden anger; strike exactly where it hurts. Will not quietly accept anything unjust and are often discontent with the system or administration.
Head posture - Adho Mukha (head bent): talk or work with the head lowered. Suited to handicrafts, desk and office work, medical diagnosis, surgery, legal investigation and law, editing, occult sciences and astrology, mind-related work, geology, swimming and diving, sea-related work, submarines, borewells, caves and bunkers, and preserving legal records.
Vision - Manda (weak sight): somewhat weak physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 9 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Magha: Ugra / Adho Mukha / Kana
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Ugra (Fierce): sharp-tongued and quick to anger; blunt, with little sentiment. Thorough professionals focused on profit; listen to the head over the heart and can reject things outright, even to the boss.
Head posture - Adho Mukha (head bent): talk or work with the head lowered. Suited to handicrafts, desk and office work, medical diagnosis, surgery, legal investigation and law, editing, occult sciences and astrology, mind-related work, geology, swimming and diving, sea-related work, submarines, borewells, caves and bunkers, and preserving legal records.
Vision - Kana (one weak eye): uneven physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 10 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Purva Phalguni: Ugra / Adho Mukha / Sulochana
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Ugra (Fierce): sharp-tongued and quick to anger; blunt, with little sentiment. Thorough professionals focused on profit; listen to the head over the heart and can reject things outright, even to the boss.
Head posture - Adho Mukha (head bent): talk or work with the head lowered. Suited to handicrafts, desk and office work, medical diagnosis, surgery, legal investigation and law, editing, occult sciences and astrology, mind-related work, geology, swimming and diving, sea-related work, submarines, borewells, caves and bunkers, and preserving legal records.
Vision - Sulochana (good sight): good physical and inner vision (foresight).'
WHERE "NakshatraNumber" = 11 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Uttara Phalguni: Dhruva / Urdhva Mukha / Andha
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Dhruva (Fixed): firm and stable in their views, with strong determination; once they decide something, they will not rest until it is done.
Head posture - Urdhva Mukha (head raised): look people in the eye when talking. Suited to promotion and sales, presentations, climbing, travel, astronomy, high-rise construction and maintenance, teaching, writing, medicine and healing, preaching, social welfare, religious work, remedial work and fortune-telling.
Vision - Andha (blind): weak physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 12 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Hasta: Kshipra / Tiryak Mukha / Manda
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Kshipra (Swift): fast-paced and impatient, lose patience quickly; skilled at enlarging or exaggerating things.
Head posture - Tiryak Mukha (head slanted): glance sideways, head moves about. Suited to work with animals, vehicles and transport, road building, sports, racing and driving, printing, publishing and writing, dealing in medicines, beauty work, wedding and event management, traffic control, digging, machinery and engineering, herbs, knowledge of species, acting and drama, long journeys, archaeology, history and scriptures.
Vision - Manda (weak sight): somewhat weak physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 13 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Chitra: Mridu / Tiryak Mukha / Kana
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Mridu (Soft): tender, emotional and innocent, full of compassion; will give everything for a little affection, even at their own loss - self-sacrificing in love.
Head posture - Tiryak Mukha (head slanted): glance sideways, head moves about. Suited to work with animals, vehicles and transport, road building, sports, racing and driving, printing, publishing and writing, dealing in medicines, beauty work, wedding and event management, traffic control, digging, machinery and engineering, herbs, knowledge of species, acting and drama, long journeys, archaeology, history and scriptures.
Vision - Kana (one weak eye): uneven physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.
Single star with no companion: few friends and less team spirit; prefers to work at the top rather than under someone.'
WHERE "NakshatraNumber" = 14 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Swati: Chara / Tiryak Mukha / Sulochana
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Chara (Movable): restless, adventurous and proactive; work continuously without rest and plan ahead. Need constant novelty and change - rearranging the house, switching brands, shops or helpers.
Head posture - Tiryak Mukha (head slanted): glance sideways, head moves about. Suited to work with animals, vehicles and transport, road building, sports, racing and driving, printing, publishing and writing, dealing in medicines, beauty work, wedding and event management, traffic control, digging, machinery and engineering, herbs, knowledge of species, acting and drama, long journeys, archaeology, history and scriptures.
Vision - Sulochana (good sight): good physical and inner vision (foresight).
Single star with no companion: few friends and less team spirit; prefers to work at the top rather than under someone.'
WHERE "NakshatraNumber" = 15 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Vishakha: Mishra / Adho Mukha / Andha
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Mishra (Mixed): a blend of all qualities and faults; mix easily with people of every age group.
Head posture - Adho Mukha (head bent): talk or work with the head lowered. Suited to handicrafts, desk and office work, medical diagnosis, surgery, legal investigation and law, editing, occult sciences and astrology, mind-related work, geology, swimming and diving, sea-related work, submarines, borewells, caves and bunkers, and preserving legal records.
Vision - Andha (blind): weak physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 16 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Anuradha: Mridu / Tiryak Mukha / Manda
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Mridu (Soft): tender, emotional and innocent, full of compassion; will give everything for a little affection, even at their own loss - self-sacrificing in love.
Head posture - Tiryak Mukha (head slanted): glance sideways, head moves about. Suited to work with animals, vehicles and transport, road building, sports, racing and driving, printing, publishing and writing, dealing in medicines, beauty work, wedding and event management, traffic control, digging, machinery and engineering, herbs, knowledge of species, acting and drama, long journeys, archaeology, history and scriptures.
Vision - Manda (weak sight): somewhat weak physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 17 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Jyeshtha: Tikshna / Tiryak Mukha / Kana
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Tikshna (Sharp): penetrating - their words wound more than weapons. Aggressive with hidden anger; strike exactly where it hurts. Will not quietly accept anything unjust and are often discontent with the system or administration.
Head posture - Tiryak Mukha (head slanted): glance sideways, head moves about. Suited to work with animals, vehicles and transport, road building, sports, racing and driving, printing, publishing and writing, dealing in medicines, beauty work, wedding and event management, traffic control, digging, machinery and engineering, herbs, knowledge of species, acting and drama, long journeys, archaeology, history and scriptures.
Vision - Kana (one weak eye): uneven physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 18 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Mula: Tikshna / Adho Mukha / Sulochana
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Tikshna (Sharp): penetrating - their words wound more than weapons. Aggressive with hidden anger; strike exactly where it hurts. Will not quietly accept anything unjust and are often discontent with the system or administration.
Head posture - Adho Mukha (head bent): talk or work with the head lowered. Suited to handicrafts, desk and office work, medical diagnosis, surgery, legal investigation and law, editing, occult sciences and astrology, mind-related work, geology, swimming and diving, sea-related work, submarines, borewells, caves and bunkers, and preserving legal records.
Vision - Sulochana (good sight): good physical and inner vision (foresight).'
WHERE "NakshatraNumber" = 19 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Purva Ashadha: Ugra / Adho Mukha / Andha
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Ugra (Fierce): sharp-tongued and quick to anger; blunt, with little sentiment. Thorough professionals focused on profit; listen to the head over the heart and can reject things outright, even to the boss.
Head posture - Adho Mukha (head bent): talk or work with the head lowered. Suited to handicrafts, desk and office work, medical diagnosis, surgery, legal investigation and law, editing, occult sciences and astrology, mind-related work, geology, swimming and diving, sea-related work, submarines, borewells, caves and bunkers, and preserving legal records.
Vision - Andha (blind): weak physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 20 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Uttara Ashadha: Dhruva / Urdhva Mukha / Manda
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Dhruva (Fixed): firm and stable in their views, with strong determination; once they decide something, they will not rest until it is done.
Head posture - Urdhva Mukha (head raised): look people in the eye when talking. Suited to promotion and sales, presentations, climbing, travel, astronomy, high-rise construction and maintenance, teaching, writing, medicine and healing, preaching, social welfare, religious work, remedial work and fortune-telling.
Vision - Manda (weak sight): somewhat weak physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 21 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Shravana: Chara / Urdhva Mukha / Sulochana
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Chara (Movable): restless, adventurous and proactive; work continuously without rest and plan ahead. Need constant novelty and change - rearranging the house, switching brands, shops or helpers.
Head posture - Urdhva Mukha (head raised): look people in the eye when talking. Suited to promotion and sales, presentations, climbing, travel, astronomy, high-rise construction and maintenance, teaching, writing, medicine and healing, preaching, social welfare, religious work, remedial work and fortune-telling.
Vision - Sulochana (good sight): good physical and inner vision (foresight).'
WHERE "NakshatraNumber" = 22 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Dhanishta: Chara / Urdhva Mukha / Andha
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Chara (Movable): restless, adventurous and proactive; work continuously without rest and plan ahead. Need constant novelty and change - rearranging the house, switching brands, shops or helpers.
Head posture - Urdhva Mukha (head raised): look people in the eye when talking. Suited to promotion and sales, presentations, climbing, travel, astronomy, high-rise construction and maintenance, teaching, writing, medicine and healing, preaching, social welfare, religious work, remedial work and fortune-telling.
Vision - Andha (blind): weak physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 23 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Shatabhisha: Chara / Urdhva Mukha / Manda
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Chara (Movable): restless, adventurous and proactive; work continuously without rest and plan ahead. Need constant novelty and change - rearranging the house, switching brands, shops or helpers.
Head posture - Urdhva Mukha (head raised): look people in the eye when talking. Suited to promotion and sales, presentations, climbing, travel, astronomy, high-rise construction and maintenance, teaching, writing, medicine and healing, preaching, social welfare, religious work, remedial work and fortune-telling.
Vision - Manda (weak sight): somewhat weak physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 24 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Purva Bhadrapada: Ugra / Adho Mukha / Kana
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Ugra (Fierce): sharp-tongued and quick to anger; blunt, with little sentiment. Thorough professionals focused on profit; listen to the head over the heart and can reject things outright, even to the boss.
Head posture - Adho Mukha (head bent): talk or work with the head lowered. Suited to handicrafts, desk and office work, medical diagnosis, surgery, legal investigation and law, editing, occult sciences and astrology, mind-related work, geology, swimming and diving, sea-related work, submarines, borewells, caves and bunkers, and preserving legal records.
Vision - Kana (one weak eye): uneven physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 25 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Uttara Bhadrapada: Dhruva / Urdhva Mukha / Sulochana
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Dhruva (Fixed): firm and stable in their views, with strong determination; once they decide something, they will not rest until it is done.
Head posture - Urdhva Mukha (head raised): look people in the eye when talking. Suited to promotion and sales, presentations, climbing, travel, astronomy, high-rise construction and maintenance, teaching, writing, medicine and healing, preaching, social welfare, religious work, remedial work and fortune-telling.
Vision - Sulochana (good sight): good physical and inner vision (foresight).'
WHERE "NakshatraNumber" = 26 AND coalesce(attributes, '') NOT LIKE '%Nature - %';

-- Revati: Mridu / Tiryak Mukha / Andha
UPDATE "Astro"."DimNakshtra" SET attributes =
    coalesce(attributes || E'\n\n', '') || 'Nature - Mridu (Soft): tender, emotional and innocent, full of compassion; will give everything for a little affection, even at their own loss - self-sacrificing in love.
Head posture - Tiryak Mukha (head slanted): glance sideways, head moves about. Suited to work with animals, vehicles and transport, road building, sports, racing and driving, printing, publishing and writing, dealing in medicines, beauty work, wedding and event management, traffic control, digging, machinery and engineering, herbs, knowledge of species, acting and drama, long journeys, archaeology, history and scriptures.
Vision - Andha (blind): weak physical and inner vision (foresight). When most planets in a chart sit in Andha, Manda or Kana nakshatras, eyesight tends to be weak and decisions are often made quickly without weighing long-term results.'
WHERE "NakshatraNumber" = 27 AND coalesce(attributes, '') NOT LIKE '%Nature - %';


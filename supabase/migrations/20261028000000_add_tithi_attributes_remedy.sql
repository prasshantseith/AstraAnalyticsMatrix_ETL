-- Adds personality-attribute and remedy reference text to Astro.DimTithi,
-- sourced from the user's own tithi notes (translated from Hindi/Hinglish
-- shorthand into English). Krishna paksha carries the full, distinct text
-- for each tithi; Shukla paksha mirrors its Krishna-paksha counterpart
-- (same Lord, same underlying nature) except where the source notes gave
-- Shukla its own distinct text (Pratipada and Purnima - Purnima has no
-- Krishna-side counterpart at all, since Krishna's 15th tithi is Amavasya,
-- a different tithi entirely).
--
-- Also corrects swami (Lord) for Dashami (tithi 10, both pakshas) from
-- Kubera to Yamraj, per the source notes - the user's own call, since
-- Kubera was this table's prior (likely mistaken) value.
ALTER TABLE "Astro"."DimTithi"
    ADD COLUMN IF NOT EXISTS attributes text COLLATE pg_catalog."default",
    ADD COLUMN IF NOT EXISTS remedy text COLLATE pg_catalog."default";

UPDATE "Astro"."DimTithi" SET swami = 'Yamraj' WHERE "number" = 10;

-- Amavasya (Krishna 15 / "tithi 0") - Pitru
UPDATE "Astro"."DimTithi" SET
    attributes = 'A deep wound. Less respect in the household. A difference between private and public life - double-faced. Introverted. Prone to depression and suicidal thoughts.',
    remedy = 'Shraddha tarpan (ancestral rites), donate, keep clean, seek elders'' blessings, keep old electronics clean, light a lamp under Tulsi and Peepal trees. Do not try to conceive. Avoid buying new things.'
WHERE "number" = 15 AND paksha = 'Krishan';

-- Pratipada (tithi 1) - Agni Dev
UPDATE "Astro"."DimTithi" SET
    attributes = 'Lord of Fire. Does not forgive easily. Sleeps little. Struggles to sustain long relationships. Overly sentimental. Has a strong appetite for food.',
    remedy = 'Perform Hawan (fire ritual) and light a lamp. Do puja. Do not interrupt any good work in progress. Observe fasts. Avoid being overly aggressive. Help with cremation/death rites when needed. Do not waste fire (Agni).'
WHERE "number" = 1 AND paksha = 'Krishan';

-- Dwitiya (tithi 2) - Brahma
UPDATE "Astro"."DimTithi" SET
    attributes = 'Creative. Easily attracted to the opposite gender. Doing good for someone can end with bad feelings toward you. Overconfident. Prioritizes friends over family, especially opposite-gender friends. Fears scandal/bad reputation.',
    remedy = 'Be discreet. Feed construction workers, help with gardening, or care for plants. Do not hurt the ego of a knowledgeable person. Avoid sexual intercourse. Observe silence (maun vrat). Pursue creative work. (Brahma is the creator.)'
WHERE "number" = 2;

-- Tritiya (tithi 3) - Gauri
UPDATE "Astro"."DimTithi" SET
    attributes = 'Can be confrontational. Dominant toward their partner. Rarely feels they are in the wrong. Spends a lot of time on beauty. Many great makeup artists are born on this tithi. Loves beautiful things like cosmetics.',
    remedy = 'Perform Devi puja and puja for girls/daughters. Respect women. Avoid gossip and backbiting. Observe fasts.'
WHERE "number" = 3;

-- Chaturthi (tithi 4) - Ganesha
UPDATE "Astro"."DimTithi" SET
    attributes = 'Remover of obstacles (Vighnaharta). Good at studies. Manipulative. Deep understanding of things. Tends toward a heavier build, laziness, emotional manipulation, and shortcuts.',
    remedy = 'Give laddoos to children and construction workers; help with their studies. Walk on grass or lemongrass. Make children happy, especially those from lower-income backgrounds.'
WHERE "number" = 4;

-- Panchami (tithi 5) - Naga
UPDATE "Astro"."DimTithi" SET
    attributes = 'Compassionate toward living creatures - ants, rats, etc. Suited to work involving chemicals, mining, or hazardous/poisonous materials, and cosmetics. Adapts well to their environment. Fond of strong fragrances - sandalwood, perfume.',
    remedy = 'Offer milk to snakes, offer food to insects. Do not use chemicals on insects or disturb them. Offer milk at the base of a Peepal tree for ants and similar creatures.'
WHERE "number" = 5;

-- Shashthi (tithi 6) - Kartikeya
UPDATE "Astro"."DimTithi" SET
    attributes = 'Simple, straightforward, and intelligent. Good knowledge of medicine/chemicals or weapons. Takes no shortcuts. Well-educated.',
    remedy = 'Help children. Do not use oil on this tithi. Keep feathers (symbolic of Kartikeya). Give grain in charity. Stand up for the person in the right.'
WHERE "number" = 6;

-- Saptami (tithi 7) - Surya
UPDATE "Astro"."DimTithi" SET
    attributes = 'Proud, drawn to royal or prestigious professions. Often misunderstood but skilled at working with trends. Determined - finishes whatever work they commit to.',
    remedy = 'Offer water to the Sun (Surya Jal). Chant the Gayatri Mantra. Take sunlight and chant "Om Namah Shivaya". Let sunlight into the room/house. Be disciplined. Avoid miscommunication.'
WHERE "number" = 7;

-- Ashtami (tithi 8) - Rudra/Shiva
UPDATE "Astro"."DimTithi" SET
    attributes = 'Do not try to conceive on this tithi. Emotional and sentimental - gives everything when happy, withholds even water when not. OCD tendencies. Poor hygiene. Tends to doubt others a lot.',
    remedy = 'Fast; avoid being overly emotional. Items used in funeral/cremation rites can be donated. Avoid air pollution. Do not misuse water.'
WHERE "number" = 8;

-- Navami (tithi 9) - Durga
UPDATE "Astro"."DimTithi" SET
    attributes = 'Follows rules and restrictions. Alert to their own rights and responsibilities. No favoritism. Strong on the outside, soft on the inside - performs for peers.',
    remedy = 'Recite Durga Saptashati. Perform puja for girls and make them happy. Fast and eat satvik (pure vegetarian) food.'
WHERE "number" = 9;

-- Dashami (tithi 10) - Yamraj (corrected above from Kubera)
UPDATE "Astro"."DimTithi" SET
    attributes = 'Lives hand-to-mouth; sometimes quite frugal. Hardworking, with a sacrificing nature. Punctual. Fire element. Gives results based on one''s own actions, like Yamraj - tit for tat. Detached.',
    remedy = 'Perform Rudrabhishek. Help the family at the time of death.'
WHERE "number" = 10;

-- Ekadashi (tithi 11) - Vishnu and all devtas
UPDATE "Astro"."DimTithi" SET
    attributes = 'Frequent change in thoughts. Can lean atheist. Emotional - falls in and out of love/hate quickly, hypocritical, holds double standards.',
    remedy = 'Perform puja for Vishnu or any avatar of Rama. Fast. Avoid grains/rice, but donating them gives the best results.'
WHERE "number" = 11;

-- Dwadashi (tithi 12) - Vishnu
UPDATE "Astro"."DimTithi" SET
    attributes = 'Changeable nature, like the ocean. Involved in two paths/pursuits at once. Double income. Walks fast, finishes work fast, no concept of retirement. Always has something to do. Not lazy.',
    remedy = 'Perform puja for Vishnu or any avatar of Rama. Fast. Donate grain regularly.'
WHERE "number" = 12;

-- Trayodashi (tithi 13) - Kamadeva
UPDATE "Astro"."DimTithi" SET
    attributes = 'Loves fine art, dresses distinctively. Pays attention to their own style, creative, has an artist''s eye. Interested in matters of romance. Warm-hearted, thinks with the heart. Loyal in relationships.',
    remedy = 'Offer water to Shiva and chant "Om Namah Shivaya".'
WHERE "number" = 13;

-- Chaturdashi (tithi 14) - kept as Shiva per the user's own confirmation
-- (source notes said Kali Mata; noted here as a secondary association
-- rather than overwriting the Lord).
UPDATE "Astro"."DimTithi" SET
    attributes = 'Destructive, fire element - a hidden, silent volcano. Receives less attention within the family, tends to overreact.',
    remedy = 'Observe silence (maun vrat), avoid conflict, do not panic, stay calm. Perform puja for Shiva and Kali Mata.'
WHERE "number" = 14;

-- Purnima (tithi 15, Shukla only - Krishna's own 15th tithi is Amavasya,
-- a different tithi, so this has no Krishna counterpart to mirror).
UPDATE "Astro"."DimTithi" SET
    attributes = 'A turning point - the full moon. Do not try to conceive. Difficulty controlling emotions.',
    remedy = 'Avoid major decisions on the full moon. No parties. Avoid sexual intercourse.'
WHERE "number" = 15 AND paksha = 'Shukla';

-- Shukla paksha mirrors its Krishna-paksha counterpart by default (same
-- Lord, same underlying nature) for every tithi that doesn't already have
-- its own distinct text set above (Purnima is the only one already set).
UPDATE "Astro"."DimTithi" shukla SET
    attributes = krishna.attributes,
    remedy = krishna.remedy
FROM "Astro"."DimTithi" krishna
WHERE shukla.paksha = 'Shukla'
  AND krishna.paksha = 'Krishan'
  AND krishna."number" = shukla."number"
  AND shukla.attributes IS NULL;

-- Pratipada is the one Shukla tithi with its own additional note beyond
-- the Krishna-paksha base text just copied above.
UPDATE "Astro"."DimTithi" SET
    attributes = attributes || ' On Shukla Pratipada specifically: also prone to being overly emotional, like a volcano beneath the surface.'
WHERE "number" = 1 AND paksha = 'Shukla';

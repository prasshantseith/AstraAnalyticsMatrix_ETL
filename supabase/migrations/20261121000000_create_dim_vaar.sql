-- Day-of-birth (Vaar) personality attributes and remedies, keyed by the
-- English weekday name app.astrology.VAAR_NAMES already produces - same
-- reference-table pattern as Astro.DimTithi's attributes/remedy columns.
-- Backs the Vaar card on KP Kundli's Panchang and Custom Panchang tabs.
--
-- Sourced from Abhay Khanna's "Day Of Birth - Personality Traits | Love,
-- Marriage, Money, Career Upay" (youtube.com/watch?v=63PDsjmM0uY),
-- translated from the Hindi transcript. The video uses the English
-- (midnight-to-midnight) calendar day, not the sunrise-based Hindu vaar -
-- matching compute_birth_panchang, which takes the local civil date's
-- weekday.
--
-- Multi-line text: one point per line, rendered with white-space:
-- pre-line on the frontend.

CREATE TABLE IF NOT EXISTS "Astro"."DimVaar"
(
    "VaarName" character varying(10) PRIMARY KEY,
    attributes text,
    remedy text
);

INSERT INTO "Astro"."DimVaar" ("VaarName", attributes, remedy) VALUES
(
    'Monday',
    'Highly intuitive and friendly; gives motherly care to family and loved ones.
Emotional and a little insecure in relationships - needs reassurance from time to time. Restless mind, mood swings, some hidden fear.
Calm, pleasing personality; can seem like a different person at home and at work.
Strong imagination and creativity.
Often feels they give more in relationships than they get back - this is a karmic debt being balanced, so keep expectations low and keep doing your part.
Career: suits work involving nurturing, emotion and creativity. In IT, aim for team-lead/management roles (people connect with them), but stay away from office politics - it makes them insecure.
Avoid alcohol. Take breaks from a routine, machine-like life (travel, time away from screens).',
    'Temple: visit Somnath (Gujarat) at least once in life.
Lucky colour: Yellow.
Donation: Milk powder.
Vastu: keep a fan (exhaust, table or ceiling) running in the North-West of the home so life never stagnates.'
),
(
    'Tuesday',
    'Great courage and a never-give-up mindset - saying "I lost" is the hardest thing for them.
Fearless warriors; never let fear or pressure show on their face, which gives courage to those around them.
Strong focus, determination and high energy - expect others to match it and become irritated, aggressive or blunt when they don''t.
Prefer doing the work themselves rather than delegating. Learn well from their own mistakes. Value talent and quality without partiality. Self-made.
Get hurt easily - speak to them with care. Answer through their work, not words.
Breakthrough comes late compared to others; needs repeated attempts.
Do not judge your efforts or switch careers before age 28 - keep up sustained effort until then.',
    'Temple: visit Maa Vaishno Devi at least once in life.
Lucky colour: Orange.
Donation: a matchbox at a Hanuman temple (place it aside for people to use - not offered to the deity).
Vastu: place 9 triangle-cut Red Phoenix stones in the South of the home so life''s graph keeps rising.'
),
(
    'Wednesday',
    'Flexible; researches everything (searches Google a lot) - be careful what you claim around them.
Work selflessly without chasing credit; do the most work in any group or partnership without asking for a bigger share.
Someone very close (at work, among friends, or a relative) will betray them once - they learn from it and come out stronger.
Get bored easily; like shortcuts. Humanitarian, pure-hearted, very supportive of friends and people around them.
Cannot say a direct "no" - they say it indirectly. Overthinkers who hide it.
However shattered, they rebuild themselves within 48-72 hours.
Care a lot about reviews; curious; need time for decisions.
Do not let people use you - say no when needed. Do not be too review-conscious. Do not isolate yourself. Do not decide under pressure.',
    'Temple: visit Siddhivinayak (Mumbai) at least once, yearly if possible.
Lucky colour: Blue and pure White.
Offering: rice to Lord Ganesha.
Vastu: keep a Tulsi plant in the North of the home - medium-sized, covered respectfully with a chunni.'
),
(
    'Thursday',
    'Positive personality; free counsellors - go to the root of any subject and share that knowledge with everyone.
Dislike fights but step in as problem-solvers to settle them.
Excellent judges - side with whoever is right, even against a friend, which can cause disagreements.
Can make big sacrifices; as big a heart as their dreams.
Face difficulty coming to the front and making a name for themselves.
Give the world great advice but make mistakes in their own decisions - learn over time and bounce back well.
Do not forget past events easily; old matters stay in their heart. Known for their knowledge.
Avoid fast food, Chinese food and tamasic food - they absorb tamasic energy quickly.',
    'Temple: visit Pushkar Kund at least once in life.
Lucky colour: Off-White and Red.
Donation: small chana (chickpeas) or besan at religious places.
Vastu: keep fresh sunflowers or marigolds in a glass bowl (with a little water) in the North-East of the home; replace once they wilt.'
),
(
    'Friday',
    'Attention seekers; very conscious of how they look and how others see their nature and character.
Dislike tension and are a bit comfort-loving. Clean finishers - do one task at a time very well, but get overwhelmed by many at once (not lazy).
Pleasing, carefree personality, but very direct in speech, which sometimes hurts people.
Have a hidden talent that brings them success - must recognise it and not underestimate themselves (they need a "Jamvant" to remind them of their strength).
Run their own calculations in mind; status-conscious, sometimes live for show. Loyal once committed.
Never cheat in relationships - they tend to either betray or be betrayed.
Avoid chemical-laden food, packaged food, preservatives and chemical supplements.
Do not chase the material world - follow your real talent.',
    'Temple: visit Sita Ramachandra Swamy Temple, Ammapally (near Shamshabad, Telangana) at least once, yearly if possible.
Lucky colour: Silver, Fluorescent, Pink.
Donation: sugar or sweets.
Vastu: place a crystal lotus (pink or red) in the South-East of the home.'
),
(
    'Saturday',
    'Responsible; patient by birth.
Must face struggle and hard work at some stage of life - doing it early brings success sooner.
Succeed only after reaching the roots of things; need constant, sustained effort. Keep improving even after success.
Practical; dislike shortcuts. Joke and trust only a small set of people.
Life tests them again and again - keep sitting the exam without worrying about the result; large, lasting success is written for them, so never give up or rush.
Good day to start mantra chanting, vows (sankalp) or long-term undertakings.
Start the day with physical activity (gym or yoga). Communicate your unspoken rules to others instead of getting hurt or angry when they are broken.',
    'Temple: visit Ujjain Mahakal if possible.
Lucky colour: Green and Silver.
Donation: vada sambar to working-class people.
Vastu: put 8 whole almonds and 250 g of iron nails in a black pouch and hide it anywhere in the West of the home, away from sunlight.'
),
(
    'Sunday',
    'Distinct personality - their own shine, dominance, path and sophistication; high self-respect.
Prone to ego clashes with their partner; do not like hearing "no". Convince them with examples - you cannot impose on them. Commanding nature.
Care a lot about social status - good clothes, car, house.
Good money managers, but expenses run high.
Treat Sunday as a working day, not a holiday. Take morning sunlight. Go to bed early and wake early; stay disciplined.
Never make false commitments - the side effect shows up somewhere unexpected in life.',
    'Temple: visit Jagannath Puri at least once in life.
Lucky colour: Red, Yellow, Blue.
Donation: jaggery.
Vastu: place a rising-sun image or a green bamboo painting in the East of the home.'
)
ON CONFLICT ("VaarName") DO NOTHING;

do $$
begin
    if not exists (select from pg_roles where rolname = 'app_user') then
        create role app_user nologin;
    end if;
end $$;

REVOKE ALL ON TABLE "Astro"."DimVaar" FROM app_user;
GRANT SELECT ON TABLE "Astro"."DimVaar" TO app_user;
GRANT ALL ON TABLE "Astro"."DimVaar" TO postgres;

-- Adds personality-attribute reference text to Astro.DimNakshtra, sourced
-- from the user's own nakshatra notes (translated from Hindi/Hinglish
-- shorthand into English). Deliberately does NOT touch "NakshatraLord" /
-- "NakshatraDevta" - most of the source notes' deity mentions already
-- match those columns once translated (e.g. "Yamraaj" = existing "Yama",
-- "jupitor" = existing "Brihaspati"), but three genuinely disagree with
-- the existing data (Anuradha: notes say Indra, DB has Mitra; Shravana:
-- notes say Garuda, DB has Vishnu; Revati: notes say Rati, DB has Pushan)
-- and the user only asked to add attributes, not correct those fields -
-- left as-is, noted here for whoever reads this migration later.
ALTER TABLE "Astro"."DimNakshtra"
    ADD COLUMN IF NOT EXISTS attributes text COLLATE pg_catalog."default";

-- Ashwini (nakshatra 1) has no row in this table at all (same kind of
-- pre-existing gap as DimTithi's missing Shukla Pratipada) - not added
-- here since NakshatraLord/NakshatraElement/is_auspicious/NakshatraScore
-- are all required and have no source value from the notes. Its text, for
-- reference: "Inclined toward the medical field. Walks/runs quickly,
-- thinks quickly. Dislikes slow-moving people. Drawn to healthcare.
-- Spends time on grooming/beautification. Always focused on their goal.
-- Beautiful eyes. Fearless. Likes white or light colors. Full of
-- self-respect. Sociable and easy to connect with. Doesn't feel the
-- effects of aging; likes to maintain a youthful appearance. Fond of
-- medicine. A fast decision-maker." (Devta: Ashwini Kumar)

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Shaped like the female reproductive organ, associated with collection, storage, and preservation. A good friend but a bad enemy. Process-oriented. Makes good lawyers and researchers. High hormonal drive, easily attracts the opposite gender. Can be aggressive and miserly, tends toward early success.'
WHERE "NakshatraNumber" = 2;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Shaped like a knife. Interested in cutting/piercing work - radiotherapy, surgery, butchery, and similar fields. Drawn to fire-related work. Fiery and spicy personality, prone to anger, stubborn, strong appetite - though if in Aries the appetite is lighter, while in Taurus it is stronger. Loves to travel. Spans two zodiac signs; a Tripushkar nakshatra.'
WHERE "NakshatraNumber" = 3;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Symbolized by the wheel of a bullock cart. Very attractive, loves driving, creative, drawn to fashion and the arts. A natural performer, soft-hearted, loves pets.'
WHERE "NakshatraNumber" = 4;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Symbolized by the head of a deer. Soft-hearted, easily attracts the opposite gender, ruled by their senses, sensual nature, lives somewhat in an imaginary world, low tolerance, trusts blindly, sleeps long hours. A Dwipushkar nakshatra (2 padas fall in Taurus, 2 in Gemini).'
WHERE "NakshatraNumber" = 5;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Symbolized by a bright diamond; a natural leader. Soft-natured but appears solid/firm, can be arrogant, tries to dominate, has a scientific mindset. Never forgets good or bad behavior shown to them. A hidden volcano. Not naturally suited to business.'
WHERE "NakshatraNumber" = 6;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'A Tripushkar nakshatra associated with resettlement - often succeeds on a second attempt after an initial failure. Tends to keep fewer belongings at home, happier outside the home. Associated with remarriage and life''s ups and downs. Can be uncertain about their life partner, tends to reach beyond their usual circle. Gold is a lucky stone for them.'
WHERE "NakshatraNumber" = 7;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Shaped like an arrow. Loyal to parents, knowledgeable, loves learning - their words can sting like an arrow. Tends toward greater success within the family; interested in loans and lending-related business, and the stock market. Likes a big house or car. Wants to grow influence within temple trusts. Sensitive about prestige. Suited to banking and finance.'
WHERE "NakshatraNumber" = 8;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Represents embrace and clinging - like a snake coiled around a sandalwood tree. A Gand Mool nakshatra. If born in the 4th pada, may face difficulties in married life. Dominating nature, can be a bully, easily provoked, blinks frequently through the day, can show a bipolar-like personality. When in a position of power, tends to play games with opponents; plans and plots during difficult times. Clingy by nature. If the Moon is strong, can live like royalty. Girls with this nakshatra are advised not to live with their in-laws.'
WHERE "NakshatraNumber" = 9;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Symbolized by the door of a house. Money-responsible, expresses thoughts clearly, prone to anger, expressive. Enjoys the comfort of having others serve them. Hardworking, devoted to ancestors and family name. Emotional, often involved in family business. May have hidden enemies. Tries not to get swept up in emotions. Good for finances if the Moon is well placed; the first pada is not favorable for marriage.'
WHERE "NakshatraNumber" = 10;

UPDATE "Astro"."DimNakshtra" SET attributes =
    '''Phalguni'' implies something not immediately usable. Shaped like a divan/couch. Speaks in a sugar-coated way, lucky, loves to travel, suited to government-related work, has an attractive personality - though others may gossip behind their back. Visible veins, enjoys gossip, can be proud. Creative but lazy, manipulative.'
WHERE "NakshatraNumber" = 11;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Natural leadership qualities, creative, a critic, likes to feel like the best, respectful. Success is skill-based; if the Moon is poorly placed, tends to speak falsehoods. Half falls in Leo (Arjuna-like: a Tripushkar portion - lucky, more sexual energy, fond of gossip; men may enjoy stereotypically feminine hobbies like nail care and grooming), half in Virgo (inclined toward cosmetics, design, makeup artistry; men may behave in a more feminine way as the sign shifts).'
WHERE "NakshatraNumber" = 12;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Represents the hand/palm. Its 5 stars represent 5 fingers. Larger hands, creative, uses hand gestures while speaking. Skilled with their hands, enjoys having children, may have habits/vices. Works with their own hands, can be jealous of competitors, proud of their own success, prefers to mind their own business. If the Moon is poorly placed: tendencies toward theft (including stealing vehicles), or professions like sculptor, surgeon, writer, civil engineer, or operating scanning equipment.'
WHERE "NakshatraNumber" = 13;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Symbolized by a pearl/gem. Associated with Vishwakarma, the divine architect. Drawn to architecture, art, and many colors; loves music. Likes clothes and a lifestyle beyond their usual means. Spends long hours in the bathroom. Can be an irresponsible spouse, lazy, drawn to comfort and brands they find hard to give up. Has big dreams, strong in creation and creativity, colorful in behavior. A dual-natured sign; can be flirtatious, and may be bisexual or gay. The middle, 14th nakshatra.'
WHERE "NakshatraNumber" = 14;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Independent-minded, represented by a single star/diamond, associated with Vayu (the wind god). Doesn''t listen to others easily. Like air - sometimes flows happily, sometimes storms like a tempest; changeable like the wind. Creates their own path, fast-natured, suited to their own business, comfortable with commission-based work. Often feels thirsty. Prone to allergies (skin or hair), indigestion, or stomach surgery. Stubborn, inclined toward tantric or occult-related work. May face difficulties in married life if the Moon is weak. Adapts themselves based on the situation.'
WHERE "NakshatraNumber" = 15;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'The name means ''a branch without branches'' - a stump. Associated with tying a ribbon/thread on the door; ruled by Indra and Agni. A Tripushkar nakshatra with contradictory qualities - a combination of inner anger and outer calm, both jealous and kind. Prone to jealousy, has few close friends, can be sugar-coated when it serves their own interest, and their words shouldn''t always be trusted. Men may have trouble with their wife''s brother, women with their husband''s younger brother. For women: issues may arise with younger brothers, brothers-in-law, or sisters-in-law, or with childbirth. For men: issues may arise with younger sisters or in-laws, or a lack of support for children. Resourceful at getting their own work done, appears civil and well-mannered, can show a bipolar-like personality. May have a biological or emotional distance from their children. A bold/dominant nakshatra, prone to legal disputes.'
WHERE "NakshatraNumber" = 16;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'The name combines ''Anu'' (after) and ''Radha/Laxmi'' - tends to fail on the first attempt, then learns and succeeds on a retry. Fond of rice, clever, manipulative, finds success away from home. Overly sentimental and can hold grudges rather than being openly emotional. May have hidden vices, especially away from home. Secretive, restless, playful. A bold/dominant nakshatra, builds a reputation through strong connections, easily forms relationships with high-status people, bonds easily, and makes close platonic bonds easily. A Mars-Moon connection here works well, as it falls in Scorpio. Prone to legal disputes.'
WHERE "NakshatraNumber" = 17;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'The eldest/biggest in the house. A Gand Mool nakshatra; often a difficult married life. Hungry for prestige, can be lazy, a big talker, flashy, talented, drawn to indulgence/luxury. A bit timid at heart, quick to anger, can be untruthful, and may show off if the Moon is in the 1st, 5th, or 10th house. Has few truly close friends. A Mars-Moon connection works well here too, as it falls in Scorpio. May have conflicts with elders - best to stay on clear terms with elders, including in-laws and older siblings. Prone to legal disputes, especially with elders, as they struggle to accept others as superior to themselves.'
WHERE "NakshatraNumber" = 18;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Falls in Sagittarius; symbolized by a lion''s tail, representing the geocentric point of the galaxy. Married life may be disturbed if born in the 1st pada. Attacking/confrontational nature, detective-like, gets to the root cause of things, OCD tendencies, can lose their dignity, somewhat eccentric. Can indicate a Raj Yoga if the Moon is strong in its paksha and well-connected with Jupiter. Women with this nakshatra are advised not to live with their in-laws; can be hard to understand. Men may find it difficult to work well with in-laws. Has knowledge of herbs, drawn to mining and research.'
WHERE "NakshatraNumber" = 19;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Adamant and unyielding - someone who cannot be bent. Angry like an elephant, strong-willed like an elephant, forms unbreakable friendships. Doesn''t like being advised. Prone to urinary-related issues. Enjoys foreign travel, can work in water-related fields. Anger can be hard to control, though a well-placed Jupiter has a positive influence.'
WHERE "NakshatraNumber" = 20;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Symbolized by a charpai (cot/bed frame). Responsible, maintains their standing/existence, makes a good life partner, fears disgrace/bad reputation, doesn''t show anger openly. Suited to design and engineering. Likes brands, enjoys living by the beach or in the mountains, enjoys pilgrimage travel. Takes revenge through careful planning and plotting. A slow and steady worker, enjoys spa/self-care, less expressive.'
WHERE "NakshatraNumber" = 21;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Associated with the birth of Vamana. A good listener and a good speaker, goal-oriented, doesn''t get easily distracted. Good at literature. Long ears are considered spiritually favorable; hair growing in the ears may indicate a higher chance of divorce. May enjoy gambling, fast driving. Suited to law, sports, and voice-related work such as teaching, law, singing, or commentary.'
WHERE "NakshatraNumber" = 22;

UPDATE "Astro"."DimNakshtra" SET attributes =
    '''Dhan'' means wealth - takes money matters seriously. Shaped like a dholki (hand drum). Likes accumulating wealth, respects government institutions. Suited to professions like cashier or financial advisor. Likes certificates and prestige. An environmental lover, likes cleanliness, dislikes pollution. A sweet speaker.'
WHERE "NakshatraNumber" = 23;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Represents forming a boundary/circle; a team player, manipulative, competitive by nature. Prone to setting counter-traps - intentionally catching someone in the trap they set for you. Prone to coughs and colds. Tends to stay either consistently sad or consistently balanced. May misuse power. Likes collecting personal belongings and keeping things unchanged over time. Can be confused, slow to make decisions. Prone to chronic ailments after the age of 40.'
WHERE "NakshatraNumber" = 24;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Symbolized by twin children. Playful, can show a bipolar-like personality. Prone to leg problems, restless. Spends on the opposite gender, can be miserly. Fond of gossip. May have difficulty walking. Manipulative, drawn to extreme hot or cold foods. Not easy to understand; remembers both friends and enemies well - can be opportunistic.'
WHERE "NakshatraNumber" = 25;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Symbolized by a stool/platform. Fearful of water, sensitive about prestige, moody. Enjoys elegant clothing, ponytails or hair buns, drawn to hairstyling. Beautiful, with strong and attractive feet.'
WHERE "NakshatraNumber" = 26;

UPDATE "Astro"."DimNakshtra" SET attributes =
    'Enjoys praise, name, and fame. Competitive nature. Can have a somewhat stronger inclination toward physical desire, especially in the 3rd/4th pada. Tends to blame fate for setbacks. Extravagant nature. May make poor choices in a life partner by prioritizing physical beauty. The 4th pada is associated with a difficult married life.'
WHERE "NakshatraNumber" = 27;

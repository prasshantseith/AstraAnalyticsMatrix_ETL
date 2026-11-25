-- More KP questions for the Vimshottari Dasha question dropdown, from the
-- KP "12 houses" lesson: court marriage (3 + 7 + 8), a dispute reaching
-- court (6 + 8), long-term stock investing (5 + 12) and intraday trading
-- (8). Unfavourable houses follow the lesson's rule - the 12th from each
-- favourable house negates it - minus any house that is itself favourable.
-- Transfer is re-based on the lesson's 3 + 9 (3 = the transfer order /
-- document, 9 = long journey), replacing 3 / 10 / 12 vs 4.

INSERT INTO "Astro"."DimKpQuestion"
    ("QuestionId", "Category", "Question", "MainCusp", "Favourable", "FavourableDesc", "Unfavourable", "UnfavourableDesc", "SortOrder")
VALUES
(23, 'Marriage', 'Court marriage', '{7}', '{3,7,8}',
 '3 = documents and signature, 7 = marriage, 8 = court.',
 '{2,6}', '2 = 12th from the 3rd, 6 = 12th from the 7th (the 7th, 12th from the 8th, is itself favourable here).', 125),

(24, 'Legal', 'Dispute reaching court', '{6}', '{6,8}',
 '6 = litigation, 8 = court.',
 '{5,7}', '5 = 12th from the 6th, 7 = 12th from the 8th.', 195),

(25, 'Finance', 'Long-term stock investing', '{5}', '{5,12}',
 '5 = shares, 12 = long-term investment.',
 '{4,11}', '4 = 12th from the 5th, 11 = 12th from the 12th.', 225),

(26, 'Finance', 'Intraday trading', '{8}', '{8}',
 '8 = others'' money and sudden, unearned gains (intraday).',
 '{7}', '7 = 12th from the 8th.', 226)
ON CONFLICT ("QuestionId") DO NOTHING;

UPDATE "Astro"."DimKpQuestion"
SET "Favourable" = '{3,9}',
    "FavourableDesc" = '3 = the transfer order / document passing, 9 = long journey.',
    "Unfavourable" = '{2,8}',
    "UnfavourableDesc" = '2 = 12th from the 3rd, 8 = 12th from the 9th.'
WHERE "QuestionId" = 6;

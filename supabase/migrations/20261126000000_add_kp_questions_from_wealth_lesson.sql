-- Two more KP questions for the Vimshottari Dasha question dropdown, from
-- the KP wealth lesson's "Bhav Cusp" method: a house whose Cusp Sub Lord
-- gives 2 / 6 / 11 lets the person earn through that house's matters, and
-- 5 / 8 / 12 blocks it.
--  - Money lent comes back: judged from the 6th cusp (lending and borrowing).
--  - Earning from astrology: judged from the 8th and 9th cusps.

INSERT INTO "Astro"."DimKpQuestion"
    ("QuestionId", "Category", "Question", "MainCusp", "Favourable", "FavourableDesc", "Unfavourable", "UnfavourableDesc", "SortOrder")
VALUES
(27, 'Finance', 'Money lent comes back', '{6}', '{2,6,11}',
 '2 = money, 6 = lending and recovery, 11 = gain - money given out returns.',
 '{5,8,12}', '5 = 12th from the 6th, 8 = money stuck, 12 = loss - money given out doesn''t return.', 227),

(28, 'Profession', 'Earning from astrology', '{8,9}', '{2,6,11}',
 '2 = money, 6 = service / consultations, 11 = gain - astrology pays.',
 '{5,8,12}', '5, 8, 12 = loss and blockage - practise astrology, but don''t count on it for income.', 75)
ON CONFLICT ("QuestionId") DO NOTHING;

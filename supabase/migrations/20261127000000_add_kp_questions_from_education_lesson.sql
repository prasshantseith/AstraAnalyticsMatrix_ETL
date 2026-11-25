-- Two KP questions for the Vimshottari Dasha question dropdown, from the
-- KP education lesson:
--  - Basic education (up to graduation): judged from the 4th cusp - the
--    mother is the first teacher; 4 = regular study.
--  - Higher education (post-graduation, PhD, LLB or a second degree):
--    judged from the 9th cusp - guru / mentor, studying away from home.
-- Good 2 / 4 / 5 / 9 / 11, bad 3 / 8 / 12 for both.

INSERT INTO "Astro"."DimKpQuestion"
    ("QuestionId", "Category", "Question", "MainCusp", "Favourable", "FavourableDesc", "Unfavourable", "UnfavourableDesc", "SortOrder")
VALUES
(29, 'Education', 'Basic education (up to graduation)', '{4}', '{2,4,5,9,11}',
 '2 = degrees gathered, 4 = regular study, 5 = intelligence, 9 = luck / good teacher, 11 = completion.',
 '{3,8,12}', '3 = irregular / distance study, 8 = obstacles in study, 12 = loss of focus.', 152),

(30, 'Education', 'Higher education (post-graduation, PhD)', '{9}', '{2,4,5,9,11}',
 '2 = degrees gathered, 4 = study, 5 = intelligence, 9 = higher learning / guru, 11 = completion.',
 '{3,8,12}', '3 = irregular / distance study, 8 = obstacles (or research), 12 = loss of focus (or study abroad).', 154)
ON CONFLICT ("QuestionId") DO NOTHING;

-- KP question reference table: for each common question, the main cusp to
-- judge it from and the favourable / unfavourable house groups. Backs the
-- question dropdown on KP Kundli's Vimshottari Dasha tab, where each Dasha
-- lord is scored against the selected question's houses (same method as
-- Life Analysis -> Wealth).
--
-- Health and Wealth match the house sets Life Analysis already uses
-- (Health 5/9/11 vs 6/8/12 is the user's own choice; most KP texts give
-- 1/5/11). Unfavourable houses are mostly the 12th from each favourable
-- one (the 12th from a house negates it). Surgery and Longevity are left
-- out on purpose: surgery needs a "Mars involved" condition a house count
-- can't express, and a per-Dasha longevity/danger score is too sensitive
-- to show casually.

CREATE TABLE IF NOT EXISTS "Astro"."DimKpQuestion"
(
    "QuestionId" smallint PRIMARY KEY,
    "Category" text NOT NULL,
    "Question" text NOT NULL,
    "MainCusp" smallint[],
    "Favourable" smallint[] NOT NULL,
    "FavourableDesc" text,
    "Unfavourable" smallint[] NOT NULL,
    "UnfavourableDesc" text,
    "SortOrder" smallint NOT NULL
);

INSERT INTO "Astro"."DimKpQuestion"
    ("QuestionId", "Category", "Question", "MainCusp", "Favourable", "FavourableDesc", "Unfavourable", "UnfavourableDesc", "SortOrder")
VALUES
(1, 'Health', 'Health / recovery', '{1}', '{5,9,11}',
 '5 = 12th from the 6th (end of disease), 9 = fortune and protection, 11 = 12th from the 12th (relief from hospital).',
 '{6,8,12}', '6 = disease, 8 = chronic illness and danger, 12 = hospitalisation.', 10),

(2, 'Wealth', 'Wealth / regular income', '{2}', '{2,6,11}',
 '2 = money and savings, 6 = earnings through service and gain over competitors, 11 = gains and fulfilment.',
 '{5,8,12}', '5 = 12th from the 6th (loss of earnings), 8 = sudden loss or debt, 12 = expenses and losses.', 20),

(3, 'Profession', 'Job (service)', '{10}', '{2,6,10,11}',
 '2 = income, 6 = service and employment, 10 = career and status, 11 = gains and fulfilment.',
 '{1,5,8,9,12}', '1, 5, 9 are the 12th from 2, 6, 10 (break or loss of job); 8 = obstacles, 12 = loss.', 30),

(4, 'Profession', 'Promotion', '{10}', '{2,6,10,11}',
 '2 = higher income, 6 = success in service, 10 = rise in status, 11 = fulfilment of ambition.',
 '{5,8,9,12}', '5 and 9 are the 12th from 6 and 10 (setback), 8 = obstacles, 12 = loss.', 40),

(5, 'Profession', 'Leaving job / break in service', '{10}', '{1,5,9}',
 '1, 5, 9 are the 12th from 2, 6, 10 - they end the current service.',
 '{2,6,10,11}', '2, 6, 10, 11 keep the current job going.', 50),

(6, 'Profession', 'Transfer / change of place', '{10}', '{3,10,12}',
 '3 = change of place and short travel, 10 = job, 12 = new or distant place.',
 '{4}', '4 = staying in the same residence and place.', 60),

(7, 'Profession', 'Business', '{7,10}', '{2,7,10,11}',
 '2 = money, 7 = trade, partners and clients, 10 = profession, 11 = profit.',
 '{6,8,12}', '6 = 12th from the 7th (loss to the business), 8 = obstacles and losses, 12 = expenses.', 70),

(8, 'Property', 'House / property purchase', '{4}', '{4,11,12}',
 '4 = house and land, 11 = fulfilment, 12 = money invested.',
 '{3,5,8}', '3 = 12th from the 4th (loss of property), 5 = gain to others, 8 = obstacles.', 80),

(9, 'Property', 'Sale of property', '{4}', '{3,5,10}',
 '3 = 12th from the 4th (parting with property), 5 = gain to the buyer, 10 = 7th from the 4th (the buyer).',
 '{4,11,12}', '4, 11, 12 keep or add property.', 90),

(10, 'Property', 'Vehicle', '{4}', '{4,11}',
 '4 = vehicles and comforts, 11 = fulfilment.',
 '{3,8,12}', '3 = 12th from the 4th, 8 = obstacles or accidents, 12 = loss.', 100),

(11, 'Marriage', 'Marriage', '{7}', '{2,7,11}',
 '2 = addition to the family, 7 = spouse and partnership, 11 = fulfilment of desire.',
 '{1,6,10}', '1, 6, 10 are the 12th from 2, 7, 11 - denial or delay of marriage.', 110),

(12, 'Marriage', 'Love affair / love marriage', '{5}', '{5,7,11}',
 '5 = romance and love, 7 = marriage, 11 = fulfilment.',
 '{1,6,10}', '1, 6, 10 negate 2, 7, 11 - break-up or opposition.', 120),

(13, 'Marriage', 'Divorce / separation', '{7}', '{1,6,10,12}',
 '1, 6, 10 are the 12th from 2, 7, 11 (end of the marriage); 12 = loss and separation.',
 '{2,7,11}', '2, 7, 11 keep the marriage together.', 130),

(14, 'Children', 'Childbirth', '{5}', '{2,5,11}',
 '2 = addition to the family, 5 = children, 11 = fulfilment of desire.',
 '{1,4,10}', '1, 4, 10 are the 12th from 2, 5, 11 - denial, delay or miscarriage.', 140),

(15, 'Education', 'Education', '{4,9}', '{4,9,11}',
 '4 = basic education, 9 = higher education, 11 = success.',
 '{3,8,12}', '3 = 12th from the 4th, 8 = 12th from the 9th (breaks in study), 12 = loss.', 150),

(16, 'Education', 'Exam success', '{4}', '{4,9,11}',
 '4 = studies, 9 = higher learning, 11 = success.',
 '{3,8,12}', '3, 8 = breaks in study, 12 = loss or failure.', 160),

(17, 'Education', 'Competitive exam', '{6}', '{6,10,11}',
 '6 = victory over competitors, 10 = status, 11 = success.',
 '{5,9,12}', '5 and 9 are the 12th from 6 and 10, 12 = loss.', 170),

(18, 'Travel', 'Foreign travel / settling abroad', '{12}', '{3,9,12}',
 '3 = short travel, 9 = long journeys, 12 = foreign land. Settling abroad needs 12 without 4.',
 '{2,4,11}', '2 = family, 4 = home and residence, 11 = staying or returning home.', 180),

(19, 'Legal', 'Court case / litigation', '{6}', '{1,6,11}',
 '1 = self, 6 = victory over enemies, 11 = fulfilment (winning).',
 '{5,7,12}', '5 = 12th from the 6th, 7 = the opponent, 12 = loss.', 190),

(20, 'Finance', 'Loan received', '{6}', '{2,6,11}',
 '2 = money, 6 = loans and borrowing, 11 = fulfilment.',
 '{8,12}', '8 = obstacles, 12 = denial or loss.', 200),

(21, 'Finance', 'Debt repaid', '{12}', '{8,12}',
 '8 = settlement of dues, 12 = expenditure (paying off the debt).',
 '{6}', '6 = debt continues.', 210),

(22, 'Finance', 'Speculation / lottery / shares', '{5}', '{5,8,11}',
 '5 = speculation, 8 = unearned or windfall money, 11 = gain. (5 and 8 are bad for regular income but good for speculation.)',
 '{12}', '12 = loss.', 220)
ON CONFLICT ("QuestionId") DO NOTHING;

do $$
begin
    if not exists (select from pg_roles where rolname = 'app_user') then
        create role app_user nologin;
    end if;
end $$;

REVOKE ALL ON TABLE "Astro"."DimKpQuestion" FROM app_user;
GRANT SELECT ON TABLE "Astro"."DimKpQuestion" TO app_user;
GRANT ALL ON TABLE "Astro"."DimKpQuestion" TO postgres;

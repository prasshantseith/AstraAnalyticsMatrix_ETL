-- Reporting/authorization pair for the "Reset Panchang User" feedback
-- flow (see AstraanAlyticsMatrixAPI's app/routers/feedback.py and
-- app/routers/panchang.py):
--
-- Users.users.reset_token_count — incremented once per "Reset Panchang
-- User" feedback submission from that user. Pure reporting: lets an admin
-- see this is someone's 2nd/3rd/... request rather than a one-off, and
-- decide whether to keep granting it or point them at buying a token.
--
-- Astro.UsersPanchang.reset_by_admin — stays false through a normal
-- user-initiated delete (explicitly cleared alongside is_active in
-- delete_person). An admin flips it to true by hand after reviewing a
-- reset request and deciding to actually grant it for that specific
-- profile — that's the only thing that stops the profile counting toward
-- the user's token limit (see app.billing.panchang_profiles_used).
ALTER TABLE "Users".users
    ADD COLUMN IF NOT EXISTS reset_token_count INTEGER NOT NULL DEFAULT 0;

ALTER TABLE "Astro"."UsersPanchang"
    ADD COLUMN IF NOT EXISTS reset_by_admin BOOLEAN NOT NULL DEFAULT false;

-- Astro.UsersPanchang holds app-owned user/profile data (who a user has
-- added for the Panchang feature) — not astrology reference or fact data
-- like the rest of the Astro schema, so it belongs under Users instead.
--
-- SET SCHEMA also moves the table's owned identity sequence
-- (UsersPanchang_id_seq) automatically — confirmed on this Postgres
-- version (17.6), no separate ALTER SEQUENCE needed. All constraints
-- (panchang_people_pkey, the FK to Users.users) and indexes move with the
-- table as normal.
ALTER TABLE "Astro"."UsersPanchang" SET SCHEMA "Users";

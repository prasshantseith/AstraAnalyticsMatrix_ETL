-- "Removing" a Panchang person (UsersPanchang) is now a soft delete — the
-- row and its data stay, only this flips to false — so a user who paid for
-- an extra Panchang token doesn't lose their data on a mistaken removal,
-- and removing/re-adding someone doesn't cost another token. Every lookup
-- in AstraanAlyticsMatrixAPI's app/routers/panchang.py (list, delete,
-- preferences, calendar, and the add-limit count) now filters on this;
-- an inactive person is 404/absent everywhere, same as a real delete would
-- look from the API's perspective.
ALTER TABLE "Astro"."UsersPanchang"
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

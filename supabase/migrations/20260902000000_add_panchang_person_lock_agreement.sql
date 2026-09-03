-- Astrology-defining fields on a Panchang person (nakshatra, rashi,
-- date_of_birth, time_of_birth, birth_place, birth_latitude,
-- birth_longitude) are read-only after creation — there's no update
-- endpoint for them, only delete-and-recreate. The user has to explicitly
-- agree to that at creation (see AstraanAlyticsMatrixAPI's
-- schemas.PersonCreate.agreed_to_lock_terms); this column records that the
-- agreement was actually given rather than just implied by the missing
-- edit endpoint. Existing rows default to true since they predate this
-- consent flow and were already effectively locked (no edit endpoint ever
-- existed for them).
ALTER TABLE "Astro"."UsersPanchang"
    ADD COLUMN IF NOT EXISTS agreed_to_lock_terms BOOLEAN NOT NULL DEFAULT true;

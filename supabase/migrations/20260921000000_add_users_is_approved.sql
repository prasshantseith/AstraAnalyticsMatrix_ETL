-- New-signup approval gate (AstraanAlyticsMatrixAPI's app.models.User.is_approved
-- and app.dependencies.get_current_user) — a brand-new account is created with
-- this false and can't do anything until an admin approves it from the Admin
-- page's Users tab. DEFAULT true exists purely so this ADD COLUMN grandfathers
-- every pre-existing row as already approved; the API explicitly passes false
-- on a fresh INSERT, overriding the default.
ALTER TABLE "Users".users
    ADD COLUMN IF NOT EXISTS is_approved BOOLEAN NOT NULL DEFAULT true;

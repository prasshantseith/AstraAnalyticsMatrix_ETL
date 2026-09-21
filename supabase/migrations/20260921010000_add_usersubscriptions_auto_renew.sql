-- Backs AstraanAlyticsMatrixAPI's app.models.UserSubscription.auto_renew /
-- .current_period_end — a paid tier now starts a ~1 year period on
-- selection; turning auto_renew off doesn't change anything immediately,
-- the plan just won't extend past current_period_end (app.billing's
-- get_effective_subscription lazily reverts it to free on the next read
-- past that date — there's no cron job).
ALTER TABLE "Users"."UserSubscriptions"
    ADD COLUMN IF NOT EXISTS auto_renew BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE "Users"."UserSubscriptions"
    ADD COLUMN IF NOT EXISTS current_period_end TIMESTAMPTZ;

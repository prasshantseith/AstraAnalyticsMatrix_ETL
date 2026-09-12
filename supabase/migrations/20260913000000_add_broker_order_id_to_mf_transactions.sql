-- Re-importing the same ShareKhan "Order Report" (or an overlapping date
-- range from a later export) previously created a duplicate transaction row
-- every time, since nothing identified "this broker order" across imports.
-- ShareKhan's own Order Id is that identifier; store it and enforce
-- uniqueness per user so a re-import can overwrite instead of duplicating.
--
-- NULL brokerorderid rows (transactions entered manually, or any pre-existing
-- row from before this column existed) are unaffected — Postgres treats
-- every NULL as distinct for UNIQUE purposes, so they never conflict with
-- each other or with a real order id.
ALTER TABLE "MF"."UserMutualFundTransactions"
    ADD COLUMN IF NOT EXISTS brokerorderid character varying(50);

ALTER TABLE "MF"."UserMutualFundTransactions"
    ADD CONSTRAINT uq_umft_user_brokerorderid UNIQUE (userid, brokerorderid);

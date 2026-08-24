-- expense_ratio numeric(5,2) and volatility numeric(8,4) were too narrow:
-- the dev scheme detail sync (32667779274) hit "numeric field overflow" on
-- 72/8662 funds writing values from the mf.captnemo.in API into these
-- columns. Widen both generously; MF_Performance and other consumers only
-- ever read these, so this is a safe, additive change.

ALTER TABLE "MF"."MF"
    ALTER COLUMN expense_ratio TYPE numeric(10, 4);

ALTER TABLE "MF"."MF"
    ALTER COLUMN volatility TYPE numeric(14, 4);

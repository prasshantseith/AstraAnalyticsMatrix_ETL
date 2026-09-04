-- Stocks.usp_RefreshStockPerformance does 7-8 LEFT JOIN LATERAL lookback
-- lookups per instrument (WHERE InstrumentId = ... AND TradeDate <= ...
-- ORDER BY TradeDate DESC LIMIT 1), scoped to cash equities only (WHERE
-- OptionType IS NULL AND ExpiryDate IS NULL - every row these lookups
-- actually touch). StockData only had separate single-column indexes on
-- InstrumentId and TradeDate, nothing matching this composite access
-- pattern. As the table has grown, the procedure degraded from ~14s to
-- over 10 minutes (exceeding even a 600s statement_timeout - see
-- call_procedure.py). Propagates automatically to every partition.
--
-- (MF.usp_RefreshMFPerformance has the identical LATERAL pattern on
-- MF.MF_NAV, but that table already has an equivalent index via its
-- UNIQUE ("SchemeCode", "NavDate") constraint - no separate index needed
-- there.)
CREATE INDEX IF NOT EXISTS "IX_StockData_InstrumentId_TradeDate_Equity"
    ON "Stocks"."StockData" ("InstrumentId", "TradeDate" DESC)
    WHERE "OptionType" IS NULL AND "ExpiryDate" IS NULL;

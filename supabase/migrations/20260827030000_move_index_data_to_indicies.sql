CREATE SCHEMA IF NOT EXISTS "Indicies";

CREATE TABLE IF NOT EXISTS "Indicies"."IndexConfig" (
    "IndexName" varchar(100) PRIMARY KEY,
    "NseIndexType" varchar(100) NOT NULL,
    "StartDate" date NOT NULL,
    "Enabled" boolean NOT NULL DEFAULT true
);

INSERT INTO "Indicies"."IndexConfig" ("IndexName", "NseIndexType", "StartDate", "Enabled")
SELECT "IndexName", "NseIndexType", "StartDate", "Enabled"
FROM "Stocks"."IndexConfig"
ON CONFLICT ("IndexName") DO NOTHING;

INSERT INTO "Indicies"."IndexConfig" ("IndexName", "NseIndexType", "StartDate")
VALUES
    ('NIFTY 50', 'NIFTY 50', DATE '1996-01-01'),
    ('NIFTY 500', 'NIFTY 500', DATE '1995-01-01'),
    ('NIFTY BANK', 'NIFTY BANK', DATE '2000-01-01')
ON CONFLICT ("IndexName") DO UPDATE SET
    "NseIndexType" = EXCLUDED."NseIndexType",
    "StartDate" = EXCLUDED."StartDate";

CREATE TABLE IF NOT EXISTS "Indicies"."IndexData" (
    "IndexName" varchar(100) NOT NULL,
    "TradeDate" date NOT NULL,
    "OpenPrice" numeric(18,4),
    "HighPrice" numeric(18,4),
    "LowPrice" numeric(18,4),
    "ClosePrice" numeric(18,4),
    "Volume" bigint,
    "TurnoverInrCr" numeric(20,4),
    "DataSource" varchar(30) NOT NULL DEFAULT 'NSE',
    "SourceFile" varchar(500),
    "CreatedAt" timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT "IndexData_pkey" PRIMARY KEY ("IndexName", "TradeDate")
) PARTITION BY RANGE ("TradeDate");

DO $$
DECLARE
    partition_year integer;
BEGIN
    FOR partition_year IN 1996..2040 LOOP
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS "Indicies"."IndexData_%s" PARTITION OF "Indicies"."IndexData" FOR VALUES FROM (%L) TO (%L)',
            partition_year,
            make_date(partition_year, 1, 1),
            make_date(partition_year + 1, 1, 1)
        );
    END LOOP;
END $$;

CREATE TABLE IF NOT EXISTS "Indicies"."IndexData_default"
    PARTITION OF "Indicies"."IndexData" DEFAULT;

INSERT INTO "Indicies"."IndexData" (
    "IndexName", "TradeDate", "OpenPrice", "HighPrice", "LowPrice",
    "ClosePrice", "Volume", "TurnoverInrCr", "DataSource", "SourceFile", "CreatedAt"
)
SELECT
    "IndexName", "TradeDate", "OpenPrice", "HighPrice", "LowPrice",
    "ClosePrice", "Volume", "TurnoverInrCr", "DataSource", "SourceFile", "CreatedAt"
FROM "Stocks"."IndexData"
ON CONFLICT ("IndexName", "TradeDate") DO NOTHING;

INSERT INTO "Indicies"."IndexData" (
    "IndexName", "TradeDate", "OpenPrice", "HighPrice", "LowPrice",
    "ClosePrice", "Volume", "TurnoverInrCr", "SourceFile"
)
SELECT
    symbol, "DATE", "OPEN", "HIGH", "LOW", "CLOSE",
    "SHARES TRADED", "TURNOVER (INR CR)", source_file
FROM "Stocks".index_data
WHERE symbol IS NOT NULL AND "DATE" IS NOT NULL
ON CONFLICT ("IndexName", "TradeDate") DO NOTHING;

DROP TABLE IF EXISTS "Stocks"."IndexConfig";
DROP TABLE IF EXISTS "Stocks"."IndexData";
DROP TABLE IF EXISTS "Stocks".index_data;

UPDATE "ETL"."ETL_CONFIG"
SET target_schema = 'Indicies', target_table = 'IndexData'
WHERE job_name = 'nse_index_history_ingest';

GRANT USAGE ON SCHEMA "Indicies" TO app_user;
GRANT SELECT ON TABLE "Indicies"."IndexConfig", "Indicies"."IndexData" TO app_user;
CREATE TABLE IF NOT EXISTS "Stocks"."IndexConfig" (
    "IndexName" varchar(100) PRIMARY KEY,
    "NseIndexType" varchar(100) NOT NULL,
    "StartDate" date NOT NULL,
    "Enabled" boolean NOT NULL DEFAULT true
);

INSERT INTO "Stocks"."IndexConfig" ("IndexName", "NseIndexType", "StartDate")
VALUES
    ('NIFTY 50', 'NIFTY 50', DATE '1996-01-01'),
    ('NIFTY 500', 'NIFTY 500', DATE '1995-01-01'),
    ('NIFTY BANK', 'NIFTY BANK', DATE '2000-01-01')
ON CONFLICT ("IndexName") DO UPDATE SET
    "NseIndexType" = EXCLUDED."NseIndexType",
    "StartDate" = EXCLUDED."StartDate";

CREATE TABLE IF NOT EXISTS "Stocks"."IndexData" (
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
);

INSERT INTO "ETL"."ETL_CONFIG"
    (job_name, source_url, target_schema, target_table, enabled)
VALUES
    ('nse_index_history_ingest', 'https://www.nseindia.com', 'Stocks', 'IndexData', true)
ON CONFLICT (job_name) DO UPDATE SET
    source_url = EXCLUDED.source_url,
    target_schema = EXCLUDED.target_schema,
    target_table = EXCLUDED.target_table;

GRANT SELECT ON TABLE "Stocks"."IndexConfig", "Stocks"."IndexData" TO app_user;
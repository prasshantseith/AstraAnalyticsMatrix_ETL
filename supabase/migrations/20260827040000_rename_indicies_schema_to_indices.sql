DO $$
BEGIN
	IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'Indicies')
	   AND NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'Indices') THEN
		ALTER SCHEMA "Indicies" RENAME TO "Indices";
	ELSE
		CREATE SCHEMA IF NOT EXISTS "Indices";
	END IF;
END $$;

CREATE TABLE IF NOT EXISTS "Indices"."IndexConfig" (
	"IndexName" varchar(100) PRIMARY KEY,
	"NseIndexType" varchar(100) NOT NULL,
	"StartDate" date NOT NULL,
	"Enabled" boolean NOT NULL DEFAULT true
);

INSERT INTO "Indices"."IndexConfig" ("IndexName", "NseIndexType", "StartDate")
VALUES
	('NIFTY 50', 'NIFTY 50', DATE '1996-01-01'),
	('NIFTY 500', 'NIFTY 500', DATE '1995-01-01'),
	('NIFTY BANK', 'NIFTY BANK', DATE '2000-01-01')
ON CONFLICT ("IndexName") DO UPDATE SET
	"NseIndexType" = EXCLUDED."NseIndexType",
	"StartDate" = EXCLUDED."StartDate";

CREATE TABLE IF NOT EXISTS "Indices"."IndexData" (
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
			'CREATE TABLE IF NOT EXISTS "Indices"."IndexData_%s" PARTITION OF "Indices"."IndexData" FOR VALUES FROM (%L) TO (%L)',
			partition_year,
			make_date(partition_year, 1, 1),
			make_date(partition_year + 1, 1, 1)
		);
	END LOOP;
END $$;

CREATE TABLE IF NOT EXISTS "Indices"."IndexData_default"
	PARTITION OF "Indices"."IndexData" DEFAULT;

UPDATE "ETL"."ETL_CONFIG"
SET target_schema = 'Indices'
WHERE job_name = 'nse_index_history_ingest';

GRANT USAGE ON SCHEMA "Indices" TO app_user;
GRANT SELECT ON TABLE "Indices"."IndexConfig", "Indices"."IndexData" TO app_user;
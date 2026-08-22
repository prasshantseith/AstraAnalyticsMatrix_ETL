create table "MF"."MF_NAV"
(
    "MFNavID" integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    "SchemeCode" bigint,
    "SchemeName" character varying(1000),
    "NavDate" date NOT NULL,
    "NAV" numeric(18,4),
    "NAVDateKey" integer,
    "LoadDateTime" timestamp with time zone DEFAULT now(),
    CONSTRAINT "MF_NAV_pkey" PRIMARY KEY ("MFNavID", "NavDate"),
    CONSTRAINT ux_mf_nav_schemecode_navdate UNIQUE ("SchemeCode", "NavDate")
) PARTITION BY RANGE ("NavDate");

-- Partitioned monthly: "MF_NAV_YYYY_MM" for each month, pre-created 35 years
-- back through 20 years ahead by the migration, plus "MF_NAV_default" for
-- anything outside that range. Individual partitions aren't listed here --
-- see the migrations that create them (20260822224430_create_mf_schema.sql,
-- 20260822230203_backfill_mf_nav_partitions.sql) for the provisioning loop,
-- and add a new migration to extend the range before it runs out.

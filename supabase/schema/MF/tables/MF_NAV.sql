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

-- Partitioned yearly: "MF_NAV_YYYY" for each year, 1996 through 2040
-- (re-partitioned from an earlier monthly scheme - too many partitions to
-- browse comfortably), plus "MF_NAV_default" for anything outside that
-- range. Individual partitions aren't listed here -- see
-- 20260830020000_repartition_mf_nav_by_year.sql for the provisioning loop,
-- and add a new migration to extend the range before it runs out.

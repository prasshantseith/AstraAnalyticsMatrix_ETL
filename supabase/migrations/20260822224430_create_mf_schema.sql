create schema if not exists "MF";

-- If a plain (non-partitioned) "MF"."MF_NAV" already exists (prod, created
-- manually before this repo tracked migrations), move it aside so its data
-- can be copied into the new partitioned table below. It is kept around as
-- "MF_NAV_legacy" -- nothing is dropped automatically.
do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV' and c.relkind = 'r'
    ) then
        alter table "MF"."MF_NAV" rename to "MF_NAV_legacy";
    end if;
end $$;

create table if not exists "MF"."MF_NAV"
(
    "MFNavID" integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    "SchemeCode" bigint,
    "SchemeName" character varying(1000) COLLATE pg_catalog."default",
    "NavDate" date NOT NULL,
    "NAV" numeric(18,4),
    "NAVDateKey" integer,
    "LoadDateTime" timestamp with time zone DEFAULT now(),
    CONSTRAINT "MF_NAV_pkey" PRIMARY KEY ("MFNavID", "NavDate"),
    CONSTRAINT ux_mf_nav_schemecode_navdate UNIQUE ("SchemeCode", "NavDate")
) PARTITION BY RANGE ("NavDate");

-- Catches any row whose NavDate falls outside the explicit monthly
-- partitions below (e.g. historical data copied from MF_NAV_legacy, or
-- dates beyond the pre-provisioned 20-year window).
create table if not exists "MF"."MF_NAV_default"
    partition of "MF"."MF_NAV" default;

-- Pre-create one partition per calendar month for the next 20 years so
-- daily ingestion never hits a missing partition. Extend this range with a
-- new migration before it runs out.
do $$
declare
    start_month date := date_trunc('month', now())::date;
    partition_start date;
    partition_end date;
    partition_name text;
    i int;
begin
    for i in 0..239 loop
        partition_start := (start_month + (i || ' months')::interval)::date;
        partition_end := (start_month + ((i + 1) || ' months')::interval)::date;
        partition_name := 'MF_NAV_' || to_char(partition_start, 'YYYY_MM');

        execute format(
            'create table if not exists "MF".%I partition of "MF"."MF_NAV" for values from (%L) to (%L);',
            partition_name, partition_start, partition_end
        );
    end loop;
end $$;

-- Copy any data from the legacy (pre-partitioning) table into the new
-- partitioned table, preserving MFNavID, then realign the identity
-- sequence so future inserts continue after the highest copied ID.
do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy' and c.relkind = 'r'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy"
        where "NavDate" is not null;

        perform setval(
            pg_get_serial_sequence('"MF"."MF_NAV"', 'MFNavID'),
            greatest((select coalesce(max("MFNavID"), 0) from "MF"."MF_NAV"), 1)
        );
    end if;
end $$;

-- Table: MF.MF

CREATE TABLE IF NOT EXISTS "MF"."MF"
(
    "MFID" integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    "SchemeCode" bigint,
    "SchemeName" character varying(1000) COLLATE pg_catalog."default",
    "LoadDateTime" timestamp with time zone DEFAULT now(),
    "isinGrowth" character varying COLLATE pg_catalog."default",
    "isinDivReinvestment" character varying COLLATE pg_catalog."default",
    external_code character varying(20) COLLATE pg_catalog."default",
    short_name character varying(150) COLLATE pg_catalog."default",
    amc_name character varying(150) COLLATE pg_catalog."default",
    category character varying(50) COLLATE pg_catalog."default",
    fund_category character varying(100) COLLATE pg_catalog."default",
    plan character varying(20) COLLATE pg_catalog."default",
    is_direct boolean,
    maturity_type character varying(30) COLLATE pg_catalog."default",
    launch_date date,
    lock_in_period_days integer,
    risk_rating character varying(30) COLLATE pg_catalog."default",
    star_rating smallint,
    star_rating_date date,
    expense_ratio numeric(5,2),
    expense_ratio_date date,
    aum_cr numeric(14,2),
    volatility numeric(8,4),
    fund_manager text COLLATE pg_catalog."default",
    investment_objective text COLLATE pg_catalog."default",
    scheme_doc_url character varying(500) COLLATE pg_catalog."default",
    tags text[] COLLATE pg_catalog."default",
    lump_available boolean,
    lump_min numeric(14,2),
    lump_min_additional numeric(14,2),
    sip_available boolean,
    sip_min numeric(14,2),
    sip_frequencies text[] COLLATE pg_catalog."default",
    redemption_allowed boolean,
    redemption_min_amount numeric(14,4),
    switch_allowed boolean,
    stp_available boolean,
    swp_available boolean,
    instant_redemption boolean,
    instant_redeem_min numeric(14,2),
    instant_redeem_max numeric(14,2),
    tax_long_term_after_days integer,
    detail_modifieddate timestamp with time zone,
    "IsActive" boolean,
    CONSTRAINT "MF_pkey" PRIMARY KEY ("MFID"),
    CONSTRAINT ux_mf_schemecode UNIQUE ("SchemeCode")
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "MF"."MF"
    OWNER to postgres;

REVOKE ALL ON TABLE "MF"."MF" FROM app_user;

GRANT SELECT, UPDATE ON TABLE "MF"."MF" TO app_user;

GRANT ALL ON TABLE "MF"."MF" TO postgres;

-- Index: ux_mf_external_code

CREATE UNIQUE INDEX IF NOT EXISTS ux_mf_external_code
    ON "MF"."MF" USING btree
    (external_code COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default
    WHERE external_code IS NOT NULL;

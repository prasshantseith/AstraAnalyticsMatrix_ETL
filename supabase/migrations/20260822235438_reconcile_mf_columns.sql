-- prod already had a pre-existing "MF"."MF" table (like MF_NAV was) created
-- before this repo tracked migrations. The earlier CREATE TABLE IF NOT
-- EXISTS silently no-op'd against it, so it never actually got the full
-- column set -- confirmed live: the metadata sync failed with
-- 'column "IsActive" of relation "MF" does not exist'. This reconciles
-- whatever subset already exists (dev, prod, or a bare table anywhere
-- else) up to the full expected column set. Every column uses
-- IF NOT EXISTS, so this is a no-op wherever a column is already present.
ALTER TABLE "MF"."MF"
    ADD COLUMN IF NOT EXISTS "SchemeCode" bigint,
    ADD COLUMN IF NOT EXISTS "SchemeName" character varying(1000),
    ADD COLUMN IF NOT EXISTS "LoadDateTime" timestamp with time zone DEFAULT now(),
    ADD COLUMN IF NOT EXISTS "isinGrowth" character varying,
    ADD COLUMN IF NOT EXISTS "isinDivPayout" character varying,
    ADD COLUMN IF NOT EXISTS "isinDivReinvestment" character varying,
    ADD COLUMN IF NOT EXISTS external_code character varying(20),
    ADD COLUMN IF NOT EXISTS short_name character varying(150),
    ADD COLUMN IF NOT EXISTS amc_name character varying(150),
    ADD COLUMN IF NOT EXISTS category character varying(50),
    ADD COLUMN IF NOT EXISTS fund_category character varying(100),
    ADD COLUMN IF NOT EXISTS plan character varying(20),
    ADD COLUMN IF NOT EXISTS is_direct boolean,
    ADD COLUMN IF NOT EXISTS maturity_type character varying(30),
    ADD COLUMN IF NOT EXISTS launch_date date,
    ADD COLUMN IF NOT EXISTS lock_in_period_days integer,
    ADD COLUMN IF NOT EXISTS risk_rating character varying(30),
    ADD COLUMN IF NOT EXISTS star_rating smallint,
    ADD COLUMN IF NOT EXISTS star_rating_date date,
    ADD COLUMN IF NOT EXISTS expense_ratio numeric(5,2),
    ADD COLUMN IF NOT EXISTS expense_ratio_date date,
    ADD COLUMN IF NOT EXISTS aum_cr numeric(14,2),
    ADD COLUMN IF NOT EXISTS volatility numeric(8,4),
    ADD COLUMN IF NOT EXISTS fund_manager text,
    ADD COLUMN IF NOT EXISTS investment_objective text,
    ADD COLUMN IF NOT EXISTS scheme_doc_url character varying(500),
    ADD COLUMN IF NOT EXISTS tags text[],
    ADD COLUMN IF NOT EXISTS lump_available boolean,
    ADD COLUMN IF NOT EXISTS lump_min numeric(14,2),
    ADD COLUMN IF NOT EXISTS lump_min_additional numeric(14,2),
    ADD COLUMN IF NOT EXISTS sip_available boolean,
    ADD COLUMN IF NOT EXISTS sip_min numeric(14,2),
    ADD COLUMN IF NOT EXISTS sip_frequencies text[],
    ADD COLUMN IF NOT EXISTS redemption_allowed boolean,
    ADD COLUMN IF NOT EXISTS redemption_min_amount numeric(14,4),
    ADD COLUMN IF NOT EXISTS switch_allowed boolean,
    ADD COLUMN IF NOT EXISTS stp_available boolean,
    ADD COLUMN IF NOT EXISTS swp_available boolean,
    ADD COLUMN IF NOT EXISTS instant_redemption boolean,
    ADD COLUMN IF NOT EXISTS instant_redeem_min numeric(14,2),
    ADD COLUMN IF NOT EXISTS instant_redeem_max numeric(14,2),
    ADD COLUMN IF NOT EXISTS tax_long_term_after_days integer,
    ADD COLUMN IF NOT EXISTS detail_modifieddate timestamp with time zone,
    ADD COLUMN IF NOT EXISTS "IsActive" boolean,
    ADD COLUMN IF NOT EXISTS latest_nav_date date;

-- Same reconciliation for the SchemeCode unique constraint the metadata
-- sync's ON CONFLICT ("SchemeCode") relies on -- ADD CONSTRAINT has no
-- IF NOT EXISTS form, so check pg_constraint directly.
do $$
declare
    scheme_code_attnum smallint;
begin
    select attnum into scheme_code_attnum
    from pg_attribute
    where attrelid = '"MF"."MF"'::regclass
      and attname = 'SchemeCode';

    if not exists (
        select 1
        from pg_constraint
        where conrelid = '"MF"."MF"'::regclass
          and contype = 'u'
          and conkey = array[scheme_code_attnum]
    ) then
        alter table "MF"."MF" add constraint ux_mf_schemecode unique ("SchemeCode");
    end if;
end $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_mf_external_code
    ON "MF"."MF" USING btree (external_code)
    WHERE external_code IS NOT NULL;

-- Convert "MF"."MF_NAV" from monthly to yearly partitioning on "NavDate".
-- The monthly scheme (~660 partitions, 35 years back through 20 years
-- ahead) made the table list unwieldy. Postgres can't repartition a table
-- in place, so: rename the existing (already partitioned) table aside
-- along with its constraints - so their default names are free for reuse
-- below - create the new yearly-partitioned table under the original
-- name, then copy every row back in, preserving MFNavID via
-- OVERRIDING SYSTEM VALUE and realigning the new table's own identity
-- sequence afterward.
--
-- Prod (unlike dev) still has an even older artifact from before this repo
-- tracked migrations: "MF_NAV_legacy", the original pre-partition table,
-- whose PK index was renamed to "legacy_MF_NAV_pkey" back in
-- 20260822224430_create_mf_schema.sql and never cleaned up. Renaming
-- *this* table's constraints with the same "legacy_" prefix collided with
-- that surviving index name (SQLSTATE 42P07). Use "legacy_monthly_"
-- instead, which can't collide with it.
do $$
declare
    r record;
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV' and c.relkind in ('r', 'p')
    ) then
        alter table "MF"."MF_NAV" rename to "MF_NAV_legacy_monthly";

        for r in
            select conname
            from pg_constraint
            where conrelid = '"MF"."MF_NAV_legacy_monthly"'::regclass
        loop
            if r.conname !~ '^legacy_monthly_' then
                execute format('alter table "MF"."MF_NAV_legacy_monthly" rename constraint %I to %I', r.conname, 'legacy_monthly_' || r.conname);
            end if;
        end loop;
    end if;
end $$;

CREATE TABLE IF NOT EXISTS "MF"."MF_NAV"
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

-- Catches any row whose NavDate falls outside 1996-2040 (e.g. a handful of
-- pre-1996 legacy records, if any exist).
create table if not exists "MF"."MF_NAV_default"
    partition of "MF"."MF_NAV" default;

-- One partition per calendar year, 1996 through 2040. Extend this range
-- with a new migration before it runs out.
do $$
declare
    y int;
    partition_name text;
begin
    for y in 1996..2040 loop
        partition_name := 'MF_NAV_' || y::text;

        execute format(
            'create table if not exists "MF".%I partition of "MF"."MF_NAV" for values from (%L) to (%L);',
            partition_name, make_date(y, 1, 1), make_date(y + 1, 1, 1)
        );
    end loop;
end $$;

-- Copy every row from the legacy (monthly-partitioned) table into the new
-- yearly-partitioned one, one year at a time.
--
-- The first attempt at this migration did the whole copy as a single
-- INSERT ... SELECT and blew a 2-minute statement_timeout (MF_NAV has far
-- more data than expected). A do $$ ... $$ block looping over years
-- internally wouldn't have fixed it either - that's still ONE top-level
-- statement, so every iteration shares the same timeout budget. Each year
-- below is its own separate statement instead, so each gets a fresh
-- timeout window. ON CONFLICT ... DO NOTHING makes a retry after a
-- partial failure safe (a year that already copied won't error on
-- re-insert).
do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" is not null and "NavDate" < '1996-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '1996-01-01' and "NavDate" < '1997-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '1997-01-01' and "NavDate" < '1998-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '1998-01-01' and "NavDate" < '1999-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '1999-01-01' and "NavDate" < '2000-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2000-01-01' and "NavDate" < '2001-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2001-01-01' and "NavDate" < '2002-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2002-01-01' and "NavDate" < '2003-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2003-01-01' and "NavDate" < '2004-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2004-01-01' and "NavDate" < '2005-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2005-01-01' and "NavDate" < '2006-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2006-01-01' and "NavDate" < '2007-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2007-01-01' and "NavDate" < '2008-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2008-01-01' and "NavDate" < '2009-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2009-01-01' and "NavDate" < '2010-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2010-01-01' and "NavDate" < '2011-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2011-01-01' and "NavDate" < '2012-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2012-01-01' and "NavDate" < '2013-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2013-01-01' and "NavDate" < '2014-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2014-01-01' and "NavDate" < '2015-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2015-01-01' and "NavDate" < '2016-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2016-01-01' and "NavDate" < '2017-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2017-01-01' and "NavDate" < '2018-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2018-01-01' and "NavDate" < '2019-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2019-01-01' and "NavDate" < '2020-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2020-01-01' and "NavDate" < '2021-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2021-01-01' and "NavDate" < '2022-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2022-01-01' and "NavDate" < '2023-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2023-01-01' and "NavDate" < '2024-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2024-01-01' and "NavDate" < '2025-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2025-01-01' and "NavDate" < '2026-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2026-01-01' and "NavDate" < '2027-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2027-01-01' and "NavDate" < '2028-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2028-01-01' and "NavDate" < '2029-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2029-01-01' and "NavDate" < '2030-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2030-01-01' and "NavDate" < '2031-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2031-01-01' and "NavDate" < '2032-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2032-01-01' and "NavDate" < '2033-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2033-01-01' and "NavDate" < '2034-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2034-01-01' and "NavDate" < '2035-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2035-01-01' and "NavDate" < '2036-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2036-01-01' and "NavDate" < '2037-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2037-01-01' and "NavDate" < '2038-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2038-01-01' and "NavDate" < '2039-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2039-01-01' and "NavDate" < '2040-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2040-01-01' and "NavDate" < '2041-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        insert into "MF"."MF_NAV" ("MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime")
        overriding system value
        select "MFNavID", "SchemeCode", "SchemeName", "NavDate", "NAV", "NAVDateKey", "LoadDateTime"
        from "MF"."MF_NAV_legacy_monthly"
        where "NavDate" >= '2041-01-01'
        on conflict on constraint "MF_NAV_pkey" do nothing;
    end if;
end $$;

-- Realign the new table's identity sequence now that every chunk has run.
do $$
begin
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'MF' and c.relname = 'MF_NAV_legacy_monthly' and c.relkind = 'p'
    ) then
        perform setval(
            pg_get_serial_sequence('"MF"."MF_NAV"', 'MFNavID'),
            greatest((select coalesce(max("MFNavID"), 0) from "MF"."MF_NAV"), 1)
        );
    end if;
end $$;

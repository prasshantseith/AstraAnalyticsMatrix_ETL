-- Convert "MF"."MF_NAV" from monthly to yearly partitioning on "NavDate".
-- The monthly scheme (~660 partitions, 35 years back through 20 years
-- ahead) made the table list unwieldy. Postgres can't repartition a table
-- in place, so: rename the existing (already partitioned) table aside
-- along with its constraints - so their default names are free for reuse
-- below - create the new yearly-partitioned table under the original
-- name, then copy every row back in, preserving MFNavID via
-- OVERRIDING SYSTEM VALUE and realigning the new table's own identity
-- sequence afterward.
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
            if r.conname !~ '^legacy_' then
                execute format('alter table "MF"."MF_NAV_legacy_monthly" rename constraint %I to %I', r.conname, 'legacy_' || r.conname);
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
-- yearly-partitioned one.
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
        where "NavDate" is not null;

        perform setval(
            pg_get_serial_sequence('"MF"."MF_NAV"', 'MFNavID'),
            greatest((select coalesce(max("MFNavID"), 0) from "MF"."MF_NAV"), 1)
        );
    end if;
end $$;

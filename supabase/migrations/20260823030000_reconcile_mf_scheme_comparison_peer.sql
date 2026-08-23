-- 20260823020000 originally created MFSchemeComparisonPeer with a different
-- shape (sourcemfid, no peer_mfid, surrogate id PK) than the table that
-- already existed on prod (source_mfid, peer_mfid FK, surrogate peerid PK).
-- That migration only ever succeeded against dev, so dev is left with the
-- old wrong shape here. Rebuild it there to match prod's actual structure,
-- then add the unique constraint both environments are missing.

do $$
begin
    if exists (
        select 1 from information_schema.columns
        where table_schema = 'MF' and table_name = 'MFSchemeComparisonPeer' and column_name = 'sourcemfid'
    ) then
        drop table "MF"."MFSchemeComparisonPeer";
    end if;
end $$;

create table if not exists "MF"."MFSchemeComparisonPeer"
(
    peerid bigint generated always as identity not null,
    source_mfid integer not null,
    peer_mfid integer null,
    peer_code character varying(20) not null,
    sort_order smallint not null,
    info_ratio numeric(8, 4) null,
    rowinsertdatetime timestamp with time zone not null default (now() AT TIME ZONE 'utc'::text),
    constraint "MFSchemeComparisonPeer_pkey" primary key (peerid),
    constraint "MFSchemeComparisonPeer_peer_mfid_fkey" foreign key (peer_mfid) references "MF"."MF" ("MFID"),
    constraint "MFSchemeComparisonPeer_source_mfid_fkey" foreign key (source_mfid) references "MF"."MF" ("MFID") on delete cascade
);

create index if not exists ix_mfscp_peer_mfid
    on "MF"."MFSchemeComparisonPeer" using btree (peer_mfid);

create index if not exists ix_mfscp_source_mfid
    on "MF"."MFSchemeComparisonPeer" using btree (source_mfid);

do $$
begin
    if not exists (
        select 1 from pg_constraint where conname = 'ux_mfscp_source_peer'
    ) then
        alter table "MF"."MFSchemeComparisonPeer"
            add constraint ux_mfscp_source_peer unique (source_mfid, peer_code);
    end if;
end $$;

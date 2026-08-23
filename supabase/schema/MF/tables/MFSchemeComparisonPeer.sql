create table "MF"."MFSchemeComparisonPeer"
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
    constraint "MFSchemeComparisonPeer_source_mfid_fkey" foreign key (source_mfid) references "MF"."MF" ("MFID") on delete cascade,
    constraint ux_mfscp_source_peer unique (source_mfid, peer_code)
);

create index ix_mfscp_peer_mfid
    on "MF"."MFSchemeComparisonPeer" using btree (peer_mfid);

create index ix_mfscp_source_mfid
    on "MF"."MFSchemeComparisonPeer" using btree (source_mfid);

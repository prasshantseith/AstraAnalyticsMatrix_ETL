create table "MF"."MFSchemeComparisonPeer"
(
    id bigint generated always as identity primary key,
    sourcemfid integer not null references "MF"."MF" ("MFID"),
    peer_code character varying(50) not null,
    sort_order integer,
    info_ratio numeric(10,4),
    rowinsertdatetime timestamp with time zone not null default now(),
    constraint ux_mf_scheme_comparison_peer unique (sourcemfid, peer_code)
);

create index ix_mf_scheme_comparison_peer_sourcemfid
    on "MF"."MFSchemeComparisonPeer" (sourcemfid);

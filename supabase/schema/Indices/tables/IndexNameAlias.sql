create table "Indices"."IndexNameAlias"
(
    "AliasName" varchar(100) PRIMARY KEY,
    "CanonicalName" varchar(100) NOT NULL,
    "EffectiveUntil" date NOT NULL,
    "Reason" varchar(200) NOT NULL
);

create index "IndexNameAlias_canonical_name_idx" on "Indices"."IndexNameAlias" ("CanonicalName");

-- Seed data (48 rows for the 2015-11-09 CNX->NIFTY rebrand + one
-- capitalization change) is inserted by migration
-- 20260828000000_add_index_name_alias_for_cnx_nifty_rebrand.sql.

-- Scheme Name to 3x its current width (1000 -> 3000). MF_NAV is
-- partitioned by NavDate; altering the parent cascades the type change to
-- every partition automatically.
alter table "MF"."MF" alter column "SchemeName" type character varying(3000);
alter table "MF"."MF_NAV" alter column "SchemeName" type character varying(3000);
alter table "MF"."MF_Performance" alter column "MFName" type character varying(3000);

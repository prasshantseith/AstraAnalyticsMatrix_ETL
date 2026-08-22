create table "MF"."MF_NAV"
(
    "MFNavID" integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    "SchemeCode" bigint,
    "SchemeName" character varying(1000),
    "NavDate" date,
    "NAV" numeric(18,4),
    "NAVDateKey" integer,
    "LoadDateTime" timestamp with time zone DEFAULT now(),
    CONSTRAINT "MF_NAV_pkey" PRIMARY KEY ("MFNavID"),
    CONSTRAINT ux_mf_nav_schemecode_navdate UNIQUE ("SchemeCode", "NavDate")
);

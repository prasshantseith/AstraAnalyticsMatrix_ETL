CREATE TABLE IF NOT EXISTS "MF"."MF_Performance"
(
    "MFCode" bigint NOT NULL,
    "MFName" character varying(1000) COLLATE pg_catalog."default",
    "LatestNAV" numeric(10,4),
    "AsOfDate" date,
    "Day" numeric(10,2),
    "Week" numeric(10,2),
    "Month" numeric(10,2),
    "ThreeMon" numeric(10,2),
    "SixMon" numeric(10,2),
    "Year" numeric(10,2),
    "ThreeYear" numeric(10,2),
    "FiveYear" numeric(10,2),
    "R_Day" integer,
    "R_Week" integer,
    "R_Month" integer,
    "R_3Mon" integer,
    "R_6Mon" integer,
    "R_Year" integer,
    "R_3Year" integer,
    "R_5Year" integer,
    "LoadDateTime" timestamp with time zone DEFAULT now(),
    "NAV_Day" numeric,
    "NAV_Week" numeric,
    "NAV_Month" numeric,
    "NAV_3Mon" numeric,
    "NAV_6Mon" numeric,
    "NAV_Year" numeric,
    "NAV_3Year" numeric,
    "NAV_5Year" numeric,
    "HighestNAV" numeric,
    "HighestNAVDate" date,
    CONSTRAINT "MF_Performance_pkey" PRIMARY KEY ("MFCode")
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "MF"."MF_Performance"
    OWNER to postgres;

-- app_user may not exist yet in every environment (e.g. it wasn't present
-- in dev). Create it as a permissions-only role so the grants below don't
-- fail; it grants no login/connect capability on its own.
do $$
begin
    if not exists (select from pg_roles where rolname = 'app_user') then
        create role app_user nologin;
    end if;
end $$;

REVOKE ALL ON TABLE "MF"."MF_Performance" FROM app_user;

GRANT SELECT ON TABLE "MF"."MF_Performance" TO app_user;

GRANT ALL ON TABLE "MF"."MF_Performance" TO postgres;

-- Index: idx_MF_Performance_RDay

-- DROP INDEX IF EXISTS "MF"."idx_MF_Performance_RDay";

CREATE INDEX IF NOT EXISTS "idx_MF_Performance_RDay"
    ON "MF"."MF_Performance" USING btree
    ("R_Day" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_MF_Performance_RMonth

-- DROP INDEX IF EXISTS "MF"."idx_MF_Performance_RMonth";

CREATE INDEX IF NOT EXISTS "idx_MF_Performance_RMonth"
    ON "MF"."MF_Performance" USING btree
    ("R_Month" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_MF_Performance_RWeek

-- DROP INDEX IF EXISTS "MF"."idx_MF_Performance_RWeek";

CREATE INDEX IF NOT EXISTS "idx_MF_Performance_RWeek"
    ON "MF"."MF_Performance" USING btree
    ("R_Week" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_MF_Performance_RYear

-- DROP INDEX IF EXISTS "MF"."idx_MF_Performance_RYear";

CREATE INDEX IF NOT EXISTS "idx_MF_Performance_RYear"
    ON "MF"."MF_Performance" USING btree
    ("R_Year" ASC NULLS LAST)
    TABLESPACE pg_default;

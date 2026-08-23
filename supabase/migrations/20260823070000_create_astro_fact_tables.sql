CREATE TABLE IF NOT EXISTS "Astro"."FactPanchang"
(
    "FactPanchangId" bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    "City" text COLLATE pg_catalog."default" NOT NULL,
    "Date" date NOT NULL,
    "Time" time without time zone NOT NULL,
    "DayOfWeek" text COLLATE pg_catalog."default" NOT NULL,
    "Sunrise" timestamp with time zone NOT NULL,
    "Sunset" timestamp with time zone NOT NULL,
    "Moonrise" timestamp with time zone,
    "SunSign" smallint NOT NULL,
    "MoonSign" smallint NOT NULL,
    "Tithi" smallint NOT NULL,
    "Tithi_End" timestamp with time zone NOT NULL,
    "Nakshatra" smallint NOT NULL,
    "Nakshatra_Name" text COLLATE pg_catalog."default" NOT NULL,
    "Nakshatra_End" timestamp with time zone NOT NULL,
    "Yoga" smallint NOT NULL,
    "Yoga_Name" text COLLATE pg_catalog."default" NOT NULL,
    "Yoga_End" timestamp with time zone NOT NULL,
    "Karana" text COLLATE pg_catalog."default" NOT NULL,
    "Karana_End" timestamp with time zone NOT NULL,
    "Paksha" text COLLATE pg_catalog."default" NOT NULL,
    "Purnimanta_Month" text COLLATE pg_catalog."default" NOT NULL,
    "Is_Adhik_Maas" boolean NOT NULL DEFAULT false,
    eclipse_type text COLLATE pg_catalog."default",
    subtype text COLLATE pg_catalog."default",
    time_window text COLLATE pg_catalog."default",
    is_visible boolean,
    "Rahu_Kaal" text COLLATE pg_catalog."default",
    "Abhijit_Muhurta" text COLLATE pg_catalog."default",
    "Amrit_Kaal" text COLLATE pg_catalog."default",
    CONSTRAINT "FactPanchang_pkey" PRIMARY KEY ("FactPanchangId"),
    CONSTRAINT "UQ_FactPanchang_City_Date_Time" UNIQUE ("City", "Date", "Time")
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "Astro"."FactPanchang"
    OWNER to postgres;

CREATE TABLE IF NOT EXISTS "Astro"."FactKundli"
(
    "FactKundliId" bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    "Date" date,
    "Time" time without time zone,
    "Planet" text COLLATE pg_catalog."default",
    "Tropical_Longitude" numeric(10,6),
    "Sidereal_Longitude" numeric(10,6),
    "Rashi" text COLLATE pg_catalog."default",
    "Nakshatra" text COLLATE pg_catalog."default",
    "Pada" integer,
    "Motion" text COLLATE pg_catalog."default",
    "Degrees_In_Sign" text COLLATE pg_catalog."default",
    "Location" text COLLATE pg_catalog."default",
    CONSTRAINT "FactKundli_pkey" PRIMARY KEY ("FactKundliId")
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "Astro"."FactKundli"
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

REVOKE ALL ON TABLE "Astro"."FactPanchang" FROM app_user;

GRANT SELECT ON TABLE "Astro"."FactPanchang" TO app_user;

GRANT ALL ON TABLE "Astro"."FactPanchang" TO postgres;

REVOKE ALL ON TABLE "Astro"."FactKundli" FROM app_user;

GRANT SELECT ON TABLE "Astro"."FactKundli" TO app_user;

GRANT ALL ON TABLE "Astro"."FactKundli" TO postgres;

-- Index: IX_FactPanchang_Date

-- DROP INDEX IF EXISTS "Astro"."IX_FactPanchang_Date";

CREATE INDEX IF NOT EXISTS "IX_FactPanchang_Date"
    ON "Astro"."FactPanchang" USING btree
    ("Date" ASC NULLS LAST)
    TABLESPACE pg_default;

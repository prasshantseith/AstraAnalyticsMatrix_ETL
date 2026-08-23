CREATE SEQUENCE IF NOT EXISTS "Astro"."FactAscendant_FactAscendantId_seq";

CREATE TABLE IF NOT EXISTS "Astro"."FactAscendant"
(
    "FactAscendantId" bigint NOT NULL DEFAULT nextval('"Astro"."FactAscendant_FactAscendantId_seq"'::regclass),
    "Date" date NOT NULL,
    "Time" time without time zone NOT NULL,
    "Location" text COLLATE pg_catalog."default" NOT NULL,
    "Rashi" text COLLATE pg_catalog."default" NOT NULL,
    "Sidereal_Longitude" numeric NOT NULL,
    CONSTRAINT "FactAscendant_pkey" PRIMARY KEY ("FactAscendantId"),
    CONSTRAINT "FactAscendant_Date_Time_Location_key" UNIQUE ("Date", "Time", "Location")
)

TABLESPACE pg_default;

ALTER SEQUENCE "Astro"."FactAscendant_FactAscendantId_seq" OWNED BY "Astro"."FactAscendant"."FactAscendantId";

ALTER TABLE IF EXISTS "Astro"."FactAscendant"
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

REVOKE ALL ON TABLE "Astro"."FactAscendant" FROM app_user;

GRANT INSERT, SELECT ON TABLE "Astro"."FactAscendant" TO app_user;

GRANT ALL ON TABLE "Astro"."FactAscendant" TO postgres;

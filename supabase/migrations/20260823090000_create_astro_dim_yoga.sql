CREATE TABLE IF NOT EXISTS "Astro"."DimYoga"
(
    id smallint NOT NULL,
    yoga_name text COLLATE pg_catalog."default" NOT NULL,
    swami text COLLATE pg_catalog."default",
    swabhava text COLLATE pg_catalog."default",
    mobility text COLLATE pg_catalog."default",
    is_auspicious boolean NOT NULL,
    auspicious_text text COLLATE pg_catalog."default",
    highlight_color text COLLATE pg_catalog."default",
    description text COLLATE pg_catalog."default",
    "YogaScore" smallint NOT NULL,
    CONSTRAINT "DimYoga_pkey" PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "Astro"."DimYoga"
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

REVOKE ALL ON TABLE "Astro"."DimYoga" FROM app_user;

GRANT SELECT ON TABLE "Astro"."DimYoga" TO app_user;

GRANT ALL ON TABLE "Astro"."DimYoga" TO postgres;

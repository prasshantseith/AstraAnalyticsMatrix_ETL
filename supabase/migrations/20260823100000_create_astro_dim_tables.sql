CREATE TABLE IF NOT EXISTS "Astro"."DimTithi"
(
    id smallint NOT NULL,
    tithi_name text COLLATE pg_catalog."default" NOT NULL,
    tithi_name_full text COLLATE pg_catalog."default" NOT NULL,
    "number" smallint NOT NULL,
    paksha text COLLATE pg_catalog."default" NOT NULL,
    swami text COLLATE pg_catalog."default",
    nature text COLLATE pg_catalog."default",
    is_masa_shunya boolean NOT NULL DEFAULT false,
    shunya_in_masas text COLLATE pg_catalog."default",
    is_auspicious boolean NOT NULL,
    auspicious_text text COLLATE pg_catalog."default",
    highlight_color text COLLATE pg_catalog."default",
    description text COLLATE pg_catalog."default",
    "TithiScore" smallint NOT NULL,
    keyword character varying COLLATE pg_catalog."default",
    CONSTRAINT "DimTithi_pkey" PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "Astro"."DimTithi"
    OWNER to postgres;

CREATE TABLE IF NOT EXISTS "Astro"."DimNakshtra"
(
    "NakshatraKey" smallint NOT NULL,
    "NakshatraNumber" smallint NOT NULL,
    "NakshatraName" text COLLATE pg_catalog."default" NOT NULL,
    "NakshatraLord" text COLLATE pg_catalog."default",
    "NakshatraDevta" text COLLATE pg_catalog."default",
    "NakshatraElement" text COLLATE pg_catalog."default",
    "NakshatraType" text COLLATE pg_catalog."default",
    "Direction" text COLLATE pg_catalog."default",
    "GoodFor" text COLLATE pg_catalog."default",
    "Description" text COLLATE pg_catalog."default",
    "DescriptionNew" text COLLATE pg_catalog."default",
    swabhava text COLLATE pg_catalog."default",
    akrti text COLLATE pg_catalog."default",
    mukha_position text COLLATE pg_catalog."default",
    eyesight text COLLATE pg_catalog."default",
    star_count smallint,
    has_visha_ghati boolean,
    is_auspicious boolean NOT NULL,
    auspicious_text text COLLATE pg_catalog."default",
    highlight_color text COLLATE pg_catalog."default",
    description1 text COLLATE pg_catalog."default",
    "NakshatraScore" smallint NOT NULL,
    CONSTRAINT "DimNakshtra_pkey" PRIMARY KEY ("NakshatraKey")
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "Astro"."DimNakshtra"
    OWNER to postgres;

CREATE TABLE IF NOT EXISTS "Astro"."DimKarana"
(
    id smallint NOT NULL,
    karan_name text COLLATE pg_catalog."default" NOT NULL,
    swami text COLLATE pg_catalog."default",
    swabhava text COLLATE pg_catalog."default",
    mobility text COLLATE pg_catalog."default",
    is_auspicious boolean NOT NULL,
    auspicious_text text COLLATE pg_catalog."default",
    highlight_color text COLLATE pg_catalog."default",
    description text COLLATE pg_catalog."default",
    "KaranScore" smallint NOT NULL,
    CONSTRAINT "DimKarana_pkey" PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "Astro"."DimKarana"
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

REVOKE ALL ON TABLE "Astro"."DimTithi" FROM app_user;

GRANT SELECT ON TABLE "Astro"."DimTithi" TO app_user;

GRANT ALL ON TABLE "Astro"."DimTithi" TO postgres;

REVOKE ALL ON TABLE "Astro"."DimNakshtra" FROM app_user;

GRANT SELECT ON TABLE "Astro"."DimNakshtra" TO app_user;

GRANT ALL ON TABLE "Astro"."DimNakshtra" TO postgres;

REVOKE ALL ON TABLE "Astro"."DimKarana" FROM app_user;

GRANT SELECT ON TABLE "Astro"."DimKarana" TO app_user;

GRANT ALL ON TABLE "Astro"."DimKarana" TO postgres;

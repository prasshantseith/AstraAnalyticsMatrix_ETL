create table "Astro"."DimTithi"
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
);

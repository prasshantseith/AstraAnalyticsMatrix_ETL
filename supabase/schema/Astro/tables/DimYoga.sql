create table "Astro"."DimYoga"
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
);

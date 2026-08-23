create table "Astro"."DimKarana"
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
);

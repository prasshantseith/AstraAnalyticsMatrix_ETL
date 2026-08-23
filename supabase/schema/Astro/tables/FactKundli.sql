create table "Astro"."FactKundli"
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
);

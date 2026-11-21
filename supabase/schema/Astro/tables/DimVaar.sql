create table "Astro"."DimVaar"
(
    "VaarName" character varying(10) NOT NULL,
    attributes text COLLATE pg_catalog."default",
    remedy text COLLATE pg_catalog."default",
    CONSTRAINT "DimVaar_pkey" PRIMARY KEY ("VaarName")
);

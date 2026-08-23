create table "Astro"."FactAscendant"
(
    "FactAscendantId" bigint NOT NULL DEFAULT nextval('"Astro"."FactAscendant_FactAscendantId_seq"'::regclass),
    "Date" date NOT NULL,
    "Time" time without time zone NOT NULL,
    "Location" text COLLATE pg_catalog."default" NOT NULL,
    "Rashi" text COLLATE pg_catalog."default" NOT NULL,
    "Sidereal_Longitude" numeric NOT NULL,
    CONSTRAINT "FactAscendant_pkey" PRIMARY KEY ("FactAscendantId"),
    CONSTRAINT "FactAscendant_Date_Time_Location_key" UNIQUE ("Date", "Time", "Location")
);

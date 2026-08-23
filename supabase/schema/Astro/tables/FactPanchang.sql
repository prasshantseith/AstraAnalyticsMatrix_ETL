create table "Astro"."FactPanchang"
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
);

CREATE INDEX "IX_FactPanchang_Date"
    ON "Astro"."FactPanchang" USING btree ("Date" ASC NULLS LAST);

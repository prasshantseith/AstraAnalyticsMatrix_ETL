create table "MF"."MF_Performance"
(
    "MFCode" bigint NOT NULL,
    "MFName" character varying(1000) COLLATE pg_catalog."default",
    "LatestNAV" numeric(10,4),
    "AsOfDate" date,
    "Day" numeric(10,2),
    "Week" numeric(10,2),
    "Month" numeric(10,2),
    "ThreeMon" numeric(10,2),
    "SixMon" numeric(10,2),
    "Year" numeric(10,2),
    "ThreeYear" numeric(10,2),
    "FiveYear" numeric(10,2),
    "R_Day" integer,
    "R_Week" integer,
    "R_Month" integer,
    "R_3Mon" integer,
    "R_6Mon" integer,
    "R_Year" integer,
    "R_3Year" integer,
    "R_5Year" integer,
    "LoadDateTime" timestamp with time zone DEFAULT now(),
    "NAV_Day" numeric,
    "NAV_Week" numeric,
    "NAV_Month" numeric,
    "NAV_3Mon" numeric,
    "NAV_6Mon" numeric,
    "NAV_Year" numeric,
    "NAV_3Year" numeric,
    "NAV_5Year" numeric,
    "HighestNAV" numeric,
    "HighestNAVDate" date,
    CONSTRAINT "MF_Performance_pkey" PRIMARY KEY ("MFCode")
);

CREATE INDEX "idx_MF_Performance_RDay"
    ON "MF"."MF_Performance" USING btree ("R_Day" ASC NULLS LAST);

CREATE INDEX "idx_MF_Performance_RMonth"
    ON "MF"."MF_Performance" USING btree ("R_Month" ASC NULLS LAST);

CREATE INDEX "idx_MF_Performance_RWeek"
    ON "MF"."MF_Performance" USING btree ("R_Week" ASC NULLS LAST);

CREATE INDEX "idx_MF_Performance_RYear"
    ON "MF"."MF_Performance" USING btree ("R_Year" ASC NULLS LAST);

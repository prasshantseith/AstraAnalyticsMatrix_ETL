create table "Commodities"."McxBhavCopy"
(
    "TradeDate" date NOT NULL,
    "Commodity" character varying(30) COLLATE pg_catalog."default" NOT NULL,
    "InstrumentType" character varying(10) COLLATE pg_catalog."default" NOT NULL,
    "ExpiryDate" date NOT NULL,
    "OptionType" character varying(5) COLLATE pg_catalog."default" NOT NULL DEFAULT '-',
    "StrikePrice" numeric(18,4) NOT NULL DEFAULT 0,
    "OpenPrice" numeric(18,4),
    "HighPrice" numeric(18,4),
    "LowPrice" numeric(18,4),
    "ClosePrice" numeric(18,4),
    "PreviousClosePrice" numeric(18,4),
    "Volume" bigint,
    "VolumeDisplay" character varying(30) COLLATE pg_catalog."default",
    "ValueInLakhs" numeric(18,4),
    "OpenInterest" bigint,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT "McxBhavCopy_pkey" PRIMARY KEY
        ("Commodity", "TradeDate", "InstrumentType", "ExpiryDate", "OptionType", "StrikePrice")
)
PARTITION BY RANGE ("TradeDate");

CREATE TABLE "Commodities"."McxBhavCopy_default"
    PARTITION OF "Commodities"."McxBhavCopy" DEFAULT;

CREATE INDEX ix_mcxbhavcopy_tradedate
    ON "Commodities"."McxBhavCopy" USING btree ("TradeDate" DESC NULLS LAST);

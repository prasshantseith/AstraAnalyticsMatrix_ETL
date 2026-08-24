create table "Stocks"."StockData"
(
    "Id" bigint NOT NULL DEFAULT nextval('"Stocks"."StockData_Id_seq"'::regclass),
    "StockExchangeCode" character varying(10) COLLATE pg_catalog."default" NOT NULL,
    "TradeDate" date NOT NULL,
    "BusinessDate" date NOT NULL,
    "MarketSegment" character varying(10) COLLATE pg_catalog."default" NOT NULL,
    "DataSource" character varying(10) COLLATE pg_catalog."default" NOT NULL,
    "InstrumentType" character varying(10) COLLATE pg_catalog."default" NOT NULL,
    "InstrumentId" bigint NOT NULL,
    "IsinCode" character varying(12) COLLATE pg_catalog."default" NOT NULL,
    "TickerSymbol" character varying(30) COLLATE pg_catalog."default" NOT NULL,
    "SecuritySeries" character varying(10) COLLATE pg_catalog."default",
    "ExpiryDate" date,
    "ActualExpiryDate" date,
    "StrikePrice" numeric(18,4),
    "OptionType" character varying(5) COLLATE pg_catalog."default",
    "InstrumentName" character varying(255) COLLATE pg_catalog."default" NOT NULL,
    "OpenPrice" numeric(18,4),
    "HighPrice" numeric(18,4),
    "LowPrice" numeric(18,4),
    "ClosePrice" numeric(18,4),
    "LastTradedPrice" numeric(18,4),
    "PreviousClosePrice" numeric(18,4),
    CONSTRAINT "StockData_pkey" PRIMARY KEY ("Id"),
    CONSTRAINT "UQ_StockData_Exchange_TradeDate_Instrument" UNIQUE ("StockExchangeCode", "TradeDate", "InstrumentId")
);

CREATE INDEX "IX_StockData_ExchangeCode"
    ON "Stocks"."StockData" USING btree ("StockExchangeCode" COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX "IX_StockData_Exchange_Ticker_Date"
    ON "Stocks"."StockData" USING btree ("StockExchangeCode" COLLATE pg_catalog."default" ASC NULLS LAST, "TickerSymbol" COLLATE pg_catalog."default" ASC NULLS LAST, "TradeDate" ASC NULLS LAST);

CREATE INDEX "IX_StockData_InstrumentId"
    ON "Stocks"."StockData" USING btree ("InstrumentId" ASC NULLS LAST);

CREATE INDEX "IX_StockData_IsinCode"
    ON "Stocks"."StockData" USING btree ("IsinCode" COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX "IX_StockData_SecuritySeries"
    ON "Stocks"."StockData" USING btree ("SecuritySeries" COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX "IX_StockData_TickerSymbol"
    ON "Stocks"."StockData" USING btree ("TickerSymbol" COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX "IX_StockData_TradeDate"
    ON "Stocks"."StockData" USING btree ("TradeDate" ASC NULLS LAST);

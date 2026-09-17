-- Snapshot table (full truncate-and-reload on each refresh, same convention
-- as Stocks.StockPerformance/MF.MF_Performance), backing the Index/Commodity
-- performance table on the web app's Index & Commodity Analysis page.
--
-- Unlike StockPerformance, "Exchange" is stored directly here rather than
-- resolved via a runtime cache in the API layer — StockPerformance couldn't
-- carry it without an ETL change it didn't have at the time, but this table
-- is being created fresh, so there's no reason to push that resolution cost
-- onto every API request when the refresh procedure already has the
-- DataSource ('NSE'/'BSE') available per row.
create table "Indices"."IndexPerformance"
(
    "IndexName" character varying(100),
    "Exchange" character varying(20),
    "LatestClose" numeric(18,4),
    "AsOfDate" date,
    "Day" numeric,
    "Week" numeric,
    "Month" numeric,
    "ThreeMon" numeric,
    "SixMon" numeric,
    "Year" numeric,
    "ThreeYear" numeric,
    "FiveYear" numeric,
    "Close_Day" numeric(18,4),
    "Close_Week" numeric(18,4),
    "Close_Month" numeric(18,4),
    "Close_3Mon" numeric(18,4),
    "Close_6Mon" numeric(18,4),
    "Close_Year" numeric(18,4),
    "Close_3Year" numeric(18,4),
    "Close_5Year" numeric(18,4),
    "HighestClose" numeric(18,4),
    "HighestCloseDate" date,
    "R_Day" bigint,
    "R_Week" bigint,
    "R_Month" bigint,
    "R_3Mon" bigint,
    "R_6Mon" bigint,
    "R_Year" bigint,
    "R_3Year" bigint,
    "R_5Year" bigint
);

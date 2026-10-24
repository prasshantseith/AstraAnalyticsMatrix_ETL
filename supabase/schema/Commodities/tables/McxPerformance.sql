-- Snapshot table, same convention as CommodityPerformance. "Commodity"
-- matches McxBhavCopy's own column name (MCX's raw upper-case symbol,
-- e.g. "GOLD"), not CommodityName - keeps it visibly distinct from
-- Commodities.CommodityData's own title-case names.
create table "Commodities"."McxPerformance"
(
    "Commodity" character varying(30),
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

-- niftyindices.com renamed 48 indices from "CNX"-style branding to "NIFTY"
-- branding on 2015-11-09 (e.g. "CNX Nifty" -> "Nifty 50"), plus one pure
-- capitalization change on the same date ("NIFTY Midcap 50" -> "Nifty Midcap
-- 50"). IndexData stores whatever name was published that day, so each of
-- these indices' history is split across two IndexName values. This table
-- maps every known pre-rebrand name to its current canonical name; pairings
-- were verified by matching closing values across 2015-11-06/2015-11-09
-- (all within ~2.1%), not name similarity alone, since several names don't
-- correspond the way they look (e.g. "GSEC10 NSE Index" maps to "Nifty 8-13
-- yr G-Sec", not "Nifty 10 yr Benchmark G-Sec").
create table "Indices"."IndexNameAlias"
(
    "AliasName" varchar(100) PRIMARY KEY,
    "CanonicalName" varchar(100) NOT NULL,
    "EffectiveUntil" date NOT NULL,
    "Reason" varchar(200) NOT NULL
);

create index "IndexNameAlias_canonical_name_idx" on "Indices"."IndexNameAlias" ("CanonicalName");

insert into "Indices"."IndexNameAlias" ("AliasName", "CanonicalName", "EffectiveUntil", "Reason") values
    ('CNX 100', 'Nifty 100', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX 100 Equal Weight', 'Nifty100 Equal Weight', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX 200', 'Nifty 200', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX 500', 'Nifty 500', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX 500 Shariah', 'Nifty500 Shariah', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Alpha Index', 'Nifty Alpha 50', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Auto', 'Nifty Auto', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Bank', 'Nifty Bank', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Commodities', 'Nifty Commodities', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Consumption', 'Nifty India Consumption', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX DEFTY', 'Nifty50 USD', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Dividend Opportunities', 'Nifty Dividend Opportunities 50', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Energy', 'Nifty Energy', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX FMCG', 'Nifty FMCG', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Finance', 'Nifty Financial Services', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX High Beta', 'Nifty High Beta 50', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX IT', 'Nifty IT', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Infrastructure', 'Nifty Infrastructure', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Low Volatility', 'Nifty Low Volatility 50', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX MNC', 'Nifty MNC', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Media', 'Nifty Media', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Metal', 'Nifty Metal', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Midcap', 'Nifty Midcap 100', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Nifty', 'Nifty 50', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Nifty Dividend', 'Nifty50 Dividend Points', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Nifty Junior', 'Nifty Next 50', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Nifty Shariah', 'Nifty50 Shariah', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX PSE', 'Nifty PSE', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX PSU Bank', 'Nifty PSU Bank', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Pharma', 'Nifty Pharma', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Realty', 'Nifty Realty', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Service Sector', 'Nifty Services Sector', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Shariah25', 'Nifty Shariah 25', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CNX Smallcap', 'Nifty Smallcap 100', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('CPSE', 'Nifty CPSE', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('GSEC10 NSE Index', 'Nifty 8-13 yr G-Sec', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('GSECBM NSE Index', 'Nifty 10 yr Benchmark G-Sec', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('LIX 15', 'Nifty100 Liquid 15', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('LIX15 Midcap', 'Nifty Midcap Liquid 15', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('NI15', 'Nifty Growth Sectors 15', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('NIFTY Midcap 50', 'Nifty Midcap 50', '2015-11-06', '2015-11-09 capitalization change'),
    ('NIFTY PR 1X Inverse', 'Nifty50 PR 1x Inverse', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('NIFTY PR 2x Leverage', 'Nifty50 PR 2x Leverage', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('NIFTY TR 1X Inverse', 'Nifty50 TR 1x Inverse', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('NIFTY TR 2X Leverage', 'Nifty50 TR 2x Leverage', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('NSE GSECBM Clean Price Index', 'Nifty 10 yr Benchmark G-Sec (Clean Price)', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('NSE Quality 30', 'Nifty Quality 30', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand'),
    ('NV 20', 'Nifty50 Value 20', '2015-11-06', '2015-11-09 CNX->NIFTY rebrand');

-- Presents IndexData under each index's current canonical name so history
-- before and after the 2015-11-09 rebrand reads as one continuous series,
-- without rewriting the as-published raw names in IndexData itself.
create or replace view "Indices"."IndexDataCanonical" as
select
    coalesce(alias."CanonicalName", d."IndexName") as "IndexName",
    d."TradeDate",
    d."OpenPrice",
    d."HighPrice",
    d."LowPrice",
    d."ClosePrice",
    d."Volume",
    d."TurnoverInrCr",
    d."DataSource",
    d."SourceFile",
    d."CreatedAt"
from "Indices"."IndexData" d
left join "Indices"."IndexNameAlias" alias
    on lower(alias."AliasName") = lower(d."IndexName");

-- Platinum/Palladium history starts before CommodityData's earliest
-- pre-created partition (2000) - add the missing years so their rows land
-- in a real yearly partition instead of the default catch-all.
do $$
declare
    y int;
    partition_name text;
begin
    for y in 1997..1999 loop
        partition_name := 'CommodityData_' || y::text;
        execute format(
            'create table if not exists "Commodities".%I partition of "Commodities"."CommodityData" for values from (%L) to (%L);',
            partition_name, make_date(y, 1, 1), make_date(y + 1, 1, 1)
        );
    end loop;
end $$;

-- Some Yahoo Finance futures (the grain/soft commodities below) are quoted
-- in USX (US cents) rather than USD. PriceDivisor normalizes those back to
-- whole dollars at ingest time (100 for cents-quoted symbols, 1 for
-- already-USD ones), so CommodityData stays consistently USD throughout
-- rather than silently mixing units.
ALTER TABLE "Commodities"."CommodityConfig"
    ADD COLUMN IF NOT EXISTS "PriceDivisor" numeric(10,4) NOT NULL DEFAULT 1;

INSERT INTO "Commodities"."CommodityConfig" ("CommodityName", "YahooSymbol", "StartDate", "PriceDivisor")
VALUES
    ('Crude Oil WTI', 'CL=F', DATE '2000-08-23', 1),
    ('Brent Crude', 'BZ=F', DATE '2007-07-30', 1),
    ('Natural Gas', 'NG=F', DATE '2000-08-30', 1),
    ('Platinum', 'PL=F', DATE '1997-10-29', 1),
    ('Palladium', 'PA=F', DATE '1998-09-28', 1),
    ('Corn', 'ZC=F', DATE '2000-07-17', 100),
    ('Wheat', 'ZW=F', DATE '2000-07-17', 100),
    ('Soybeans', 'ZS=F', DATE '2000-09-15', 100),
    ('Coffee', 'KC=F', DATE '2000-01-03', 100),
    ('Sugar', 'SB=F', DATE '2000-03-01', 100),
    ('Cotton', 'CT=F', DATE '2000-01-03', 100),
    ('Cocoa', 'CC=F', DATE '2000-01-03', 1)
ON CONFLICT ("CommodityName") DO UPDATE SET
    "YahooSymbol" = EXCLUDED."YahooSymbol",
    "StartDate" = EXCLUDED."StartDate",
    "PriceDivisor" = EXCLUDED."PriceDivisor";

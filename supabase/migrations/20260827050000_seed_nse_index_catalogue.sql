ALTER TABLE "Indices"."IndexConfig"
    ADD COLUMN IF NOT EXISTS "Category" varchar(50);

UPDATE "Indices"."IndexConfig"
SET "Category" = 'Broad Based'
WHERE "Category" IS NULL;

ALTER TABLE "Indices"."IndexConfig"
    ALTER COLUMN "Category" SET NOT NULL;

-- Keep the complete catalogue available for testing, but run only the three
-- indices whose historical API responses have already been selected.
UPDATE "Indices"."IndexConfig"
SET "Enabled" = false;

INSERT INTO "Indices"."IndexConfig"
    ("IndexName", "Category", "NseIndexType", "StartDate", "Enabled")
VALUES
    ('NIFTY 50', 'Broad Based', 'NIFTY 50', DATE '1996-01-01', true),
    ('NIFTY NEXT 50', 'Broad Based', 'NIFTY NEXT 50', DATE '1996-01-01', false),
    ('NIFTY 100', 'Broad Based', 'NIFTY 100', DATE '1996-01-01', false),
    ('NIFTY NEXT 100', 'Broad Based', 'NIFTY NEXT 100', DATE '1996-01-01', false),
    ('NIFTY 200', 'Broad Based', 'NIFTY 200', DATE '1996-01-01', false),
    ('NIFTY TOTAL MARKET', 'Broad Based', 'NIFTY TOTAL MARKET', DATE '1996-01-01', false),
    ('NIFTY 500', 'Broad Based', 'NIFTY 500', DATE '1995-01-01', true),
    ('NIFTY500 MULTICAP 50:25:25', 'Broad Based', 'NIFTY500 MULTICAP 50:25:25', DATE '1996-01-01', false),
    ('NIFTY500 LARGEMIDSMALL EQUAL-CAP WEIGHTED', 'Broad Based', 'NIFTY500 LARGEMIDSMALL EQUAL-CAP WEIGHTED', DATE '1996-01-01', false),
    ('NIFTY MIDCAP 150', 'Broad Based', 'NIFTY MIDCAP 150', DATE '1996-01-01', false),
    ('NIFTY MIDCAP 50', 'Broad Based', 'NIFTY MIDCAP 50', DATE '1996-01-01', false),
    ('NIFTY MIDCAP SELECT', 'Broad Based', 'NIFTY MIDCAP SELECT', DATE '1996-01-01', false),
    ('NIFTY MIDCAP 100', 'Broad Based', 'NIFTY MIDCAP 100', DATE '1996-01-01', false),
    ('NIFTY SMALLCAP 500', 'Broad Based', 'NIFTY SMALLCAP 500', DATE '1996-01-01', false),
    ('NIFTY SMALLCAP 250', 'Broad Based', 'NIFTY SMALLCAP 250', DATE '1996-01-01', false),
    ('NIFTY SMALL CAP 50', 'Broad Based', 'NIFTY SMALL CAP 50', DATE '1996-01-01', false),
    ('NIFTY SMALLCAP 100', 'Broad Based', 'NIFTY SMALLCAP 100', DATE '1996-01-01', false),
    ('NIFTY MICROCAP 250', 'Broad Based', 'NIFTY MICROCAP 250', DATE '1996-01-01', false),
    ('NIFTY LARGEMIDCAP 250', 'Broad Based', 'NIFTY LARGEMIDCAP 250', DATE '1996-01-01', false),
    ('NIFTY MIDSMALLCAP 400', 'Broad Based', 'NIFTY MIDSMALLCAP 400', DATE '1996-01-01', false),
    ('NIFTY MIDSMALLCAP400 50:50', 'Broad Based', 'NIFTY MIDSMALLCAP400 50:50', DATE '1996-01-01', false),
    ('NIFTY INDIA FPI 150', 'Broad Based', 'NIFTY INDIA FPI 150', DATE '1996-01-01', false),
    ('NIFTY BANK', 'Sectoral', 'NIFTY BANK', DATE '2000-01-01', true),
    ('NIFTY AUTO', 'Sectoral', 'NIFTY AUTO', DATE '2005-01-01', false),
    ('NIFTY FINANCIAL SERVICES', 'Sectoral', 'NIFTY FINANCIAL SERVICES', DATE '2005-01-01', false),
    ('NIFTY FMCG', 'Sectoral', 'NIFTY FMCG', DATE '1996-01-01', false),
    ('NIFTY HEALTHCARE INDEX', 'Sectoral', 'NIFTY HEALTHCARE INDEX', DATE '2005-01-01', false),
    ('NIFTY IT', 'Sectoral', 'NIFTY IT', DATE '1996-01-01', false),
    ('NIFTY MEDIA', 'Sectoral', 'NIFTY MEDIA', DATE '2005-01-01', false),
    ('NIFTY METAL', 'Sectoral', 'NIFTY METAL', DATE '1996-01-01', false),
    ('NIFTY PHARMA', 'Sectoral', 'NIFTY PHARMA', DATE '2005-01-01', false),
    ('NIFTY PRIVATE BANK', 'Sectoral', 'NIFTY PRIVATE BANK', DATE '2005-01-01', false),
    ('NIFTY PSU BANK', 'Sectoral', 'NIFTY PSU BANK', DATE '2005-01-01', false),
    ('NIFTY REALTY', 'Sectoral', 'NIFTY REALTY', DATE '2005-01-01', false),
    ('NIFTY CONSUMER DURABLES', 'Sectoral', 'NIFTY CONSUMER DURABLES', DATE '2005-01-01', false),
    ('NIFTY OIL & GAS', 'Sectoral', 'NIFTY OIL & GAS', DATE '2005-01-01', false),
    ('NIFTY INDIA DEFENCE', 'Thematic', 'NIFTY INDIA DEFENCE', DATE '2020-01-01', false),
    ('NIFTY INDIA DIGITAL', 'Thematic', 'NIFTY INDIA DIGITAL', DATE '2020-01-01', false),
    ('NIFTY INDIA EV', 'Thematic', 'NIFTY INDIA EV', DATE '2020-01-01', false),
    ('NIFTY INDIA MANUFACTURING', 'Thematic', 'NIFTY INDIA MANUFACTURING', DATE '2005-01-01', false),
    ('NIFTY INDIA TOURISM', 'Thematic', 'NIFTY INDIA TOURISM', DATE '2020-01-01', false),
    ('NIFTY INDIA INFRASTRUCTURE', 'Thematic', 'NIFTY INDIA INFRASTRUCTURE', DATE '2005-01-01', false),
    ('NIFTY INDIA CONSUMPTION', 'Thematic', 'NIFTY INDIA CONSUMPTION', DATE '2005-01-01', false),
    ('NIFTY INDIA MNC', 'Thematic', 'NIFTY INDIA MNC', DATE '1996-01-01', false),
    ('NIFTY ALPHA 50', 'Strategy', 'NIFTY ALPHA 50', DATE '2005-01-01', false),
    ('NIFTY QUALITY 30', 'Strategy', 'NIFTY QUALITY 30', DATE '2005-01-01', false),
    ('NIFTY LOW VOLATILITY 30', 'Strategy', 'NIFTY LOW VOLATILITY 30', DATE '2005-01-01', false),
    ('NIFTY 100 EQUAL WEIGHT', 'Strategy', 'NIFTY 100 EQUAL WEIGHT', DATE '2005-01-01', false),
    ('NIFTY 50 EQUAL WEIGHT', 'Strategy', 'NIFTY 50 EQUAL WEIGHT', DATE '2005-01-01', false),
    ('NIFTY DIVIDEND OPPORTUNITIES 50', 'Strategy', 'NIFTY DIVIDEND OPPORTUNITIES 50', DATE '2005-01-01', false)
ON CONFLICT ("IndexName") DO UPDATE SET
    "Category" = EXCLUDED."Category",
    "NseIndexType" = EXCLUDED."NseIndexType",
    "StartDate" = EXCLUDED."StartDate",
    "Enabled" = EXCLUDED."Enabled";

UPDATE "ETL"."ETL_CONFIG"
SET target_schema = 'Indices', target_table = 'IndexData'
WHERE job_name = 'nse_index_history_ingest';
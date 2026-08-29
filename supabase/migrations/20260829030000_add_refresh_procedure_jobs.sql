-- ETL_CONFIG rows for the three post-ingest refresh procedures now called
-- by daily_incremental_orchestrator.py via call_procedure.py. source_url
-- isn't meaningful for a stored procedure call, so it's repurposed to
-- record the fully-qualified procedure name; target_schema/target_table
-- record the schema/procedure name for the same reason.
INSERT INTO "ETL"."ETL_CONFIG"
    (job_name, source_url, target_schema, target_table, enabled)
VALUES
    ('refresh_dim_date_flags', 'internal:Report.usp_RefreshDimDateFlags', 'Report', 'usp_RefreshDimDateFlags', true),
    ('refresh_mf_performance', 'internal:MF.usp_RefreshMFPerformance', 'MF', 'usp_RefreshMFPerformance', true),
    ('refresh_stock_performance', 'internal:Stocks.usp_RefreshStockPerformance', 'Stocks', 'usp_RefreshStockPerformance', true)
ON CONFLICT (job_name) DO UPDATE SET
    source_url = EXCLUDED.source_url,
    target_schema = EXCLUDED.target_schema,
    target_table = EXCLUDED.target_table;

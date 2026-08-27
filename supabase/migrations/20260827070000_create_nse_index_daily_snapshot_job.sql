INSERT INTO "ETL"."ETL_CONFIG"
    (job_name, source_url, target_schema, target_table, enabled)
VALUES
    ('nse_index_daily_snapshot_ingest', 'https://niftyindices.com/Daily_Snapshot', 'Indices', 'IndexData', true)
ON CONFLICT (job_name) DO UPDATE SET
    source_url = EXCLUDED.source_url,
    target_schema = EXCLUDED.target_schema,
    target_table = EXCLUDED.target_table;
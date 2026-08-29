-- BSE indices land in the same Indices.IndexData table as NSE (partitioned
-- by TradeDate, already has yearly partitions from 2016 - see
-- 20260827030000_move_index_data_to_indicies.sql), distinguished by
-- "DataSource" = 'BSE' vs 'NSE'/'NSE_DAILY_SNAPSHOT'. No new table needed.
INSERT INTO "ETL"."ETL_CONFIG"
    (job_name, source_url, target_schema, target_table, enabled)
VALUES
    ('bse_index_ingest', 'https://api.bseindia.com/BseIndiaAPI/api', 'Indices', 'IndexData', true),
    ('bse_index_backfill', 'https://api.bseindia.com/BseIndiaAPI/api', 'Indices', 'IndexData', true)
ON CONFLICT (job_name) DO UPDATE SET
    source_url = EXCLUDED.source_url,
    target_schema = EXCLUDED.target_schema,
    target_table = EXCLUDED.target_table;

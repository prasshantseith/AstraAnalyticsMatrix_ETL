insert into "ETL"."ETL_CONFIG"
    (job_name, source_url, target_schema, target_table, enabled)
values
    ('nse_index_daily_snapshot_backfill', 'https://niftyindices.com/Daily_Snapshot', 'Indices', 'IndexData', true)
on conflict (job_name) do update set
    source_url = excluded.source_url,
    target_schema = excluded.target_schema,
    target_table = excluded.target_table;

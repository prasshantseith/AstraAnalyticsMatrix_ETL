insert into "ETL"."ETL_CONFIG"
    (job_name, source_url, target_schema, target_table, enabled)
values
    ('nse_bhavcopy_ingest', 'https://nsearchives.nseindia.com', 'Stocks', 'StockData', true)
on conflict (job_name) do nothing;

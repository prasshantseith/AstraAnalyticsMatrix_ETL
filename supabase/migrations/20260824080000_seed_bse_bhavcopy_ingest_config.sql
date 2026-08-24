insert into "ETL"."ETL_CONFIG"
    (job_name, source_url, target_schema, target_table, enabled)
values
    ('bse_bhavcopy_ingest', 'https://www.bseindia.com', 'Stocks', 'StockData', true)
on conflict (job_name) do nothing;

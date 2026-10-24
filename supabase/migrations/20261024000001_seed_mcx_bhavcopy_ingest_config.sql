insert into "ETL"."ETL_CONFIG"
    (job_name, source_url, target_schema, target_table, enabled)
values
    ('mcx_bhavcopy_ingest', 'https://www.mcxindia.com', 'Commodities', 'McxBhavCopy', true)
on conflict (job_name) do nothing;

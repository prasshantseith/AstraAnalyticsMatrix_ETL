insert into "ETL"."ETL_CONFIG"
    (job_name, source_url, target_schema, target_table, enabled)
values
    ('mf_latest_nav_date_sync', 'https://api.mfapi.in/mf/latest', 'MF', 'MF', true)
on conflict (job_name) do update set
    source_url = excluded.source_url,
    target_schema = excluded.target_schema,
    target_table = excluded.target_table;
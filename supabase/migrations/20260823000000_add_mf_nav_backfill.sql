insert into "ETL"."ETL_CONFIG"
    (job_name, source_url, target_schema, target_table, enabled)
values
    ('mf_nav_backfill', 'https://api.mfapi.in/mf', 'MF', 'MF_NAV', true)
on conflict (job_name) do nothing;

ALTER TABLE "MF"."MF"
    ADD COLUMN IF NOT EXISTS "isinDivPayout" character varying,
    ADD COLUMN IF NOT EXISTS latest_nav_date date;

insert into "ETL"."ETL_CONFIG"
    (job_name, source_url, target_schema, target_table, enabled)
values
    ('mf_metadata_sync', 'https://portal.amfiindia.com/spages/NAVAll.txt', 'MF', 'MF', true)
on conflict (job_name) do nothing;

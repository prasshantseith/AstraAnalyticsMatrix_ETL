create table "ETL"."ETL_CONFIG" (
    job_name text primary key,
    source_url text not null,
    target_schema text not null,
    target_table text not null,
    enabled boolean not null default true,
    schedule_cron text,
    last_run_at timestamptz,
    last_run_status text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

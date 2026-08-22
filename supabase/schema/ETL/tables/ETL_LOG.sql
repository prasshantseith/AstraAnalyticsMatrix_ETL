create table "ETL"."ETL_LOG" (
    log_id bigint generated always as identity primary key,
    job_name text not null references "ETL"."ETL_CONFIG" (job_name),
    start_time timestamptz not null,
    end_time timestamptz,
    status text not null,
    rows_updated integer,
    watermark_value text,
    error_message text,
    created_at timestamptz not null default now()
);

create index "ETL_LOG_job_name_idx" on "ETL"."ETL_LOG" (job_name);

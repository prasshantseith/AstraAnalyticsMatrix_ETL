-- Backfills environments that already applied 20260822224430 before it
-- covered the past 35 years (dev applied it with a 20-years-forward-only
-- range). Safe to run anywhere: every partition is created with
-- IF NOT EXISTS, so this is a no-op wherever the range already exists
-- (e.g. an environment that applies 20260822224430 for the first time
-- after this file was added).
do $$
declare
    start_month date := date_trunc('month', now())::date;
    partition_start date;
    partition_end date;
    partition_name text;
    i int;
begin
    for i in -420..239 loop
        partition_start := (start_month + (i || ' months')::interval)::date;
        partition_end := (start_month + ((i + 1) || ' months')::interval)::date;
        partition_name := 'MF_NAV_' || to_char(partition_start, 'YYYY_MM');

        execute format(
            'create table if not exists "MF".%I partition of "MF"."MF_NAV" for values from (%L) to (%L);',
            partition_name, partition_start, partition_end
        );
    end loop;
end $$;

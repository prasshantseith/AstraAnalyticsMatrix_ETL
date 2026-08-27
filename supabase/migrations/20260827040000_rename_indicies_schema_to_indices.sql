ALTER SCHEMA "Indicies" RENAME TO "Indices";

UPDATE "ETL"."ETL_CONFIG"
SET target_schema = 'Indices'
WHERE job_name = 'nse_index_history_ingest';

GRANT USAGE ON SCHEMA "Indices" TO app_user;
GRANT SELECT ON TABLE "Indices"."IndexConfig", "Indices"."IndexData" TO app_user;
-- ETL_LOG/ETL_CONFIG were created with no grants to app_user at all (not
-- even schema USAGE) - fine while only the ETL scripts' own (higher-
-- privilege) DB role touched them, but the AstraAnalyticsMatrixAPI app now
-- needs read access too, for the Admin page's "rows loaded per table"
-- section (GET /admin/etl-runs). SELECT only - the app never writes to
-- either table, ETL scripts remain the only writer.
GRANT USAGE ON SCHEMA "ETL" TO app_user;

GRANT SELECT ON TABLE "ETL"."ETL_LOG" TO app_user;
GRANT SELECT ON TABLE "ETL"."ETL_CONFIG" TO app_user;

CREATE TABLE IF NOT EXISTS "Stocks".index_data
(
    "DATE" date,
    "OPEN" numeric(12,2),
    "HIGH" numeric(12,2),
    "LOW" numeric(12,2),
    "CLOSE" numeric(12,2),
    "SHARES TRADED" bigint,
    "TURNOVER (INR CR)" numeric(16,2),
    source_file character varying(255) COLLATE pg_catalog."default",
    symbol character varying(100) COLLATE pg_catalog."default",
    file_suffix character varying(255) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "Stocks".index_data
    OWNER to postgres;

-- app_user may not exist yet in every environment (e.g. it wasn't present
-- in dev). Create it as a permissions-only role so the grants below don't
-- fail; it grants no login/connect capability on its own.
do $$
begin
    if not exists (select from pg_roles where rolname = 'app_user') then
        create role app_user nologin;
    end if;
end $$;

REVOKE ALL ON TABLE "Stocks".index_data FROM app_user;

GRANT SELECT ON TABLE "Stocks".index_data TO app_user;

GRANT ALL ON TABLE "Stocks".index_data TO postgres;

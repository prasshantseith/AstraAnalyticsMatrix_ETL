-- Automatic per-account/per-IP abuse detection (AstraanAlyticsMatrixAPI's
-- app.abuse_detection, wired into app.dependencies.get_current_user and
-- app.main's block_abusive_ips middleware). A user or IP that crosses
-- settings.api_rate_lock_threshold requests within
-- settings.api_rate_lock_window_seconds gets locked/blocked instantly;
-- an admin reviews and releases from the Admin page's new API Activity tab.

ALTER TABLE "Users".users
    ADD COLUMN IF NOT EXISTS is_locked BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE "Users".users
    ADD COLUMN IF NOT EXISTS locked_at TIMESTAMPTZ;

ALTER TABLE "Users".users
    ADD COLUMN IF NOT EXISTS locked_reason VARCHAR;

-- One row per authenticated API call — backs both the in-memory rate window
-- (app.abuse_detection keeps the actual sliding-window count itself; this
-- table is the admin-reviewable history of *which* calls) and the Admin
-- page's API Activity tab. user_id has no FK/NOT NULL so a row survives the
-- user being deleted later; email is denormalized for the same reason.
CREATE SEQUENCE IF NOT EXISTS "Users"."apiRequestLog_id_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

CREATE TABLE IF NOT EXISTS "Users"."apiRequestLog"
(
    id integer NOT NULL DEFAULT nextval('"Users"."apiRequestLog_id_seq"'::regclass),
    user_id integer,
    email character varying COLLATE pg_catalog."default" NOT NULL,
    ip_address character varying COLLATE pg_catalog."default",
    method character varying(10) COLLATE pg_catalog."default" NOT NULL,
    path character varying COLLATE pg_catalog."default" NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT "apiRequestLog_pkey" PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER SEQUENCE "Users"."apiRequestLog_id_seq"
    OWNED BY "Users"."apiRequestLog".id;

ALTER SEQUENCE "Users"."apiRequestLog_id_seq"
    OWNER TO postgres;

ALTER TABLE IF EXISTS "Users"."apiRequestLog"
    OWNER to postgres;

CREATE INDEX IF NOT EXISTS ix_apirequestlog_user_id
    ON "Users"."apiRequestLog" USING btree (user_id ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS ix_apirequestlog_email
    ON "Users"."apiRequestLog" USING btree (email COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS ix_apirequestlog_ip_address
    ON "Users"."apiRequestLog" USING btree (ip_address COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS ix_apirequestlog_created_at
    ON "Users"."apiRequestLog" USING btree (created_at DESC NULLS LAST)
    TABLESPACE pg_default;

-- Populated when an IP crosses the same per-minute threshold used for
-- account locking — blocks that IP outright (app.main's block_abusive_ips
-- middleware) regardless of which account(s) it's used from, since an
-- account lock alone doesn't stop the same machine from signing up again.
CREATE SEQUENCE IF NOT EXISTS "Users"."blockedIPs_id_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

CREATE TABLE IF NOT EXISTS "Users"."blockedIPs"
(
    id integer NOT NULL DEFAULT nextval('"Users"."blockedIPs_id_seq"'::regclass),
    ip_address character varying COLLATE pg_catalog."default" NOT NULL,
    reason character varying COLLATE pg_catalog."default",
    blocked_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT "blockedIPs_pkey" PRIMARY KEY (id),
    CONSTRAINT "blockedIPs_ip_address_key" UNIQUE (ip_address)
)

TABLESPACE pg_default;

ALTER SEQUENCE "Users"."blockedIPs_id_seq"
    OWNED BY "Users"."blockedIPs".id;

ALTER SEQUENCE "Users"."blockedIPs_id_seq"
    OWNER TO postgres;

ALTER TABLE IF EXISTS "Users"."blockedIPs"
    OWNER to postgres;

-- app_user may not exist yet in every environment. Create it as a
-- permissions-only role so the grants below don't fail; it grants no
-- login/connect capability on its own.
do $$
begin
    if not exists (select from pg_roles where rolname = 'app_user') then
        create role app_user nologin;
    end if;
end $$;

REVOKE ALL ON TABLE "Users"."apiRequestLog" FROM app_user;
-- No UPDATE/DELETE — a request-log row is write-once, admin-reviewable only.
GRANT INSERT, SELECT ON TABLE "Users"."apiRequestLog" TO app_user;
GRANT ALL ON TABLE "Users"."apiRequestLog" TO postgres;
GRANT USAGE, SELECT ON SEQUENCE "Users"."apiRequestLog_id_seq" TO app_user;

REVOKE ALL ON TABLE "Users"."blockedIPs" FROM app_user;
-- No UPDATE — a block is either created (app.abuse_detection / admin block)
-- or removed outright (admin unblock), never edited in place.
GRANT INSERT, DELETE, SELECT ON TABLE "Users"."blockedIPs" TO app_user;
GRANT ALL ON TABLE "Users"."blockedIPs" TO postgres;
GRANT USAGE, SELECT ON SEQUENCE "Users"."blockedIPs_id_seq" TO app_user;

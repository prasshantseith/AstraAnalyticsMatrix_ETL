CREATE SEQUENCE IF NOT EXISTS "Users".feedback_id_seq;

CREATE TABLE IF NOT EXISTS "Users".feedback
(
    id integer NOT NULL DEFAULT nextval('"Users".feedback_id_seq'::regclass),
    name character varying COLLATE pg_catalog."default" NOT NULL,
    email character varying COLLATE pg_catalog."default" NOT NULL,
    mobile character varying COLLATE pg_catalog."default",
    message character varying COLLATE pg_catalog."default" NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    feedback_type character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'Feedback'::character varying,
    has_attachment boolean NOT NULL DEFAULT false,
    CONSTRAINT feedback_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER SEQUENCE "Users".feedback_id_seq OWNED BY "Users".feedback.id;

ALTER TABLE IF EXISTS "Users".feedback
    OWNER to postgres;

CREATE SEQUENCE IF NOT EXISTS "Users".otp_codes_id_seq;

CREATE TABLE IF NOT EXISTS "Users".otp_codes
(
    id integer NOT NULL DEFAULT nextval('"Users".otp_codes_id_seq'::regclass),
    email character varying COLLATE pg_catalog."default" NOT NULL,
    code_hash character varying COLLATE pg_catalog."default" NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    attempts integer NOT NULL,
    is_used boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT otp_codes_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER SEQUENCE "Users".otp_codes_id_seq OWNED BY "Users".otp_codes.id;

ALTER TABLE IF EXISTS "Users".otp_codes
    OWNER to postgres;

CREATE SEQUENCE IF NOT EXISTS "Users"."userActivity_id_seq";

CREATE TABLE IF NOT EXISTS "Users"."userActivity"
(
    id integer NOT NULL DEFAULT nextval('"Users"."userActivity_id_seq"'::regclass),
    email character varying COLLATE pg_catalog."default" NOT NULL,
    ip_address character varying COLLATE pg_catalog."default",
    local_time character varying COLLATE pg_catalog."default",
    utc_time timestamp with time zone NOT NULL DEFAULT now(),
    city character varying COLLATE pg_catalog."default",
    country character varying COLLATE pg_catalog."default",
    timezone character varying COLLATE pg_catalog."default",
    region character varying COLLATE pg_catalog."default",
    region_code character varying COLLATE pg_catalog."default",
    country_code character varying COLLATE pg_catalog."default",
    CONSTRAINT "userActivity_pkey" PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER SEQUENCE "Users"."userActivity_id_seq" OWNED BY "Users"."userActivity".id;

ALTER TABLE IF EXISTS "Users"."userActivity"
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

REVOKE ALL ON TABLE "Users".feedback FROM app_user;

GRANT INSERT, SELECT ON TABLE "Users".feedback TO app_user;

GRANT ALL ON TABLE "Users".feedback TO postgres;

REVOKE ALL ON TABLE "Users".otp_codes FROM app_user;

GRANT INSERT, SELECT, UPDATE ON TABLE "Users".otp_codes TO app_user;

GRANT ALL ON TABLE "Users".otp_codes TO postgres;

REVOKE ALL ON TABLE "Users"."userActivity" FROM app_user;

GRANT INSERT, SELECT ON TABLE "Users"."userActivity" TO app_user;

GRANT ALL ON TABLE "Users"."userActivity" TO postgres;

-- Index: ix_feedback_email

-- DROP INDEX IF EXISTS "Users".ix_feedback_email;

CREATE INDEX IF NOT EXISTS ix_feedback_email
    ON "Users".feedback USING btree
    (email COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: ix_Users_otp_codes_email

-- DROP INDEX IF EXISTS "Users"."ix_Users_otp_codes_email";

CREATE INDEX IF NOT EXISTS "ix_Users_otp_codes_email"
    ON "Users".otp_codes USING btree
    (email COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: ix_useractivity_email

-- DROP INDEX IF EXISTS "Users".ix_useractivity_email;

CREATE INDEX IF NOT EXISTS ix_useractivity_email
    ON "Users"."userActivity" USING btree
    (email COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

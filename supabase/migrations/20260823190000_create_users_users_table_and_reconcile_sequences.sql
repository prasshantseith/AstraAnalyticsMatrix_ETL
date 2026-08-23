CREATE SEQUENCE IF NOT EXISTS "Users".users_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

CREATE TABLE IF NOT EXISTS "Users".users
(
    id integer NOT NULL DEFAULT nextval('"Users".users_id_seq'::regclass),
    email character varying COLLATE pg_catalog."default" NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    name character varying COLLATE pg_catalog."default",
    is_admin boolean NOT NULL DEFAULT false,
    first_name character varying COLLATE pg_catalog."default",
    last_name character varying COLLATE pg_catalog."default",
    date_of_birth date,
    nakshatra character varying COLLATE pg_catalog."default",
    rashi character varying COLLATE pg_catalog."default",
    billing_address_line1 character varying COLLATE pg_catalog."default",
    billing_address_line2 character varying COLLATE pg_catalog."default",
    billing_city character varying COLLATE pg_catalog."default",
    billing_state character varying COLLATE pg_catalog."default",
    billing_postal_code character varying COLLATE pg_catalog."default",
    billing_country character varying COLLATE pg_catalog."default",
    language character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'English'::character varying,
    CONSTRAINT users_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "Users".users
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

REVOKE ALL ON TABLE "Users".users FROM app_user;

GRANT INSERT, SELECT, UPDATE ON TABLE "Users".users TO app_user;

GRANT ALL ON TABLE "Users".users TO postgres;

-- Index: ix_Users_users_email

-- DROP INDEX IF EXISTS "Users"."ix_Users_users_email";

CREATE UNIQUE INDEX IF NOT EXISTS "ix_Users_users_email"
    ON "Users".users USING btree
    (email COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: ix_users_is_admin

-- DROP INDEX IF EXISTS "Users".ix_users_is_admin;

CREATE INDEX IF NOT EXISTS ix_users_is_admin
    ON "Users".users USING btree
    (id ASC NULLS LAST, is_admin ASC NULLS LAST)
    TABLESPACE pg_default;

-- Reconcile pre-existing sequences (backing identity/serial columns created
-- above and in earlier migrations) with their full spec and app_user grants.

CREATE SEQUENCE IF NOT EXISTS "Users"."UserSubscriptions_subscriptionid_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE "Users"."UserSubscriptions_subscriptionid_seq"
    OWNER TO postgres;

GRANT USAGE, SELECT ON SEQUENCE "Users"."UserSubscriptions_subscriptionid_seq" TO app_user;

GRANT ALL ON SEQUENCE "Users"."UserSubscriptions_subscriptionid_seq" TO postgres;

CREATE SEQUENCE IF NOT EXISTS "Users".feedback_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

ALTER SEQUENCE "Users".feedback_id_seq
    OWNED BY "Users".feedback.id;

ALTER SEQUENCE "Users".feedback_id_seq
    OWNER TO postgres;

GRANT USAGE, SELECT ON SEQUENCE "Users".feedback_id_seq TO app_user;

GRANT ALL ON SEQUENCE "Users".feedback_id_seq TO postgres;

CREATE SEQUENCE IF NOT EXISTS "Users".otp_codes_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

ALTER SEQUENCE "Users".otp_codes_id_seq
    OWNED BY "Users".otp_codes.id;

ALTER SEQUENCE "Users".otp_codes_id_seq
    OWNER TO postgres;

GRANT USAGE, SELECT ON SEQUENCE "Users".otp_codes_id_seq TO app_user;

GRANT ALL ON SEQUENCE "Users".otp_codes_id_seq TO postgres;

ALTER SEQUENCE "Users".users_id_seq
    OWNED BY "Users".users.id;

ALTER SEQUENCE "Users".users_id_seq
    OWNER TO postgres;

GRANT USAGE, SELECT ON SEQUENCE "Users".users_id_seq TO app_user;

GRANT ALL ON SEQUENCE "Users".users_id_seq TO postgres;

CREATE SEQUENCE IF NOT EXISTS "Users"."userActivity_id_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

ALTER SEQUENCE "Users"."userActivity_id_seq"
    OWNED BY "Users"."userActivity".id;

ALTER SEQUENCE "Users"."userActivity_id_seq"
    OWNER TO postgres;

GRANT USAGE, SELECT ON SEQUENCE "Users"."userActivity_id_seq" TO app_user;

GRANT ALL ON SEQUENCE "Users"."userActivity_id_seq" TO postgres;

-- Users.products doesn't exist in this repo yet, so this sequence is
-- created standalone (no OWNED BY) until that table is added.
CREATE SEQUENCE IF NOT EXISTS "Users".products_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

ALTER SEQUENCE "Users".products_id_seq
    OWNER TO postgres;

GRANT USAGE, SELECT ON SEQUENCE "Users".products_id_seq TO app_user;

GRANT ALL ON SEQUENCE "Users".products_id_seq TO postgres;

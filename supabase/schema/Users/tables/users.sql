create table "Users".users
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
);

CREATE UNIQUE INDEX "ix_Users_users_email"
    ON "Users".users USING btree (email COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX ix_users_is_admin
    ON "Users".users USING btree (id ASC NULLS LAST, is_admin ASC NULLS LAST);

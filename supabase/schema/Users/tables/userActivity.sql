create table "Users"."userActivity"
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
);

CREATE INDEX ix_useractivity_email
    ON "Users"."userActivity" USING btree (email COLLATE pg_catalog."default" ASC NULLS LAST);

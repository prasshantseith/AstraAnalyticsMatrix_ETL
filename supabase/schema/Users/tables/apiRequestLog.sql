create table "Users"."apiRequestLog"
(
    id integer NOT NULL DEFAULT nextval('"Users"."apiRequestLog_id_seq"'::regclass),
    user_id integer,
    email character varying COLLATE pg_catalog."default" NOT NULL,
    ip_address character varying COLLATE pg_catalog."default",
    method character varying(10) COLLATE pg_catalog."default" NOT NULL,
    path character varying COLLATE pg_catalog."default" NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT "apiRequestLog_pkey" PRIMARY KEY (id)
);

CREATE INDEX ix_apirequestlog_user_id
    ON "Users"."apiRequestLog" USING btree (user_id ASC NULLS LAST);

CREATE INDEX ix_apirequestlog_email
    ON "Users"."apiRequestLog" USING btree (email COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX ix_apirequestlog_ip_address
    ON "Users"."apiRequestLog" USING btree (ip_address COLLATE pg_catalog."default" ASC NULLS LAST);

CREATE INDEX ix_apirequestlog_created_at
    ON "Users"."apiRequestLog" USING btree (created_at DESC NULLS LAST);

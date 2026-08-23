create table "Users".otp_codes
(
    id integer NOT NULL DEFAULT nextval('"Users".otp_codes_id_seq'::regclass),
    email character varying COLLATE pg_catalog."default" NOT NULL,
    code_hash character varying COLLATE pg_catalog."default" NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    attempts integer NOT NULL,
    is_used boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT otp_codes_pkey PRIMARY KEY (id)
);

CREATE INDEX "ix_Users_otp_codes_email"
    ON "Users".otp_codes USING btree (email COLLATE pg_catalog."default" ASC NULLS LAST);

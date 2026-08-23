create table "Users".feedback
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
);

CREATE INDEX ix_feedback_email
    ON "Users".feedback USING btree (email COLLATE pg_catalog."default" ASC NULLS LAST);

create table "Users"."UserNotes"
(
    id integer NOT NULL DEFAULT nextval('"Users"."UserNotes_id_seq"'::regclass),
    user_id integer NOT NULL,
    page_key character varying COLLATE pg_catalog."default" NOT NULL,
    subject character varying(200) COLLATE pg_catalog."default" NOT NULL,
    body text COLLATE pg_catalog."default" NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT "UserNotes_pkey" PRIMARY KEY (id),
    CONSTRAINT user_notes_user_id_fkey FOREIGN KEY (user_id)
        REFERENCES "Users".users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE INDEX ix_user_notes_user_page
    ON "Users"."UserNotes" USING btree (user_id ASC NULLS LAST, page_key ASC NULLS LAST, created_at DESC NULLS LAST);

-- Per-user, per-page scratchpad notes (subject + body), so a user can save
-- their own analysis/findings on the Transit Search, Index & Commodities,
-- Stock Analysis and Mutual Fund Analysis pages and see them again next time
-- they log in. Deliberately no update column/endpoint — notes are
-- create-and-delete only, never edited in place, same as "Users"."UsersPanchang".

CREATE SEQUENCE IF NOT EXISTS "Users"."UserNotes_id_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

CREATE TABLE IF NOT EXISTS "Users"."UserNotes"
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
)

TABLESPACE pg_default;

ALTER SEQUENCE "Users"."UserNotes_id_seq"
    OWNED BY "Users"."UserNotes".id;

ALTER SEQUENCE "Users"."UserNotes_id_seq"
    OWNER TO postgres;

ALTER TABLE IF EXISTS "Users"."UserNotes"
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

REVOKE ALL ON TABLE "Users"."UserNotes" FROM app_user;

-- No UPDATE grant — notes are create-and-delete only, never edited.
GRANT INSERT, DELETE, SELECT ON TABLE "Users"."UserNotes" TO app_user;

GRANT ALL ON TABLE "Users"."UserNotes" TO postgres;

GRANT USAGE, SELECT ON SEQUENCE "Users"."UserNotes_id_seq" TO app_user;

-- Index: ix_user_notes_user_page

-- DROP INDEX IF EXISTS "Users".ix_user_notes_user_page;

CREATE INDEX IF NOT EXISTS ix_user_notes_user_page
    ON "Users"."UserNotes" USING btree
    (user_id ASC NULLS LAST, page_key ASC NULLS LAST, created_at DESC NULLS LAST)
    TABLESPACE pg_default;

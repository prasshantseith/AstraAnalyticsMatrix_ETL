create schema if not exists "Astro";

CREATE SEQUENCE IF NOT EXISTS "Astro"."UsersPanchang_id_seq";

CREATE TABLE IF NOT EXISTS "Astro"."UsersPanchang"
(
    id integer NOT NULL DEFAULT nextval('"Astro"."UsersPanchang_id_seq"'::regclass),
    user_id integer NOT NULL,
    label character varying COLLATE pg_catalog."default" NOT NULL,
    nakshatra character varying COLLATE pg_catalog."default",
    rashi character varying COLLATE pg_catalog."default",
    date_of_birth date,
    time_of_birth time without time zone,
    birth_place character varying COLLATE pg_catalog."default",
    created_at timestamp with time zone DEFAULT now(),
    birth_latitude double precision,
    birth_longitude double precision,
    default_city character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'Delhi'::character varying,
    default_time character varying COLLATE pg_catalog."default" NOT NULL DEFAULT '09:00'::character varying,
    CONSTRAINT panchang_people_pkey PRIMARY KEY (id),
    CONSTRAINT panchang_people_user_id_fkey FOREIGN KEY (user_id)
        REFERENCES "Users".users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER SEQUENCE "Astro"."UsersPanchang_id_seq" OWNED BY "Astro"."UsersPanchang".id;

ALTER TABLE IF EXISTS "Astro"."UsersPanchang"
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

REVOKE ALL ON TABLE "Astro"."UsersPanchang" FROM app_user;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE "Astro"."UsersPanchang" TO app_user;

GRANT ALL ON TABLE "Astro"."UsersPanchang" TO postgres;
-- Index: ix_panchang_people_user_id

-- DROP INDEX IF EXISTS "Astro".ix_panchang_people_user_id;

CREATE INDEX IF NOT EXISTS ix_panchang_people_user_id
    ON "Astro"."UsersPanchang" USING btree
    (user_id ASC NULLS LAST)
    TABLESPACE pg_default;

create table "Users"."UsersPanchang"
(
    id integer NOT NULL DEFAULT nextval('"Users"."UsersPanchang_id_seq"'::regclass),
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
    agreed_to_lock_terms boolean NOT NULL DEFAULT true,
    is_active boolean NOT NULL DEFAULT true,
    reset_by_admin boolean NOT NULL DEFAULT false,
    CONSTRAINT panchang_people_pkey PRIMARY KEY (id),
    CONSTRAINT panchang_people_user_id_fkey FOREIGN KEY (user_id)
        REFERENCES "Users".users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE INDEX ix_panchang_people_user_id
    ON "Users"."UsersPanchang" USING btree (user_id ASC NULLS LAST);

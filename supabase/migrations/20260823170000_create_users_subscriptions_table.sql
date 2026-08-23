CREATE TABLE IF NOT EXISTS "Users"."UserSubscriptions"
(
    subscriptionid bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    userid bigint NOT NULL,
    tier character varying(10) COLLATE pg_catalog."default" NOT NULL DEFAULT 'free'::character varying,
    extra_panchang_tokens integer NOT NULL DEFAULT 0,
    rowinsertdatetime timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc'::text),
    modifieddate timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc'::text),
    CONSTRAINT "UserSubscriptions_pkey" PRIMARY KEY (subscriptionid),
    CONSTRAINT "UserSubscriptions_userid_key" UNIQUE (userid),
    CONSTRAINT "UserSubscriptions_userid_fkey" FOREIGN KEY (userid)
        REFERENCES "Users".users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT ck_usersub_extra_tokens CHECK (extra_panchang_tokens >= 0),
    CONSTRAINT ck_usersub_tier CHECK (tier::text = ANY (ARRAY['free'::character varying, 'plus'::character varying, 'pro'::character varying]::text[]))
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "Users"."UserSubscriptions"
    OWNER to postgres;

ALTER TABLE IF EXISTS "Users"."UserSubscriptions"
    ENABLE ROW LEVEL SECURITY;

ALTER TABLE IF EXISTS "Users"."UserSubscriptions"
    FORCE ROW LEVEL SECURITY;

-- app_user may not exist yet in every environment (e.g. it wasn't present
-- in dev). Create it as a permissions-only role so the grants below don't
-- fail; it grants no login/connect capability on its own.
do $$
begin
    if not exists (select from pg_roles where rolname = 'app_user') then
        create role app_user nologin;
    end if;
end $$;

REVOKE ALL ON TABLE "Users"."UserSubscriptions" FROM app_user;

GRANT INSERT, SELECT, UPDATE ON TABLE "Users"."UserSubscriptions" TO app_user;

GRANT ALL ON TABLE "Users"."UserSubscriptions" TO postgres;

-- Index: ix_usersub_userid

-- DROP INDEX IF EXISTS "Users".ix_usersub_userid;

CREATE INDEX IF NOT EXISTS ix_usersub_userid
    ON "Users"."UserSubscriptions" USING btree
    (userid ASC NULLS LAST)
    TABLESPACE pg_default;

-- POLICY: usersub_insert_own

DROP POLICY IF EXISTS usersub_insert_own ON "Users"."UserSubscriptions";

CREATE POLICY usersub_insert_own
    ON "Users"."UserSubscriptions"
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ((userid = (current_setting('app.current_user_id'::text, true))::bigint));

-- POLICY: usersub_select_own_or_admin

DROP POLICY IF EXISTS usersub_select_own_or_admin ON "Users"."UserSubscriptions";

CREATE POLICY usersub_select_own_or_admin
    ON "Users"."UserSubscriptions"
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING (((userid = (current_setting('app.current_user_id'::text, true))::bigint) OR (EXISTS ( SELECT 1
   FROM "Users".users u
  WHERE ((u.id = (current_setting('app.current_user_id'::text, true))::bigint) AND (u.is_admin = true))))));

-- POLICY: usersub_update_own

DROP POLICY IF EXISTS usersub_update_own ON "Users"."UserSubscriptions";

CREATE POLICY usersub_update_own
    ON "Users"."UserSubscriptions"
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((userid = (current_setting('app.current_user_id'::text, true))::bigint))
    WITH CHECK ((userid = (current_setting('app.current_user_id'::text, true))::bigint));

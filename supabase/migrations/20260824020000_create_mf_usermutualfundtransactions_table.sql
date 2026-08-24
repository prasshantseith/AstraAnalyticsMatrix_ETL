CREATE TABLE IF NOT EXISTS "MF"."UserMutualFundTransactions"
(
    transactionid bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    userid bigint NOT NULL,
    "MFID" bigint NOT NULL,
    folionumber character varying(30) COLLATE pg_catalog."default",
    transactiontype character varying(20) COLLATE pg_catalog."default" NOT NULL,
    transactiondirection character varying(6) COLLATE pg_catalog."default" NOT NULL,
    transactiondate date NOT NULL,
    units numeric(18,4) NOT NULL,
    nav numeric(18,4),
    amount numeric(18,2) NOT NULL,
    brokeragecharge numeric(18,2) DEFAULT 0,
    sttcharge numeric(18,2) DEFAULT 0,
    othercharges numeric(18,2) DEFAULT 0,
    netamount numeric(18,2),
    status character varying(20) COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVE'::character varying,
    rowinsertdatetime timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc'::text),
    modifieddate timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc'::text),
    CONSTRAINT "UserMutualFundTransactions_pkey" PRIMARY KEY (transactionid),
    CONSTRAINT fk_umft_scheme FOREIGN KEY ("MFID")
        REFERENCES "MF"."MF" ("MFID") MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_umft_user FOREIGN KEY (userid)
        REFERENCES "Users".users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT ck_umft_direction CHECK (transactiondirection::text = ANY (ARRAY['CREDIT'::character varying, 'DEBIT'::character varying]::text[]))
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "MF"."UserMutualFundTransactions"
    OWNER to postgres;

ALTER TABLE IF EXISTS "MF"."UserMutualFundTransactions"
    ENABLE ROW LEVEL SECURITY;

ALTER TABLE IF EXISTS "MF"."UserMutualFundTransactions"
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

REVOKE ALL ON TABLE "MF"."UserMutualFundTransactions" FROM app_user;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE "MF"."UserMutualFundTransactions" TO app_user;

GRANT ALL ON TABLE "MF"."UserMutualFundTransactions" TO postgres;

-- Index: ix_umft_modifieddate

-- DROP INDEX IF EXISTS "MF".ix_umft_modifieddate;

CREATE INDEX IF NOT EXISTS ix_umft_modifieddate
    ON "MF"."UserMutualFundTransactions" USING btree
    (modifieddate ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: ix_umft_scheme

-- DROP INDEX IF EXISTS "MF".ix_umft_scheme;

CREATE INDEX IF NOT EXISTS ix_umft_scheme
    ON "MF"."UserMutualFundTransactions" USING btree
    ("MFID" ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: ix_umft_transactiondate

-- DROP INDEX IF EXISTS "MF".ix_umft_transactiondate;

CREATE INDEX IF NOT EXISTS ix_umft_transactiondate
    ON "MF"."UserMutualFundTransactions" USING btree
    (transactiondate ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: ix_umft_user

-- DROP INDEX IF EXISTS "MF".ix_umft_user;

CREATE INDEX IF NOT EXISTS ix_umft_user
    ON "MF"."UserMutualFundTransactions" USING btree
    (userid ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: ix_umft_user_scheme_date

-- DROP INDEX IF EXISTS "MF".ix_umft_user_scheme_date;

CREATE INDEX IF NOT EXISTS ix_umft_user_scheme_date
    ON "MF"."UserMutualFundTransactions" USING btree
    (userid ASC NULLS LAST, "MFID" ASC NULLS LAST, transactiondate ASC NULLS LAST)
    TABLESPACE pg_default;

-- POLICY: umft_delete_own

DROP POLICY IF EXISTS umft_delete_own ON "MF"."UserMutualFundTransactions";

CREATE POLICY umft_delete_own
    ON "MF"."UserMutualFundTransactions"
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING ((userid = (current_setting('app.current_user_id'::text, true))::bigint));

-- POLICY: umft_insert_own

DROP POLICY IF EXISTS umft_insert_own ON "MF"."UserMutualFundTransactions";

CREATE POLICY umft_insert_own
    ON "MF"."UserMutualFundTransactions"
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ((userid = (current_setting('app.current_user_id'::text, true))::bigint));

-- POLICY: umft_select_own_or_admin

DROP POLICY IF EXISTS umft_select_own_or_admin ON "MF"."UserMutualFundTransactions";

CREATE POLICY umft_select_own_or_admin
    ON "MF"."UserMutualFundTransactions"
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING (((userid = (current_setting('app.current_user_id'::text, true))::bigint) OR (EXISTS ( SELECT 1
   FROM "Users".users u
  WHERE ((u.id = (current_setting('app.current_user_id'::text, true))::bigint) AND (u.is_admin = true))))));

-- POLICY: umft_update_own

DROP POLICY IF EXISTS umft_update_own ON "MF"."UserMutualFundTransactions";

CREATE POLICY umft_update_own
    ON "MF"."UserMutualFundTransactions"
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((userid = (current_setting('app.current_user_id'::text, true))::bigint))
    WITH CHECK ((userid = (current_setting('app.current_user_id'::text, true))::bigint));

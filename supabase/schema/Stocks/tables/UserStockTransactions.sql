create table "Stocks"."UserStockTransactions"
(
    transactionid bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    userid bigint NOT NULL,
    tickersymbol character varying(30) COLLATE pg_catalog."default" NOT NULL,
    stockexchangecode character varying(10) COLLATE pg_catalog."default" NOT NULL,
    instrumentname character varying(255) COLLATE pg_catalog."default" NOT NULL,
    transactiontype character varying(20) COLLATE pg_catalog."default" NOT NULL,
    transactiondirection character varying(6) COLLATE pg_catalog."default" NOT NULL,
    transactiondate date NOT NULL,
    units numeric(18,4) NOT NULL,
    price numeric(18,4) NOT NULL,
    amount numeric(18,2) NOT NULL,
    brokeragecharge numeric(18,2) DEFAULT 0,
    sttcharge numeric(18,2) DEFAULT 0,
    othercharges numeric(18,2) DEFAULT 0,
    netamount numeric(18,2),
    status character varying(20) COLLATE pg_catalog."default" NOT NULL DEFAULT 'ACTIVE'::character varying,
    rowinsertdatetime timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc'::text),
    modifieddate timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc'::text),
    CONSTRAINT "UserStockTransactions_pkey" PRIMARY KEY (transactionid),
    CONSTRAINT fk_ustt_user FOREIGN KEY (userid)
        REFERENCES "Users".users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT ck_ustt_direction CHECK (transactiondirection::text = ANY (ARRAY['CREDIT'::character varying, 'DEBIT'::character varying]::text[]))
);

ALTER TABLE "Stocks"."UserStockTransactions"
    ENABLE ROW LEVEL SECURITY;

ALTER TABLE "Stocks"."UserStockTransactions"
    FORCE ROW LEVEL SECURITY;

CREATE INDEX ix_ustt_modifieddate
    ON "Stocks"."UserStockTransactions" USING btree (modifieddate ASC NULLS LAST);

CREATE INDEX ix_ustt_ticker_exchange
    ON "Stocks"."UserStockTransactions" USING btree (stockexchangecode ASC NULLS LAST, tickersymbol ASC NULLS LAST);

CREATE INDEX ix_ustt_transactiondate
    ON "Stocks"."UserStockTransactions" USING btree (transactiondate ASC NULLS LAST);

CREATE INDEX ix_ustt_user
    ON "Stocks"."UserStockTransactions" USING btree (userid ASC NULLS LAST);

CREATE INDEX ix_ustt_user_ticker_exchange_date
    ON "Stocks"."UserStockTransactions" USING btree (userid ASC NULLS LAST, tickersymbol ASC NULLS LAST, stockexchangecode ASC NULLS LAST, transactiondate ASC NULLS LAST);

CREATE POLICY ustt_delete_own
    ON "Stocks"."UserStockTransactions"
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING ((userid = (current_setting('app.current_user_id'::text, true))::bigint));

CREATE POLICY ustt_insert_own
    ON "Stocks"."UserStockTransactions"
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ((userid = (current_setting('app.current_user_id'::text, true))::bigint));

CREATE POLICY ustt_select_own_or_admin
    ON "Stocks"."UserStockTransactions"
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING (((userid = (current_setting('app.current_user_id'::text, true))::bigint) OR (EXISTS ( SELECT 1
   FROM "Users".users u
  WHERE ((u.id = (current_setting('app.current_user_id'::text, true))::bigint) AND (u.is_admin = true))))));

CREATE POLICY ustt_update_own
    ON "Stocks"."UserStockTransactions"
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((userid = (current_setting('app.current_user_id'::text, true))::bigint))
    WITH CHECK ((userid = (current_setting('app.current_user_id'::text, true))::bigint));

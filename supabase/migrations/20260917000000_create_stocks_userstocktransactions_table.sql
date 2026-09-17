-- User-entered equity buy/sell transactions, backing the Stocks Portfolio
-- page (gain/loss over time, mirroring MF.UserMutualFundTransactions /
-- MFPortfolio.tsx). Unlike MF, there's no stable dimension table to FK a
-- transaction's identity against here — Stocks.StockData is a huge
-- partitioned fact table, not a dimension table (same reason StockData
-- itself carries no FK to a "stock" master row). A position's identity is
-- instead the (TickerSymbol, StockExchangeCode) pair already used
-- everywhere else in app/stocks.py (get_ohlc, search_stocks, ...), stored
-- directly on the row, plus a denormalized instrumentname captured at entry
-- time for display — StockData/StockPerformance already denormalize
-- InstrumentName the same way rather than normalizing it out.
--
-- Also unlike MF (which resolves NAV server-side from MF_NAV on write),
-- price here is user-entered directly, so there's no `nav`-style column;
-- `price` is trusted from the client, matching amount/units.
CREATE TABLE IF NOT EXISTS "Stocks"."UserStockTransactions"
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
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "Stocks"."UserStockTransactions"
    OWNER to postgres;

ALTER TABLE IF EXISTS "Stocks"."UserStockTransactions"
    ENABLE ROW LEVEL SECURITY;

ALTER TABLE IF EXISTS "Stocks"."UserStockTransactions"
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

REVOKE ALL ON TABLE "Stocks"."UserStockTransactions" FROM app_user;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE "Stocks"."UserStockTransactions" TO app_user;

GRANT ALL ON TABLE "Stocks"."UserStockTransactions" TO postgres;

-- Index: ix_ustt_modifieddate

CREATE INDEX IF NOT EXISTS ix_ustt_modifieddate
    ON "Stocks"."UserStockTransactions" USING btree
    (modifieddate ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: ix_ustt_ticker_exchange

CREATE INDEX IF NOT EXISTS ix_ustt_ticker_exchange
    ON "Stocks"."UserStockTransactions" USING btree
    (stockexchangecode ASC NULLS LAST, tickersymbol ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: ix_ustt_transactiondate

CREATE INDEX IF NOT EXISTS ix_ustt_transactiondate
    ON "Stocks"."UserStockTransactions" USING btree
    (transactiondate ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: ix_ustt_user

CREATE INDEX IF NOT EXISTS ix_ustt_user
    ON "Stocks"."UserStockTransactions" USING btree
    (userid ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: ix_ustt_user_ticker_exchange_date

CREATE INDEX IF NOT EXISTS ix_ustt_user_ticker_exchange_date
    ON "Stocks"."UserStockTransactions" USING btree
    (userid ASC NULLS LAST, tickersymbol ASC NULLS LAST, stockexchangecode ASC NULLS LAST, transactiondate ASC NULLS LAST)
    TABLESPACE pg_default;

-- POLICY: ustt_delete_own

DROP POLICY IF EXISTS ustt_delete_own ON "Stocks"."UserStockTransactions";

CREATE POLICY ustt_delete_own
    ON "Stocks"."UserStockTransactions"
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING ((userid = (current_setting('app.current_user_id'::text, true))::bigint));

-- POLICY: ustt_insert_own

DROP POLICY IF EXISTS ustt_insert_own ON "Stocks"."UserStockTransactions";

CREATE POLICY ustt_insert_own
    ON "Stocks"."UserStockTransactions"
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ((userid = (current_setting('app.current_user_id'::text, true))::bigint));

-- POLICY: ustt_select_own_or_admin

DROP POLICY IF EXISTS ustt_select_own_or_admin ON "Stocks"."UserStockTransactions";

CREATE POLICY ustt_select_own_or_admin
    ON "Stocks"."UserStockTransactions"
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING (((userid = (current_setting('app.current_user_id'::text, true))::bigint) OR (EXISTS ( SELECT 1
   FROM "Users".users u
  WHERE ((u.id = (current_setting('app.current_user_id'::text, true))::bigint) AND (u.is_admin = true))))));

-- POLICY: ustt_update_own

DROP POLICY IF EXISTS ustt_update_own ON "Stocks"."UserStockTransactions";

CREATE POLICY ustt_update_own
    ON "Stocks"."UserStockTransactions"
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((userid = (current_setting('app.current_user_id'::text, true))::bigint))
    WITH CHECK ((userid = (current_setting('app.current_user_id'::text, true))::bigint));

create table "Stocks".index_data
(
    "DATE" date,
    "OPEN" numeric(12,2),
    "HIGH" numeric(12,2),
    "LOW" numeric(12,2),
    "CLOSE" numeric(12,2),
    "SHARES TRADED" bigint,
    "TURNOVER (INR CR)" numeric(16,2),
    source_file character varying(255) COLLATE pg_catalog."default",
    symbol character varying(100) COLLATE pg_catalog."default",
    file_suffix character varying(255) COLLATE pg_catalog."default"
);

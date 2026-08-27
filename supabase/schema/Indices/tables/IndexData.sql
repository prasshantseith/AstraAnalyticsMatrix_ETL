create table "Indices"."IndexData"
(
    "IndexName" varchar(100) NOT NULL,
    "TradeDate" date NOT NULL,
    "OpenPrice" numeric(18,4),
    "HighPrice" numeric(18,4),
    "LowPrice" numeric(18,4),
    "ClosePrice" numeric(18,4),
    "Volume" bigint,
    "TurnoverInrCr" numeric(20,4),
    "DataSource" varchar(30) NOT NULL DEFAULT 'NSE',
    "SourceFile" varchar(500),
    "CreatedAt" timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT "IndexData_pkey" PRIMARY KEY ("IndexName", "TradeDate")
)
PARTITION BY RANGE ("TradeDate");

-- Yearly partitions from 1996 through 2040 are created by migration
-- 20260827030000_move_index_data_to_indicies.sql.
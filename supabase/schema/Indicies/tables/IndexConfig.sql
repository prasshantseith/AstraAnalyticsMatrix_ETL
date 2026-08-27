create table "Indicies"."IndexConfig"
(
    "IndexName" varchar(100) PRIMARY KEY,
    "NseIndexType" varchar(100) NOT NULL,
    "StartDate" date NOT NULL,
    "Enabled" boolean NOT NULL DEFAULT true
);
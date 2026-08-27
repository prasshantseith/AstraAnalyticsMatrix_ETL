create table "Indices"."IndexConfig"
(
    "IndexName" varchar(100) PRIMARY KEY,
    "Category" varchar(50) NOT NULL,
    "NseIndexType" varchar(100) NOT NULL,
    "StartDate" date NOT NULL,
    "Enabled" boolean NOT NULL DEFAULT true
);
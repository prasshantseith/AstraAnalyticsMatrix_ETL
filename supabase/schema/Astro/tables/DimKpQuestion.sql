create table "Astro"."DimKpQuestion"
(
    "QuestionId" smallint NOT NULL,
    "Category" text COLLATE pg_catalog."default" NOT NULL,
    "Question" text COLLATE pg_catalog."default" NOT NULL,
    "MainCusp" smallint[],
    "Favourable" smallint[] NOT NULL,
    "FavourableDesc" text COLLATE pg_catalog."default",
    "Unfavourable" smallint[] NOT NULL,
    "UnfavourableDesc" text COLLATE pg_catalog."default",
    "SortOrder" smallint NOT NULL,
    CONSTRAINT "DimKpQuestion_pkey" PRIMARY KEY ("QuestionId")
);

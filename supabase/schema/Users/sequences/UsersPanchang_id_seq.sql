CREATE SEQUENCE "Users"."UsersPanchang_id_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE "Users"."UsersPanchang_id_seq"
    OWNED BY "Users"."UsersPanchang".id;

ALTER SEQUENCE "Users"."UsersPanchang_id_seq"
    OWNER TO postgres;

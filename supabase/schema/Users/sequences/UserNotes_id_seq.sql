CREATE SEQUENCE "Users"."UserNotes_id_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE "Users"."UserNotes_id_seq"
    OWNED BY "Users"."UserNotes".id;

ALTER SEQUENCE "Users"."UserNotes_id_seq"
    OWNER TO postgres;

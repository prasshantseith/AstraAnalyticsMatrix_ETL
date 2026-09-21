create table "Users"."blockedIPs"
(
    id integer NOT NULL DEFAULT nextval('"Users"."blockedIPs_id_seq"'::regclass),
    ip_address character varying COLLATE pg_catalog."default" NOT NULL,
    reason character varying COLLATE pg_catalog."default",
    blocked_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT "blockedIPs_pkey" PRIMARY KEY (id),
    CONSTRAINT "blockedIPs_ip_address_key" UNIQUE (ip_address)
);

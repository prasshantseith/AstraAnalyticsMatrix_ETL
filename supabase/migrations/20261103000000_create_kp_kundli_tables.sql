-- KP Kundli: brand new tables only, nothing existing touched. Caches a
-- person's full KP computation (planets, house cusps, Vimshottari dasha)
-- so a repeat view doesn't re-call freeastrologyapi.com or re-run the
-- local Placidus math - app/routers/kp_kundli.py checks for an existing
-- row before computing anything.

CREATE TABLE IF NOT EXISTS "Users"."KpPlanetPosition"
(
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    person_id integer NOT NULL REFERENCES "Users"."UsersPanchang"(id) ON DELETE CASCADE,
    planet_name character varying(10) NOT NULL,
    full_degree numeric(10,6) NOT NULL,
    sign character varying(20) NOT NULL,
    sign_lord character varying(10) NOT NULL,
    nakshatra character varying(20) NOT NULL,
    pada smallint NOT NULL,
    star_lord character varying(10) NOT NULL,
    sub_lord character varying(10) NOT NULL,
    sub_sub_lord character varying(10) NOT NULL,
    house_number smallint NOT NULL,
    is_retrograde boolean NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT kp_planet_position_unique UNIQUE (person_id, planet_name)
);

-- House cusps, including the Ascendant (house_number = 1 IS the Ascendant
-- - no separate table for it, since a cusp and the Ascendant are the same
-- kind of point with the same Sub Lord computation).
CREATE TABLE IF NOT EXISTS "Users"."KpHouseCusp"
(
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    person_id integer NOT NULL REFERENCES "Users"."UsersPanchang"(id) ON DELETE CASCADE,
    house_number smallint NOT NULL,
    full_degree numeric(10,6) NOT NULL,
    sign character varying(20) NOT NULL,
    sign_lord character varying(10) NOT NULL,
    nakshatra character varying(20) NOT NULL,
    pada smallint NOT NULL,
    star_lord character varying(10) NOT NULL,
    sub_lord character varying(10) NOT NULL,
    sub_sub_lord character varying(10) NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT kp_house_cusp_unique UNIQUE (person_id, house_number),
    CONSTRAINT kp_house_cusp_number_range CHECK (house_number BETWEEN 1 AND 12)
);

-- Mahadasha and Antardasha rows together (level distinguishes them) -
-- antardasha_lord is NULL for a Mahadasha-level row.
CREATE TABLE IF NOT EXISTS "Users"."KpDasha"
(
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    person_id integer NOT NULL REFERENCES "Users"."UsersPanchang"(id) ON DELETE CASCADE,
    level character varying(20) NOT NULL,
    mahadasha_lord character varying(10) NOT NULL,
    antardasha_lord character varying(10),
    start_time timestamp NOT NULL,
    end_time timestamp NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT kp_dasha_level_check CHECK (level IN ('Mahadasha', 'Antardasha'))
);

CREATE INDEX IF NOT EXISTS ix_kp_dasha_person ON "Users"."KpDasha" (person_id, level, start_time);

do $$
begin
    if not exists (select from pg_roles where rolname = 'app_user') then
        create role app_user nologin;
    end if;
end $$;

-- INSERT/DELETE/SELECT (not just SELECT) - the API itself writes this
-- cache on first computation, same grant shape as Users.UserNotes, unlike
-- the SELECT-only tables the ETL pipelines populate.
REVOKE ALL ON TABLE "Users"."KpPlanetPosition" FROM app_user;
GRANT INSERT, DELETE, SELECT ON TABLE "Users"."KpPlanetPosition" TO app_user;
GRANT ALL ON TABLE "Users"."KpPlanetPosition" TO postgres;

REVOKE ALL ON TABLE "Users"."KpHouseCusp" FROM app_user;
GRANT INSERT, DELETE, SELECT ON TABLE "Users"."KpHouseCusp" TO app_user;
GRANT ALL ON TABLE "Users"."KpHouseCusp" TO postgres;

REVOKE ALL ON TABLE "Users"."KpDasha" FROM app_user;
GRANT INSERT, DELETE, SELECT ON TABLE "Users"."KpDasha" TO app_user;
GRANT ALL ON TABLE "Users"."KpDasha" TO postgres;

CREATE OR REPLACE FUNCTION "Astro".decimal_to_dms_in_sign(
	decimal_degrees numeric)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
DECLARE
  sign_remainder numeric;
  deg int;
  min int;
  sec int;
BEGIN
  sign_remainder := decimal_degrees - floor(decimal_degrees / 30) * 30;
  deg := floor(sign_remainder)::int;
  min := floor((sign_remainder - deg) * 60)::int;
  sec := floor(((sign_remainder - deg) * 60 - min) * 60)::int;
  RETURN deg || '° ' || min || ''' ' || sec || '"';
END;
$BODY$;

ALTER FUNCTION "Astro".decimal_to_dms_in_sign(numeric)
    OWNER TO postgres;

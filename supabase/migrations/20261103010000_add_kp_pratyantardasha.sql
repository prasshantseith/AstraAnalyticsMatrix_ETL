-- KP Kundli: extend the Dasha cache to a third level (Pratyantardasha),
-- nested under its own Antardasha row. Purely additive to the brand-new
-- KpDasha table from the previous migration - no other table touched.

ALTER TABLE "Users"."KpDasha" ADD COLUMN IF NOT EXISTS pratyantardasha_lord character varying(10);

ALTER TABLE "Users"."KpDasha" DROP CONSTRAINT IF EXISTS kp_dasha_level_check;
ALTER TABLE "Users"."KpDasha" ADD CONSTRAINT kp_dasha_level_check
    CHECK (level IN ('Mahadasha', 'Antardasha', 'Pratyantardasha'));

-- KP Kundli: clears cached Dasha rows so every profile recomputes with
-- the fixed Vimshottari Dasha (app repo PR #33, computed locally from
-- the Moon's own position instead of a separate, internally-inconsistent
-- freeastrologyapi.com dasha endpoint). Planets/cusps are unaffected by
-- this particular fix, so only KpDasha needs clearing this time.

DELETE FROM "Users"."KpDasha";

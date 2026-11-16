-- KP Kundli: clears all cached natal data so every profile recomputes
-- with the geocentric + true-Placidus-house fixes (app repo PR #31).
-- Safe to wipe entirely - this cache is rebuilt automatically the next
-- time each profile's KP Kundli page is viewed, at the cost of the
-- same 2 freeastrologyapi.com calls the very first view already makes.

DELETE FROM "Users"."KpDasha";
DELETE FROM "Users"."KpHouseCusp";
DELETE FROM "Users"."KpPlanetPosition";

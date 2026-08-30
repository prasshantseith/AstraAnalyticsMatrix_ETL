-- MF_NAV_legacy_monthly (the pre-repartition, monthly-partitioned table) has
-- been verified to match "MF"."MF_NAV" row-for-row (17,416,964 = 17,416,964)
-- after 20260830020000_repartition_mf_nav_by_year.sql copied everything
-- across. Drop it now - CASCADE removes all ~660 monthly child partitions
-- along with it, which is what actually declutters the table list.
DROP TABLE IF EXISTS "MF"."MF_NAV_legacy_monthly" CASCADE;

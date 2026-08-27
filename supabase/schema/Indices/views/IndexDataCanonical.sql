-- Presents IndexData under each index's current canonical name so history
-- before and after the 2015-11-09 CNX->NIFTY rebrand reads as one continuous
-- series, without rewriting the as-published raw names in IndexData itself.
create or replace view "Indices"."IndexDataCanonical" as
select
    coalesce(alias."CanonicalName", d."IndexName") as "IndexName",
    d."TradeDate",
    d."OpenPrice",
    d."HighPrice",
    d."LowPrice",
    d."ClosePrice",
    d."Volume",
    d."TurnoverInrCr",
    d."DataSource",
    d."SourceFile",
    d."CreatedAt"
from "Indices"."IndexData" d
left join "Indices"."IndexNameAlias" alias
    on lower(alias."AliasName") = lower(d."IndexName");

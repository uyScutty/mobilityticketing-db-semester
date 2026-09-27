\set ON_ERROR_STOP on

-- Compatibility reader: prefer the stable ID and fall back to the old code
-- only for rows that have not been backfilled yet.
select
    t.id,
    coalesce(p_by_id.id, p_by_code.id) as resolved_product_id,
    coalesce(p_by_id.code, p_by_code.code) as resolved_product_code,
    t.price,
    t.currency
from tickets t
left join products p_by_id
  on p_by_id.id = t.product_id
left join products p_by_code
  on t.product_id is null
 and p_by_code.code = t.product_code
order by t.id;


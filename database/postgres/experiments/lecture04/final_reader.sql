\set ON_ERROR_STOP on

-- ID-only reader. It does not depend on tickets.product_code and therefore
-- survives removal of that legacy column.
select
    t.id,
    t.product_id,
    p.code as product_code,
    t.price,
    t.currency
from tickets t
join products p on p.id = t.product_id
order by t.id;


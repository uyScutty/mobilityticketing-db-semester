-- Lecture 4 backfill phase. Safe to repeat and safe for late old-writer rows.

begin;

with backfilled as (
    update tickets t
    set product_id = p.id
    from products p
    where t.product_id is null
      and p.code = t.product_code
    returning t.id
)
select count(*) as rows_backfilled
from backfilled;

commit;

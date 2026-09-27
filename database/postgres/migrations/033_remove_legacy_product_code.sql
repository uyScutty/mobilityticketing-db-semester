-- Lecture 4 legacy-removal phase. The pre-removal checks must pass first.
-- The Lecture 3 materialized view is rebuilt on stable product_id before the
-- legacy ticket column is removed.

begin;
set local lock_timeout = '3s';

do $migration$
begin
    if exists (select 1 from tickets where product_id is null) then
        raise exception 'Cannot remove product_code while product_id is null';
    end if;

    if exists (
        select 1
        from tickets t
        join products p_by_id on p_by_id.id = t.product_id
        join products p_by_code on p_by_code.code = t.product_code
        where p_by_id.id <> p_by_code.id
    ) then
        raise exception 'Cannot remove product_code while product references disagree';
    end if;
end
$migration$;

drop materialized view ticket_sales_summary;

alter table tickets
    drop constraint tickets_product_identity_fk,
    drop constraint tickets_product_code_fk,
    drop column product_code;

create materialized view ticket_sales_summary as
select
    t.product_id,
    p.code as product_code,
    t.currency,
    count(*)::bigint as ticket_count,
    sum(t.price) as total_sales
from tickets t
join products p on p.id = t.product_id
group by t.product_id, p.code, t.currency;

create unique index ticket_sales_summary_identity
    on ticket_sales_summary (product_id, currency);

commit;

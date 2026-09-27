\set ON_ERROR_STOP on

select conname, pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid = 'tickets'::regclass
  and pg_get_constraintdef(oid) ilike '%product%'
order by conname;

select pg_get_viewdef('ticket_sales_summary'::regclass, true) as dependent_view_before_removal;

do $test$
begin
    if exists (select 1 from tickets where product_id is null) then
        raise exception 'Null product IDs remain';
    end if;

    if exists (
        select 1
        from tickets t
        join products p_by_id on p_by_id.id = t.product_id
        join products p_by_code on p_by_code.code = t.product_code
        where p_by_id.id <> p_by_code.id
    ) then
        raise exception 'Product ID/code mismatch remains';
    end if;

    if not exists (
        select 1
        from pg_attribute
        where attrelid = 'tickets'::regclass
          and attname = 'product_id'
          and attnotnull
          and not attisdropped
    ) then
        raise exception 'product_id is not required yet';
    end if;

    if exists (
        select 1
        from pg_constraint
        where conname in ('tickets_product_id_fk', 'tickets_product_identity_fk')
          and not convalidated
    ) then
        raise exception 'A new product foreign key is not validated';
    end if;
end
$test$;

select 'PASS: no null/mismatch remains; FKs are validated; dependent view was identified' as result;

\set ON_ERROR_STOP on

refresh materialized view ticket_sales_summary;

do $test$
begin
    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public'
          and table_name = 'tickets'
          and column_name = 'product_code'
    ) then
        raise exception 'Legacy tickets.product_code still exists';
    end if;

    if exists (
        select 1
        from tickets t
        left join products p on p.id = t.product_id
        where p.id is null
    ) then
        raise exception 'An ID-only product reference does not resolve';
    end if;

    if not exists (
        select 1
        from tickets t
        join products p on p.id = t.product_id
        where t.id = 'TICKET-3'
          and p.code = 'DAY'
          and p.price = 80.00
          and t.price = 65.00
          and t.currency = 'DKK'
    ) then
        raise exception 'Historical DAY ticket snapshot changed';
    end if;

    if not exists (
        select 1
        from tickets
        where id = 'L4-FINAL-1'
          and price = 35.00
          and currency = 'DKK'
    ) then
        raise exception 'Final ID-only writer row is missing';
    end if;

    if (select sum(ticket_count) from ticket_sales_summary)
       <> (select count(*) from tickets) then
        raise exception 'Migrated materialized view is inconsistent';
    end if;
end
$test$;

select 'PASS: legacy column removed and all tickets resolve by product_id' as result;
select 'PASS: historical DAY ticket remains 65 DKK versus catalogue 80 DKK' as result;
select 'PASS: migrated materialized view matches the base table' as result;

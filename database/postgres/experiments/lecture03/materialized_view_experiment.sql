\set ON_ERROR_STOP on

begin;

insert into tickets (
    id, user_id, trip_id, ticket_code, status, product_code,
    valid_from_utc, valid_to_utc, price, currency
) values (
    'L3-MV-TICKET', 'USER-1', 'TRIP-M2-20260429-0800',
    'L3-MV-CODE', 'Active', 'SINGLE',
    '2026-04-29 08:00:00+00', '2026-04-29 10:00:00+00',
    36.00, 'DKK'
);

select
    'before_refresh' as stage,
    (select count(*) from tickets where product_code = 'SINGLE') as base_ticket_count,
    (select ticket_count from ticket_sales_summary
      where product_code = 'SINGLE' and currency = 'DKK') as materialized_ticket_count;

do $test$
declare
    base_count bigint;
    materialized_count bigint;
begin
    select count(*)
    into base_count
    from tickets
    where product_code = 'SINGLE';

    select ticket_count
    into materialized_count
    from ticket_sales_summary
    where product_code = 'SINGLE'
      and currency = 'DKK';

    if base_count <> 3 or materialized_count <> 2 then
        raise exception
            'Expected base count 3 and stale materialized count 2, got % and %',
            base_count,
            materialized_count;
    end if;
end
$test$;

select 'PASS: materialized view is stale while the base-table query is current' as result;

refresh materialized view ticket_sales_summary;

select
    'after_refresh' as stage,
    (select count(*) from tickets where product_code = 'SINGLE') as base_ticket_count,
    (select ticket_count from ticket_sales_summary
      where product_code = 'SINGLE' and currency = 'DKK') as materialized_ticket_count;

do $test$
begin
    if (
        select count(*)
        from tickets
        where product_code = 'SINGLE'
    ) <> (
        select ticket_count
        from ticket_sales_summary
        where product_code = 'SINGLE'
          and currency = 'DKK'
    ) then
        raise exception 'Materialized view is still stale after refresh';
    end if;
end
$test$;

select 'PASS: refresh brought the materialized view back in sync' as result;

rollback;

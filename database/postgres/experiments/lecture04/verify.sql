\set ON_ERROR_STOP on

select
    t.id,
    t.product_code,
    t.product_id,
    p.price as catalogue_price,
    t.price as ticket_price,
    t.currency
from tickets t
left join products p
  on p.id = t.product_id
 and p.code = t.product_code
order by t.id;

do $test$
begin
    if exists (select 1 from tickets where product_id is null) then
        raise exception 'A ticket still has a null product_id';
    end if;

    if exists (
        select 1
        from tickets t
        left join products p
          on p.id = t.product_id
         and p.code = t.product_code
        where p.id is null
    ) then
        raise exception 'A ticket has a missing or mismatched product reference';
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
        raise exception 'Historical ticket price/currency changed during migration';
    end if;

    if not exists (
        select 1
        from tickets
        where id = 'L4-NEW-1'
          and price = 34.00
          and currency = 'DKK'
    ) then
        raise exception 'New writer did not preserve its agreed purchase price';
    end if;

    begin
        insert into tickets (
            id, user_id, trip_id, ticket_code, status,
            product_code, product_id,
            valid_from_utc, valid_to_utc, price, currency
        )
        select
            'L4-MISMATCH', 'USER-1', 'TRIP-M2-20260429-0800',
            'L4-CODE-MISMATCH', 'Active',
            'SINGLE', p.id,
            '2026-04-29 08:00:00+00', '2026-04-29 10:00:00+00',
            36.00, 'DKK'
        from products p
        where p.code = 'DAY';

        raise exception using
            errcode = 'P0001',
            message = 'A mismatched product ID/code pair was accepted';
    exception
        when foreign_key_violation then
            null;
    end;
end
$test$;

select 'PASS: references match and mismatch is rejected (SQLSTATE 23503)' as result;
select 'PASS: TICKET-3 remains DAY at 65 DKK while catalogue price is 80 DKK' as result;

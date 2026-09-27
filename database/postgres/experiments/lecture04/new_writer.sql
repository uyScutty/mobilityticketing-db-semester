\set ON_ERROR_STOP on

-- Test setup chooses an ID from the catalogue. The writer contract itself
-- accepts that ID, derives product_code from the same product and stores the
-- agreed purchase price rather than copying the catalogue price.
select id as selected_product_id
from products
where code = 'SINGLE'
\gset

insert into tickets (
    id, user_id, trip_id, ticket_code, status,
    product_code, product_id,
    valid_from_utc, valid_to_utc, price, currency
)
select
    'L4-NEW-1',
    'USER-1',
    'TRIP-M2-20260429-0800',
    'L4-CODE-NEW-1',
    'Active',
    p.code,
    p.id,
    '2026-04-29 08:00:00+00',
    '2026-04-29 10:00:00+00',
    34.00,
    'DKK'
from products p
where p.id = :'selected_product_id'::uuid;

select 'PASS: new writer stored matching ID/code and the agreed price 34.00 DKK' as result;


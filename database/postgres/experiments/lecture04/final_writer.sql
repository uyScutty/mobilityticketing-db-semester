\set ON_ERROR_STOP on

select id as selected_product_id
from products
where code = 'SINGLE'
\gset

-- ID-only writer: tickets.product_code is intentionally absent.
insert into tickets (
    id, user_id, trip_id, ticket_code, status, product_id,
    valid_from_utc, valid_to_utc, price, currency
) values (
    'L4-FINAL-1',
    'USER-1',
    'TRIP-M2-20260429-0800',
    'L4-CODE-FINAL-1',
    'Active',
    :'selected_product_id'::uuid,
    '2026-04-29 08:00:00+00',
    '2026-04-29 10:00:00+00',
    35.00,
    'DKK'
);

select 'PASS: final writer inserted a ticket using product_id only' as result;


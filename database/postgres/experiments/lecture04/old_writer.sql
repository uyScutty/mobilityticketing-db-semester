\set ON_ERROR_STOP on

-- Late write from an old application instance. product_id is intentionally
-- omitted and must be filled by the repeatable backfill.
\set ticket_id 'LAB04-OLD-1'
\set ticket_code 'LAB04-CODE-OLD-1'

insert into tickets
    (id, user_id, trip_id, ticket_code, status, product_code,
     valid_from_utc, valid_to_utc, price, currency)
select :'ticket_id', user_id, trip_id, :'ticket_code', status, product_code,
       valid_from_utc, valid_to_utc, price, currency
from tickets
where id = 'TICKET-1';

select 'PASS: late old writer inserted a ticket with product_id still null' as result;

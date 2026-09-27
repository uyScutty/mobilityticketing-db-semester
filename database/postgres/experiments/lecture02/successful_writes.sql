\set ON_ERROR_STOP on

begin;

insert into products (code, name, price, currency)
values ('L2-SINGLE', 'Lecture 2 single trip', 42.00, 'DKK');

insert into users (id, email, full_name, is_disabled)
values ('L2-USER', 'lecture2@example.test', 'Lecture 2 Test', false);

insert into tickets (
    id, user_id, trip_id, ticket_code, status, product_code,
    valid_from_utc, valid_to_utc, price, currency
) values (
    'L2-TICKET', 'L2-USER', 'TRIP-M2-20260429-0800',
    'L2-CODE-0001', 'Active', 'L2-SINGLE',
    '2026-04-29 07:45:00+00', '2026-04-29 10:00:00+00',
    42.00, 'DKK'
);

insert into payments (
    id, user_id, ticket_id, external_payment_reference,
    amount, currency, status
) values (
    'L2-PAYMENT', 'L2-USER', 'L2-TICKET',
    'lecture2-capture-0001', 42.00, 'DKK', 'Captured'
);

insert into validations (
    id, ticket_id, ticket_code, vehicle_id, stop_id, device_id, result
) values (
    'L2-VALIDATION', 'L2-TICKET', 'L2-CODE-0001',
    'L2-VEHICLE', 'STOP-NORREPORT', 'L2-DEVICE', 'Accepted'
);

do $test$
begin
    if not exists (
        select 1
        from tickets t
        join payments p on p.ticket_id = t.id
        join validations v
          on v.ticket_id = t.id
         and v.ticket_code = t.ticket_code
        where t.id = 'L2-TICKET'
          and p.id = 'L2-PAYMENT'
          and v.id = 'L2-VALIDATION'
    ) then
        raise exception 'Valid Lecture 2 write set was not stored';
    end if;

end
$test$;

select 'PASS: valid product, user, ticket, payment and validation writes' as result;

rollback;

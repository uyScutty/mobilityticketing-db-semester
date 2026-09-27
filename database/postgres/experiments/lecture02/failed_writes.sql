\set ON_ERROR_STOP on

begin;

do $test$
begin
    begin
        update trips
        set capacity = -1
        where id = 'TRIP-M2-20260429-0800';

        raise exception using errcode = 'P0001', message = 'Negative capacity was accepted';
    exception
        when check_violation then
            null;
    end;
end
$test$;

select 'PASS: negative capacity rejected (SQLSTATE 23514)' as result;

do $test$
begin
    begin
        insert into tickets (
            id, user_id, trip_id, ticket_code, status, product_code,
            valid_from_utc, valid_to_utc, price, currency
        )
        select
            'L2-BAD-FK', 'NO-SUCH-USER', trip_id, 'L2-BAD-FK-CODE',
            status, product_code, valid_from_utc, valid_to_utc, price, currency
        from tickets
        where id = 'TICKET-1';

        raise exception using errcode = 'P0001', message = 'Unknown user reference was accepted';
    exception
        when foreign_key_violation then
            null;
    end;
end
$test$;

select 'PASS: unknown user rejected (SQLSTATE 23503)' as result;

do $test$
begin
    begin
        insert into tickets (
            id, user_id, trip_id, ticket_code, status, product_code,
            valid_from_utc, valid_to_utc, price, currency
        )
        select
            'L2-BAD-UNIQUE', user_id, trip_id, ticket_code,
            status, product_code, valid_from_utc, valid_to_utc, price, currency
        from tickets
        where id = 'TICKET-1';

        raise exception using errcode = 'P0001', message = 'Duplicate ticket code was accepted';
    exception
        when unique_violation then
            null;
    end;
end
$test$;

select 'PASS: duplicate ticket code rejected (SQLSTATE 23505)' as result;

do $test$
begin
    begin
        insert into products (code, name, price, currency)
        values ('L2-BAD-CURRENCY', 'Bad currency', 10.00, 'dkk');

        raise exception using errcode = 'P0001', message = 'Lower-case currency was accepted';
    exception
        when check_violation then
            null;
    end;
end
$test$;

select 'PASS: malformed currency rejected (SQLSTATE 23514)' as result;

do $test$
begin
    begin
        insert into tickets (
            id, user_id, trip_id, ticket_code, status, product_code,
            valid_from_utc, valid_to_utc, price, currency
        )
        select
            'L2-BAD-WINDOW', user_id, trip_id, 'L2-BAD-WINDOW-CODE',
            status, product_code, valid_to_utc, valid_from_utc, price, currency
        from tickets
        where id = 'TICKET-1';

        raise exception using errcode = 'P0001', message = 'Reversed validity window was accepted';
    exception
        when check_violation then
            null;
    end;
end
$test$;

select 'PASS: reversed validity window rejected (SQLSTATE 23514)' as result;

do $test$
begin
    begin
        insert into payments (
            id, user_id, ticket_id, external_payment_reference,
            amount, currency, status, created_utc
        )
        select
            'L2-BAD-CAPTURE', user_id, ticket_id, external_payment_reference,
            amount, currency, status, created_utc
        from payments
        where id = 'PAYMENT-1';

        raise exception using errcode = 'P0001', message = 'Duplicate captured payment reference was accepted';
    exception
        when unique_violation then
            null;
    end;
end
$test$;

select 'PASS: duplicate captured payment reference rejected (SQLSTATE 23505)' as result;

rollback;

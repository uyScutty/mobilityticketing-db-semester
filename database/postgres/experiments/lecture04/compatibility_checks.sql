\set ON_ERROR_STOP on

begin;

do $test$
begin
    begin
        insert into tickets (
            id, user_id, trip_id, ticket_code, status, product_code,
            valid_from_utc, valid_to_utc, price, currency
        )
        select
            'L4-OLD-BLOCKED', user_id, trip_id, 'L4-CODE-OLD-BLOCKED',
            status, product_code, valid_from_utc, valid_to_utc, price, currency
        from tickets
        where id = 'TICKET-1';

        raise exception using
            errcode = 'P0001',
            message = 'Old writer unexpectedly worked after product_id became required';
    exception
        when not_null_violation then
            null;
    end;
end
$test$;

select 'PASS: old writer shape is rejected after cutover (SQLSTATE 23502)' as result;

rollback;

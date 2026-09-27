\set ON_ERROR_STOP on

do $test$
declare
    expected text[] := array[
        'trips_capacity_nonnegative',
        'trips_reserved_valid',
        'trips_status_valid',
        'products_price_valid',
        'products_currency_valid',
        'tickets_user_fk',
        'tickets_trip_fk',
        'tickets_product_code_fk',
        'tickets_code_unique',
        'tickets_identity_unique',
        'tickets_status_valid',
        'tickets_price_valid',
        'tickets_currency_valid',
        'tickets_validity_valid',
        'payments_user_fk',
        'payments_ticket_fk',
        'payments_amount_valid',
        'payments_currency_valid',
        'payments_status_valid',
        'validations_ticket_identity_fk',
        'validations_stop_fk'
    ];
    missing text[];
begin
    select array_agg(required_name order by required_name)
    into missing
    from unnest(expected) as required(required_name)
    where not exists (
        select 1
        from pg_constraint c
        where c.conname = required.required_name
          and c.connamespace = 'public'::regnamespace
    );

    if missing is not null then
        raise exception 'Missing Lecture 2 constraints: %', missing;
    end if;

    if not exists (
        select 1
        from pg_indexes
        where schemaname = 'public'
          and indexname = 'payments_capture_reference_unique'
          and indexdef ilike '%unique%'
          and indexdef ilike '%where%status%captured%'
    ) then
        raise exception 'Missing partial unique captured-payment index';
    end if;

end
$test$;

select 'PASS: 21 named constraints and the partial unique payment index exist' as result;

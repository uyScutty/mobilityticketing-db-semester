\set ON_ERROR_STOP on

do $test$
declare
    trip_ids text[];
    ordered_stop_ids text[];
begin
    select array_agg(id order by scheduled_departure_utc)
    into trip_ids
    from (
        select id, scheduled_departure_utc
        from trips
        where route_id = 'LINE-M2'
          and scheduled_departure_utc > timestamptz '2026-04-29 07:30:00+00'
          and status = 'Scheduled'
        order by scheduled_departure_utc
        limit 20
    ) next_trips;

    if trip_ids <> array['TRIP-M2-20260429-0800', 'TRIP-M2-20260429-1200'] then
        raise exception 'Unexpected next-trip result: %', trip_ids;
    end if;

    select array_agg(stop_id order by stop_sequence)
    into ordered_stop_ids
    from route_stops
    where route_id = 'LINE-M2';

    if ordered_stop_ids <> array[
        'STOP-NORREPORT',
        'STOP-KONGENS-NYTORV',
        'STOP-AIRPORT'
    ] then
        raise exception 'Unexpected ordered-stop result: %', ordered_stop_ids;
    end if;

    if not exists (
        select 1
        from routes r
        left join trips t
          on t.route_id = r.id
         and t.service_date = date '2026-04-29'
         and t.status = 'Scheduled'
        group by r.id
        having r.id = 'LINE-12' and count(t.id) = 0
    ) then
        raise exception 'Route with zero Scheduled trips was not preserved';
    end if;
end
$test$;

select 'PASS: next trips are filtered, ordered and limited correctly' as result;
select 'PASS: route stops are returned in stop_sequence order' as result;
select 'PASS: route aggregation includes LINE-12 with zero trips' as result;

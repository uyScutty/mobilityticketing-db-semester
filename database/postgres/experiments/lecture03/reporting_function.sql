\set ON_ERROR_STOP on

select *
from route_schedule_report(date '2026-04-29');

do $test$
begin
    if (select count(*) from route_schedule_report(date '2026-04-29')) <> 3 then
        raise exception 'The report did not return every route';
    end if;

    if not exists (
        select 1 from route_schedule_report(date '2026-04-29')
        where route_id = 'LINE-5C' and scheduled_trip_count = 2
    ) or not exists (
        select 1 from route_schedule_report(date '2026-04-29')
        where route_id = 'LINE-M2' and scheduled_trip_count = 2
    ) or not exists (
        select 1 from route_schedule_report(date '2026-04-29')
        where route_id = 'LINE-12' and scheduled_trip_count = 0
    ) then
        raise exception 'Unexpected scheduled-trip count in route report';
    end if;
end
$test$;

select 'PASS: reporting function returns route counts 2, 2 and 0' as result;

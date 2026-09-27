-- Lecture 3: shared reporting logic, a narrow audit trigger and a cached report.

begin;
set local lock_timeout = '3s';

create function route_schedule_report(p_service_date date)
returns table (
    route_id text,
    route_short_name text,
    scheduled_trip_count bigint
)
language sql
stable
as $function$
    select
        r.id,
        r.short_name,
        count(t.id)
    from routes r
    left join trips t
      on t.route_id = r.id
     and t.service_date = p_service_date
     and t.status = 'Scheduled'
    group by r.id, r.short_name
    order by r.short_name, r.id
$function$;

create table ticket_status_audit (
    id bigint generated always as identity primary key,
    ticket_id text not null references tickets(id),
    old_status text not null,
    new_status text not null,
    changed_at timestamptz not null default clock_timestamp()
);

create function record_ticket_status_change()
returns trigger
language plpgsql
as $function$
begin
    insert into ticket_status_audit (ticket_id, old_status, new_status)
    values (new.id, old.status, new.status);

    return new;
end
$function$;

create trigger tickets_status_audit_trigger
after update of status on tickets
for each row
when (old.status is distinct from new.status)
execute function record_ticket_status_change();

create materialized view ticket_sales_summary as
select
    t.product_code,
    t.currency,
    count(*)::bigint as ticket_count,
    sum(t.price) as total_sales
from tickets t
group by t.product_code, t.currency;

create unique index ticket_sales_summary_identity
    on ticket_sales_summary (product_code, currency);

commit;

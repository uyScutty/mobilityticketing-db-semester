\set ON_ERROR_STOP on

begin;

update tickets
set status = 'Validated'
where id = 'TICKET-1';

do $test$
begin
    if not exists (
        select 1
        from ticket_status_audit
        where ticket_id = 'TICKET-1'
          and old_status = 'Active'
          and new_status = 'Validated'
    ) then
        raise exception 'Expected ticket status audit row was not written';
    end if;
end
$test$;

select ticket_id, old_status, new_status
from ticket_status_audit
where ticket_id = 'TICKET-1';

select 'PASS: trigger recorded the Active-to-Validated status change' as result;

rollback;

\set ON_ERROR_STOP on
select current_database();
select id, product_code, price, currency from tickets order by id;
select t.id,t.product_code from tickets t left join products p on p.code=t.product_code
where t.product_code is null or p.code is null;
do $$ begin
 if (select count(*) from tickets)<3 or (select count(distinct product_code) from tickets)<2 then
  raise exception 'Expected at least three tickets covering two products';
 end if;
 if exists(select 1 from tickets t left join products p on p.code=t.product_code where p.code is null) then
  raise exception 'Unresolved product reference';
 end if;
 if not exists (
  select 1
  from tickets t
  join products p on p.code = t.product_code
  where t.id = 'TICKET-3'
    and t.price = 65.00
    and t.currency = 'DKK'
    and p.code = 'DAY'
    and p.price = 80.00
 ) then
  raise exception 'Expected historical DAY ticket price 65 DKK and catalogue price 80 DKK';
 end if;
end $$;
select 'PASS: baseline has three tickets and preserves DAY price 65 DKK vs catalogue 80 DKK' as result;

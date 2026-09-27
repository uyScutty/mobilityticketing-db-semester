-- Lecture 4 expand phase: add stable product IDs while old code still uses
-- products.code and tickets.product_code.

begin;
set local lock_timeout = '3s';

alter table products add column id uuid;

update products
set id = gen_random_uuid()
where id is null;

alter table products
  alter column id set default gen_random_uuid();

alter table products
  alter column id set not null;

alter table products
  add constraint products_id_unique unique (id);

alter table products
  add constraint products_identity_unique unique (id, code);

alter table tickets
  add column product_id uuid;

alter table tickets
  add constraint tickets_product_id_fk
  foreign key (product_id)
  references products(id)
  not valid;

-- The pair constraint prevents a new writer from storing an ID and code that
-- identify different products. Old writers remain valid while product_id is null.
alter table tickets
  add constraint tickets_product_identity_fk
  foreign key (product_id, product_code)
  references products(id, code)
  not valid;

commit;

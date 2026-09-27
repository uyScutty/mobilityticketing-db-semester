-- Lecture 4 contract phase. Run only after old writers are retired and the
-- final backfill and compatibility checks have passed.

begin;
set local lock_timeout = '3s';

alter table tickets
    validate constraint tickets_product_id_fk;

alter table tickets
    validate constraint tickets_product_identity_fk;

alter table tickets
    alter column product_id set not null;

commit;

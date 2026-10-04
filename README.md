# Compulsory Assignment 1 review guide

Group members: **No love for db** — Thorbjørn Høgh

Submitted commit: See Moodle submission

Setup and reset instructions: [docs/setup.md](docs/setup.md)

## Where to find the work

- Lecture 1: model, workload map and queries: [model and design notes](docs/lab.md), [workload map](docs/Diagrammer/workload-map.png), [relational model](docs/Diagrammer/Lecture1-relational-model.png), [schema](database/postgres/init/001_relational_baseline.sql), [seed data](database/postgres/init/002_seed.sql), [three queries](database/postgres/init/003_queries.sql), and [test evidence](docs/evidence/lecture01/README.md).
- Lecture 2: constraints and tests: [integrity map](docs/integrity-map.md), [constraint migration](database/postgres/migrations/020_enforce_ticketing_integrity.sql), [successful writes](database/postgres/experiments/lecture02/successful_writes.sql), [failed writes](database/postgres/experiments/lecture02/failed_writes.sql), and [test evidence](docs/evidence/lecture02/README.md).
- Lecture 3: reporting experiment and comparison: [design and responsibility decision](docs/lecture03.md), [reporting, trigger and materialized-view migration](database/postgres/migrations/021_add_reporting_programmability.sql), [experiments](database/postgres/experiments/lecture03/), and [stale/base-table comparison evidence](docs/evidence/lecture03/README.md).
- Lecture 4: migration stages and verification: [migration design and compatibility matrix](docs/lecture04.md), [product-identity migrations](database/postgres/migrations/), [old/new/final readers, writers and checks](database/postgres/experiments/lecture04/), and [rollout, late-write and price/currency evidence](docs/evidence/lecture04/README.md).

## Two decisions worth discussing

### 1. Route-stop identity

- **What did we choose?** `route_stops` uses `(route_id, stop_sequence)` as its primary key. This records the functional dependency `(route_id, stop_sequence) -> stop_id`.
- **What was the alternative?** `(route_id, stop_id)` could have been the primary key.
- **Why does our choice fit MobilityTicketing?** A route may visit the same stop more than once; its position in the ordered route is therefore the stable identity of that visit.
- **Which file/result supports it?** The choice is implemented in the [Lecture 1 schema](database/postgres/init/001_relational_baseline.sql) and documented in the [model notes](docs/lab.md).

### 2. Compatible product-identity migration

- **What did we choose?** Product identity is migrated through expand → backfill → compatibility → contract, followed by removal of the legacy reference only after verification.
- **What was the alternative?** Replace `product_code` destructively with `product_id` in one deployment.
- **Why does our choice fit MobilityTicketing?** The overlap lets old and new application versions operate while tickets are backfilled, including a late write from the old writer. Checks guard the cutover, while stored ticket price and currency remain purchase-time snapshots.
- **Which file/result supports it?** See the [migration stages](docs/lecture04.md), [migration SQL](database/postgres/migrations/), and [executed evidence](docs/evidence/lecture04/README.md).

## One limitation or open question

- **What does the implementation not guarantee?** `CHECK (reserved_seats <= capacity)` prevents an invalid final row state, but does not alone resolve a race where two concurrent purchases attempt to buy the last seat.
- **Which evidence supports this?** The limitation and available database protections are documented in the [integrity map](docs/integrity-map.md); the [constraint migration](database/postgres/migrations/020_enforce_ticketing_integrity.sql) shows that the check is row-local.
- **What would we check next?** Run a two-session concurrency test and select a transaction strategy, such as an atomic conditional `UPDATE`, row locking, or suitable isolation.

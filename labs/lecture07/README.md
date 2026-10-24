# Lecture 7 – Design Decision

## 1. Read Model Design Alternatives

### Design A – Direct Live Query (Chosen)

The Live Board reads directly from PostgreSQL using EF Core LINQ queries with projection to `RouteOverviewDto`.

The database filters scheduled trips within the requested UTC window and calculates the departure count and earliest departure for each route.

This design supports arbitrary time windows and returns current values without maintaining additional summary tables.

### Design B – Maintained Summary Table (Alternative)

A separate read-model table stores precomputed departure information.

The table must be updated whenever trips are cancelled, routes are renamed, or other relevant data changes. So when live queries are performed we need to guarantee that the data is up to date and therefore a Maintained Read model is not the right way to guarantee strong consitency.

This can reduce query computation but introduces additional storage, synchronization logic and the risk of stale data. 
A summary table could be a future addition - if the specific buisness rules would demand a more performance optimized approach and the workload of queries are known to be very heavy and how often data is expected to be updated.


## 2. Command and Query Paths

| Operation | Type | Database responsibility |
|---|---|---|
| ReadOverview | Query | Read Routes and Trips using projection |
| CancelTrip | Command | Lock and update Trip status |
| RenameRoute | Command | Update Route name |
| BookTrip | Command | Check existing request, lock Trip, validate status and insert Booking |
| PublishSnapshot | Command | Read current overview and persist immutable snapshot |
| ReadSnapshot | Query | Read saved snapshot without loading Route or Trip entities |

## 3. Transaction Boundaries

**Booking:** Begin transaction → check existing request → lock Trip → validate current status → insert Booking and receipt → commit.

**Publication:** Begin transaction → check existing plan ID → calculate the current overview → save snapshot header and rows → commit.

Published snapshots must remain unchanged after cancellations or route renames.

The supplied `DatabaseSession.WriteAsync` and `LockTripAsync` helpers will be used to coordinate writes and protect booking against concurrent cancellations.


### Decision

We choose **Design A – Direct Live Query** because the assignment requires current data after changes, supports arbitrary UTC windows and limits live reads to one or two database queries. A maintained summary table adds complexity without a demonstrated performance need.




# MobilityTicketing: Lecture 7 starter

Build a live departure board, saved dispatch plans and booking operations. The [application contract](docs/contract.md) defines the required behavior.

You need Docker Desktop with Compose. Run these commands from this directory:

```sh
docker compose up -d --wait postgres
docker compose build app tests
docker compose run --rm app reset
docker compose run --rm app baseline
docker compose run --rm tests --filter Category=Starter
```

The fixture contains four routes and nine trips. The default window is 23 October 2026, 06:00 to 07:00 UTC. `baseline` uses lazy loading and saves its SQL and results in `docs/evidence/lecture07/logs/`.

Implement the six methods in `StudentApplication.cs`, and put your snapshot schema in `database/postgres/lecture07/03-read-model.sql`. Use your own command and query classes. The [contract](docs/contract.md) defines the required behavior. Keep your design note in `docs/design.md` and your measurements in `docs/evidence/lecture07/README.md`.

After editing code or SQL, rebuild with `docker compose build app tests`. Run `reset` to apply schema changes. It recreates `lab07` and clears bookings and published plans. Tests reset their own database, `mobility_l07_test`.

Once implemented, try this sequence. The initial reset makes it repeatable:

```sh
docker compose run --rm app reset
docker compose run --rm app overview
docker compose run --rm app publish morning
docker compose run --rm app book T201 campus-1
docker compose run --rm app book T201 campus-1
docker compose run --rm app cancel T102
docker compose run --rm app rename R1 "City Ring"
docker compose run --rm app book T102 cancelled-1
docker compose run --rm app overview
docker compose run --rm app snapshot morning
docker compose run --rm app publish revised
docker compose run --rm app snapshot revised
```

The T201 calls return `Booked` and then `AlreadyBooked`, with the same receipt. Booking T102 returns `Cancelled` with exit code 2. The live board shows the cancellation and new route name. The saved `morning` plan keeps its original values; `revised` records the changes.

Compare the reads with more data:

```sh
docker compose run --rm app reset
docker compose run --rm app scale
docker compose run --rm app baseline
docker compose run --rm app overview
```

This fixture has 200 routes and 100,000 trips. Keep the SQL logs and record the executed reads and loaded entities for both sizes.

Run the implementation checks and your own tests:

```sh
docker compose run --rm tests --filter Category=Acceptance
docker compose run --rm tests --filter Category=Student
```

The nine Starter checks pass before you begin. Acceptance checks fail until the application is implemented. `StudentTests.cs` starts empty: add at least four tests and check that they actually run.

For startup problems, check `docker compose logs postgres`. Stop the lab with `docker compose stop`.

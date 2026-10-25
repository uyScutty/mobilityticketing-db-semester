# Design decision

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

Add your sketch of the command/query paths and the tables they use.

Compare two designs in about 150 words. Explain your choice, what a cancellation
would update, and how a published plan keeps its original values. Mark the
transaction boundaries for booking and publication.

ReadOverviewAsync(window)
  -> LiveRouteOverviewQuery
  -> lab07.routes + lab07.trips
  -> SQL projection: route name, COUNT(Scheduled trips), MIN(departure)
  -> RouteOverviewDto[]

CancelTripAsync(tripId)
  -> CancelTripCommand
  -> [transaction + trip row lock]
  -> lab07.trips.status = 'Cancelled' (row retained)

RenameRouteAsync(routeId, name)
  -> RenameRouteCommand
  -> [transaction]
  -> lab07.routes.short_name = trimmed name

BookTripAsync(tripId, requestId)
  -> BookTripCommand
  -> [transaction + request-ID advisory lock + trip row lock]
  -> check existing lab07.bookings request_id first
  -> check current lab07.trips.status, insert lab07.bookings receipt

PublishSnapshotAsync(snapshotId, window)
  -> PublishSnapshotCommand
  -> [transaction + snapshot-ID advisory lock]
  -> check existing lab07.published_plans ID/window
  -> read current lab07.routes + lab07.trips overview
  -> insert lab07.published_plans + lab07.published_plan_rows
  -> SaveChanges -> BeforePublishCommit hook -> COMMIT

ReadSnapshotAsync(snapshotId)
  -> ReadSnapshotQuery
  -> one projected LEFT JOIN of lab07.published_plans and
     lab07.published_plan_rows
  -> PublishedSnapshot with RouteOverviewDto[]


Alternatives and decision (approximately 150 words)
Option A – Direct live projection (chosen): For each board request, query routes and use SQL COUNT and MIN over scheduled trips in the supplied UTC window. The LINQ projection returns only the displayed values, including routes with no matching departures; no Route or Trip entities are materialized. A cancellation updates the authoritative trips.status, and a rename updates routes.short_name; the next successful board query sees the committed values. The design is simple and supports arbitrary valid time windows, at the cost of recalculating aggregates for each request.

Option B – Maintained summary table: Persist counts and next departures per route/window. Reads could be cheaper under high traffic, but every cancellation and schedule change would need coordinated summary updates. Arbitrary windows, invalidation and finding a replacement earliest departure make this considerably more complex. We therefore choose direct projection. Published plans are a separate, intentionally immutable read model: publication copies the route name, count, next departure, time window and timestamp into snapshot tables. Later source-table changes never rewrite a published plan.
Snapshot schema and immutability
- lab07.published_plans: id (PK), from_utc, to_utc, published_at_utc.
- lab07.published_plan_rows: plan_id (FK), route_id, route_name, scheduled_trip_count, next_departure_utc.
- Composite PK (plan_id, route_id) gives each plan at most one row per route.
- A stored route_name deliberately duplicates source data: historic plan names must not change on later renames. A route with zero departures has count 0 and next departure NULL.
- Snapshot reads project persisted values, not joins to current routes or trips. A LEFT JOIN preserves a published header even with no detail rows.
Consistency, validation and transaction boundaries
- TimeWindow.Validate() checks positive UTC intervals of no more than 24 hours and exact PostgreSQL-compatible microsecond endpoints before database access; caller-supplied window endpoints are never rounded.
- Cancellation and booking lock the same trip row to ensure their decisions use the current trip status. A cancelled trip is retained, not deleted. Request-ID locking plus the bookings.request_id primary key protects booking retries; identical retries return the original stored receipt and reusing the ID for another trip returns a conflict.
- The publication transaction includes checking the ID/window, computing the board values, adding the snapshot header and all rows, saving changes, and committing. The stable snapshot:{id} advisory lock coordinates publication retries. Same ID/window returns AlreadyPublished; different window raises a conflict. A BeforePublishCommit failure rolls back the entire write. The overview is calculated with one SQL statement in the transaction for a consistent statement-level view.
- Generated receipt/publication timestamps use the supplied TimeProvider; generated timestamps are reduced to PostgreSQL's microsecond precision so a receipt read after retry matches the first response.
- EF Core's change tracker persists commands, but read paths use projections and AsNoTracking() to avoid unnecessarily tracking entities. DatabaseSession.WriteAsync owns transaction/save/commit behavior.
Measured read-model comparison
Dataset	Strategy	Executed SQL reads	Materialized Route entities	Materialized Trip entities
4 routes / 9 trips	Lazy-loading baseline	5	4	9
4 routes / 9 trips	Live projection	1	0	0
200 routes / 100,000 trips	Lazy-loading baseline	201	200	100,000
200 routes / 100,000 trips	Live projection	1	0	0


Baseline exhibits N+1: first load all routes, then separately load trips for each route. The live projection generates one SQL statement with two correlated aggregates (COUNT, MIN) per route. This removes unnecessary network round trips and entity materialization, but one SQL command is not the same as one index lookup or one scan. The provided (route_id, scheduled_departure_utc) INCLUDE (status) index can help qualifying trip lookups; actual execution-plan choice and latency require EXPLAIN ANALYZE / timing evidence and must not be inferred from command counts alone.

Evidence: docs/evidence/lecture07/logs/ contains SQL files produced by the supplied CLI benchmark commands. Instructor acceptance tests were reported as passing after implementation. Four additional student-authored tests were not completed.  

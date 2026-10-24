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

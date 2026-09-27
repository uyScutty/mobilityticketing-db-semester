# MobilityTicketing – Compulsory Assignment 1

Repositoryet samler arbejdet fra de første fire database-lectures. PostgreSQL
17 startes med Docker Compose fra repository-roden:

```powershell
docker compose up -d --wait
docker compose ps
```

Databasen er tilgængelig på `localhost:5432` med database, user og password
`mobility`. Stop servicen med `docker compose down`. En fuld lokal reset kan
laves med `docker compose down -v` efterfulgt af startkommandoen ovenfor.

Alle reproducerbare tests kan køres samlet:

```powershell
powershell -ExecutionPolicy Bypass -File database/postgres/experiments/run-all.ps1
```

Testene bruger separate databaser fra `mobility_l1_test` til
`mobility_l4_test` og overskriver ikke hoveddatabasen.

## Compulsory Assignment 1 review guide

### Lecture 1 – Introduction to Databases

- [Workload map, relational model og modelling choice](docs/lab.md)
- [Relational schema](database/postgres/init/001_relational_baseline.sql)
- [Seed med trips og en route med 0 trips](database/postgres/init/002_seed.sql)
- [Tre workload queries](database/postgres/init/003_queries.sql)
- [Kørsel og assertions](docs/evidence/lecture01/README.md)

`route_stops` bruger `(route_id, stop_sequence)` som primary key. Det tillader,
at samme stop besøges flere gange på samme route. Den dokumenterede functional
dependency er `(route_id, stop_sequence) -> stop_id`.

### Lecture 2 – SQL Operations

- [Integrity map og constraint-boundaries](docs/integrity-map.md)
- [Selvstændig constraint-migration](database/postgres/migrations/020_enforce_ticketing_integrity.sql)
- [Successful writes](database/postgres/experiments/lecture02/successful_writes.sql)
- [Rejected writes](database/postgres/experiments/lecture02/failed_writes.sql)
- [Faktisk PostgreSQL-evidence](docs/evidence/lecture02/README.md)

Migrationen testes på draft-schemaet uden
`012_completed_integrity.sql`, som fortsat er en separat teaching fixture.
Evidence viser bl.a. `23514`, `23503` og `23505`. Simple constraints løser
ikke konkurrencen mellem samtidige køb af den sidste ledige plads; det kræver
locking, en atomisk betinget update eller passende isolation.

### Lecture 3 – SQL Programmability

- [Design og responsibility decision](docs/lecture03.md)
- [Reporting, trigger og materialized-view migration](database/postgres/migrations/021_add_reporting_programmability.sql)
- [Eksperimenter](database/postgres/experiments/lecture03/)
- [Faktisk PostgreSQL-evidence](docs/evidence/lecture03/README.md)

Route-reportfunktionen returnerer også routes med 0 trips. Triggeren har det
smalle ansvar at skrive en atomisk ticket-status-audit; payment-workflow og
kapacitetskonkurrence forbliver eksplicit applikations-/transaktionslogik.
Materialized-view-eksperimentet dokumenterer et stale resultat på 2 tickets,
mens base-tabellen viser 3, og derefter 3 mod 3 efter refresh.

### Lecture 4 – Schema Migration

- [Migration decision og compatibility matrix](docs/lecture04.md)
- [Product-identity migrations](database/postgres/migrations/)
- [Old/new/final readers, writers og checks](database/postgres/experiments/lecture04/)
- [Faktisk rollout-evidence](docs/evidence/lecture04/README.md)

Forløbet er expand → backfill → contract → legacy removal. Backfill ændrer
først 3 rækker, derefter 0 ved gentagelse og til sidst 1 efter en sen write fra
den gamle writer. Før legacy-kolonnen fjernes, kontrolleres nuller, mismatches,
validerede foreign keys og afhængige databaseobjekter. Lecture 3-viewet bliver
migreret til `product_id` før fjernelsen.

`TICKET-3` er det centrale price/currency-bevis: ticketen forbliver knyttet
til DAY med historisk pris 65 DKK, selv om katalogprisen er 80 DKK. Dermed
behandles ticket-prisen som et købssnapshot og ikke som en dynamisk kopi af
produktets nuværende pris.

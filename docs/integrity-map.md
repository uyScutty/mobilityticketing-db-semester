# Integrity map – Lecture 2

Migrationen i `database/postgres/migrations/020_enforce_ticketing_integrity.sql`
lægger constraints oven på det bevidst ufuldstændige ticketing-schema fra
`010_ticketing_draft.sql`. `012_completed_integrity.sql` er en senere Lecture 4
teaching fixture og er ikke brugt som Lecture 2-migration.

| Invariant / regel | Beskyttelse i databasen | Forventet fejl | Boundary |
|---|---|---|---|
| `trips.capacity >= 0` | `NOT NULL` og `CHECK` | `23502` / `23514` | Afgør ikke, hvem der får den sidste plads ved samtidige køb. |
| `reserved_seats` er mellem 0 og `capacity` | `NOT NULL` og `CHECK` på begge kolonner | `23502` / `23514` | Kræver stadig korrekt locking/transaktionsdesign ved samtidige reservationer. |
| Trip-status er `Scheduled`, `Cancelled` eller `Completed` | `CHECK` | `23514` | Garanterer ikke, at enhver statusovergang er tilladt. |
| Produkt- og ticket-pris er ikke negativ | `NOT NULL` og `CHECK` | `23502` / `23514` | Databasen kan ikke afgøre, om beløbet er den aftalte forretningspris. |
| Currency er tre store bogstaver | `NOT NULL` og regex-`CHECK` | `23502` / `23514` | Formatet beviser ikke, at koden er en tilladt ISO-valuta. |
| En ticket refererer til eksisterende user, trip og product | Tre foreign keys | `23503` | En FK afgør ikke, om en disabled user må købe. |
| `ticket_code` identificerer én ticket | `UNIQUE (ticket_code)` | `23505` | Beskytter kun mod dubletter i denne database. |
| Ticket-status er kendt | `CHECK` | `23514` | Garanterer ikke gyldige statusovergange. |
| Ticket validity slutter tidligst, når den starter | `CHECK (valid_to_utc >= valid_from_utc)` | `23514` | Garanterer ikke, at vinduet matcher produktets forretningsregler. |
| En payment refererer til eksisterende user og ticket | To foreign keys | `23503` | Databasen kan ikke kontrollere gatewayens faktiske capture. |
| To captured payments må ikke dele ekstern reference | Partial unique index på `external_payment_reference` hvor status er `Captured` | `23505` | Forskellige referencer kan stadig dække samme eksterne betaling. |
| En validation bruger ticketens korrekte ID/kode-par | Composite FK til `tickets(id, ticket_code)` | `23503` | Beviser ikke, at scanningen fysisk fandt sted. |
| Et angivet validation-stop skal eksistere | FK fra `validations.stop_id` | `23503` | `stop_id` er fortsat valgfri, når en scanner ikke leverer den. |

## Boundary, som simple constraints ikke løser

To transaktioner kan begge læse den samme sidste ledige plads, før en af dem
opdaterer `reserved_seats`. Row-level constraints beskytter den endelige række,
men de vælger ikke en vinder mellem konkurrerende køb. Det kræver eksempelvis
en atomisk betinget `UPDATE`, row locking eller en passende isolation strategy.

Den eksterne payment gateway er en tilsvarende systemgrænse: databasen kan
afvise en kendt duplicate capture-reference, men kan ikke selv bevise, hvad
gatewayen faktisk har captured.

## Test-evidence

- Positive writes: `database/postgres/experiments/lecture02/successful_writes.sql`
- Afviste writes: `database/postgres/experiments/lecture02/failed_writes.sql`
- Constraint-kontrol: `database/postgres/experiments/lecture02/verify_constraints.sql`
- Reproducerbar runner: `database/postgres/experiments/lecture02/run.ps1`
- Faktiske resultater: `docs/evidence/lecture02/README.md`

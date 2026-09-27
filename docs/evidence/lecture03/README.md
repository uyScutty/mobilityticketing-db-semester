# Lecture 3 evidence

Testdatabasen bygges fra Lecture 1-schema og seed, ticketing-draftet samt den
rigtige Lecture 2-migration. Derefter anvendes Lecture 3-migrationen.

Kør fra repository-roden:

```powershell
powershell -ExecutionPolicy Bypass -File database/postgres/experiments/lecture03/run.ps1
```

## Resultat

Kørt med PostgreSQL 17 i Docker den 27. september 2026. Det fulde output findes
i `test-output.txt`.

| Eksperiment | Resultat |
|---|---|
| Route-reportfunktion | 5C: 2; M2: 2; LINE-12: 0 Scheduled trips |
| Ticket-status-trigger | Skrev audit-rækken `Active` → `Validated` |
| Base table efter ny ticket | 3 SINGLE-tickets |
| Materialized view før refresh | 2 SINGLE-tickets – dokumenteret stale resultat |
| Materialized view efter refresh | 3 SINGLE-tickets – igen i sync |

Trigger- og materialized-view-eksperimenterne slutter med `ROLLBACK`.

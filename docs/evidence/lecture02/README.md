# Lecture 2 evidence

## Test scope

Testdatabasen bygges kun fra `001`, `002`, `010` og `011`, hvorefter den
selvstændige migration `020_enforce_ticketing_integrity.sql` anvendes. Dermed
kommer resultaterne ikke fra den senere `012_completed_integrity.sql` fixture.

Runneren starter selv PostgreSQL-containeren, bygger en isoleret database,
verificerer constraints og kører positive og negative writes:

```powershell
powershell -ExecutionPolicy Bypass -File database/postgres/experiments/lecture02/run.ps1
```

## Resultat

Kørt med PostgreSQL 17 i Docker den 27. september 2026. Det faktiske output
findes i `test-output.txt`.

| Kontrol | Resultat |
|---|---|
| Migration på draft-schema uden `012` | PASS |
| 21 navngivne constraints og partial unique payment-index | PASS |
| Gyldig product, user, ticket, payment og validation write-kæde | PASS |
| Negativ capacity | Afvist med `23514` |
| Ukendt user-reference | Afvist med `23503` |
| Duplicate ticket code | Afvist med `23505` |
| Currency med små bogstaver | Afvist med `23514` |
| Omvendt validity-vindue | Afvist med `23514` |
| Duplicate captured payment-reference | Afvist med `23505` |

De positive og negative tests kører i transaktioner med `ROLLBACK`, så de
efterlader ikke test-rækker. Den separate database hedder `mobility_l2_test`.

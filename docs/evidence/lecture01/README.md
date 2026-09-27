# Lecture 1 evidence

Runneren bygger `mobility_l1_test` kun fra Lecture 1-schema og seed og kører
derefter de tre workload queries og assertions.

```powershell
powershell -ExecutionPolicy Bypass -File database/postgres/experiments/lecture01/run.ps1
```

## Resultat

Kørt med PostgreSQL 17 i Docker den 27. september 2026. Det fulde output findes
i `test-output.txt`.

| Query | Verificeret resultat |
|---|---|
| Næste Scheduled trips for M2 efter 07:30 UTC | 08:00 og 12:00 i korrekt rækkefølge |
| Ordered stops for M2 | Nørreport, Kongens Nytorv, Copenhagen Airport |
| Scheduled trips pr. route | 5C: 2, M2: 2, LINE-12: 0 |

Alle tre assertions bestod, og loggen slutter med `Lecture 1 tests passed.`

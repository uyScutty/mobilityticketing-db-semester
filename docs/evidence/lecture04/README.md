# Lecture 4 evidence

Runneren bygger `mobility_l4_test` fra de tidligere lectures og gennemfører
hele expand–backfill–contract–remove-forløbet.

Kør fra repository-roden:

```powershell
powershell -ExecutionPolicy Bypass -File database/postgres/experiments/lecture04/run.ps1
```

## Verificerede beviser

- Baseline: `TICKET-3` er DAY købt til 65 DKK mod katalogpris 80 DKK: PASS.
- Backfill-runs ændrede henholdsvis 3, 0 og 1 rækker: PASS.
- Den sidste `1` kom fra en sen write fra den gamle writer: PASS.
- New writer lagrede matchende ID/kode og en aftalt pris på 34 DKK: PASS.
- Mismatched ID/kode blev afvist med `23503`: PASS.
- Old writer-formen blev afvist med `23502`, da ID blev obligatorisk: PASS.
- Tre code-relaterede constraints og Lecture 3-viewet blev fundet før removal.
- Final reader/writer og det migrerede materialized view virkede på ID alene.

## Resultat

Kørt med PostgreSQL 17 i Docker den 27. september 2026. Det faktiske output
findes i `test-output.txt` og slutter med `Lecture 4 tests passed.`

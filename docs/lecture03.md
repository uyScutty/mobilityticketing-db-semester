# Lecture 3 – SQL programmability

## Reporting function

`route_schedule_report(service_date)` er den fælles database-definition af
antal `Scheduled` trips pr. route. Den bruger `LEFT JOIN`, så routes uden trips
stadig returneres. Funktionen er markeret `STABLE`, fordi den kun læser data og
skal se et konsistent snapshot inden for samme statement.

## Trigger experiment

Triggeren skriver kun en audit-række, når `tickets.status` faktisk ændres. Det
er et smalt databaseansvar, fordi statusændringen og audit-rækken dermed bliver
atomiske. Triggeren forsøger ikke at styre køb, betaling eller ledig kapacitet.
De workflows kræver eksplicit applikationslogik og transaktionsdesign.

## Materialized-view experiment

`ticket_sales_summary` cacher ticket count og historisk salgsbeløb pr.
produktkode og currency. Eksperimentet indsætter en ticket i en transaktion:
base-table query viser straks 3 SINGLE-tickets, mens viewet stadig viser 2.
Efter `REFRESH MATERIALIZED VIEW` viser begge 3.

Det stale resultat er forventet adfærd, ikke datatab. Consumers, der kræver
aktuelle tal, skal bruge base-tabellerne eller en normal view/function.

## Responsibility decision

| Ansvar | Placering | Begrundelse |
|---|---|---|
| Fælles route-reportdefinition | Databasefunktion | Én konsistent definition for flere consumers. |
| Atomisk status-audit | Databasetrigger | Audit må ikke kunne committe separat fra statusændringen. |
| Payment workflow og kapacitetskonkurrence | Applikation + database-transaktioner | Kræver koordinering og kendskab til eksterne systemer. |
| Refresh af materialized view | Drifts-/applikationsjob | Refresh-frekvens er et freshness/performance-valg. |

## Evidence

- Migration: `database/postgres/migrations/021_add_reporting_programmability.sql`
- Reporting function: `database/postgres/experiments/lecture03/reporting_function.sql`
- Trigger: `database/postgres/experiments/lecture03/trigger_experiment.sql`
- Stale og refreshed view: `database/postgres/experiments/lecture03/materialized_view_experiment.sql`
- Faktiske resultater: `docs/evidence/lecture03/README.md`

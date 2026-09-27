# Lecture 4 – Product identity migration

Produktkoden er menneskeligt læsbar, men kan ændres. `products.id` er derfor
den stabile produktidentitet, mens ticketens `price` og `currency` fortsat er
et historisk købssnapshot og aldrig backfilles fra den aktuelle katalogpris.

## Expand, backfill and contract

1. `030_expand_product_identity.sql` giver produkter UUID'er, tilføjer nullable
   `tickets.product_id` og beholder den gamle kodekontrakt.
2. `031_backfill_ticket_product.sql` udfylder kun nuller. Den køres to gange
   og igen efter en sen write fra den gamle writer.
3. `032_require_ticket_product.sql` validerer begge nye foreign keys og gør
   `product_id` obligatorisk, efter den gamle writer er pensioneret.
4. `033_remove_legacy_product_code.sql` migrerer Lecture 3-viewet til ID,
   fjerner kode-afhængige constraints og fjerner derefter ticket-kolonnen.

Det sammensatte FK-par `(product_id, product_code)` forhindrer en ny writer i
at gemme et ID og en kode for to forskellige produkter under overlapperioden.
En gammel writer kan fortsat skrive med `product_id = null`, indtil cutover.

## Compatibility matrix

| Fase | Old reader | Old writer | Compatibility reader/new writer | ID-only reader/writer |
|---|---|---|---|---|
| Før `030` | Virker | Virker | Ikke deployet | Ikke muligt |
| Efter `030`, før backfill | Virker | Virker | Virker med fallback / begge references | Ikke klar |
| Efter backfill, før `032` | Virker | Virker; sen write giver null ID | Virker | Ikke nødvendig endnu |
| Efter `032` | Virker | Fejler med `23502` | Virker uden nye nuller | Klar |
| Efter `033` | Fejler | Fejler | Legacy fallback kan fjernes | Virker |

## Checks before legacy removal

Før `033` kontrolleres: ingen null IDs, ingen ID/kode-mismatch, validerede
foreign keys, `product_id NOT NULL` og databaseobjekter, der stadig læser
`tickets.product_code`. Kontrollen finder Lecture 3-materialized viewet, som
`033` derfor dropper og genopretter på `product_id`.

Rollback til den gamle applikation er let under overlapperioden. Efter `032`
kræver rollback, at ID-kravet midlertidigt lempes; efter `033` kræver den også,
at ticket-koden rekonstrueres via produkt-ID. Derfor fjernes legacy-kolonnen
først efter reader/writer-cutover og de dokumenterede checks.

## Price and currency evidence

`TICKET-3` købte DAY til 65 DKK, mens katalogprisen er 80 DKK. Baseline,
pre-contract verification og final verification kontrollerer alle, at ticketen
stadig peger på DAY og fortsat har 65 DKK efter migrationerne.

## Evidence

- Migrations: `database/postgres/migrations/030_*.sql` til `033_*.sql`
- Readers/writers/checks: `database/postgres/experiments/lecture04/`
- Faktisk kørsel: `docs/evidence/lecture04/README.md`

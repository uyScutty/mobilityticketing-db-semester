# Setup and reset

Run the commands from the repository root. Docker Desktop must be running.

Start PostgreSQL 17 and wait until it is ready:

```powershell
docker compose up -d --wait
docker compose ps
```

The database is available on `localhost:5432`. The database name, user and
password are all `mobility`.

Run all four reproducible lecture test suites:

```powershell
powershell -ExecutionPolicy Bypass -File database/postgres/experiments/run-all.ps1
```

The suites use separate databases named `mobility_l1_test` through
`mobility_l4_test`; they do not overwrite the main `mobility` database.

Stop the services without deleting their data:

```powershell
docker compose down
```

Perform a full local reset, including the PostgreSQL volume, and start again:

```powershell
docker compose down -v
docker compose up -d --wait
```

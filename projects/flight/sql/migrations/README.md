# SkyHub SQL Migrations

This folder contains the SQL scripts to create schemas, load staging data, build final constrained tables, and transform/load data into the final schema.

## Run order
1. 001_create_schemas.sql
2. 002_create_staging_tables.sql
3. 003_load_staging.sql
4. 004_create_final_tables.sql
5. 005_transform_and_load.sql

Tip: Run each script idempotently; scripts are written to be safe to re-run.

## Data flow
- Staging: raw CSVs, no constraints.
- Final: normalized tables with PK/FK and CHECK constraints.
- Transform: trims/normalizes values and inserts only FK-valid rows.
- Rejects: invalid rows are logged to skyhub.bookings_rejects with a reason.

## Data quality note
Some bookings reference flight_ids that are missing from flights data (e.g., 1, 6, 35). 
This wasn’t intentional in the dataset, so the pipeline captures those bookings as rejects with reason: missing_flight.

## Sanity checks

```sql
-- Count final rows 
SELECT COUNT(_) AS customers FROM skyhub.customers; SELECT COUNT(_) AS flights FROM skyhub.flights; SELECT COUNT(*) AS bookings FROM skyhub.bookings;
-- Rejects summary 
SELECT reject_reason, COUNT(*) FROM skyhub.bookings_rejects GROUP BY reject_reason ORDER BY 2 DESC;
-- Orphan references (should be zero in final tables) 
SELECT COUNT(*) AS missing_flight_refs FROM skyhub.bookings b LEFT JOIN skyhub.flights f ON f.flight_id = b.flight_id WHERE f.flight_id IS NULL;
```

## Remediation (optional)

If you want to load the “missing_flight” rejects, backfill the missing flights with the correct values, then re-run the transform.
```sql
-- Backfill template: replace placeholders with correct airline/origin/destination 
INSERT INTO skyhub.flights (flight_id, airline, origin, destination) VALUES (1, 'AirlineX', 'AAA', 'BBB'), (6, 'AirlineY', 'CCC', 'DDD'), (35, 'AirlineZ', 'EEE', 'FFF') ON CONFLICT (flight_id) DO NOTHING;
-- Re-run the transform/load script 
-- \i 005_transform_and_load.sql
```

## Rerun/reset tips
- Scripts are idempotent; safe to re-run.
- To start fresh, TRUNCATE in dependency order:
```sql
TRUNCATE skyhub.bookings_rejects; 
TRUNCATE skyhub.bookings;
TRUNCATE skyhub.flights;
TRUNCATE skyhub.customers;
```

## Troubleshooting
- FK violation on bookings: ensure flights/customers are loaded first; run “Remediation” or rely on rejects.
- Lots of duplicate rejects: check that you’re using a pre-insert snapshot for duplicate detection or re-run after TRUNCATE if testing repeated loads.

## Commit checkpoints
- Schemas
- Staging tables
- CSV loads
- Final tables (constraints + indexes)
- Transform and rejects pipeline
- Checks and README updates

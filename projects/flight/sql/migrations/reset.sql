-- IMPORTANT:
-- - Execute this script while connected to a maintenance DB (e.g., 'postgres'), NOT 'skyhub_db'.
-- - Ensure DROP DATABASE runs outside a transaction (Auto-commit enabled in your client).
-- - Requires superuser or sufficient privileges to terminate backends.

-- Terminate all other connections to 'skyhub_db' (pre-Postgres 13 approach)
DO
$do$
    BEGIN
        PERFORM pg_terminate_backend(pg_stat_activity.pid)
        FROM pg_stat_activity
        WHERE pg_stat_activity.datname = 'skyhub_db'
          AND pg_stat_activity.pid <> pg_backend_pid();
    END
$do$;

-- Alternative on newer Postgres versions (13+): you can replace the above DO block with:
-- DROP DATABASE IF EXISTS skyhub_db WITH (FORCE);

-- Drop the database if it exists
DROP DATABASE IF EXISTS skyhub_db;

-- Clean up any objects owned by the role (in all DBs) before dropping the role
-- Safe even if the role or its objects don't exist.
DO
$do$
    BEGIN
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'skyhub_owner') THEN
            EXECUTE 'DROP OWNED BY skyhub_owner';
        END IF;
    END
$do$;

-- Drop the role if it exists
DROP ROLE IF EXISTS skyhub_owner;

-- Recreate role
CREATE ROLE skyhub_owner LOGIN PASSWORD 'change_me';

-- Recreate database with owner
CREATE DATABASE skyhub_db OWNER skyhub_owner;

-- psql only: connect to the new database to create schemas
-- If you're using DataGrip, switch your console's database to 'skyhub_db' and run the statements below.
\connect skyhub_db

CREATE SCHEMA IF NOT EXISTS skyhub AUTHORIZATION skyhub_owner;
CREATE SCHEMA IF NOT EXISTS staging AUTHORIZATION skyhub_owner;

-- Optional: set default search path for this role within this DB
ALTER ROLE skyhub_owner IN DATABASE skyhub_db SET search_path = skyhub, public;
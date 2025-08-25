-- Connect to the new database (run this manually or from psql with \c skyhub_db)
-- \c skyhub_db
-- In DataGrip: open a new console on skyhub_db and run:

-- Create schemas (idempotent)
CREATE SCHEMA IF NOT EXISTS skyhub AUTHORIZATION skyhub_owner;
CREATE SCHEMA IF NOT EXISTS staging AUTHORIZATION skyhub_owner;

-- Set search_path for this role (so queries default to skyhub)
ALTER ROLE skyhub_owner IN DATABASE skyhub_db SET search_path = skyhub, public;

-- Grant privileges (extra safety)
GRANT ALL ON SCHEMA skyhub TO skyhub_owner;
GRANT ALL ON SCHEMA staging TO skyhub_owner;

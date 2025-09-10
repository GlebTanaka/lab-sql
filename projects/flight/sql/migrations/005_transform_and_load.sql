-- Load from staging into final (idempotent if PKs enforced and DISTINCT used)

-- Customers
INSERT INTO skyhub.customers (customer_id, name, signup_date, country)
SELECT DISTINCT
  customer_id,
  NULLIF(TRIM(name), '')        AS name,
  signup_date,
  NULLIF(TRIM(country), '')     AS country
FROM staging.customers_raw
WHERE customer_id IS NOT NULL
ON CONFLICT (customer_id) DO NOTHING;

-- Flights
INSERT INTO skyhub.flights (flight_id, airline, origin, destination)
SELECT DISTINCT
  flight_id,
  NULLIF(TRIM(airline), '')     AS airline,
  NULLIF(TRIM(origin), '')      AS origin,
  NULLIF(TRIM(destination), '') AS destination
FROM staging.flights_raw
WHERE flight_id IS NOT NULL
ON CONFLICT (flight_id) DO NOTHING;

-- Bookings
INSERT INTO skyhub.bookings (booking_id, customer_id, flight_id, price, status, booking_date)
SELECT DISTINCT
  booking_id,
  customer_id,
  flight_id,
  price::numeric(10,2),
  LOWER(TRIM(status)) AS status,
  booking_date
FROM staging.bookings_raw
WHERE booking_id IS NOT NULL
ON CONFLICT (booking_id) DO NOTHING;

-- Log rejected bookings (failed FK/constraints or duplicates)
INSERT INTO skyhub.bookings_rejects
  (booking_id, customer_id, flight_id, price_raw, status_raw, booking_date, reject_reason)
SELECT
  b.booking_id,
  b.customer_id,
  b.flight_id,
  b.price,
  b.status,
  b.booking_date,
  CASE
    WHEN f.flight_id IS NULL THEN 'missing_flight'
    WHEN c.customer_id IS NULL THEN 'missing_customer'
    WHEN LOWER(TRIM(b.status)) NOT IN ('confirmed','cancelled') THEN 'bad_status'
    WHEN EXISTS (SELECT 1 FROM skyhub.bookings bk WHERE bk.booking_id = b.booking_id) THEN 'duplicate_booking_id_final'
  END AS reject_reason
FROM staging.bookings_raw b
LEFT JOIN skyhub.flights   f ON f.flight_id   = b.flight_id
LEFT JOIN skyhub.customers c ON c.customer_id = b.customer_id
WHERE b.booking_id IS NOT NULL
  AND (
        f.flight_id IS NULL
     OR c.customer_id IS NULL
     OR LOWER(TRIM(b.status)) NOT IN ('confirmed','cancelled')
     OR EXISTS (SELECT 1 FROM skyhub.bookings bk WHERE bk.booking_id = b.booking_id)
  );

-- Optionally log duplicate booking_ids within staging itself (beyond first occurrence)
WITH dedup AS (
  SELECT
    b.*,
    ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY booking_id) AS rn
  FROM staging.bookings_raw b
  WHERE b.booking_id IS NOT NULL
)
INSERT INTO skyhub.bookings_rejects
  (booking_id, customer_id, flight_id, price_raw, status_raw, booking_date, reject_reason)
SELECT
  d.booking_id, d.customer_id, d.flight_id, d.price, d.status, d.booking_date,
  'duplicate_booking_id_staging' AS reject_reason
FROM dedup d
WHERE d.rn > 1;

-- Optional remediation (data fix):
-- If specific flight_ids are missing from flights.csv but referenced by bookings,
-- you may backfill them here (replace with correct airline/origin/destination).
-- After backfilling, re-run this transform to load the previously rejected bookings.
-- INSERT INTO skyhub.flights (flight_id, airline, origin, destination) VALUES
--   (1,  'AirlineX', 'AAA', 'BBB'),
--   (6,  'AirlineY', 'CCC', 'DDD'),
--   (35, 'AirlineZ', 'EEE', 'FFF')
-- ON CONFLICT (flight_id) DO NOTHING;

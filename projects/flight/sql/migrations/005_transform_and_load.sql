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
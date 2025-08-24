-- Staging tables matching CSVs exactly (no constraints)
CREATE TABLE IF NOT EXISTS staging.customers_raw (
  customer_id   integer,
  name          text,
  signup_date   date,
  country       text
);

CREATE TABLE IF NOT EXISTS staging.flights_raw (
  flight_id     integer,
  airline       text,
  origin        text,
  destination   text
);

CREATE TABLE IF NOT EXISTS staging.bookings_raw (
  booking_id    integer,
  customer_id   integer,
  flight_id     integer,
  price         numeric,
  status        text,
  booking_date  date
);
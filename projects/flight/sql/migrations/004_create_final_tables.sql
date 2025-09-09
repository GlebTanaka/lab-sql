-- Final tables with constraints
CREATE TABLE IF NOT EXISTS skyhub.customers (
  customer_id  integer PRIMARY KEY,
  name         text NOT NULL,
  signup_date  date NOT NULL,
  country      text
);

CREATE TABLE IF NOT EXISTS skyhub.flights (
  flight_id    integer PRIMARY KEY,
  airline      text NOT NULL,
  origin       text NOT NULL,
  destination  text NOT NULL
);

CREATE TABLE IF NOT EXISTS skyhub.bookings (
  booking_id    integer PRIMARY KEY,
  customer_id   integer NOT NULL REFERENCES skyhub.customers(customer_id),
  flight_id     integer NOT NULL REFERENCES skyhub.flights(flight_id),
  price         numeric(10,2) NOT NULL CHECK (price >= 0),
  status        text NOT NULL CHECK (status IN ('confirmed','cancelled')),
  booking_date  date NOT NULL
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_bookings_customer ON skyhub.bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_flight   ON skyhub.bookings(flight_id);
CREATE INDEX IF NOT EXISTS idx_bookings_date     ON skyhub.bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_bookings_status   ON skyhub.bookings(status);

-- Capture rows rejected during bookings load
CREATE TABLE IF NOT EXISTS skyhub.bookings_rejects (
  booking_id    integer,
  customer_id   integer,
  flight_id     integer,
  price_raw     text,
  status_raw    text,
  booking_date  text,
  reject_reason text NOT NULL,
  rejected_at   timestamptz NOT NULL DEFAULT now()
);

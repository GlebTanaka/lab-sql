-- Option A: Use DataGrip UI: right-click each staging table > Import from File…
-- Option B: Use psql client-side \copy (works with local file paths)

-- Adjust paths below. Example for macOS:
-- /Users/yourname/path/to/data/customers.csv

\copy staging.customers_raw (customer_id, name, signup_date, country) FROM '/Users/glebtanaka/practice/lab/lab-sql/projects/flight/customers.csv' WITH (FORMAT csv, HEADER true);

\copy staging.flights_raw (flight_id, airline, origin, destination) FROM '/Users/glebtanaka/practice/lab/lab-sql/projects/flight/flights.csv' WITH (FORMAT csv, HEADER true);

\copy staging.bookings_raw (booking_id, customer_id, flight_id, price, status, booking_date) FROM '/Users/glebtanaka/practice/lab/lab-sql/projects/flight/bookings.csv' WITH (FORMAT csv, HEADER true);

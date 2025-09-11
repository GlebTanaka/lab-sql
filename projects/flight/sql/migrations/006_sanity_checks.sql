-- 006_sanity_checks.sql
-- SkyHub: Sanity checks for staging and final schemas
-- Rerunnable, read-only (no DML)

-- Formatting (psql-friendly; harmless elsewhere)
\echo === SkyHub Sanity Checks ===
\timing on

-- 1) Row counts: staging vs final
\echo -- Row counts
SELECT
    (SELECT COUNT(*) FROM staging.customers_raw) AS stg_customers,
    (SELECT COUNT(*) FROM skyhub.customers)      AS fin_customers,
    (SELECT COUNT(*) FROM staging.flights_raw)   AS stg_flights,
    (SELECT COUNT(*) FROM skyhub.flights)        AS fin_flights,
    (SELECT COUNT(*) FROM staging.bookings_raw)  AS stg_bookings,
    (SELECT COUNT(*) FROM skyhub.bookings)       AS fin_bookings,
    (SELECT COUNT(*) FROM skyhub.bookings_rejects) AS rejects;

-- 2) Rejects summary by reason
\echo -- Rejects summary
SELECT reject_reason, COUNT(*) AS cnt
FROM skyhub.bookings_rejects
GROUP BY reject_reason
ORDER BY cnt DESC, reject_reason;

-- 3) Final integrity: orphan FK checks (should be zero)
\echo -- Orphan checks in final (should be zero)
SELECT
    SUM(CASE WHEN f.flight_id IS NULL THEN 1 ELSE 0 END) AS missing_flight_refs
FROM skyhub.bookings b
         LEFT JOIN skyhub.flights f ON f.flight_id = b.flight_id;

SELECT
    SUM(CASE WHEN c.customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_refs
FROM skyhub.bookings b
         LEFT JOIN skyhub.customers c ON c.customer_id = b.customer_id;

-- 4) Staging data quality: orphans relative to final (informational)
\echo -- Orphan references in staging.bookings_raw vs final flights/customers
SELECT 'missing_flight' AS issue, b.flight_id AS id, COUNT(*) AS cnt
FROM staging.bookings_raw b
         LEFT JOIN skyhub.flights f ON f.flight_id = b.flight_id
WHERE b.flight_id IS NOT NULL AND f.flight_id IS NULL
GROUP BY b.flight_id
ORDER BY cnt DESC
LIMIT 50;

SELECT 'missing_customer' AS issue, b.customer_id AS id, COUNT(*) AS cnt
FROM staging.bookings_raw b
         LEFT JOIN skyhub.customers c ON c.customer_id = b.customer_id
WHERE b.customer_id IS NOT NULL AND c.customer_id IS NULL
GROUP BY b.customer_id
ORDER BY cnt DESC
LIMIT 50;

-- 5) Duplicates
\echo -- Duplicate IDs in staging (beyond first occurrence)
WITH s AS (
    SELECT booking_id, ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY booking_id) AS rn
    FROM staging.bookings_raw
    WHERE booking_id IS NOT NULL
)
SELECT COUNT(*) AS dup_booking_ids_in_staging
FROM s
WHERE rn > 1;

\echo -- Duplicate primary keys in final (should be zero due to PKs)
SELECT
    (SELECT COUNT(*) FROM (SELECT customer_id FROM skyhub.customers GROUP BY customer_id HAVING COUNT(*)>1) x) AS dup_customers,
    (SELECT COUNT(*) FROM (SELECT flight_id   FROM skyhub.flights   GROUP BY flight_id   HAVING COUNT(*)>1) x) AS dup_flights,
    (SELECT COUNT(*) FROM (SELECT booking_id  FROM skyhub.bookings  GROUP BY booking_id  HAVING COUNT(*)>1) x) AS dup_bookings;

-- 6) Status distribution and date ranges
\echo -- Status distribution in final bookings
SELECT status, COUNT(*) AS cnt
FROM skyhub.bookings
GROUP BY status
ORDER BY cnt DESC, status;

\echo -- Booking date range in final bookings
SELECT MIN(booking_date) AS min_booking_date, MAX(booking_date) AS max_booking_date
FROM skyhub.bookings;

-- 7) Basic value sanity: price, nulls
\echo -- Price sanity (negative or NULL should be zero due to CHECK/NOT NULL)
SELECT
    SUM(CASE WHEN price < 0 THEN 1 ELSE 0 END) AS negative_prices,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_prices
FROM skyhub.bookings;

\echo -- Required columns null check (should be zero)
SELECT
    SUM(CASE WHEN booking_id IS NULL THEN 1 ELSE 0 END) AS null_booking_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN flight_id IS NULL THEN 1 ELSE 0 END) AS null_flight_id,
    SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) AS null_status,
    SUM(CASE WHEN booking_date IS NULL THEN 1 ELSE 0 END) AS null_booking_date
FROM skyhub.bookings;

-- 8) Coverage: share of staging bookings that made it to final vs rejects
\echo -- Coverage of staging bookings
WITH base AS (
    SELECT COUNT(*) AS stg_cnt FROM staging.bookings_raw WHERE booking_id IS NOT NULL
),
     fin AS (
         SELECT COUNT(*) AS fin_cnt FROM skyhub.bookings
     ),
     rej AS (
         SELECT COUNT(*) AS rej_cnt FROM skyhub.bookings_rejects
     )
SELECT
    base.stg_cnt,
    fin.fin_cnt,
    rej.rej_cnt,
    ROUND(100.0 * fin.fin_cnt / NULLIF(base.stg_cnt,0), 2) AS pct_loaded,
    ROUND(100.0 * rej.rej_cnt / NULLIF(base.stg_cnt,0), 2) AS pct_rejected
FROM base, fin, rej;

\echo === Done ===
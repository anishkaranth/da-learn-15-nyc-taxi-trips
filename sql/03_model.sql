-- 03_model.sql  Star schema: fact_trips (one row per valid trip) + dim_zone, dim_date, dim_payment, dim_ratecode, dim_vendor.

CREATE OR REPLACE TABLE dim_zone AS
SELECT location_id, borough, zone, service_zone,
       CASE WHEN zone IN ('JFK Airport', 'LaGuardia Airport', 'Newark Airport') THEN 1 ELSE 0 END AS is_airport
FROM cln_zones;

CREATE OR REPLACE TABLE dim_payment AS
SELECT * FROM (VALUES (0, 'Flex fare / unknown'), (1, 'Credit card'), (2, 'Cash'), (3, 'No charge'), (4, 'Dispute'),
                      (5, 'Unknown'), (6, 'Voided trip')) AS t(payment_type, payment_name);

CREATE OR REPLACE TABLE dim_ratecode AS
SELECT * FROM (VALUES (1, 'Standard'), (2, 'JFK flat fare'), (3, 'Newark'), (4, 'Nassau/Westchester'),
                      (5, 'Negotiated'), (6, 'Group ride'), (99, 'Unknown')) AS t(ratecode_id, ratecode_name);

CREATE OR REPLACE TABLE dim_vendor AS
SELECT * FROM (VALUES (1, 'Creative Mobile Technologies'), (2, 'Curb Mobility (VeriFone)'), (6, 'Myle Technologies')) AS t(vendor_id, vendor_name);

CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT CAST(year(pickup_ts) * 10000 + month(pickup_ts) * 100 + day(pickup_ts) AS INT) AS date_key,
  CAST(pickup_ts AS DATE) AS trip_date, dayofweek(pickup_ts) AS day_of_week,
  CASE dayofweek(pickup_ts) WHEN 1 THEN 'Sun' WHEN 2 THEN 'Mon' WHEN 3 THEN 'Tue' WHEN 4 THEN 'Wed'
       WHEN 5 THEN 'Thu' WHEN 6 THEN 'Fri' ELSE 'Sat' END AS day_name,
  CASE WHEN dayofweek(pickup_ts) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend
FROM cln_trips;

CREATE OR REPLACE TABLE fact_trips AS
SELECT
  CAST(year(pickup_ts) * 10000 + month(pickup_ts) * 100 + day(pickup_ts) AS INT) AS date_key,
  hour(pickup_ts) AS pickup_hour, pickup_ts, dropoff_ts,
  pu_location_id, do_location_id, vendor_id, COALESCE(ratecode_id, 99) AS ratecode_id, payment_type,
  passenger_count, trip_distance, ROUND(duration_min, 2) AS duration_min,
  fare_amount, extra, mta_tax, tip_amount, tolls_amount, improvement_surcharge,
  congestion_surcharge, airport_fee, total_amount, dq_unknown_payment
FROM cln_trips;

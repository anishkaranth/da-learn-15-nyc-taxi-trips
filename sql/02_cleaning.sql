-- 02_cleaning.sql  (Spark SQL dialect; DuckDB via 00 shims)
-- types -> derived duration/speed/date parts -> rule-based quality flags -> keep valid January-2024 trips.
-- Rules follow the TLC data dictionary: payment_type 0 = unknown/flex (no passenger/ratecode either),
-- RatecodeID 99 = unknown, negative amounts = refunds/voids.

CREATE OR REPLACE TABLE cln_zones AS
SELECT TRY_CAST(LocationID AS INT) AS location_id, trim(Borough) AS borough, trim(Zone) AS zone, trim(service_zone) AS service_zone
FROM stg_zones WHERE TRY_CAST(LocationID AS INT) IS NOT NULL;

CREATE OR REPLACE TABLE cln_trips_flagged AS
WITH t AS (
  SELECT
    TRY_CAST(VendorID AS INT)                         AS vendor_id,
    CAST(tpep_pickup_datetime AS TIMESTAMP)           AS pickup_ts,
    CAST(tpep_dropoff_datetime AS TIMESTAMP)          AS dropoff_ts,
    TRY_CAST(passenger_count AS INT)                  AS passenger_count,
    TRY_CAST(trip_distance AS DOUBLE)                 AS trip_distance,
    TRY_CAST(RatecodeID AS INT)                       AS ratecode_id,
    TRY_CAST(PULocationID AS INT)                     AS pu_location_id,
    TRY_CAST(DOLocationID AS INT)                     AS do_location_id,
    TRY_CAST(payment_type AS INT)                     AS payment_type,
    TRY_CAST(fare_amount AS DOUBLE)                   AS fare_amount,
    TRY_CAST(extra AS DOUBLE)                         AS extra,
    TRY_CAST(mta_tax AS DOUBLE)                       AS mta_tax,
    TRY_CAST(tip_amount AS DOUBLE)                    AS tip_amount,
    TRY_CAST(tolls_amount AS DOUBLE)                  AS tolls_amount,
    TRY_CAST(improvement_surcharge AS DOUBLE)         AS improvement_surcharge,
    TRY_CAST(congestion_surcharge AS DOUBLE)          AS congestion_surcharge,
    TRY_CAST(Airport_fee AS DOUBLE)                   AS airport_fee,
    TRY_CAST(total_amount AS DOUBLE)                  AS total_amount
  FROM stg_trips
), d AS (
  SELECT *, (unix_timestamp(dropoff_ts) - unix_timestamp(pickup_ts)) / 60.0 AS duration_min FROM t
)
SELECT d.*,
  CASE WHEN pickup_ts < TIMESTAMP'2024-01-01 00:00:00' OR pickup_ts >= TIMESTAMP'2024-02-01 00:00:00' THEN 1 ELSE 0 END AS dq_outside_month,
  CASE WHEN duration_min < 1 OR duration_min > 180 THEN 1 ELSE 0 END                                  AS dq_bad_duration,
  CASE WHEN trip_distance IS NULL OR trip_distance <= 0 OR trip_distance > 100 THEN 1 ELSE 0 END      AS dq_bad_distance,
  CASE WHEN fare_amount IS NULL OR fare_amount <= 0 OR total_amount <= 0 OR fare_amount > 500 THEN 1 ELSE 0 END AS dq_bad_amount,
  CASE WHEN trip_distance > 0 AND duration_min > 0 AND trip_distance / (duration_min / 60.0) > 80 THEN 1 ELSE 0 END AS dq_speed_outlier,
  CASE WHEN payment_type = 0 OR payment_type IS NULL THEN 1 ELSE 0 END                                AS dq_unknown_payment
FROM d;

CREATE OR REPLACE TABLE cln_trips AS
SELECT * FROM cln_trips_flagged
WHERE dq_outside_month = 0 AND dq_bad_duration = 0 AND dq_bad_distance = 0 AND dq_bad_amount = 0 AND dq_speed_outlier = 0;

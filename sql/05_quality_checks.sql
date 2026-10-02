-- 05_quality_checks.sql  before/after counts, DQ issue counts and hard assertions

CREATE OR REPLACE TABLE dq_row_counts AS
SELECT 'trips' AS entity, (SELECT COUNT(*) FROM stg_trips) AS raw_rows, (SELECT COUNT(*) FROM cln_trips) AS clean_rows,
       (SELECT COUNT(*) FROM stg_trips) - (SELECT COUNT(*) FROM cln_trips) AS removed_rows, 'trip' AS grain
UNION ALL SELECT 'zones', (SELECT COUNT(*) FROM stg_zones), (SELECT COUNT(*) FROM cln_zones), 0, 'TLC location'
UNION ALL SELECT 'fact_trips', NULL, (SELECT COUNT(*) FROM fact_trips), NULL, 'trip'
UNION ALL SELECT 'dim_zone', NULL, (SELECT COUNT(*) FROM dim_zone), NULL, 'zone'
UNION ALL SELECT 'dim_date', NULL, (SELECT COUNT(*) FROM dim_date), NULL, 'day'
UNION ALL SELECT 'dim_payment', NULL, (SELECT COUNT(*) FROM dim_payment), NULL, 'payment type';

-- flags overlap, so each count is "rows with this flag" (a trip can fail several rules)
CREATE OR REPLACE TABLE dq_issues AS
SELECT 'pickup outside Jan 2024' AS check_name, (SELECT SUM(dq_outside_month) FROM cln_trips_flagged) AS affected_rows
UNION ALL SELECT 'duration < 1 min or > 3 h (incl. dropoff <= pickup)', (SELECT SUM(dq_bad_duration) FROM cln_trips_flagged)
UNION ALL SELECT 'distance <= 0 or > 100 mi', (SELECT SUM(dq_bad_distance) FROM cln_trips_flagged)
UNION ALL SELECT 'fare <= 0, total <= 0 or fare > $500 (refunds/voids)', (SELECT SUM(dq_bad_amount) FROM cln_trips_flagged)
UNION ALL SELECT 'implied speed > 80 mph', (SELECT SUM(dq_speed_outlier) FROM cln_trips_flagged)
UNION ALL SELECT 'payment_type 0 (flex/unknown; kept, flagged)', (SELECT SUM(dq_unknown_payment) FROM cln_trips_flagged)
UNION ALL SELECT 'passenger_count NULL (kept)', (SELECT COUNT(*) FROM cln_trips_flagged WHERE passenger_count IS NULL)
UNION ALL SELECT 'passenger_count 0 (kept)', (SELECT COUNT(*) FROM cln_trips_flagged WHERE passenger_count = 0)
UNION ALL SELECT 'pickup zone 264/265 (unknown / outside NYC)', (SELECT COUNT(*) FROM cln_trips WHERE pu_location_id IN (264, 265))
UNION ALL SELECT 'total rows removed', (SELECT COUNT(*) FROM stg_trips) - (SELECT COUNT(*) FROM cln_trips);

CREATE OR REPLACE TABLE dq_assertions AS
WITH c AS (
  SELECT 'every clean trip is in fact_trips' AS check_name, (SELECT COUNT(*) FROM cln_trips) - (SELECT COUNT(*) FROM fact_trips) AS failed_rows
  UNION ALL SELECT 'all pickups within Jan 2024', (SELECT COUNT(*) FROM fact_trips WHERE pickup_ts < TIMESTAMP'2024-01-01 00:00:00' OR pickup_ts >= TIMESTAMP'2024-02-01 00:00:00')
  UNION ALL SELECT 'pickup zone exists in dim_zone', (SELECT COUNT(*) FROM fact_trips f LEFT JOIN dim_zone z ON z.location_id = f.pu_location_id WHERE z.location_id IS NULL)
  UNION ALL SELECT 'dropoff zone exists in dim_zone', (SELECT COUNT(*) FROM fact_trips f LEFT JOIN dim_zone z ON z.location_id = f.do_location_id WHERE z.location_id IS NULL)
  UNION ALL SELECT 'payment type exists in dim_payment', (SELECT COUNT(*) FROM fact_trips f LEFT JOIN dim_payment p ON p.payment_type = f.payment_type WHERE p.payment_type IS NULL)
  UNION ALL SELECT 'date exists in dim_date', (SELECT COUNT(*) FROM fact_trips f LEFT JOIN dim_date d ON d.date_key = f.date_key WHERE d.date_key IS NULL)
  UNION ALL SELECT 'positive fare, distance, duration', (SELECT COUNT(*) FROM fact_trips WHERE fare_amount <= 0 OR trip_distance <= 0 OR duration_min < 1)
  UNION ALL SELECT 'hourly trips sum = fact rows', (SELECT ABS((SELECT SUM(trips) FROM a_hourly) - (SELECT COUNT(*) FROM fact_trips)))
  UNION ALL SELECT 'zone lookup ids unique', (SELECT COUNT(*) - COUNT(DISTINCT location_id) FROM dim_zone)
)
SELECT check_name, failed_rows, CASE WHEN failed_rows = 0 THEN 'PASS' ELSE 'FAIL' END AS status FROM c;

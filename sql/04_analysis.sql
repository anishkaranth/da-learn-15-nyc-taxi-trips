-- 04_analysis.sql  KPIs and business questions (valid trips only)

CREATE OR REPLACE TABLE a_kpi_headline AS
SELECT COUNT(*) AS trips,
  ROUND(COUNT(*) / COUNT(DISTINCT f.date_key), 0) AS avg_trips_per_day,
  ROUND(SUM(f.total_amount), 2) AS gross_revenue,
  ROUND(AVG(f.fare_amount), 2) AS avg_fare,
  ROUND(AVG(f.total_amount), 2) AS avg_total,
  ROUND(AVG(f.trip_distance), 2) AS avg_distance_mi,
  ROUND(AVG(f.duration_min), 2) AS avg_duration_min,
  ROUND(100.0 * SUM(CASE WHEN f.payment_type = 1 THEN f.tip_amount END) / SUM(CASE WHEN f.payment_type = 1 THEN f.fare_amount END), 2) AS card_tip_pct_of_fare,
  ROUND(100.0 * AVG(CASE WHEN f.payment_type = 1 THEN 1.0 ELSE 0.0 END), 2) AS card_share_pct,
  ROUND(100.0 * AVG(CASE WHEN z.is_airport = 1 THEN 1.0 ELSE 0.0 END), 2) AS airport_pickup_share_pct
FROM fact_trips f LEFT JOIN dim_zone z ON z.location_id = f.pu_location_id;

-- Q1: demand by hour of day (weekday vs weekend averages per day)
CREATE OR REPLACE TABLE a_hourly AS
WITH n AS (SELECT SUM(1 - is_weekend) AS weekdays, SUM(is_weekend) AS weekend_days FROM dim_date)
SELECT f.pickup_hour, COUNT(*) AS trips,
  ROUND(SUM(CASE WHEN d.is_weekend = 0 THEN 1 ELSE 0 END) / NULLIF(MAX(n.weekdays), 0), 1) AS avg_weekday_trips,
  ROUND(SUM(CASE WHEN d.is_weekend = 1 THEN 1 ELSE 0 END) / NULLIF(MAX(n.weekend_days), 0), 1) AS avg_weekend_trips,
  ROUND(AVG(f.fare_amount), 2) AS avg_fare,
  ROUND(SUM(f.trip_distance) / (SUM(f.duration_min) / 60.0), 2) AS avg_speed_mph
FROM fact_trips f JOIN dim_date d ON d.date_key = f.date_key CROSS JOIN n
GROUP BY f.pickup_hour;

CREATE OR REPLACE TABLE a_daily AS
SELECT d.trip_date, d.day_name, COUNT(*) AS trips, ROUND(SUM(f.total_amount), 2) AS revenue
FROM fact_trips f JOIN dim_date d ON d.date_key = f.date_key
GROUP BY d.trip_date, d.day_name;

CREATE OR REPLACE TABLE a_day_of_week AS
SELECT d.day_of_week, d.day_name, COUNT(*) AS trips, COUNT(DISTINCT d.date_key) AS days,
  ROUND(COUNT(*) / COUNT(DISTINCT d.date_key), 0) AS avg_trips_per_day
FROM fact_trips f JOIN dim_date d ON d.date_key = f.date_key
GROUP BY d.day_of_week, d.day_name;

-- Q2: where - pickup zones and boroughs
CREATE OR REPLACE TABLE a_pickup_zones AS
SELECT z.zone, z.borough, COUNT(*) AS trips, ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct,
  ROUND(AVG(f.fare_amount), 2) AS avg_fare, ROUND(AVG(f.trip_distance), 2) AS avg_distance_mi
FROM fact_trips f JOIN dim_zone z ON z.location_id = f.pu_location_id
GROUP BY z.zone, z.borough;

CREATE OR REPLACE TABLE a_borough AS
SELECT z.borough AS pickup_borough, COUNT(*) AS trips, ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct,
  ROUND(AVG(f.fare_amount), 2) AS avg_fare, ROUND(AVG(f.trip_distance), 2) AS avg_distance_mi,
  ROUND(100.0 * SUM(CASE WHEN f.payment_type = 1 THEN f.tip_amount END) / SUM(CASE WHEN f.payment_type = 1 THEN f.fare_amount END), 2) AS card_tip_pct
FROM fact_trips f JOIN dim_zone z ON z.location_id = f.pu_location_id
GROUP BY z.borough;

CREATE OR REPLACE TABLE a_od_pairs AS
SELECT pz.zone AS pickup_zone, dz.zone AS dropoff_zone, COUNT(*) AS trips, ROUND(AVG(f.fare_amount), 2) AS avg_fare
FROM fact_trips f JOIN dim_zone pz ON pz.location_id = f.pu_location_id JOIN dim_zone dz ON dz.location_id = f.do_location_id
GROUP BY pz.zone, dz.zone
ORDER BY trips DESC, pickup_zone, dropoff_zone
LIMIT 15;

-- Q3: fares and tips
CREATE OR REPLACE TABLE a_payment AS
SELECT p.payment_name, COUNT(*) AS trips, ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct,
  ROUND(AVG(f.total_amount), 2) AS avg_total, ROUND(100.0 * SUM(f.tip_amount) / NULLIF(SUM(f.fare_amount), 0), 2) AS tip_pct_of_fare
FROM fact_trips f JOIN dim_payment p ON p.payment_type = f.payment_type
GROUP BY p.payment_name;

CREATE OR REPLACE TABLE a_distance_bands AS
SELECT CASE WHEN trip_distance < 1 THEN '1 <1 mi' WHEN trip_distance < 2 THEN '2 1-2 mi' WHEN trip_distance < 5 THEN '3 2-5 mi'
            WHEN trip_distance < 10 THEN '4 5-10 mi' WHEN trip_distance < 20 THEN '5 10-20 mi' ELSE '6 20+ mi' END AS distance_band,
  COUNT(*) AS trips, ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct,
  ROUND(AVG(fare_amount), 2) AS avg_fare, ROUND(SUM(fare_amount) / SUM(trip_distance), 2) AS fare_per_mile,
  ROUND(AVG(duration_min), 1) AS avg_duration_min,
  ROUND(100.0 * SUM(CASE WHEN payment_type = 1 THEN tip_amount END) / SUM(CASE WHEN payment_type = 1 THEN fare_amount END), 2) AS card_tip_pct
FROM fact_trips GROUP BY 1;

CREATE OR REPLACE TABLE a_airports AS
SELECT z.zone AS airport, COUNT(*) AS pickups, ROUND(AVG(f.fare_amount), 2) AS avg_fare,
  ROUND(AVG(f.total_amount), 2) AS avg_total, ROUND(AVG(f.trip_distance), 2) AS avg_distance_mi,
  ROUND(100.0 * AVG(CASE WHEN f.ratecode_id = 2 THEN 1.0 ELSE 0.0 END), 2) AS jfk_flat_fare_pct
FROM fact_trips f JOIN dim_zone z ON z.location_id = f.pu_location_id
WHERE z.is_airport = 1 GROUP BY z.zone;

"""Project config shared by run_pipeline.py, build_databricks.py (and the Databricks deploy)."""
REPO = "da-learn-15-nyc-taxi-trips"
NN = "15"
DASH_TITLE = "NYC yellow taxi trips - January 2024"
DASH_NAME = "da-learn-15 NYC taxi trips"
NOTEBOOK = "nyc_taxi_pipeline_notebook"
DASH_FILE = "nyc_taxi_dashboard"
CURRENCY = "USD"
DATASET = "NYC TLC Yellow Taxi Trip Records, January 2024 (yellow_tripdata_2024-01.parquet) + Taxi Zone Lookup"
RAW = {"stg_trips": {"file": "yellow_tripdata_2024-01.parquet", "format": "parquet"},
       "stg_zones": {"file": "taxi_zone_lookup.csv", "format": "csv"}}
RAW_FILES = [v["file"] for v in RAW.values()]
# sample mode: same columns as CSV (git cannot hold a meaningful parquet sample as text)
SAMPLE_FILES = {"yellow_tripdata_2024-01.parquet": "yellow_tripdata_2024-01_sample.csv"}
CLEAN = ["cln_zones", "cln_trips_flagged", "cln_trips"]
STAR = ["fact_trips", "dim_zone", "dim_date", "dim_payment", "dim_ratecode", "dim_vendor"]
PBI_CAP = {"fact_trips": 30, "dim_zone": 40, "dim_date": 31}
_F = "date_key = 20240115 AND pickup_hour = 8 AND minute(pickup_ts) = 0"
PBI_SAMPLE_FILTER = {"fact_trips": _F,
                     "dim_zone": f"location_id IN (SELECT pu_location_id FROM fact_trips WHERE {_F} UNION SELECT do_location_id FROM fact_trips WHERE {_F})"}
COMPARE_TABLES = ["a_kpi_headline", "a_hourly", "a_day_of_week", "a_borough", "a_payment", "a_distance_bands", "a_airports", "dq_issues"]
SHOT_CONFIG = {"engine": "duckdb (local, full data) + Databricks serverless SQL", "sql_dialect": "Spark/Databricks SQL + DuckDB shims (sql/00)",
               "month": "2024-01 (pickup timestamp)", "valid_trip": "pickup in month, 1-180 min, 0-100 mi, fare 0-500, total > 0, speed <= 80 mph",
               "tip_pct": "tip / fare on credit-card trips (cash tips are not recorded)",
               "sample_rule": "data/raw = first pickup of each hour on 2024-01-15 + first row breaking each of 6 rules (5 rows), as CSV; zones used by those rows"}
SHOT_QUERIES = {
    "peak_hours": "SELECT pickup_hour, trips, avg_speed_mph FROM a_hourly ORDER BY trips DESC LIMIT 3",
    "boroughs": "SELECT pickup_borough, trips, share_pct, avg_fare FROM a_borough ORDER BY trips DESC",
    "top5_zones": "SELECT zone, trips, share_pct FROM a_pickup_zones ORDER BY trips DESC LIMIT 5",
    "payment": "SELECT payment_name, share_pct, tip_pct_of_fare FROM a_payment ORDER BY trips DESC",
    "airports": "SELECT * FROM a_airports ORDER BY pickups DESC",
}
METRIC_QUERIES = {
    "hourly": "SELECT * FROM a_hourly ORDER BY pickup_hour",
    "day_of_week": "SELECT * FROM a_day_of_week ORDER BY day_of_week",
    "borough": "SELECT * FROM a_borough ORDER BY trips DESC",
    "top10_pickup_zones": "SELECT * FROM a_pickup_zones ORDER BY trips DESC LIMIT 10",
    "top10_od_pairs": "SELECT * FROM a_od_pairs ORDER BY trips DESC LIMIT 10",
    "payment": "SELECT * FROM a_payment ORDER BY trips DESC",
    "distance_bands": "SELECT * FROM a_distance_bands ORDER BY distance_band",
    "airports": "SELECT * FROM a_airports ORDER BY pickups DESC",
    "busiest_days": "SELECT * FROM a_daily ORDER BY trips DESC LIMIT 3",
    "quietest_days": "SELECT * FROM a_daily ORDER BY trips LIMIT 3",
}
CARDS = [("trips", "Valid trips", "{:,}"), ("avg_trips_per_day", "Trips / day", "{:,.0f}"), ("gross_revenue", "Gross revenue", "${:,.0f}"),
         ("avg_fare", "Avg fare", "${:.2f}"), ("avg_distance_mi", "Avg distance (mi)", "{:.2f}"),
         ("avg_duration_min", "Avg duration (min)", "{:.1f}"), ("card_tip_pct_of_fare", "Card tip % of fare", "{:.1f}%")]
DASH_KPI_SQL = "SELECT trips, gross_revenue, avg_fare, card_tip_pct_of_fare / 100 AS card_tip_rate FROM {S}a_kpi_headline"
COUNTERS = [("trips", "Valid trips (Jan 2024)", "num"), ("card_tip_rate", "Card tip as % of fare", "pct")]
DASH_NOTE = "Source: NYC TLC Trip Record Data, yellow taxi, January 2024 (public). Valid trips only. Tables: workspace.da_learn_15."
VIZ = [
    {"name": "hourly_demand", "title": "Trips by pickup hour", "kind": "bar", "x": "pickup_hour", "y": "trips", "fmt": "{:,.0f}",
     "sql": "SELECT pickup_hour, trips FROM {S}a_hourly ORDER BY pickup_hour"},
    {"name": "daily_trips", "title": "Trips per day (Jan 2024)", "kind": "line", "x": "trip_date", "y": "trips", "fmt": "{:,.0f}",
     "sql": "SELECT CAST(trip_date AS STRING) AS trip_date, trips FROM {S}a_daily ORDER BY trip_date"},
    {"name": "top_pickup_zones", "title": "Top 10 pickup zones", "kind": "hbar", "x": "zone", "y": "trips", "fmt": "{:,.0f}",
     "sql": "SELECT zone, trips FROM {S}a_pickup_zones ORDER BY trips DESC LIMIT 10"},
    {"name": "fare_per_mile", "title": "Fare per mile by trip distance ($)", "kind": "bar", "x": "distance_band", "y": "fare_per_mile", "fmt": "${:.2f}",
     "sql": "SELECT distance_band, fare_per_mile FROM {S}a_distance_bands ORDER BY distance_band"},
    {"name": "tip_by_distance", "title": "Card tip % of fare by trip distance", "kind": "bar", "x": "distance_band", "y": "card_tip_pct", "fmt": "{:.1f}%",
     "sql": "SELECT distance_band, card_tip_pct FROM {S}a_distance_bands ORDER BY distance_band"},
    {"name": "payment_mix", "title": "Share of trips by payment type (%)", "kind": "hbar", "x": "payment_name", "y": "share_pct", "fmt": "{:.1f}%",
     "sql": "SELECT payment_name, share_pct FROM {S}a_payment ORDER BY share_pct DESC"},
]

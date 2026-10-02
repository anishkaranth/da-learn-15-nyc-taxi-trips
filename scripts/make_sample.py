#!/usr/bin/env python3
"""Build the git-sized raw sample in data/raw/ from data/raw_full/ (deterministic).

Rule: the first pickup of every hour on Mon 2024-01-15 (24 trips) plus the first row breaking each cleaning rule
(outside month, bad duration, zero distance, non-positive fare, >80 mph, payment_type 0), written as CSV with the
Parquet column names; zone lookup rows limited to the zones those trips use."""
import pathlib
import duckdb

ROOT = pathlib.Path(__file__).resolve().parents[1]
FULL, OUT = ROOT / "data/raw_full", ROOT / "data/raw"
OUT.mkdir(parents=True, exist_ok=True)
con = duckdb.connect()
con.execute(f"CREATE TABLE t AS SELECT * FROM '{FULL}/yellow_tripdata_2024-01.parquet'")
dur = "epoch(tpep_dropoff_datetime) - epoch(tpep_pickup_datetime)"
rules = ["tpep_pickup_datetime < TIMESTAMP '2024-01-01'", f"{dur} <= 0", "trip_distance = 0", "fare_amount < 0",
         f"trip_distance > 0 AND {dur} > 0 AND trip_distance * 3600.0 / ({dur}) > 80", "payment_type = 0"]
parts = ["(SELECT * FROM t WHERE CAST(tpep_pickup_datetime AS DATE) = DATE '2024-01-15' "
         "QUALIFY ROW_NUMBER() OVER (PARTITION BY hour(tpep_pickup_datetime) ORDER BY tpep_pickup_datetime, PULocationID, DOLocationID) = 1)"]
parts += [f"(SELECT * FROM t WHERE {r} ORDER BY tpep_pickup_datetime, PULocationID, DOLocationID, fare_amount LIMIT 1)" for r in rules]
con.execute("CREATE TABLE s AS " + " UNION ".join(parts))
con.execute(f"COPY (SELECT * FROM s ORDER BY tpep_pickup_datetime, PULocationID) TO '{OUT}/yellow_tripdata_2024-01_sample.csv' (HEADER)")
con.execute(f"""COPY (SELECT * FROM read_csv('{FULL}/taxi_zone_lookup.csv', all_varchar = true)
  WHERE CAST(LocationID AS INT) IN (SELECT PULocationID FROM s UNION SELECT DOLocationID FROM s) ORDER BY CAST(LocationID AS INT))
  TO '{OUT}/taxi_zone_lookup.csv' (HEADER, FORCE_QUOTE *)""")
print(con.sql("SELECT COUNT(*) FROM s").fetchone()[0], "trips")

# Databricks setup

1. **Schema and volume:** run the config cell in the notebook, or `CREATE SCHEMA IF NOT EXISTS workspace.da_learn_15; CREATE VOLUME IF NOT EXISTS workspace.da_learn_15.raw;`
2. **Upload the full raw files** (from `python scripts/download_full_data.py`) to `/Volumes/workspace/da_learn_15/raw/`. Use Catalog Explorer → Volume → *Upload*, or `databricks fs cp data/raw_full/yellow_tripdata_2024-01.parquet dbfs:/Volumes/workspace/da_learn_15/raw/` (and the same for `taxi_zone_lookup.csv`).
3. **Import** `nyc_taxi_pipeline_notebook.sql` into `/Workspace/Shared/da-learn-15-nyc-taxi-trips/`. Attach it to a SQL warehouse (this run used *Serverless Starter Warehouse*) and choose **Run all**. That covers staging (`read_files`), cleaning, the star schema, analysis and DQ.
4. **Dashboard:** in Dashboards, choose *Import* and select `nyc_taxi_dashboard.lvdash.json`. Choose warehouse → *Publish*. It has 8 widgets: 2 counters (valid trips, card tip %), trips by hour, trips per day, top pickup zones, fare per mile by distance, card tip % by distance and payment mix. Every dataset reads `workspace.da_learn_15.a_*`.
5. **Check parity:** `run_outputs/duckdb_vs_databricks.json` records the 2026-10-02 run. All 11 pipeline tables have equal row counts (stg_trips 2,964,624; fact_trips 2,858,847), and 9 analysis/DQ tables have 0 differing cells.

Dialect notes: the SQL in `sql/` is written to run on both engines. `sql/00_duckdb_compat.sql` adds DuckDB macros for Spark functions (`unix_timestamp`, `dayofweek`, `to_date`, `percentile_approx`). QUALIFY over aggregates is avoided because Databricks rejects it.

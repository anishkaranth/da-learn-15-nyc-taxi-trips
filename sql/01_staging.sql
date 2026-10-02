-- 01_staging.sql  Land the TLC trip file and the zone lookup as-is. {{RAW_DIR}} is set by run_pipeline.py.
-- Full run reads the official Parquet; the committed sample is the same columns as CSV (run_pipeline swaps the name).
-- Databricks: read_files('<volume>/yellow_tripdata_2024-01.parquet', format => 'parquet') and read_files(... csv ...)
CREATE OR REPLACE TABLE stg_trips AS
SELECT * FROM '{{RAW_DIR}}/yellow_tripdata_2024-01.parquet';

CREATE OR REPLACE TABLE stg_zones AS
SELECT * FROM read_csv('{{RAW_DIR}}/taxi_zone_lookup.csv', header = true, all_varchar = true);

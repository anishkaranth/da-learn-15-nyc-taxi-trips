# data/

- `raw/yellow_tripdata_2024-01_sample.csv` is a 29-row sample of the real TLC file, built by `scripts/make_sample.py`. It holds the first pickup of each hour on Mon 2024-01-15 (24 trips) plus the first real row that breaks each cleaning rule: a 2002 timestamp that is also a negative-fare refund, dropoff ≤ pickup, zero distance, >80 mph (2.3 mi in 19 s) and payment_type 0. Columns and names match the Parquet file.
- `raw/taxi_zone_lookup.csv` holds the 33 zone rows referenced by the sample, unchanged from TLC.
- `raw_full/` (git-ignored) holds the full month, fetched by `python scripts/download_full_data.py` (~50 MB, SHA-256 verified).
- `clean_full/` (git-ignored) holds the full star-schema CSV exports written by the runner.

Source: NYC TLC Trip Record Data (https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page), NYC Open Data terms of use. Data dictionary: https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf

# Power BI model (star schema)

| Table | Grain | Key | Notes |
|---|---|---|---|
| fact_trips | one valid trip | (none) | date_key, pickup_hour, pu/do_location_id, vendor_id, ratecode_id, payment_type, passenger_count, trip_distance, duration_min, fare and surcharge columns, total_amount, dq_unknown_payment |
| dim_date | day | date_key | trip_date, day_of_week (1 = Sun), day_name, is_weekend |
| dim_zone | TLC zone | location_id | borough, zone, service_zone, is_airport |
| dim_payment | payment code | payment_type | payment_name |
| dim_ratecode | rate code | ratecode_id | ratecode_name (99 = unknown/NULL) |
| dim_vendor | TPEP vendor | vendor_id | vendor_name |

Relationships (single direction, many-to-one, from fact to dimension):
- fact_trips[date_key] → dim_date[date_key]
- fact_trips[pu_location_id] → dim_zone[location_id] (**active**, "Pickup zone")
- fact_trips[do_location_id] → dim_zone[location_id] (**inactive**; activate it with USERELATIONSHIP in dropoff measures, or import dim_zone a second time as "Dropoff zone")
- fact_trips[payment_type] → dim_payment[payment_type]
- fact_trips[ratecode_id] → dim_ratecode[ratecode_id]
- fact_trips[vendor_id] → dim_vendor[vendor_id]

`powerbi/data/` is sample-sized: 30 trips (08:00 on 2024-01-15), the zones they touch and all 31 dates. Run `python run_pipeline.py --source full` and point Power BI at `data/clean_full/star/` for the full 2.86M-row fact table.

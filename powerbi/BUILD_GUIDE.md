# Build guide (Power BI Desktop)

1. **Get data → Text/CSV:** load the six files in `powerbi/data/`, or `data/clean_full/star/` after a full run. Set date_key, location ids and codes to *Whole number*, pickup_ts/dropoff_ts to *Date/Time*, money columns to *Fixed decimal* and trip_date to *Date*.
2. **Model view:** create the relationships in `model.md`. Mark dim_date as a date table on trip_date. Leave the dropoff → dim_zone relationship inactive.
3. **Distance band:** add a calculated column on fact_trips:
   `Distance Band = SWITCH(TRUE(), fact_trips[trip_distance] < 1, "1 <1 mi", fact_trips[trip_distance] < 2, "2 1-2 mi", fact_trips[trip_distance] < 5, "3 2-5 mi", fact_trips[trip_distance] < 10, "4 5-10 mi", fact_trips[trip_distance] < 20, "5 10-20 mi", "6 20+ mi")`
4. **Measures:** create a blank *_Measures* table and paste each line of `measures.dax` as a new measure. Format the % measures as percentages and the money measures as currency ($).
5. **Visuals:** follow `dashboard_spec.md`. Sort the hour axis ascending and the distance bands by name (the numeric prefix keeps them in order).
6. **Validate:** on full data the cards must equal `results/metrics.json` (2,858,847 trips; $78,041,996). On the sample, expect 30 trips.

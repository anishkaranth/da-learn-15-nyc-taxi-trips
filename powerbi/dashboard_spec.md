# Power BI dashboard spec: "NYC Taxi January 2024"

**Page 1 Overview** (these are the full-data targets to check against `results/metrics.json`)
- KPI cards: Trips (2,858,847), Trips per Day (92,221), Gross Revenue ($78.04M), Avg Fare ($18.45), Avg Distance (3.30), Card Tip % of Fare (22.64%)
- Column chart: Trips by fact_trips[pickup_hour] (peak at 18:00 = 205,643)
- Line chart: Trips by dim_date[trip_date] (low 64,871 on 01-07, high 106,815 on 01-27)
- Clustered column: Weekday vs Weekend Trips per Day by pickup_hour

**Page 2 Where and how**
- Bar chart: top 10 dim_zone[zone] by Trips (Upper East Side South 139,822)
- Donut: Trips by dim_zone[borough] (Manhattan 89.75%)
- Column chart: Fare per Mile by a distance-band calculated column (<1, 1–2, 2–5, 5–10, 10–20, 20+ mi). Expect $10.78 down to $3.75.
- Bar chart: Card Share by dim_payment[payment_name]
- Table: airports (dim_zone[is_airport] = 1) with Trips, Avg Fare, Avg Total

**Slicers:** dim_date[day_name], dim_date[is_weekend], dim_zone[borough], dim_vendor[vendor_name]

**Theme:** a single teal accent (#1f6f8b) to match `results/charts/dashboard.svg`.

#!/usr/bin/env python3
"""Download the full NYC TLC yellow-taxi month used by this project into data/raw_full/ and verify SHA-256.

Source  : NYC Taxi & Limousine Commission, TLC Trip Record Data
          https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page (files served from d37ci6vzurychx.cloudfront.net)
Kaggle  : https://www.kaggle.com/datasets/usmanshams/nyc-yellow-taxi-dataset-2024 (same monthly Parquet files, re-hosted)
Licence : NYC public data, published by TLC under the NYC Open Data terms of use (free to use, no warranty).
Month   : January 2024 only (one documented month keeps the run under a minute on a laptop).
"""
import hashlib, pathlib, urllib.request

FILES = {
    "yellow_tripdata_2024-01.parquet": ("https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet",
                                        "c4d59da7bbc8abaeeeb1727947ee93d9891a71acb42854bd80db1571b2030510"),
    "taxi_zone_lookup.csv": ("https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv",
                             "1a99e105092230f8620f301edcca7f80d3080642ff404d28ed957d3fa222c8ed"),
}
out = pathlib.Path(__file__).resolve().parents[1] / "data" / "raw_full"
out.mkdir(parents=True, exist_ok=True)
ok = True
for name, (url, sha) in FILES.items():
    p = out / name
    if not p.exists():
        print("downloading", url)
        urllib.request.urlretrieve(url, p)
    got = hashlib.sha256(p.read_bytes()).hexdigest()
    ok &= got == sha
    print(f"{name} {p.stat().st_size:,} bytes  {'OK' if got == sha else 'CHECKSUM MISMATCH ' + got}")
raise SystemExit(0 if ok else 1)

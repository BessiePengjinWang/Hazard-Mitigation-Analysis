# scripts/

Numbered, run-in-order pipeline that turns the raw FEMA/Census extracts in
`data/raw/` into the small artifacts the app reads from `data/processed/`
and `models/`. Nothing in `app/` trains a model or re-parses a raw CSV -
that all happens here, once.

| Script | Produces | Depends on |
|---|---|---|
| `01_download_data.R` | `data/raw/*.csv`, `data/raw/2023_Gaz_zcta_national.txt` | network access |
| `02_geocode_mission_assignments.R` | `data/processed/mission_assignments_geocoded.csv` | 01 |
| `03_fund_allocation_summary.R` | `data/processed/state_obligation_summary.csv`, `incident_type_funding_summary.csv`, `fund_allocation_correlation.csv` | 01 |
| `04_feature_importance_model.R` | `models/federal_share_rf.rds`, `data/processed/federal_share_feature_importance.csv` | 01 |
| `05_ny_incident_forecast_model.R` | `models/ny_incident_rf.rds`, `data/processed/ny_2024_incident_forecast.csv` | 01 |
| `00_run_all.R` | runs 02-05 in order | 01 |

Run the whole pipeline with:

```r
Rscript scripts/01_download_data.R   # skip if data/raw/ is already populated
Rscript scripts/00_run_all.R
```

All random forests are fit with `set.seed(123)` (see `lib/modeling.R`), so
re-running the pipeline against the same `data/raw/` reproduces identical
`data/processed/*.csv` output byte-for-byte.

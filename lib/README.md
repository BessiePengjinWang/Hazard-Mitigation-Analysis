# lib/

Reusable function definitions only - nothing in this folder executes on its
own. The numbered scripts in [`scripts/`](../scripts) and the app in
[`app/`](../app) `source()` these files.

- **utils.R** - small shared helpers: `clean_zip5()` (zero-pads/validates US
  ZIP codes), `season_from_month()`, `state_name_to_abbr()`.
- **geocode.R** - `load_zip_gazetteer()` and `geocode_mission_assignments()`,
  used to attach lat/long to `MissionAssignments.csv` via the Census
  Bureau's ZCTA Gazetteer file (see [`data/README.md`](../data/README.md)).
- **modeling.R** - `fit_federal_share_rf()` and `fit_ny_incident_forecast()`,
  the two random forest models behind the app's "Fund drivers" and "NY 2024
  outlook" tabs. Both are fit once by the scripts in `scripts/` and cached
  under `models/` - the Shiny app only reads the cached artifacts.

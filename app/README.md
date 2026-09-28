# app/

The Shiny app: six tabs over FEMA's Hazard Mitigation Assistance data.

- **global.R** - loaded once at startup (explicitly `source()`d by
  `app.R` - Shiny only auto-sources `global.R` for the `server.R`/`ui.R`
  layout, not the single-file `app.R` convention used here). Reads the
  small precomputed CSVs in [`data/processed/`](../data/processed) and
  builds the three static ggplot objects. No CSV parsing or model fitting
  happens here or anywhere else in the app - see
  [`scripts/README.md`](../scripts/README.md) for where that happens.
- **app.R** - `ui` and `server`. Server logic is limited to filtering and
  rendering data that's already in memory; the random-forest-backed tabs
  just render the objects `global.R` built from cached model output.

Run with:

```r
shiny::runApp("app")
```

Requires `data/processed/*.csv` to exist first - run
[`scripts/00_run_all.R`](../scripts/00_run_all.R) if they don't.

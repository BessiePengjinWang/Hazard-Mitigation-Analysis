# models/

Cached random forest artifacts, fit once by
[`scripts/`](../scripts) and read directly by [`app/`](../app) - the app
never trains a model.

- **federal_share_rf.rds** - regression model behind the "Fund drivers"
  tab, fit by `scripts/04_feature_importance_model.R`.
- **ny_incident_rf.rds** - classifier behind the "NY 2024 outlook" tab,
  fit by `scripts/05_ny_incident_forecast_model.R`.

Both are saved with `environment(model$terms) <- new.env(parent =
baseenv())` before `saveRDS()` - see the comment in
[`lib/modeling.R`](../lib/modeling.R). Without this, R's formula interface
captures the entire calling environment (including the full raw data
frame) into what should be a small model artifact.

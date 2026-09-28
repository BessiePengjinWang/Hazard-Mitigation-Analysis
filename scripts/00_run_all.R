# Run the full pipeline end to end: raw data -> data/processed/ + models/.
# Assumes data/raw/ is already populated (see scripts/01_download_data.R).
#
# Usage: Rscript scripts/00_run_all.R

steps <- c(
  "scripts/02_geocode_mission_assignments.R",
  "scripts/03_fund_allocation_summary.R",
  "scripts/04_feature_importance_model.R",
  "scripts/05_ny_incident_forecast_model.R"
)

for (step in steps) {
  message("\n== Running ", step, " ==")
  source(step)
}

message("\nPipeline complete. Launch the app with: shiny::runApp('app')")

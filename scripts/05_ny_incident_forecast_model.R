# Fit the random forest behind the "NY 2024 outlook" tab: given only
# (year, month), what's the historical mix of incident types for New York's
# federally declared disasters? This is a low-sample extrapolation (~50
# historical NY declarations) presented as such, not a calibrated forecast.
#
# Usage: Rscript scripts/05_ny_incident_forecast_model.R

library(dplyr)
library(readr)
library(randomForest)

source("lib/modeling.R")

pa_data <- read_csv("data/raw/PublicAssistanceFundedProjectsDetails.csv", show_col_types = FALSE)

result <- fit_ny_incident_forecast(pa_data)

dir.create("models", showWarnings = FALSE, recursive = TRUE)
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
saveRDS(result$model, "models/ny_incident_rf.rds")
write_csv(result$forecast, "data/processed/ny_2024_incident_forecast.csv")

message("Fit on ", result$n_events, " historical NY disaster declarations.")
print(result$forecast)

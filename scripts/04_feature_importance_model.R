# Fit the random forest behind the "Fund drivers" tab: what predicts
# federalShareObligated? Fits once here and caches the model + importance
# table, rather than retraining on every Shiny render.
#
# Usage: Rscript scripts/04_feature_importance_model.R

library(dplyr)
library(readr)
library(randomForest)

source("lib/utils.R")
source("lib/modeling.R")

hma <- read_csv("data/raw/HazardMitigationAssistanceProjects.csv", show_col_types = FALSE)
disasters <- read_csv("data/raw/DisasterDeclarationsSummaries.csv", show_col_types = FALSE)

hma <- disasters |>
  distinct(disasterNumber, incidentType) |>
  inner_join(hma, by = "disasterNumber")

result <- fit_federal_share_rf(hma)

dir.create("models", showWarnings = FALSE, recursive = TRUE)
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
saveRDS(result$model, "models/federal_share_rf.rds")
write_csv(result$importance, "data/processed/federal_share_feature_importance.csv")

message("Fit on ", result$n_obs, " complete rows (programFy >= 2013).")
print(result$importance)

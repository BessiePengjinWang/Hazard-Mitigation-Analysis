# Build the two summary tables behind the "Fund allocation" tab:
#   - percentage of requested project funds obligated, by state
#   - total federal share obligated, by incident type
#
# Usage: Rscript scripts/03_fund_allocation_summary.R

library(dplyr)
library(readr)

source("lib/utils.R")

hma <- read_csv("data/raw/HazardMitigationAssistanceProjects.csv", show_col_types = FALSE)
disasters <- read_csv("data/raw/DisasterDeclarationsSummaries.csv", show_col_types = FALSE)

hma <- hma |>
  left_join(disasters |> distinct(disasterNumber, incidentType), by = "disasterNumber") |>
  mutate(
    percentage_obligated = case_when(
      projectAmount == 0 & federalShareObligated == 0 ~ 0,
      projectAmount == 0 & federalShareObligated != 0 ~ 100,
      TRUE ~ (federalShareObligated / projectAmount) * 100
    )
  )

state_abbr <- state_name_to_abbr()

state_obligation_summary <- hma |>
  filter(state %in% names(state_abbr)) |>
  group_by(state) |>
  summarise(percentage_obligated = mean(percentage_obligated, na.rm = TRUE), .groups = "drop") |>
  mutate(state_code = state_abbr[state])

incident_type_funding_summary <- hma |>
  filter(!is.na(incidentType)) |>
  group_by(incidentType) |>
  summarise(total_federal_share = sum(federalShareObligated, na.rm = TRUE), .groups = "drop") |>
  arrange(desc(total_federal_share))

# benefitCostRatio is extremely right-skewed (a handful of projects report
# ratios in the hundreds of thousands), so Pearson correlation is dominated
# by those outliers; Spearman rank correlation is the more honest summary
# of whether obligated-% and BCR move together.
bcr_data <- hma |> filter(is.finite(percentage_obligated), is.finite(benefitCostRatio))
fund_allocation_correlation <- tibble::tibble(
  n_projects = nrow(bcr_data),
  pearson_cor = cor(bcr_data$percentage_obligated, bcr_data$benefitCostRatio, method = "pearson"),
  spearman_cor = cor(bcr_data$percentage_obligated, bcr_data$benefitCostRatio, method = "spearman")
)

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
write_csv(state_obligation_summary, "data/processed/state_obligation_summary.csv")
write_csv(incident_type_funding_summary, "data/processed/incident_type_funding_summary.csv")
write_csv(fund_allocation_correlation, "data/processed/fund_allocation_correlation.csv")

message("Wrote data/processed/state_obligation_summary.csv (", nrow(state_obligation_summary), " states)")
message("Wrote data/processed/incident_type_funding_summary.csv (", nrow(incident_type_funding_summary), " incident types)")
message("percentage_obligated vs benefitCostRatio: pearson = ", round(fund_allocation_correlation$pearson_cor, 3),
        ", spearman = ", round(fund_allocation_correlation$spearman_cor, 3),
        " (n = ", fund_allocation_correlation$n_projects, ")")

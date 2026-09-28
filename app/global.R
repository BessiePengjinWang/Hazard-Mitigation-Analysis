# Sourced once by app.R when the app starts. Only reads small precomputed
# artifacts from data/processed/ - no CSV parsing or model fitting happens
# per-session or per-render. See scripts/00_run_all.R for how these
# artifacts are produced.

library(dplyr)
library(readr)
library(ggplot2)
library(scales)

mission_data <- read_csv("../data/processed/mission_assignments_geocoded.csv", show_col_types = FALSE)
state_obligation <- read_csv("../data/processed/state_obligation_summary.csv", show_col_types = FALSE)
incident_funding <- read_csv("../data/processed/incident_type_funding_summary.csv", show_col_types = FALSE)
feature_importance <- read_csv("../data/processed/federal_share_feature_importance.csv", show_col_types = FALSE)
ny_forecast <- read_csv("../data/processed/ny_2024_incident_forecast.csv", show_col_types = FALSE)

season_levels <- c("Spring", "Summer", "Fall", "Winter")

# Drop incident types below 1% of the mean total federal share so the long
# tail of rarely-used incident categories doesn't crowd the chart.
incident_funding_display <- incident_funding |>
  filter(total_federal_share > 0.01 * mean(total_federal_share))

incident_type_plot <- ggplot(
  incident_funding_display,
  aes(x = reorder(incidentType, total_federal_share), y = total_federal_share / 1e9, fill = total_federal_share)
) +
  geom_bar(stat = "identity") +
  scale_fill_viridis_c(guide = "none") +
  coord_flip() +
  labs(
    title = "Total Federal Share Obligated by Incident Type",
    x = "Incident Type",
    y = "Total Federal Share Obligated (billions USD)"
  ) +
  theme_minimal() +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(linetype = "dashed"),
    axis.text.y = element_text(size = 12)
  ) +
  scale_y_continuous(labels = scales::comma)

feature_importance_plot <- ggplot(feature_importance, aes(x = reorder(feature, percent_inc_mse), y = percent_inc_mse)) +
  geom_bar(stat = "identity", fill = "seagreen") +
  coord_flip() +
  labs(
    title = "Feature Importance for Federal Share Obligated",
    subtitle = "Permutation importance (% increase in out-of-bag MSE), random forest",
    x = NULL,
    y = "% increase in MSE when permuted"
  ) +
  theme_minimal()

ny_forecast_plot <- ggplot(ny_forecast, aes(x = "", y = expected_months, fill = incidentType)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar(theta = "y") +
  labs(
    title = "Modeled 2024 Incident-Type Mix for New York",
    subtitle = "Random forest predicted probability, summed across 12 months\nHistorical extrapolation, not a forecast",
    fill = "Incident type"
  ) +
  theme_void() +
  scale_fill_brewer(palette = "Set2")

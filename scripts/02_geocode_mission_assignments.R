# Geocode MissionAssignments.csv (add ZCTA centroid lat/long from a ZIP)
# and derive the Year/Season columns the app's map and seasonality tabs use.
# Writes a slim, app-ready extract to data/processed/ - only the columns the
# app actually reads, instead of carrying every MissionAssignments column
# through to a 44MB+ derived file.
#
# Usage: Rscript scripts/02_geocode_mission_assignments.R

library(dplyr)
library(readr)

source("lib/utils.R")
source("lib/geocode.R")

missions <- read_csv("data/raw/MissionAssignments.csv", show_col_types = FALSE)
gazetteer <- load_zip_gazetteer("data/raw/2023_Gaz_zcta_national.txt")

# A handful of source rows have an embedded delimiter in a free-text field
# (statementOfWork/disasterDescription) that shifts every column after it -
# e.g. a date ends up in the zip column. readr flags these via problems();
# drop them explicitly rather than let them silently corrupt downstream
# dates/coordinates.
bad_rows <- unique(problems(missions)$row)
if (length(bad_rows) > 0) {
  message("Dropping ", length(bad_rows), " row(s) with column-shifted fields: ", paste(bad_rows, collapse = ", "))
  missions <- missions[-bad_rows, ]
}

geocoded <- geocode_mission_assignments(missions, gazetteer) |>
  mutate(dateRequested = as.Date(dateRequested, format = "%Y-%m-%d")) |>
  filter(!is.na(disasterDescription), !is.na(dateRequested)) |>
  mutate(
    year = as.integer(format(dateRequested, "%Y")),
    month = as.integer(format(dateRequested, "%m")),
    season = season_from_month(month)
  ) |>
  select(disasterDescription, dateRequested, year, month, season, zip, latitude, longitude)

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
write_csv(geocoded, "data/processed/mission_assignments_geocoded.csv")

message(
  "Wrote data/processed/mission_assignments_geocoded.csv: ",
  nrow(geocoded), " / ", nrow(missions), " mission assignment rows retained after ZIP cleaning + geocoding."
)

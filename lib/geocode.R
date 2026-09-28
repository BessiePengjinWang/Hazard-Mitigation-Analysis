# ZIP-code geocoding helpers, built on the US Census Bureau's Gazetteer
# ZCTA file instead of a third-party ZIP database. The Gazetteer file is
# public domain, versioned by year, and needs no runtime network access or
# API key - see scripts/01_download_data.R for how it's fetched.

#' Load the Census Gazetteer ZCTA file into a zip -> lat/long lookup table.
#'
#' @param path path to a *_Gaz_zcta_national.txt file
#' @return tibble with columns zip, latitude, longitude
load_zip_gazetteer <- function(path) {
  readr::read_tsv(
    path,
    col_types = readr::cols_only(
      GEOID = readr::col_character(),
      INTPTLAT = readr::col_double(),
      INTPTLONG = readr::col_double()
    ),
    trim_ws = TRUE
  ) |>
    dplyr::transmute(
      zip = GEOID,
      latitude = INTPTLAT,
      longitude = INTPTLONG
    )
}

#' Attach ZCTA centroid coordinates to FEMA Mission Assignments records.
#'
#' Rows with an unparseable ZIP, a ZIP outside the gazetteer, or a resulting
#' coordinate outside the continental US bounding box are dropped rather than
#' silently kept with NA/incorrect coordinates.
#'
#' @param missions raw MissionAssignments data frame (must have a `zip` column)
#' @param gazetteer output of load_zip_gazetteer()
#' @return tibble of missions with latitude/longitude columns added
geocode_mission_assignments <- function(missions, gazetteer) {
  missions |>
    dplyr::mutate(zip = clean_zip5(zip)) |>
    dplyr::filter(!is.na(zip)) |>
    dplyr::inner_join(gazetteer, by = "zip") |>
    dplyr::filter(
      dplyr::between(latitude, 24.396308, 49.384358),
      dplyr::between(longitude, -125.000000, -66.934570)
    )
}

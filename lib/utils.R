# Shared helper functions used by the pipeline scripts and the Shiny app.
# This file only defines functions - nothing here executes on source().

#' Zero-pad and validate US ZIP codes.
#'
#' Source ZIP columns in FEMA's exports are stored as integers upstream, so
#' leading zeros are dropped for zips in New England, NY, PR, and the Virgin
#' Islands (e.g. "01731" becomes "1731"). Re-pad before validating length.
#'
#' @param zip character or numeric vector of raw ZIP values
#' @return character vector of 5-digit ZIP strings, NA where invalid
clean_zip5 <- function(zip) {
  zip <- trimws(as.character(zip))
  zip[!grepl("^[0-9]{1,5}$", zip)] <- NA_character_
  formatC(as.integer(zip), width = 5, flag = "0")
}

#' Map a numeric month (1-12) to a meteorological season.
season_from_month <- function(month) {
  dplyr::case_when(
    month %in% c(12, 1, 2) ~ "Winter",
    month %in% c(3, 4, 5) ~ "Spring",
    month %in% c(6, 7, 8) ~ "Summer",
    month %in% c(9, 10, 11) ~ "Fall",
    TRUE ~ NA_character_
  )
}

#' Full US state name -> two-letter abbreviation, including DC.
#'
#' Built from base R's state.name/state.abb rather than a hand-typed lookup
#' table so it can't silently drift out of sync with the 50 states.
state_name_to_abbr <- function() {
  c(stats::setNames(state.abb, state.name), "District of Columbia" = "DC")
}

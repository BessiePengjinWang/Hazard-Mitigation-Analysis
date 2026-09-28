# Download the raw FEMA extracts and the Census ZIP gazetteer into
# data/raw/. Run this once before the rest of the pipeline, or whenever you
# want to refresh the analysis against the latest OpenFEMA data.
#
# data/raw/ is gitignored (see .gitignore) because these files run from a
# few MB to ~250MB - too large to version sensibly. OpenFEMA is a live,
# continuously-updated feed, so a fresh download will contain more/newer
# records than the snapshot this analysis was originally built on, and
# OpenFEMA occasionally renames columns across dataset versions. If a
# downstream script errors on a missing/renamed column after a fresh
# download, check the dataset's current field list at
# https://www.fema.gov/about/openfema/data-sets before assuming the script
# itself is broken.
#
# Usage: Rscript scripts/01_download_data.R

raw_dir <- "data/raw"
dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)

download_if_missing <- function(url, destfile) {
  if (file.exists(destfile)) {
    message("Already present, skipping: ", destfile)
    return(invisible())
  }
  message("Downloading ", destfile, " ...")
  utils::download.file(url, destfile, mode = "wb", quiet = FALSE)
}

fema_datasets <- list(
  DisasterDeclarationsSummaries = "https://www.fema.gov/api/open/v2/DisasterDeclarationsSummaries.csv",
  HazardMitigationAssistanceProjects = "https://www.fema.gov/api/open/v2/HazardMitigationAssistanceProjects.csv",
  MissionAssignments = "https://www.fema.gov/api/open/v2/MissionAssignments.csv",
  PublicAssistanceFundedProjectsDetails = "https://www.fema.gov/api/open/v2/PublicAssistanceFundedProjectsDetails.csv"
)

for (name in names(fema_datasets)) {
  download_if_missing(fema_datasets[[name]], file.path(raw_dir, paste0(name, ".csv")))
}

# US Census Bureau Gazetteer ZCTA file: public-domain ZIP -> lat/long
# centroids, used for geocoding instead of a third-party ZIP database.
gazetteer_zip <- file.path(raw_dir, "zcta_gazetteer_2023.zip")
gazetteer_txt <- file.path(raw_dir, "2023_Gaz_zcta_national.txt")
download_if_missing(
  "https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2023_Gazetteer/2023_Gaz_zcta_national.zip",
  gazetteer_zip
)
if (!file.exists(gazetteer_txt)) {
  utils::unzip(gazetteer_zip, exdir = raw_dir)
}

message("Done. Raw files are in ", normalizePath(raw_dir))

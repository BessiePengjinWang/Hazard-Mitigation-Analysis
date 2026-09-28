# data/

- **raw/** - FEMA and Census extracts, downloaded by
  [`scripts/01_download_data.R`](../scripts/01_download_data.R). Gitignored
  (up to ~250MB) rather than committed; regenerate with:

  ```r
  Rscript scripts/01_download_data.R
  ```

  | File | Source |
  |---|---|
  | `HazardMitigationAssistanceProjects.csv` | [OpenFEMA HMA Projects v3](https://www.fema.gov/openfema-data-page/hazard-mitigation-assistance-projects-v3) |
  | `DisasterDeclarationsSummaries.csv` | [OpenFEMA Disaster Declarations Summaries v2](https://www.fema.gov/openfema-data-page/disaster-declarations-summaries-v2) |
  | `MissionAssignments.csv` | [OpenFEMA Mission Assignments v1](https://www.fema.gov/openfema-data-page/mission-assignments-v1) |
  | `PublicAssistanceFundedProjectsDetails.csv` | [OpenFEMA Public Assistance Funded Projects Details v1](https://www.fema.gov/openfema-data-page/public-assistance-funded-projects-details-v1) |
  | `2023_Gaz_zcta_national.txt` | [US Census Bureau ZCTA Gazetteer file](https://www.census.gov/geographies/reference-files/time-series/geo/gazetteer-files.html) |

  OpenFEMA datasets are versioned and occasionally add/rename columns
  upstream; if a script breaks after a fresh download, check the dataset's
  OpenFEMA page for schema changes first.

- **processed/** - small derived CSVs produced by
  [`scripts/`](../scripts) and read directly by the app. Committed, since
  each is well under 1MB and reproducing them requires the multi-hundred-MB
  raw downloads above. See [`scripts/README.md`](../scripts/README.md) for
  which script produces which file.

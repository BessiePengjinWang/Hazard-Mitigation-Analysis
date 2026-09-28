# Model-fitting helpers. Both models are fit once by the scripts/0*_*.R
# pipeline and cached to models/*.rds - the Shiny app never (re)trains
# anything, it only reads the saved artifacts.

#' Fit a random forest on federalShareObligated and return the model plus a
#' tidy permutation feature-importance table.
#'
#' Importance uses randomForest's built-in %IncMSE (mean increase in OOB MSE
#' when a predictor is permuted), not a hand-rolled shuffle-and-refit loop:
#' the latter refits a whole new forest per predictor (slow) and produces
#' unstable/NA importance for high-cardinality factors such as `state`.
#'
#' randomForest's classic (non-conditional) implementation refuses
#' categorical predictors with more than 53 levels, so two of the five
#' predictors need to be collapsed first: `state` (56 levels incl.
#' territories) is restricted to the 50 states + DC, matching the scope of
#' the state choropleth elsewhere in the app; `projectType` (312 free-text
#' values) is reduced to its leading FEMA eligible-activity code (e.g.
#' "601.2: Generators - Regular" -> "601"), which covers 100% of rows in 39
#' categories.
#'
#' @param hma HazardMitigationAssistanceProjects data, already joined to
#'   incidentType from DisasterDeclarationsSummaries
#' @param seed random seed for reproducibility
#' @param ntree number of trees
fit_federal_share_rf <- function(hma, seed = 123, ntree = 500) {
  state_abbr <- state_name_to_abbr()
  predictors <- c("programArea", "incidentType", "state", "programFy", "projectCategory")

  model_data <- hma |>
    dplyr::filter(programFy >= 2013, state %in% names(state_abbr)) |>
    dplyr::mutate(projectCategory = sub("^([0-9]+)\\..*", "\\1", projectType)) |>
    dplyr::select(dplyr::all_of(c(predictors, "federalShareObligated"))) |>
    stats::na.omit() |>
    dplyr::mutate(dplyr::across(dplyr::where(is.character), as.factor))

  set.seed(seed)
  model <- randomForest::randomForest(
    federalShareObligated ~ .,
    data = model_data,
    ntree = ntree,
    importance = TRUE
  )

  importance_table <- randomForest::importance(model, type = 1) |>
    as.data.frame() |>
    tibble::rownames_to_column("feature") |>
    dplyr::rename(percent_inc_mse = `%IncMSE`) |>
    dplyr::arrange(dplyr::desc(percent_inc_mse))

  # randomForest's formula interface stashes the *calling environment* on
  # model$terms, so a naive saveRDS() would serialize every large object
  # this function was called with (here, the full multi-MB `hma` frame)
  # into what should be a small model artifact. Strip it - prediction on
  # new data doesn't need it.
  environment(model$terms) <- new.env(parent = baseenv())

  list(model = model, importance = importance_table, n_obs = nrow(model_data))
}

#' Fit a random forest classifier for NY incident type by (year, month) and
#' return month-by-month predicted class probabilities for 2024.
#'
#' With ~50 historical NY disaster declarations across ~9 incident types,
#' this is a low-sample extrapolation, not a calibrated forecast - callers
#' should present it as such. Returning full class probabilities (rather
#' than a single hard-label prediction per month) avoids implying more
#' precision than 50-odd training rows can support.
#'
#' @param pa_data PublicAssistanceFundedProjectsDetails data (all states)
#' @param seed random seed for reproducibility
#' @param ntree number of trees
fit_ny_incident_forecast <- function(pa_data, seed = 123, ntree = 500) {
  ny_events <- pa_data |>
    dplyr::filter(state == "New York") |>
    dplyr::mutate(declarationDate = as.Date(declarationDate)) |>
    dplyr::distinct(disasterNumber, declarationDate, incidentType) |>
    dplyr::mutate(
      year = as.integer(format(declarationDate, "%Y")),
      month = as.integer(format(declarationDate, "%m")),
      incidentType = as.factor(incidentType)
    )

  set.seed(seed)
  model <- randomForest::randomForest(
    incidentType ~ year + month,
    data = ny_events,
    ntree = ntree
  )

  environment(model$terms) <- new.env(parent = baseenv())

  newdata_2024 <- data.frame(year = 2024L, month = 1:12)
  probs <- predict(model, newdata = newdata_2024, type = "prob")

  forecast <- tibble::tibble(
    incidentType = colnames(probs),
    expected_months = colSums(probs)
  ) |>
    dplyr::filter(expected_months > 0.01) |>
    dplyr::arrange(dplyr::desc(expected_months))

  list(model = model, forecast = forecast, n_events = nrow(ny_events))
}

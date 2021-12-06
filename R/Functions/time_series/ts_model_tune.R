ts_model_tune <- function(.modeltime_model_id, .calibration_tbl,
           .splits_obj, .drop_training_na = TRUE, .date_col,
           .value_col, .tscv_assess = "12 months",
           .tscv_skip = "6 months", .slice_limit = 6,
           .facet_ncol = 2, .grid_size = 30, .num_cores = 1,
           .best_metric = "rmse") {
    
    # * Tidyeval ----
    model_number <- base::as.integer(.modeltime_model_id)
    calibration_tbl <- .calibration_tbl
    splits_obj <- .splits_obj
    drop_na <- base::as.logical(.drop_training_na)
    date_col <- rlang::enquo(.date_col)
    value_col <- rlang::enquo(.value_col)
    assess <- base::as.character(.tscv_assess)
    skip <- base::as.character(.tscv_skip)
    slice_limit <- .slice_limit
    facet_ncol <- base::as.integer(.facet_ncol)
    grid_size <- base::as.integer(.grid_size)
    num_cores <- base::as.integer(.num_cores)
    best_metric <- base::as.character(.best_metric)
    
    
    # * Checks ----
    if (!modeltime::is_calibrated(calibration_tbl)) {
      stop(call. = FALSE, "(.calibration_tbl) must be a calibrated modeltime_table.")
    }
    
    if (!is.integer(model_number)) {
      stop(call. = FALSE, "(.modeltime_model_id) must be an integer.")
    }
    
    # * Manipulations ----
    # Get Model
    plucked_model <- calibration_tbl %>%
      modeltime::pluck_modeltime_model(model_number)
    
    # Get Training Data
    if (!drop_na) {
      training_data <- rsample::training(splits_obj)
    } else {
      training_data <- rsample::training(splits_obj) %>%
        tidyr::drop_na()
    }
    
    # Make TSCV
    tscv <- timetk::time_series_cv(
      data        = training_data,
      date_var    = {{ date_col }},
      cumulative  = TRUE,
      assess      = assess,
      skip        = skip,
      slice_limit = slice_limit
    )
    
    # TSCV Data Plan Tibble
    tscv_data_tbl <- tscv %>%
      timetk::tk_time_series_cv_plan()
    
    # TSCV Plot
    tscv_plt <- tscv_data_tbl %>%
      timetk::plot_time_series_cv_plan(
        {{ date_col }}, {{ value_col }},
        .facet_ncol = {{ facet_ncol }}
      )
    
    # * Tune Spec ----
    # Model Spec
    model_spec <- plucked_model %>% parsnip::extract_spec_parsnip()
    model_spec_engine <- model_spec[["engine"]]
    model_spec_tuner <- healthyR.ts::ts_model_spec_tune_template(model_spec_engine)
    
    # * Grid Spec ----
    grid_spec <- dials::grid_latin_hypercube(
      tune::parameters(model_spec_tuner),
      size = grid_size
    )
    
    # * Tune Model ----
    wflw_tune_spec <- plucked_model %>%
      workflows::update_model(model_spec_tuner)
    
    # * Run Tuning Grid ----
    modeltime::parallel_start(num_cores)
    
    tune_results <- wflw_tune_spec %>%
      tune::tune_grid(
        resamples = tscv,
        grid = grid_spec,
        metrics = modeltime::default_forecast_accuracy_metric_set(),
        control = tune::control_grid(
          verbose = TRUE,
          save_pred = TRUE
        )
      )
    
    modeltime::parallel_stop()
    
    # * Get best result
    best_result_set <- tune_results %>%
      tune::show_best(metric = best_metric, n = 1)
    
    # * Viz results ----
    tune_results_plt <- tune_results %>%
      tune::autoplot() +
      ggplot2::geom_smooth(se = FALSE)
    
    # * Retrain and Assess ----
    wflw_tune_spec_tscv <- wflw_tune_spec %>%
      workflows::update_model(model_spec_tuner) %>%
      tune::finalize_workflow(
        tune_results %>%
          tune::show_best(metric = best_metric, n = 1)
      ) %>%
      parsnip::fit(rsample::training(splits_obj))
    
    # * Calibration Tuned tibble ----
    calibration_tuned_tbl <- modeltime::modeltime_table(
      wflw_tune_spec_tscv
    ) %>%
      modeltime::modeltime_calibrate(rsample::testing(splits_obj)) %>%
      dplyr::mutate(.model_desc = base::paste0(.model_desc, " - Tuned"))
    
    
    # * Return ----
    output <- list(
      data = list(
        calibration_tbl        = calibration_tbl,
        calibration_tuned_tbl  = calibration_tuned_tbl,
        tscv_data_tbl          = tscv_data_tbl,
        tuned_results          = tune_results,
        best_tuned_results_tbl = best_result_set,
        tscv_obj               = tscv
      ),
      model_info = list(
        model_spec           = model_spec,
        model_spec_engine    = model_spec_engine,
        model_spec_tuner     = model_spec_tuner,
        plucked_model        = plucked_model,
        wflw_tune_spec       = wflw_tune_spec,
        grid_spec            = grid_spec,
        tuned_tscv_wflw_spec = wflw_tune_spec_tscv
      ),
      plots = list(
        tune_results_plt = tune_results_plt,
        tscv_plt         = tscv_plt
      )
    )
    
    return(output)
}

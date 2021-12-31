ts_models <- function(.data, .value_col, .date_col) {
  
  value_col_var_expr <- rlang::enquo(.value_col)
  date_col_var_expr  <- rlang::enquo(.date_col)
  
  data_tbl <- tibble::as_tibble(.data)
  data_tbl <- data_tbl %>%
    dplyr::select({{date_col_var_expr}}, {{value_col_var_expr}}) %>%
    purrr::set_names("date_col","value")

  splits <- rsample::initial_time_split(data_tbl, prop = 0.8)

  # Models ----
  
  # Prophet -----------------------------------------------------------------

  model_fit_prophet <- prophet_reg() %>%
    set_engine(engine = "prophet") %>%
    fit(value ~ date_col, data = training(splits))

  model_fit_prophet_boost <- prophet_boost(learn_rate = 0.1) %>%
    set_engine("prophet_xgboost") %>%
    fit(
     value ~ date_col +
       as.numeric(date_col) +
       lubridate::wday(date_col, label = TRUE) +
       lubridate::hour(date_col) +
       lubridate::minute(date_col)
      , data = training(splits)
    )

  # Model Table -------------------------------------------------------------

  models_tbl <- modeltime_table(
    model_fit_prophet,
    model_fit_prophet_boost
  )

  # Calibrate Model Testing -------------------------------------------------

  calibration_tbl <- models_tbl %>%
    modeltime_calibrate(new_data = testing(splits))

  # Refit to all Data -------------------------------------------------------

  refit_tbl <- calibration_tbl %>%
    modeltime_refit(data = data_tbl)

  plt <- refit_tbl %>%
    modeltime_forecast(h = "1 day", actual_data = data_tbl) %>%
    plot_modeltime_forecast(
      .legend_show = FALSE
      , .interactive = TRUE
      , .title = "ED Census 1 Day out"
    )

  return(plt)
}
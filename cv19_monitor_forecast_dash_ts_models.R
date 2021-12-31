ts_models <- function(.data, .date_col, .value_col, .title) {
  
  value_col_var_expr <- rlang::enquo(.value_col)
  date_col_var_expr  <- rlang::enquo(.date_col)
  
  data_tbl <- tibble::as_tibble(.data)
  data_tbl <- data_tbl %>%
    dplyr::select({{date_col_var_expr}}, {{value_col_var_expr}}) %>%
    purrr::set_names("date_col","value")
  
  # If nrow(data_tbl) < 15 then return out with a message of not enough info
  if(nrow(data_tbl) < 15){
    return(print("There is not enough data to produce a model at this time."))
  }
  
  splits <- rsample::initial_time_split(data_tbl, prop = 0.85, cumulative = TRUE)
  
  end_date   <- max(data_tbl$date_col)
  start_date <- timetk::subtract_time(end_date, "15 days")
  
  # Models ----
  
  # Prophet -----------------------------------------------------------------
  
  model_fit_arima_no_boost <- modeltime::arima_reg() %>%
    parsnip::set_engine(engine = "auto_arima") %>%
    parsnip::fit(value ~ date_col, data = rsample::training(splits))
  
  model_fit_prophet <- prophet_reg(logistic_floor = 0) %>%
    set_engine(engine = "prophet") %>%
    fit(value ~ date_col, data = training(splits))
  
  model_fit_prophet_boost <- prophet_boost(learn_rate = 0.1) %>%
    set_engine("prophet_xgboost") %>%
    fit(
      value ~ date_col +
        as.numeric(date_col) +
        lubridate::month(date_col, label = TRUE) +
        lubridate::week(date_col) +
        lubridate::wday(date_col, label = TRUE)
      , data = training(splits)
    )
  
  # Model Table -------------------------------------------------------------
  
  models_tbl <- modeltime_table(
    model_fit_arima_no_boost,
    model_fit_prophet,
    model_fit_prophet_boost
  )
  
  # Calibrate Model Testing -------------------------------------------------
  
  calibration_tbl <- models_tbl %>%
    modeltime_calibrate(new_data = testing(splits))
  
  # Refit to all Data -------------------------------------------------------
  
  refit_tbl <- calibration_tbl %>%
    modeltime_refit(data = data_tbl)
  
  top_two_models <- refit_tbl %>% 
    modeltime_accuracy() %>% 
    arrange(mae) %>% 
    slice(1:2)
  
  plt <- refit_tbl %>%
    filter(.model_id %in% top_two_models$.model_id) %>%
    modeltime_forecast(h = "21 days", actual_data = data_tbl) %>%
    timetk::filter_by_time(
      .date_var = .index
      , .start_date = start_date
    ) %>%
    plot_modeltime_forecast(
      .legend_show = TRUE
      , .interactive = TRUE
      , .title = .title
    )
  
  return(plt)
}

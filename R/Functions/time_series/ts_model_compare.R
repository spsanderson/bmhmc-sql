ts_model_compare <- function(.model_1, .model_2, .type = "testing", .splits_obj
                             , .data, .print_info = TRUE, .metric = "rmse"
                             , .interactive = FALSE){
  
  # Tidyeval ----
  splits_obj <- .splits_obj
  st_metric  <- as.character(tolower(.metric))
  
  # Checks ----
  if(!st_metric %in% c("mae","mape","mase","smape","rmse","rsq")){
    stop(call. = FALSE, ".subtitle_metric must be one of the following: 'mae','mape','mase','smpae','rmse','rsq")
  }
  
  if(.type == "testing"){
    new_data = rsample::testing(splits_obj)
  } else {
    new_data = rsample::training(splits_obj) %>%
      tidyr::drop_na()
  }
  
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing or is not a data.frame/tibble, please supply.")
  }
  
  if(!class(splits_obj)[[1]] == "ts_cv_split") {
    if(!class(splits_obj)[[2]] == "rsplit") {
      stop(call. = FALSE, ("(.splits) is missing or is not an rsplit or ts_cv_split. Please supply."))
    }
    stop(call. = FALSE, ("(.splits) is missing or is not a rsplit or ts_cv_split. Please supply."))
  }
  
  # Data
  data <- .data
  
  # Calibration Tibble
  calibration_tbl <- modeltime::modeltime_table(.model_1, .model_2) %>%
    modeltime::modeltime_calibrate(new_data)
  
  model_accuracy_tbl <- calibration_tbl %>%
    modeltime::modeltime_accuracy()
  
  rc_mae   <- (model_accuracy_tbl$mae[1] - model_accuracy_tbl$mae[2])/model_accuracy_tbl$mae[1]
  rc_mape  <- (model_accuracy_tbl$mape[1] - model_accuracy_tbl$mape[2])/model_accuracy_tbl$mape[1]
  rc_mase  <- (model_accuracy_tbl$mase[1] - model_accuracy_tbl$mase[2])/model_accuracy_tbl$mase[1]
  rc_smape <- (model_accuracy_tbl$smape[1] - model_accuracy_tbl$smape[2])/model_accuracy_tbl$smape[1]
  rc_rmse  <- (model_accuracy_tbl$rmse[1] - model_accuracy_tbl$rmse[2])/model_accuracy_tbl$rmse[1]
  rc_rsq   <- (model_accuracy_tbl$rsq[1] - model_accuracy_tbl$rsq[2])/model_accuracy_tbl$rsq[1]
  
  relative_delta_tbl <- tibble::tibble(
    .model_id   = 3L,
    .model_desc = 'Relative',
    .type       = 'Delta',
    mae        = as.double(rc_mae * 100.0),
    mape       = as.double(rc_mape * 100.0),
    mase       = as.double(rc_mase * 100.0),
    smape      = as.double(rc_smape * 100.0),
    rmse       = as.double(rc_rmse * 100.0),
    rsq        = as.double(rc_rsq * 100.0)
  )
  
  metric_value <- if(st_metric == "mae"){
    relative_delta_tbl$mae
  } else if(st_metric == "mape"){
    relative_delta_tbl$mape
  } else if(st_metric == "mase"){
    relative_delta_tbl$mase
  } else if(st_metric == "smape"){
    relative_delta_tbl$smape
  } else if(st_metric == "rmse"){
    relative_delta_tbl$rmse
  } else {
    relative_delta_tbl$rsq
  }
  
  metric_string <- base::paste0(
    "Model Metric Delta: ", 
    base::toupper(st_metric),
    " ",
    base::round(metric_value, 2),
    "%"
  )
  
  caption_string <- base::paste0(
    "Metric Deltas: ",
    " MAE: ", round(relative_delta_tbl$mae,2), "%",
    " MAPE: ", round(relative_delta_tbl$mape,2), "%",
    " MASE: ", round(relative_delta_tbl$mase,2), "%",
    " SMAPE: ", round(relative_delta_tbl$smape,2), "%",
    " RMSE: ", round(relative_delta_tbl$rmse,2), "%",
    " RSQ: ", round(relative_delta_tbl$rsq,2), "%"
  )
  
  model_message <- message(
    "Thew new model has the following metric improvements:",
    "\nMAE:   ", round(relative_delta_tbl$mae,2), "%", ifelse(relative_delta_tbl$mae < 0," - Excellent!"," - Bummer"),
    "\nMAPE:  ", round(relative_delta_tbl$mape,2), "%", ifelse(relative_delta_tbl$mape < 0," - Excellent!"," - Bummer"),
    "\nMASE:  ", round(relative_delta_tbl$mase,2), "%", ifelse(relative_delta_tbl$mase < 0," - Excellent!"," - Bummer"),
    "\nSMAPE: ", round(relative_delta_tbl$smape,2), "%", ifelse(relative_delta_tbl$smape < 0," - Excellent!"," - Bummer"),
    "\nRMSE:  ", round(relative_delta_tbl$rmse,2), "%", ifelse(relative_delta_tbl$rmse < 0," - Excellent!"," - Bummer"),
    "\nRSQ:   ", round(relative_delta_tbl$rsq,2), "%", ifelse(relative_delta_tbl$rsq > 0," - Excellent!"," - Bummer")
  )
  
  model_accuracy_tbl <- model_accuracy_tbl %>%
    dplyr::bind_rows(relative_delta_tbl)
  
  plt <- calibration_tbl %>%
    modeltime::modeltime_forecast(
      new_data = new_data
      , actual_data = data
    ) %>%
    modeltime::plot_modeltime_forecast(
      .conf_interval_show = FALSE
      , .interactive = .interactive
    ) +
    ggplot2::labs(
      title    = base::paste0("Forecast Plot - ", metric_string),
      subtitle = "Redline Indicates New Model",
      caption  = caption_string
    ) +
    ggplot2::theme(
      plot.caption = element_text(face = "bold")
    )
  
  output <- list(
    calibration_tbl = calibration_tbl,
    model_accuracy  = model_accuracy_tbl,
    plot            = plt
  )
  
  # Should we print?
  if(.print_info){
    print(model_accuracy_tbl)
    print(plt)
    model_message
  }
  return(invisible(output))
}

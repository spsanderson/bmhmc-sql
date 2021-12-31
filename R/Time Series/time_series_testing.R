
# Lib Load ----------------------------------------------------------------

if(!require(pacman)) install.packages("pacman")
pacman::p_load(
  "tidymodels",
  "modeltime",
  "rules",
  "plotly",
  "tidyverse",
  "timetk",
  "odbc",
  "DBI",
  "janitor",
  "tidyquant",
  "modeltime.ensemble",
  "modeltime.resample",
  "stringr",
  "workflowsets",
  "parallel",
  "healthyverse",
  "gt"
)

n_cores = detectCores() - 1

interactive <- TRUE

my_path <- ("S:/Global Finance/1 REVENUE CYCLE/Steve Sanderson II/Code/R/Functions/time_series/")
file_list <- list.files(my_path, "*.R")
map(paste0(my_path, file_list), source)

# Data ---
data_tbl <- ts_to_tbl(AirPassengers) %>%
  select(-index)

# TS Plot -----------------------------------------------------------------

start_date <- min(data_tbl$date_col)
end_date   <- max(data_tbl$date_col)

plot_time_series(
  .data = data_tbl
  , .date_var = date_col
  , .value = value
  , .title = paste0(
    "Excess Days for IP Discharges from: "
    , start_date
    , " to "
    , end_date
  )
  , .interactive = TRUE
)

plot_seasonal_diagnostics(
  .data = data_tbl
  , .date_var = date_col
  , .value = value
)

plot_anomaly_diagnostics(
  .data = data_tbl
  , .date_var = date_col
  , .value = value
)

# Data Split --------------------------------------------------------------
splits <- time_series_split(
  data_tbl
  , date_var = date_col
  , assess = round(0.2*nrow(data_tbl), 0)
  , cumulative = TRUE
)

splits %>%
  tk_time_series_cv_plan() %>%
  plot_time_series_cv_plan(date_col, value)

# Features ----------------------------------------------------------------

recipe_base <- recipe(value ~ ., data = training(splits)) %>%
  step_mutate(yr = lubridate::year(date_col)) %>%
  step_harmonic(yr, frequency = 365/12, cycle_size = 1) %>%
  step_rm(yr) %>%
  step_lag(value, lag = 1) %>%
  step_impute_knn(contains("lag_"))

recipe_date <- recipe_base %>%
  step_timeseries_signature(date_col) %>%
  step_rm(matches("(iso$)|(xts$)|(hour)|(min)|(sec)|(am.pm)")) %>%
  step_normalize(contains("index.num"), contains("date_col_year"))

recipe_fourier <- recipe_date %>%
  step_dummy(all_nominal(), one_hot = TRUE) %>%
  step_fourier(date_col, period = 365/12, K = 1) %>%
  step_YeoJohnson(value, limits = c(0,1))

recipe_fourier_final <- recipe_fourier %>%
  step_nzv(all_predictors())

recipe_pca <- recipe_base %>%
  step_timeseries_signature(date_col) %>%
  step_rm(matches("(iso$)|(xts$)|(hour)|(min)|(sec)|(am.pm)")) %>%
  step_dummy(all_nominal_predictors(), one_hot = TRUE) %>%
  step_normalize(value) %>%
  step_fourier(date_col, period = 365/12, K = 1) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_nzv(all_predictors()) %>%
  step_pca(all_numeric_predictors(), threshold = .95)

recipe_num_only <- recipe_pca %>%
  step_rm(-value, -all_numeric_predictors())

# Models ------------------------------------------------------------------

# Auto ARIMA --------------------------------------------------------------

model_spec_arima_no_boost <- arima_reg() %>%
  set_engine(engine = "auto_arima")

# Boosted Auto ARIMA ------------------------------------------------------

model_spec_arima_boosted <- arima_boost(
  min_n = 2
  , learn_rate = 0.015
) %>%
  set_engine(engine = "auto_arima_xgboost")

# ETS ---------------------------------------------------------------------

model_spec_ets <- exp_smoothing(
  seasonal_period = "auto",
  error = "auto",
  trend = "auto",
  season = "auto",
  damping = "auto"
) %>%
  set_engine(engine = "ets") 

model_spec_croston <- exp_smoothing(
  seasonal_period = "auto",
  error = "auto",
  trend = "auto",
  season = "auto",
  damping = "auto"
) %>%
  set_engine(engine = "croston")

model_spec_theta <- exp_smoothing(
  seasonal_period = "auto",
  error = "auto",
  trend = "auto",
  season = "auto",
  damping = "auto"
) %>%
  set_engine(engine = "theta")


# STLM ETS ----------------------------------------------------------------

model_spec_stlm_ets <- seasonal_reg(
  seasonal_period_1 = "auto",
  seasonal_period_2 = "auto",
  seasonal_period_3 = "auto"
) %>%
  set_engine("stlm_ets")

model_spec_stlm_tbats <- seasonal_reg(
  seasonal_period_1 = "auto",
  seasonal_period_2 = "auto",
  seasonal_period_3 = "auto"
) %>%
  set_engine("tbats")

model_spec_stlm_arima <- seasonal_reg(
  seasonal_period_1 = "auto",
  seasonal_period_2 = "auto",
  seasonal_period_3 = "auto"
) %>%
  set_engine("stlm_arima")

# NNETAR ------------------------------------------------------------------

model_spec_nnetar <- nnetar_reg(
  mode              = "regression"
  , seasonal_period = "auto"
) %>%
  set_engine("nnetar")


# Prophet -----------------------------------------------------------------

model_spec_prophet <- prophet_reg(
  seasonality_yearly = "auto",
  seasonality_weekly = "auto",
  seasonality_daily = "auto"
) %>%
  set_engine(engine = "prophet")

model_spec_prophet_boost <- prophet_boost(
  learn_rate = 0.1
  , trees = 10
  , seasonality_yearly = FALSE
  , seasonality_weekly = FALSE
  , seasonality_daily  = FALSE
) %>% 
  set_engine("prophet_xgboost") 

# TSLM --------------------------------------------------------------------

model_spec_lm <- linear_reg() %>%
  set_engine("lm")

model_spec_glm <- linear_reg(
  penalty = 1,
  mixture = 0.5
) %>%
  set_engine("glmnet")

model_spec_stan <- linear_reg() %>%
  set_engine("stan")

model_spec_spark <- linear_reg(
  penalty = 1,
  mixture = 0.5
) %>% 
  set_engine("spark")

model_spec_keras <- linear_reg(
  penalty = 1,
  mixture = 0.5
) %>%
  set_engine("keras")

# MARS --------------------------------------------------------------------

model_spec_mars <- mars(mode = "regression") %>%
  set_engine("earth")

# XGBoost -----------------------------------------------------------------

model_spec_xgboost <- boost_tree(
  mode  = "regression",
  mtry  = 10,
  trees = 100,
  min_n = 5,
  tree_depth = 3,
  learn_rate = 0.3,
  loss_reduction = 0.01
) %>%
  set_engine("xgboost")


# Workflowsets ------------------------------------------------------------

wfsets <- workflow_set(
  preproc = list(
    base          = recipe_base,
    date          = recipe_date,
    fourier       = recipe_fourier,
    fourier_final = recipe_fourier_final,
    pca           = recipe_pca,
    num_only_pca  = recipe_num_only
  ),
  models = list(
    model_spec_arima_no_boost,
    model_spec_arima_boosted,
    model_spec_ets,
    model_spec_lm,
    model_spec_glm,
    # model_spec_stan,
    # model_spec_spark,
    # model_spec_keras,
    model_spec_mars,
    model_spec_nnetar,
    model_spec_prophet,
    model_spec_prophet_boost,
    model_spec_stlm_arima,
    model_spec_stlm_ets,
    model_spec_stlm_tbats,
    model_spec_xgboost
  ),
  cross = TRUE
)

parallel_start(n_cores)
wf_fits <- wfsets %>% 
  modeltime_fit_workflowset(
    data = training(splits)
    , control = control_fit_workflowset(
      allow_par = TRUE
      , verbose = TRUE
    )
  )
parallel_stop()

wf_fits <- wf_fits %>%
  filter(.model != "NULL")

# Model Table -------------------------------------------------------------

models_tbl <- wf_fits

# Model Ensemble Table ----------------------------------------------------

fit_mean_ensemble <- models_tbl %>%
  ensemble_average(type = "mean")

fit_median_ensemble <- models_tbl %>%
  ensemble_average(type = "median")

# Model Table -------------------------------------------------------------

models_tbl <- models_tbl %>%
  add_modeltime_model(fit_mean_ensemble) %>%
  add_modeltime_model(fit_median_ensemble)

models_tbl

# Calibrate Model Testing -------------------------------------------------

parallel_start(n_cores)

calibration_tbl <- models_tbl %>%
  modeltime_calibrate(new_data = testing(splits))

parallel_stop()

calibration_tbl <- calibration_tbl %>%
  filter(!is.na(.type))

# Testing Accuracy --------------------------------------------------------

parallel_start(n_cores)

calibration_tbl %>%
  modeltime_forecast(
    new_data = testing(splits),
    actual_data = data_tbl
  ) %>%
  plot_modeltime_forecast(
    .legend_max_width = 25,
    .interactive = interactive,
    .conf_interval_show = FALSE
  )

parallel_stop()

calibration_tbl %>% 
  filter(!str_starts(.model_desc, "FOURIER")) %>%
  filter(!str_starts(.model_desc, "PCA")) %>%
  filter(!str_starts(.model_desc, "NUM_ONLY")) %>%
  filter(!str_starts(.model_desc, "ENSEMBLE")) %>%
  filter(!.model_id %in% c(5, 19, 10, 9)) %>%
  ts_model_rank_tbl() %>%
  as.data.frame() %>%
  filter(rsq >= 0.01) %>%
  filter(rsq < 1) %>%
  filter(rmse > 0.1) %>%
  select(-.type) %>%
  gt()

# New Calibration Tibble
calibration_tbl <- calibration_tbl %>% 
  filter(!str_starts(.model_desc, "FOURIER")) %>%
  filter(!str_starts(.model_desc, "PCA")) %>%
  filter(!str_starts(.model_desc, "NUM_ONLY")) %>% 
  filter(!str_starts(.model_desc, "ENSEMBLE")) %>%
  filter(!.model_id %in% c(5, 19, 10, 9))

# New Ensembles
fit_mean_ensemble <- calibration_tbl %>%
  ensemble_average(type = "mean")

fit_median_ensemble <- calibration_tbl %>%
  ensemble_average(type = "median")

parallel_start(n_cores)
calibration_tbl <- calibration_tbl %>%
  add_modeltime_model(fit_mean_ensemble) %>%
  add_modeltime_model(fit_median_ensemble) %>%
  modeltime_calibrate(new_data = testing(splits))
parallel_stop()

calibration_tbl %>%
  ts_model_rank_tbl() %>%
  gt()

# Hyperparameter Tuning ---------------------------------------------------

tuned_model <- ts_model_auto_tune(
  .modeltime_model_id = 2,
  .calibration_tbl = calibration_tbl,
  .splits_obj = splits,
  .date_col = date_col,
  .value_col = value,
  .tscv_assess = "12 months",
  .tscv_skip = "3 months",
  .num_cores = n_cores,
  .grid_size = 30
)

original_model <- tuned_model$model_info$plucked_model
new_model      <- tuned_model$model_info$tuned_tscv_wflw_spec

original_model_desc <- model_extraction_helper(original_model)
new_model_desc      <- paste0(model_extraction_helper(new_model), " - TUNED")

ts_model_compare(
  .model_1 = new_model,
  .model_2 = original_model,
  .type = "testing",
  .splits_obj = splits,
  .data = data_tbl,
  .print_info = TRUE,
  .metric = "rsq"
)

calibration_tuned_tbl <- modeltime_table(
  new_model
) %>%
  update_model_description(1, new_model_desc) %>%
  modeltime_calibrate(testing(splits))

parallel_start(n_cores)
calibration_tbl <- combine_modeltime_tables(
  calibration_tbl,
  calibration_tuned_tbl
) %>%
  modeltime_refit(
    data = data_tbl,
    control = control_refit(
      verbose = TRUE,
      allow_par = TRUE
    )
  ) %>%
  modeltime_calibrate(testing(splits))
parallel_stop()


# Refit to all Data -------------------------------------------------------

parallel_start(n_cores)
refit_tbl <- calibration_tbl %>%
  modeltime_refit(
    data = data_tbl
    , control = control_refit(
      verbose     = TRUE
      , allow_par = TRUE
    )
  )
parallel_stop()

top_two_models <- refit_tbl %>%
  ts_model_rank_tbl() %>%
  filter(rsq < 0.999) %>%
  slice(1:2)

ensemble_models <- refit_tbl %>%
  ts_model_rank_tbl() %>%
  filter(
    .model_desc %>%
      str_to_lower() %>%
      str_detect("ensemble")
  )

model_choices <- rbind(top_two_models, ensemble_models) %>%
  arrange(model_score) %>%
  slice(1:2)

# Forecast Plot ----
parallel_start(n_cores)
refit_tbl %>%
  filter(.model_id %in% model_choices$.model_id) %>%
  modeltime_forecast(h = "1 year", actual_data = data_tbl) %>%
  #filter_by_time(.date_var = .index, .start_date = "2020") %>%
  plot_modeltime_forecast(
    .legend_max_width     = 25
    , .interactive        = FALSE
    , .conf_interval_show = FALSE
    #, .title = "IP Discharges Avg Excess Days Forecast 12 Months Out"
  )
parallel_stop()


# Misc --------------------------------------------------------------------
models_tbl %>%
  modeltime_calibrate(new_data = testing(splits)) %>%
  modeltime_residuals() %>%
  plot_modeltime_residuals()

calibration_tbl %>% 
  dplyr::ungroup() %>% 
  dplyr::select(-.model) %>% 
  tidyr::unnest(.calibration_data) %>% 
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      sample = .residuals
      , fill = .model_desc
    )
  ) + 
  ggplot2::stat_qq() +
  ggplot2::stat_qq_line() +
  ggplot2::facet_wrap(
    ~ .model_desc
    , scales = "free"
  ) + 
  tidyquant::scale_color_tq() + 
  ggplot2::theme_minimal() +
  ggplot2::theme(legend.position = "none")

ts_sum_arrivals_plt(
  .data = data_tbl
  , .date_col = date_col
  , .value_col = value
  , .x_axis = wk
  , .ggplt_group_var = yr
  , yr
  , wk
) + 
  labs(
    x = "Month of Discharge"
    , y = "Total Excess Days"
    , title = "Total Excess days for IP Discharges by Month"
    , subtitle = "Redline is current year."
  )

ts_median_excess_plt(
  .data = data_tbl
  , .date_col = date_col
  , .value_col = value
  , .x_axis = wk
  , .ggplt_group_var = yr
  , .secondary_grp_var = wk
  , yr
  , wk
) +
  labs(
    x = "Month of Discharge"
    , y = "Excess of Median (+/-)"
    , title = "Median Excess Days for IP Discharges by Month"
    , subtitle = "Redline is current year"
  )


# Lib Load ----------------------------------------------------------------

if(!require(pacman)) install.packages("pacman")
pacman::p_load(
  "tidymodels",
  "modeltime",
  "dplyr",
  "lubridate",
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
  "sknifedatar"
)

n_cores = detectCores() - 1

interactive <- TRUE

my_path <- ("S:/Global Finance/1 REVENUE CYCLE/Steve Sanderson II/Code/R/Functions/time_series/")
file_list <- list.files(my_path, "*.R")
map(paste0(my_path, file_list), source)

# DB Connection -----------------------------------------------------------

db_con <- LICHospitalR::db_connect()

# Query -------------------------------------------------------------------

query <- dbGetQuery(
  conn = db_con
  , statement = paste0(
    "
    SELECT Arrival AS [Arrival_Date]
    , COUNT(ACCOUNT) AS [visit_count]
    
    FROM [SQL-WS\\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
    
    WHERE ARRIVAL >= '2010-01-01'
    AND ARRIVAL < DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0)
    AND TIMELEFTED != '-- ::00'
    AND ARRIVAL != '-- ::00'
    
    GROUP BY ARRIVAL   
    
    ORDER BY ARRIVAL
    "
  )
) %>%
  as_tibble() %>%
  clean_names() %>%
  mutate(arrival_date = arrival_date %>% ymd_hms()) %>%
  rename(date_col = arrival_date)
  
# DB Disconnect -----------------------------------------------------------

dbDisconnect(db_con)

# Manipulate --------------------------------------------------------------

data_tbl <- query %>%
  summarise_by_time(
    .date_var = date_col
    , .by = "hour"
    , value = sum(visit_count, na.rm = TRUE)
  ) %>%
  pad_by_time(
    .date_var = date_col
    , .by = "hour"
    , .pad_value = 0
  )

# TS Plot -----------------------------------------------------------------

start_date <- min(data_tbl$date_col)
end_date   <- max(data_tbl$date_col)

plot_time_series(
  .data = data_tbl %>%
    filter(date_col >= end_date - dhours(7*24))
  , .date_var = date_col
  , .value = value
  , .title = paste0(
    "Daily ED Arrivals from: "
    , end_date - dhours(7*24)
    , " to "
    , end_date
  )
  , .plotly_slider = TRUE
  , .smooth_period = "24 hours"
)

plot_seasonal_diagnostics(
  .data = data_tbl %>%
    filter(date_col >= end_date - dhours(365*24))
  , .date_var = date_col
  , .value = value
  , .feature_set = c("hour", "wday.lbl","month.lbl","year")
  , .title = "Seasonal Diagnostics Last 365 Days"
  , .geom_outlier_color = "#FF0000"
  , .interactive = interactive
)

plot_stl_diagnostics(
  .data = data_tbl %>%
    filter(date_col >= end_date - dhours(30*24))
  , .date_var = date_col
  , .value = value
  , .title = "STL Diagnositcs Last 30 Days"
)

plot_anomaly_diagnostics(
    .data = filter_by_time(
    .data = data_tbl
    , .date_var = date_col
    , .start_date = (end_date - dhours(30*24))
  )
  , .date_var = date_col
  , .value = value
  , .title = "Anomaly Diagnostics Last 30 Days"
)

filter_by_time(
  .data = data_tbl
  , .date_var = date_col
  , .start_date = FLOOR_MONTH(end_date - dhours(30*24))
) %>%
  anomalize::time_decompose(value) %>%
  anomalize::anomalize(remainder) %>%
  anomalize::plot_anomaly_decomposition() +
  labs(title = "Anomaly Diagnostics")

# Data Split --------------------------------------------------------------

splits <- initial_time_split(data_tbl, prop = 0.8)

# Features ----------------------------------------------------------------

recipe_base <- recipe(value ~ ., data = training(splits))

recipe_date <- recipe_base %>%
  step_timeseries_signature(date_col) %>%
  step_rm(matches("(iso$)|(xts$)|(min)|(sec)|(am.pm)")) %>%
  step_normalize(contains("index.num"), contains("date_col_year"))

recipe_fourier <- recipe_date %>%
  step_dummy(all_nominal_predictors(), one_hot = TRUE) %>%
  step_fourier(date_col, period = 365/52, K = 1) %>%
  step_YeoJohnson(value, limits = c(0,1))

recipe_fourier_final <- recipe_fourier %>%
  step_nzv(all_predictors())

recipe_pca <- recipe_base %>%
  step_timeseries_signature(date_col) %>%
  step_rm(matches("(iso$)|(xts$)|(min)|(sec)|(am.pm)")) %>%
  step_dummy(all_nominal_predictors(), one_hot = TRUE) %>%
  step_normalize(value) %>%
  step_fourier(date_col, period = 365/52, K = 1) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_nzv(all_predictors()) %>%
  step_pca(all_numeric_predictors(), threshold = .95)

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
  seasonal_period = "auto"
  , penalty = 0.5
  , epochs = 12
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
  , seasonality_yearly = "auto"
  , seasonality_weekly = "auto"
  , seasonality_daily = "auto"
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

# Workflowsets ------------------------------------------------------------

wfsets <- workflow_set(
  preproc = list(
    base          = recipe_base,
    date          = recipe_date,
    fourier       = recipe_fourier,
    fourier_final = recipe_fourier_final
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
    model_spec_stlm_tbats
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
  filter(.model_desc != "NULL")

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
  #modeltime_refit(training(splits)) %>%
  modeltime_calibrate(new_data = testing(splits))

parallel_stop()

calibration_tbl

# Testing Accuracy --------------------------------------------------------

parallel_start(n_cores)

calibration_tbl %>%
  modeltime_forecast(
    new_data = testing(splits),
    actual_data = data_tbl
  ) %>%
  plot_modeltime_forecast(
    .legend_max_width = 25,
    .interactive = interactive
  )
parallel_stop()

calibration_tbl %>%
  modeltime_accuracy() %>%
  arrange(desc(rsq)) %>%
  table_modeltime_accuracy(.interactive = FALSE)

# Refit to all Data -------------------------------------------------------
parallel_start(n_cores)
refit_tbl <- calibration_tbl %>%
  modeltime_refit(
    data = data_tbl
    , control = control_refit(
      verbose   = TRUE
    )
  )
parallel_stop()

top_two_models <- refit_tbl %>% 
  modeltime_accuracy() %>% 
  arrange(mae) %>% 
  slice(1:2)

ensemble_models <- refit_tbl %>%
  filter(
    .model_desc %>%
      str_to_lower() %>%
      str_detect("ensemble")
  ) %>%
  modeltime_accuracy()

model_choices <- rbind(top_two_models, ensemble_models)

refit_tbl %>%
  filter(.model_id %in% top_two_models$.model_id) %>%
  modeltime_forecast(h = "2 Days", actual_data = data_tbl) %>%
  plot_modeltime_forecast(
    .interactive = FALSE
    , .conf_interval_show = FALSE
    , .title = "ER Arrivals Forecast 2 Days Out"
  )

# Misc --------------------------------------------------------------------

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
    x = "Week of Arrival"
    , y = "Total Arrivals"
    , title = "Total ED Arrivals by Week from 2010 forward"
    , subtitle = "Redline indicates current year. Grouped by Year"
  )

ts_sum_arrivals_plt(
  .data = data_tbl
  , .date_col = date_col
  , .value_col = value
  , .x_axis = hr
  , .ggplt_group_var = yr
  , yr
  , hr
) + 
  labs(
    x = "Hour of Arrival"
    , y = "Total Arrivals"
    , title = "Total ED Arrivals by Hour from 2010 forward"
    , subtitle = "Redline indicats current year. Grouped by Year"
  )

ts_sum_arrivals_plt(
  .data = data_tbl
  , .date_col = date_col
  , .value_col = value
  , .x_axis = wd
  , .ggplt_group_var = wk
  , wk
  , wd
) + 
  labs(
    x = "Day of Arrival"
    , y = "Total Arrivals"
    , title = "Total ED Arrivals by Day of Week from 2010 forward"
    , subtitle = "Redline indicates current year. Grouped by Week of the Year"
  )

ts_median_excess_plt(
  .data = data_tbl
  , .date_col = date_col
  , .value_col = value
  , .x_axis = hr
  , .ggplt_group_var = yr
  , .secondary_grp_var = hr
  , yr
  , hr
) +
  labs(
    x = "Hour of Arrival"
    , y = "Excess of Median"
    , title = "Median Excess (+/-) by Hour of Day"
    , subtitle = "Redline indicates current year. Grouped by Year"
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
    x = "Week of Arrival"
    , y = "Excess of Median"
    , title = "Median Excess (+/-) by Week of the Year"
    , subtitle = "Redline indicates current year. Grouped by Year"
  )

ts_median_excess_plt(
  .data = data_tbl
  , .date_col = date_col
  , .value_col = value
  , .x_axis = wd
  , .ggplt_group_var = wk
  , .secondary_grp_var = wd
  , wk
  , wd
) + 
  labs(
    x = "Day of Arrival"
    , y = "Excess of Median"
    , title = "Median Excess (+/-) by Day of the Weekk"
    , subtitle = "Redline indicates current year. Grouped by Week"
  )


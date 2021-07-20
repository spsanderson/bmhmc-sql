
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
  "workflowsets"
)

interactive <- TRUE

my_path <- ("S:/Global Finance/1 REVENUE CYCLE/Steve Sanderson II/Code/R/Functions/time_series/")
file_list <- list.files(my_path, "*.R")
map(paste0(my_path, file_list), source)

# DB Connection -----------------------------------------------------------

db_con <- dbConnect(
  odbc(),
  Driver = "SQL Server",
  Server = "LI-HIDB",
  Database = "SMSPHDSSS0X0",
  Trusted_Connection = T
)

# Query -------------------------------------------------------------------

query <- dbGetQuery(
  conn = db_con
  , statement = paste0(
    "
    SELECT CAST(Dsch_Date as date) AS [dsch_date]
    , COUNT(DISTINCT(PTNO_NUM)) AS visit_count
    
    FROM smsdss.BMH_PLM_PtAcct_V
    
    WHERE Dsch_Date >= '2001-01-01'
    AND Dsch_Date < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
    AND tot_chg_amt > 0
    AND Plm_Pt_Acct_Type = 'I'
    AND LEFT(PTNO_NUM, 1) != '2'
    AND LEFT(PTNO_NUM, 4) != '1999'
    
    GROUP BY Dsch_Date
    
    ORDER BY Dsch_Date
    "
  )
) %>%
  as_tibble() %>%
  clean_names() %>%
  mutate(date_col = lubridate::ymd(dsch_date)) %>%
  select(-dsch_date)

# DB Disconnect -----------------------------------------------------------

dbDisconnect(db_con)

# Manipulate --------------------------------------------------------------

data_tbl <- query %>%
    summarise_by_time(
      .date_var = date_col
      , .by = "month"
      , value = sum(visit_count, na.rm = TRUE)
    )

# TS Plot -----------------------------------------------------------------

start_date <- min(data_tbl$date_col)
end_date   <- max(data_tbl$date_col)

plot_time_series(
  .data = data_tbl
  , .date_var = date_col
  , .value = value
  , .title = paste0(
    "IP Discharges from: "
    , start_date
    , " to "
    , end_date
  )
  , .plotly_slider = TRUE
)

plot_seasonal_diagnostics(
  .data = data_tbl
  , .date_var = date_col
  , .value = value
)

plot_stl_diagnostics(
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

splits <- initial_time_split(
  data_tbl
  , prop = 0.8
  , cumulative = TRUE
)

splits %>%
  tk_time_series_cv_plan() %>%
  plot_time_series_cv_plan(date_col, value, .interactive = FALSE)

# Features ----------------------------------------------------------------

recipe_base <- recipe(value ~ ., data = training(splits))

recipe_date <- recipe_base %>%
  step_timeseries_signature(date_col) %>%
  step_rm(matches("(iso$)|(xts$)|(hour)|(min)|(sec)|(am.pm)")) %>%
  step_normalize(contains("index.num"), contains("date_col_year"))

recipe_fourier <- recipe_date %>%
  step_dummy(all_nominal_predictors(), one_hot = TRUE) %>%
  step_fourier(date_col, period = 365/12, K = 1) %>%
  step_YeoJohnson(value, limits = c(0,1))

recipe_fourier_final <- recipe_fourier %>%
  step_nzv(all_predictors())

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

model_spec_ets <- exp_smoothing() %>%
  set_engine(engine = "ets") 

model_spec_croston <- exp_smoothing() %>%
  set_engine(engine = "croston")

model_spec_theta <- exp_smoothing() %>%
  set_engine(engine = "theta")

# STLM ETS ----------------------------------------------------------------

model_spec_stlm_ets <- seasonal_reg() %>%
  set_engine("stlm_ets")


model_spec_stlm_tbats <- seasonal_reg(
  seasonal_period_1 = 30
) %>%
  set_engine("tbats")

model_spec_stlm_arima <- seasonal_reg() %>%
  set_engine("stlm_arima")

# NNETAR ------------------------------------------------------------------

model_spec_nnetar <- nnetar_reg() %>%
  set_engine("nnetar")

# Prophet -----------------------------------------------------------------

model_spec_prophet <- prophet_reg(
  changepoint_range = 0.95,
  seasonality_yearly = TRUE,
  seasonality_weekly = TRUE
) %>%
  set_engine(engine = "prophet")

model_spec_prophet_boost <- prophet_boost(
  learn_rate = 0.1
  , trees = 10
) %>% 
  set_engine("prophet_xgboost") 

# TSLM --------------------------------------------------------------------

model_spec_lm <- linear_reg() %>%
  set_engine("lm")

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

wf_fits <- wfsets %>% 
  modeltime_fit_workflowset(
    data = data_tbl
    , control = control_fit_workflowset(
      allow_par = TRUE
      , cores   = 5
    )
  )

wf_fits <- wf_fits %>%
  filter(.model_desc != "NULL")

# Model Table -------------------------------------------------------------

models_tbl <- combine_modeltime_tables(wf_fits)

# Model Ensemble Table ----------------------------------------------------
resample_tscv <- training(splits) %>%
  time_series_cv(
    date_var      = date_col
    , assess      = "6 months"
    , initial     = "12 months"
    , skip        = "1 months"
    , slice_limit = 6
  )

# submodel_predictions <- wf_fits %>%
#   modeltime_fit_resamples(
#     resamples = resample_tscv
#     , control = control_resamples(verbose = TRUE)
#   )
# 
# ensemble_fit <- submodel_predictions %>%
#   ensemble_model_spec(
#     model_spec = linear_reg(
#       penalty  = tune()
#       , mixture = tune()
#     ) %>%
#       set_engine("glmnet")
#     , kfold    = 5
#     , grid     = 6
#     , control  = control_grid(verbose = TRUE)
#   )

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

parallel_start(5)
calibration_tbl <- models_tbl %>%
  #modeltime_refit(training(splits)) %>%
  modeltime_calibrate(new_data = testing(splits))
parallel_stop()

calibration_tbl

# Testing Accuracy --------------------------------------------------------

calibration_tbl %>%
  modeltime_forecast(
    new_data    = testing(splits),
    actual_data = data_tbl
  ) %>%
  plot_modeltime_forecast(
    .legend_max_width   = 25,
    .interactive        = interactive,
    .conf_interval_show = FALSE
  )

calibration_tbl %>%
  modeltime_accuracy() %>%
  arrange(mae) %>%
  table_modeltime_accuracy(.interactive = FALSE)
#table_modeltime_accuracy(resizable = TRUE, bordered = TRUE)

# Residuals ---------------------------------------------------------------

# residuals_out_tbl <- calibration_tbl %>%
#   modeltime_residuals()
# 
# residuals_in_tbl  <- calibration_tbl %>%
#   modeltime_residuals(
#     training(splits) %>% drop_na()
#   )
# 
# # * Time Plot ----
# 
# # Out-of-Sample 
# 
# residuals_out_tbl %>% 
#   plot_modeltime_residuals(
#     .y_intercept = 0,
#     .y_intercept_color = "blue"
#   )
# 
# # In-Sample
# 
# residuals_in_tbl %>% 
#   plot_modeltime_residuals()
# 
# 
# # * ACF Plot ----
# 
# # Out-of-Sample 
# 
# residuals_out_tbl %>%
#   plot_modeltime_residuals(
#     .type = "acf"
#   )
# 
# 
# # In-Sample
# 
# residuals_in_tbl %>%
#   plot_modeltime_residuals(
#     .type = "acf"
#   )
# 
# 
# # * Seasonality ----
# 
# # Out-of-Sample 
# 
# residuals_out_tbl %>%
#   plot_modeltime_residuals(
#     .type = "seasonality"
#   )
# 
# calibration_tbl %>%
#   modeltime_forecast(
#     new_data = testing(splits),
#     actual_data = ra_excess_summary_tbl
#   ) %>%
#   plot_modeltime_forecast()


# Refit to all Data -------------------------------------------------------

parallel_start(5)
refit_tbl <- calibration_tbl %>%
  modeltime_refit(
    data        = data_tbl
    , resamples = resample_tscv
    #, control   = control_resamples(verbose = TRUE)
  )
parallel_stop()

top_two_models <- refit_tbl %>% 
  modeltime_accuracy() %>% 
  arrange(mae) %>% 
  head(2)

ensemble_models <- refit_tbl %>%
  filter(
    .model_desc %>% 
      str_to_lower() %>%
      str_detect("ensemble")
  ) %>%
  modeltime_accuracy()

model_choices <- rbind(top_two_models, ensemble_models)

# Forecast Plot ----
parallel_start(5)
refit_tbl %>%
  filter(.model_id %in% top_two_models$.model_id) %>%
  modeltime_forecast(h = "1 year", actual_data = data_tbl) %>%
  plot_modeltime_forecast(
    .legend_max_width     = 25
    , .interactive        = FALSE
    , .conf_interval_show = FALSE
    , .title = "IP Discharges Forecast 12 Months Out"
  )
parallel_stop()

# Misc --------------------------------------------------------------------

calibration_tbl %>% 
  dplyr::ungroup() %>% 
  dplyr::select(-.model) %>% 
  tidyr::unnest(.calibration_data) %>% 
  ggplot(
    mapping = aes(
      x = .residuals
      , fill = .model_desc)
  ) + 
  geom_histogram(
    binwidth = 25
    , color = "black"
  ) + 
  facet_wrap(
    ~ .model_desc
    , scales = "free_x"
  ) + 
  scale_color_tq() + 
  theme_tq()

ts_sum_arrivals_plt(
  .data = query
  , .date_col = date_col
  , .value_col = value
  , .x_axis = mn
  , .ggplt_group_var = yr
  , yr
  , mn
) + 
  labs(
    x = "Month of Discharge"
    , y = "Total Discharges"
    , title = "Total Inpatient Discharges by Month"
    , subtitle = "Redline indicates current year"
  )

ts_median_excess_plt(
  .data = query
  , .date_col = date_col
  , .value_col = value
  , .x_axis = mn
  , .ggplt_group_var = yr
  , .secondary_grp_var = mn
  , yr
  , mn
) + 
  labs(
    x = "Month of Discharges"
    , y = "Excess of Median (+/-)"
    , title = "Total Median Discharges with Excess (+/-)"
    , subtitle = "Redline indicates current year"
  )

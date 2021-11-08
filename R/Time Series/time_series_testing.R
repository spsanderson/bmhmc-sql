
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
  "parallel"
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
    DECLARE @TODAY DATE;
    DECLARE @END   DATE;
    
    SET @TODAY = CAST(GETDATE() AS date);
    SET @END   = DATEADD(MM, DATEDIFF(MM, 0, @TODAY), 0);
    
    SELECT a.LIHN_Svc_Line
    , b.Pt_No
    , b.Dsch_Date
    , CASE
    	WHEN b.Days_Stay = '0'
    		THEN '1'
    		ELSE b.Days_Stay
      END AS [LOS]
    , CASE 
    	WHEN d.Performance = '0'
    		THEN '1'
    	WHEN d.Performance IS null 
    	AND b.Days_Stay = 0
    		THEN '1'
    	WHEN d.Performance IS null
    	AND b.days_stay != 0
    		THEN b.Days_Stay
    		ELSE d.Performance
      END AS [Performance]
    
    FROM smsdss.c_LIHN_Svc_Line_tbl                   AS a
    LEFT JOIN smsdss.BMH_PLM_PtAcct_V                 AS b
    ON a.Encounter = b.Pt_No
    LEFT JOIN Customer.Custom_DRG                     AS c
    ON b.PtNo_Num = c.PATIENT#
    LEFT JOIN smsdss.c_LIHN_SPARCS_BenchmarkRates     AS d
    ON c.APRDRGNO = d.[APRDRG Code]
    	AND c.SEVERITY_OF_ILLNESS = d.SOI
    	AND d.[Measure ID] = 4
    	AND d.[Benchmark ID] = 3
    	AND a.LIHN_Svc_Line = d.[LIHN Service Line]
    LEFT JOIN smsdss.pract_dim_v                      AS e
    ON b.Atn_Dr_No = e.src_pract_no
    	AND e.orgz_cd = 's0x0'
    LEFT JOIN smsdss.c_LIHN_APR_DRG_OutlierThresholds AS f
    ON c.APRDRGNO = f.[apr-drgcode]
    LEFT JOIN smsdss.pyr_dim_v AS G
    ON B.Pyr1_Co_Plan_Cd = G.pyr_cd
    	AND b.Regn_Hosp = G.orgz_cd
    
    WHERE b.Dsch_Date >= '2014-04-01'
    AND b.Dsch_Date < @end
    AND b.drg_no NOT IN (
    	'0','981','982','983','984','985',
    	'986','987','988','989','998','999'
    )
    AND b.Plm_Pt_Acct_Type = 'I'
    AND LEFT(B.PTNO_NUM, 1) != '2'
    AND LEFT(b.PtNo_Num, 4) != '1999'
    AND b.tot_chg_amt > 0
    AND e.med_staff_dept NOT IN ('?', 'Anesthesiology', 'Emergency Department')
    AND c.PATIENT# IS NOT NULL
    "
  )
) %>%
  as_tibble() %>%
  clean_names() %>%
  select(
    dsch_date
    , los
    , performance
  )

# DB Disconnect -----------------------------------------------------------

dbDisconnect(db_con)


# Manipulation ------------------------------------------------------------

data_tbl <- query %>%
  summarise_by_time(
    .date_var      = dsch_date
    , .by          = "week"
    , visit_count  = n()
    , sum_days     = sum(los, na.rm = TRUE)
    , sum_exp_days = sum(performance, na.rm = TRUE)
    , alos         = sum_days / visit_count
    , elos         = sum_exp_days / visit_count
    , excess_days  = sum_days - sum_exp_days
    , avg_excess   = alos - elos
  ) %>%
  rename(date_col = dsch_date) %>%
  mutate(date_col = ymd(date_col)) %>%
  arrange(date_col)

# TS Plot -----------------------------------------------------------------

start_date <- min(data_tbl$date_col)
end_date   <- max(data_tbl$date_col)

plot_time_series(
  .data = data_tbl
  , .date_var = date_col
  , .value = avg_excess
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
  , .value = avg_excess
)

plot_anomaly_diagnostics(
  .data = data_tbl
  , .date_var = date_col
  , .value = avg_excess
)


# Data Split --------------------------------------------------------------
data_final_tbl <- data_tbl %>%
  select(date_col, avg_excess) %>%
  set_names("date_col","value")

splits <- data_final_tbl %>%
  time_series_split(
    date_var    = date_col
    , assess     = "1 year"
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
      allow_par = FALSE
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

calibration_tbl

# Testing Accuracy --------------------------------------------------------

parallel_start(n_cores)

calibration_tbl %>%
  modeltime_forecast(
    new_data = testing(splits),
    actual_data = data_final_tbl
  ) %>%
  plot_modeltime_forecast(
    .legend_max_width = 25,
    .interactive = interactive,
    .conf_interval_show = FALSE
  )

parallel_stop()

calibration_tbl %>%
  modeltime_accuracy() %>%
  filter(rsq >= 0.01) %>%
  arrange(rmse) %>%
  table_modeltime_accuracy(.interactive = FALSE)


# Hyperparameter Tuning ---------------------------------------------------

tuned_prophet_model <- ts_model_tune(
  .modeltime_model_id = 22,
  .calibration_tbl = calibration_tbl,
  .splits_obj = splits,
  .date_col = date_col,
  .value_col = value,
  .tscv_assess = "52 weeks",
  .tscv_skip = "7 weeks",
  .num_cores = n_cores
)

# wflw_fit_f_prophet <- calibration_tbl %>%
#   pluck_modeltime_model(28)
# 
# wflw_fit_ff_prophet <- calibration_tbl %>%
#   pluck_modeltime_model(37)
# 
# wflw_fit_glm  <- calibration_tbl %>%
#   pluck_modeltime_model(24)
# 
# # * Cross Validation Plan (TSCV) ----
# # - Time Series Cross Validation
# 
# tscv <- time_series_cv(
#   data = training(splits) %>% drop_na(),
#   date_var = date_col,
#   cumulative = TRUE,
#   assess = "26 weeks",
#   skip = "13 weeks",
#   slice_limit = 6
# )
# 
# tscv %>%
#   tk_time_series_cv_plan() %>%
#   plot_time_series_cv_plan(date_col, value, .facet_ncol = 2)
# 
# # * Tune Model Spec ----
# 
# model_spec_glm <- linear_reg(
#   mode = "regression"
#   , penalty = tune()
#   , mixture = tune()
# ) %>%
#   set_engine("glmnet")
# 
# model_spec_f_prophet <- prophet_boost(
#   mode = "regression"
#   , changepoint_num = tune()
#   , changepoint_range = tune()
#   , seasonality_yearly = "auto"
#   , prior_scale_changepoints = tune()
#   , prior_scale_seasonality = tune()
#   , prior_scale_holidays = tune()
# ) %>%
#   set_engine("prophet_xgboost")
# 
# model_spec_ff_prophet <- prophet_boost(
#   mode = "regression"
#   , changepoint_num = tune()
#   , changepoint_range = tune()
#   , seasonality_yearly = "auto"
#   , prior_scale_changepoints = tune()
#   , prior_scale_seasonality = tune()
#   , prior_scale_holidays = tune()
# ) %>%
#   set_engine("prophet_xgboost")
# 
# parameters(model_spec_glm)
# parameters(model_spec_f_prophet)
# parameters(model_spec_ff_prophet)
# 
# # ** Round 1 ----
# set.seed(123)
# grid_spec_glm_1 <- grid_latin_hypercube(
#   parameters(model_spec_glm)
#   , size = 30
# )
# 
# grid_spec_f_prophet_1 <- grid_latin_hypercube(
#   parameters(model_spec_f_prophet)
#   , size = 30
# )
# 
# grid_spec_ff_prophet_1 <- grid_latin_hypercube(
#   parameters(model_spec_ff_prophet)
# )
# 
# # * Tune ----
# # Workflow - Tuning
# wflw_tune_glm <- wflw_fit_glm %>%
#   update_model(model_spec_glm)
# 
# wflw_tune_f_prophet <- wflw_fit_f_prophet %>%
#   update_model(model_spec_f_prophet)
# 
# wflw_tune_ff_prophet <- wflw_fit_ff_prophet %>%
#   update_model(model_spec_ff_prophet)
# 
# # Run Tune Grid (Expensive Operation)
# # ** Setup Parallel Processing ----
# parallel_start(n_cores)
# 
# 
# # ** TSCV Cross Validation ----
# 
# set.seed(123)
# tune_results_glm_1 <- wflw_tune_glm %>%
#   tune_grid(
#     resamples = tscv,
#     grid      = grid_spec_glm_1,
#     metrics   = default_forecast_accuracy_metric_set(),
#     control   = control_grid(
#       verbose   = TRUE,
#       save_pred = TRUE
#     )
#   )
# 
# 
# set.seed(123)
# tune_results_f_prophet_1 <- wflw_tune_f_prophet %>%
#   tune_grid(
#     resamples = tscv,
#     grid = grid_spec_f_prophet_1,
#     metrics = default_forecast_accuracy_metric_set(),
#     control = control_grid(
#       verbose = TRUE,
#       save_pred = TRUE
#     )
#   )
# 
# set.seed(123)
# tune_results_ff_prophet_1 <- wflw_tune_ff_prophet %>%
#   tune_grid(
#     resamples = tscv,
#     grid = grid_spec_prophet_1,
#     metrics = default_forecast_accuracy_metric_set(),
#     control = control_grid(
#       verbose = TRUE,
#       save_pred = TRUE
#     )
#   )
# 
# parallel_stop()
# 
# # Show Results
# tune_results_glm_1 %>%
#   show_best(metric = "rmse", n = 1)
# 
# tune_results_f_prophet_1 %>%
#   show_best(metric = "rmse", n = 1)
# 
# tune_results_ff_prophet_1 %>%
#   show_best(metric = "rmse", n = 1)
# 
# # Visualize Results
# tune_results_glm_1 %>%
#   tune::autoplot() +
#   geom_smooth(se = FALSE)
# 
# tune_results_f_prophet_1 %>%
#   tune::autoplot() +
#   geom_smooth(se = FALSE)
# 
# tune_results_ff_prophet_1 %>%
#   tune::autoplot() +
#   geom_smooth(se = FALSE)
# 
# # * Retrain and Assess ----
# set.seed(123)
# wflw_tune_glm_tscv <- wflw_tune_glm %>%
#   update_model(model_spec_glm) %>%
#   finalize_workflow(
#     tune_results_glm_1 %>%
#       show_best(metric = "rmse", n = 1)
#   ) %>%
#   fit(training(splits))
# 
# wflw_tune_f_prophet_tscv <- wflw_tune_f_prophet %>%
#   update_model(model_spec_f_prophet) %>%
#   finalize_workflow(
#     tune_results_f_prophet_1 %>%
#       show_best(metric = "rmse", n = 1)
#   ) %>%
#   fit(training(splits))
# 
# wflw_tune_ff_prophet_tscv <- wflw_tune_ff_prophet %>%
#   update_model(model_spec_ff_prophet) %>%
#   finalize_workflow(
#     tune_results_ff_prophet_1 %>%
#       show_best(metric = "rmse", n = 1)
#   ) %>%
#   fit(training(splits))

calibration_tuned_tbl <- modeltime_table(
  tuned_prophet_model$model_info$tuned_tscv_wflw_spec
) %>%
  modeltime_calibrate(testing(splits))


# Refit to all Data -------------------------------------------------------

parallel_start(n_cores)
refit_tbl <- calibration_tuned_tbl %>%
  modeltime_refit(
    data = data_final_tbl
    , control = control_refit(
      verbose   = TRUE
      , allow_par = FALSE
    )
  )
parallel_stop()

# top_two_models <- refit_tbl %>% 
#   modeltime_accuracy() %>% 
#   arrange(desc(rsq)) %>% 
#   slice(1:2)
# 
# ensemble_models <- refit_tbl %>%
#   filter(
#     .model_desc %>%
#       str_to_lower() %>%
#       str_detect("ensemble")
#   ) %>%
#   modeltime_accuracy()
# 
# model_choices <- rbind(top_two_models, ensemble_models)

refit_tbl %>%
  #filter(.model_id %in% top_two_models$.model_id) %>%
  modeltime_forecast(h = "12 weeks", actual_data = data_final_tbl) %>%
  filter_by_time(.date_var = .index, .start_date = "2020") %>%
  plot_modeltime_forecast(
    .legend_max_width     = 25
    , .interactive        = FALSE
    , .conf_interval_show = FALSE
    , .title = "IP Discharges Avg Excess Days Forecast 12 Weeks Out"
  )

# Misc --------------------------------------------------------------------
models_tbl %>%
  modeltime_calibrate(new_data = testing(splits)) %>%
  modeltime_residuals() %>%
  plot_modeltime_residuals()

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
  .data = data_final_tbl
  , .date_col = date_col
  , .value_col = excess_days
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
  .data = data_final_tbl
  , .date_col = date_col
  , .value_col = excess_days
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

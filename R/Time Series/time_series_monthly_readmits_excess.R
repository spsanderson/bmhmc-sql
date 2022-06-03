
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
file_list <- list.files(my_path, "*\\.R$")
map(paste0(my_path, file_list), source)

# DB Connection -----------------------------------------------------------

db_con <- LICHospitalR::db_connect()

# Query -------------------------------------------------------------------

query <- dbGetQuery(
  conn = db_con
  , statement = paste0(
    "
    DECLARE @START DATE;
    DECLARE @END   DATE;
    
    SET @START = '2016-04-01';
    SET @END   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0)
    
    SELECT CAST(A.DSCH_DATE AS date) AS [Dsch_Date]
    , A.PTNO_NUM
    , DATEPART(YEAR, A.DSCH_DATE) AS [Dsch_YR]
    , C.SEVERITY_OF_ILLNESS
    , D.LIHN_Svc_Line
    , 1 AS [DSCH]
    , CASE
    	WHEN E.[READMIT] IS NOT NULL
    		THEN 1
    		ELSE 0
    	END AS [RA_Flag]
    , F.READMIT_RATE AS [RR_Bench]
    , F.BENCH_YR
    
    FROM smsdss.BMH_PLM_PtAcct_V AS A
    LEFT OUTER JOIN smsdss.pract_dim_v AS B
    ON A.Atn_Dr_No = B.src_pract_no
    	AND A.Regn_Hosp = B.orgz_cd
    LEFT OUTER JOIN Customer.Custom_DRG AS C
    ON A.PtNo_Num = C.PATIENT#
    LEFT OUTER JOIN smsdss.c_LIHN_Svc_Line_Tbl AS D
    ON A.PtNo_Num = D.Encounter
    	AND A.prin_dx_cd_schm = D.prin_dx_cd_schme
    LEFT OUTER JOIN smsdss.vReadmits AS E
    ON A.PtNo_Num = E.[INDEX]
    	AND E.[INTERIM] < 31
    	AND E.[READMIT SOURCE DESC] != 'Scheduled Admission'
    LEFT OUTER JOIN smsdss.c_Readmit_Dashboard_Bench_Tbl AS F
    ON D.LIHN_Svc_Line = F.LIHN_SVC_LINE
    	AND (DATEPART(YEAR, A.DSCH_DATE) - 1) = F.BENCH_YR
    	AND C.SEVERITY_OF_ILLNESS = F.SOI
    
    WHERE A.DSCH_DATE >= @START
    AND A.Dsch_Date < @END
    AND A.tot_chg_amt > 0
    AND LEFT(A.PtNo_Num, 1) != '2'
    AND LEFT(A.PTNO_NUM, 4) != '1999'
    AND A.drg_no IS NOT NULL
    AND A.dsch_disp IN ('AHR','ATW')
    AND C.APRDRGNO NOT IN (	
    	SELECT ZZZ.[APR-DRG]
    	FROM smsdss.c_ppr_apr_drg_global_exclusions AS ZZZ
    )
    AND B.med_staff_dept != 'Emergency Department'
    AND B.pract_rpt_name != 'TEST DOCTOR X'
    
    ORDER BY A.Dsch_Date
    "
  )
) %>%
  as_tibble() %>%
  clean_names() %>%
  select(
    dsch_date
    , severity_of_illness
    , lihn_svc_line
    , dsch
    , ra_flag
    , rr_bench
  ) %>%
  mutate(dsch_date = lubridate::ymd(dsch_date)) %>%
  select(dsch_date, dsch, ra_flag, rr_bench)

# DB Disconnect -----------------------------------------------------------

dbDisconnect(db_con)


# Manipulation ------------------------------------------------------------

data_tbl <- query %>%
  summarise_by_time(
    .date_var       = dsch_date
    , .by           = "month"
    , dsch_count    = n()
    , dsch_count    = sum(dsch, na.rm = TRUE)
    , readmit_count = sum(ra_flag, na.rm = TRUE)
    , readmit_rate  = round(readmit_count / dsch_count, 4) * 100
    , readmit_bench = round(mean(rr_bench, na.rm = TRUE), 4)  * 100
    , value         = round((readmit_rate - readmit_bench), 2)
  ) %>%
  rename(date_col = dsch_date) %>%
  select(date_col, value)


# TS Plot -----------------------------------------------------------------

start_date <- min(data_tbl$date_col)
end_date   <- max(data_tbl$date_col)

plot_time_series(
  .data = data_tbl
  , .date_var = date_col
  , .value = value
  , .title = paste0(
    "Monthly Excess IP Readmit Rates from: "
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

data_tbl %>%
  tk_anomaly_diagnostics(
    .date_var = date_col
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
  step_hai_fourier(value, scale_type = "sincos", period = 365/12, order = 1) %>%
  step_lag(value, lag = c(1,3,6,12)) %>%
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
  ts_model_rank_tbl() %>%
  as.data.frame() %>%
  filter(rsq >= 0.01) %>%
  filter(rsq < 1) %>%
  filter(rmse > 0.1) %>%
  select(-.type) %>%
  arrange(rmse) %>%
  gt()

# New Calibration Tibble
calibration_tbl_model_id <- calibration_tbl %>% 
  filter(.model_id %in% c(1,4,5,6,7,8,14,15,16,17,18,23)) %>%
  pull(.model_id)

calibration_tbl <- calibration_tbl %>%
  filter(.model_id %in% calibration_tbl_model_id)

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
  .modeltime_model_id = 3,
  .calibration_tbl    = calibration_tbl,
  .splits_obj         = splits,
  .date_col           = date_col,
  .value_col          = value,
  .tscv_assess        = "12 months",
  .tscv_skip          = "3 months",
  .num_cores          = n_cores,
  .grid_size          = 30
)

original_model <- tuned_model$model_info$plucked_model
new_model      <- tuned_model$model_info$tuned_tscv_wflw_spec

original_model_desc <- model_extraction_helper(original_model)
new_model_desc      <- paste0(model_extraction_helper(new_model), " - TUNED")

ts_model_compare(
  .model_1 = new_model,
  .model_2 = original_model,
  .type = "training",
  .splits_obj = splits,
  .data = data_tbl,
  .print_info = TRUE,
  .metric = "rsq"
)

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
  filter(
    !.model_desc %>% 
      str_to_lower() %>% 
      str_detect("ensemble")
    ) %>%
  filter(rsq < 0.999) %>%
  slice(1:2)

ensemble_models <- refit_tbl %>%
  filter(
    .model_desc %>%
      str_to_lower() %>%
      str_detect("ensemble")
  ) %>%
  ts_model_rank_tbl()

model_choices <- rbind(top_two_models, ensemble_models) %>%
  arrange(model_score) %>%
  slice(2)

# Forecast Plot ----
parallel_start(n_cores)
refit_tbl %>%
  filter(.model_id %in% model_choices$.model_id) %>%
  modeltime_forecast(h = "1 year", actual_data = data_tbl) %>%
  filter_by_time(
    .date_var = .index
    , .start_date = FLOOR_YEAR(end_date - dyears(2)) %>% 
      as.Date()
  ) %>%
  plot_modeltime_forecast(
    .legend_max_width     = 25
    , .interactive        = FALSE
    , .conf_interval_show = FALSE
    , .title = "Monthly IP Readmit Excess Rate Forecast 1 Year Out"
  )
parallel_stop()

# Misc --------------------------------------------------------------------
models_tbl %>%
  modeltime_calibrate(new_data = testing(splits)) %>%
  modeltime_residuals() %>%
  plot_modeltime_residuals()

calibration_tuned_tbl %>% 
  dplyr::ungroup() %>% 
  dplyr::select(-.model) %>% 
  tidyr::unnest(.calibration_data) %>% 
  ggplot(
    mapping = aes(
      x = .residuals
      , fill = .model_desc)
  ) + 
  geom_histogram(
    binwidth = .5
    , color = "black"
  ) + 
  facet_wrap(
    ~ .model_desc
    , scales = "free_x"
  ) + 
  scale_color_tq() + 
  theme_tq()

ts_sum_arrivals_plt(
  .data = data_tbl
  , .date_col = date_col
  , .value_col = value
  , .x_axis = mn
  , .ggplt_group_var = yr
  , yr
  , mn
) + 
  labs(
    x = "Month of Discharge"
    , y = "Excess Readmit Rate"
    , title = "Excess Readmit Rate by Month"
    , subtitle = "Readline indicates current year"
  )

ts_median_excess_plt(
  .data = data_tbl
  , .date_col = date_col
  , .value_col = value
  , .x_axis = mn
  , .ggplt_group_var = yr
  , .secondary_grp_var = mn
  , yr
  , mn
) +
  labs(
    x = "Month of Discharge"
    , y = "Excess of Median (+/-)"
    , title = "Median Excess (+/-) Readmit Rate by Month"
    , subtitle = "Redline indicates current year. Grouped by Year."
  )


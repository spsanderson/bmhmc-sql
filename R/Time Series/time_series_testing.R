
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
  "modeltime.h2o",
  "stringr",
  "workflowsets"
)

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
    
    SELECT b.Pt_No
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
    , .by          = "month"
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
  , .value = excess_days
  , .title = paste0(
    "Excess Days for IP Discharges from: "
    , start_date
    , " to "
    , end_date
  )
  , .interactive = FALSE
)

plot_seasonal_diagnostics(
  .data = data_tbl
  , .date_var = date_col
  , .value = excess_days
)

plot_anomaly_diagnostics(
  .data = data_tbl
  , .date_var = date_col
  , .value = excess_days
)


# Data Split --------------------------------------------------------------
data_final_tbl <- data_tbl %>%
  select(date_col, excess_days)

splits <- initial_time_split(
  data_final_tbl
  , prop = 0.8
  , cumulative = TRUE
)

splits %>%
  tk_time_series_cv_plan() %>%
  plot_time_series_cv_plan(date_col, excess_days, .interactive = FALSE)

# Features ----------------------------------------------------------------

recipe_base <- recipe(excess_days ~ ., data = training(splits))

recipe_date <- recipe_base %>%
  step_timeseries_signature(date_col) %>%
  step_rm(matches("(iso$)|(xts$)|(hour)|(min)|(sec)|(am.pm)")) %>%
  step_normalize(contains("index.num"), contains("date_col_year"))

recipe_fourier <- recipe_date %>%
  step_dummy(all_nominal_predictors(), one_hot = TRUE) %>%
  step_fourier(date_col, period = 365/12, K = 1) %>%
  step_YeoJohnson(excess_days, limits = c(0,1))

recipe_fourier_final <- recipe_fourier %>%
  step_nzv(all_predictors())

# Models ------------------------------------------------------------------

# Auto ARIMA --------------------------------------------------------------

model_spec_arima_no_boost <- arima_reg() %>%
  set_engine(engine = "auto_arima")

# wflw_fit_arima_no_boost <- workflow() %>%
#   add_recipe(recipe = recipe_base) %>%
#   add_model(model_spec_arima_no_boost) %>%
#   fit(training(splits))

# Boosted Auto ARIMA ------------------------------------------------------

model_spec_arima_boosted <- arima_boost(
    min_n = 2
    , learn_rate = 0.015
  ) %>%
  set_engine(engine = "auto_arima_xgboost")

# wflw_fit_arima_boosted <- workflow() %>%
#   add_recipe(recipe = recipe_fourier_final) %>%
#   add_model(model_spec_arima_boosted) %>%
#   fit(training(splits))


# ETS ---------------------------------------------------------------------

model_spec_ets <- exp_smoothing() %>%
  set_engine(engine = "ets") 

# wflw_fit_ets <- workflow() %>%
#   add_recipe(recipe = recipe_fourier_final) %>%
#   add_model(model_spec_ets) %>%
#   fit(training(splits))

model_spec_croston <- exp_smoothing() %>%
  set_engine(engine = "croston")

# wflw_fit_croston <- workflow() %>%
#   add_recipe(recipe = recipe_fourier_final) %>%
#   add_model(model_spec_croston) %>%
#   fit(training(splits))

model_spec_theta <- exp_smoothing() %>%
  set_engine(engine = "theta")

# wflw_fit_theta <- workflow() %>%
#   add_recipe(recipe = recipe_fourier_final) %>%
#   add_model(model_spec_theta) %>%
#   fit(training(splits))


# STLM ETS ----------------------------------------------------------------

model_spec_stlm_ets <- seasonal_reg() %>%
  set_engine("stlm_ets")

# wflw_fit_stlm_ets <- workflow() %>%
#   add_recipe(recipe = recipe_fourier_final) %>%
#   add_model(model_spec_stlm_ets) %>%
#   fit(training(splits))

model_spec_stlm_tbats <- seasonal_reg() %>%
  set_engine("tbats")

# wflw_fit_stlm_tbats <- workflow() %>%
#   add_recipe(recipe = recipe_fourier_final) %>%
#   add_model(model_spec_stlm_tbats) %>%
#   fit(training(splits))

model_spec_stlm_arima <- seasonal_reg() %>%
  set_engine("stlm_arima")

# wflw_fit_stlm_arima <- workflow() %>%
#   add_recipe(recipe = recipe_base) %>%
#   add_model(model_spec_stlm_arima) %>%
#   fit(training(splits))

# NNETAR ------------------------------------------------------------------

model_spec_nnetar <- nnetar_reg() %>%
  set_engine("nnetar")

# wflw_fit_nnetar <- workflow() %>%
#   add_recipe(recipe = recipe_fourier_final) %>%
#   add_model(model_spec_nnetar) %>%
#   fit(training(splits))

# Prophet -----------------------------------------------------------------

model_spec_prophet <- prophet_reg() %>%
  set_engine(engine = "prophet")

# wflw_fit_prophet <- workflow() %>%
#   add_recipe(recipe = recipe_fourier_final) %>%
#   add_model(model_spec_prophet) %>%
#   fit(training(splits))

model_spec_prophet_boost <- prophet_boost(
    learn_rate = 0.1
    , trees = 10
  ) %>% 
  set_engine("prophet_xgboost") 

# wflw_fit_prophet_boost <- workflow() %>%
#   add_recipe(recipe = recipe_fourier_final) %>%
#   add_model(model_spec_prophet_boost) %>%
#   fit(training(splits))

# TSLM --------------------------------------------------------------------

model_spec_lm <- linear_reg() %>%
  set_engine("lm")

# wflw_fit_lm <- workflow() %>%
#   add_recipe(recipe = recipe_fourier_final) %>%
#   add_model(model_spec_lm) %>%
#   fit(training(splits))


# MARS --------------------------------------------------------------------

model_spec_mars <- mars(mode = "regression") %>%
  set_engine("earth")

# wflw_fit_mars <- workflow() %>%
#   add_recipe(recipe = recipe_fourier_final) %>%
#   add_model(model_spec_mars) %>%
#   fit(training(splits))

# Garchmodels 
# 
# model_spec_garch_multi_var <- garch_reg(
#     type = "ugarchspec"
#   ) %>%
#   set_engine(
#     "rugarch"
#     , specs = list(
#       spec1 = list(
#         mean.model = list(armaOrder = c(1, 0))
#       )
#       , spec2 = list(
#         mean.model = list(armaOrder = c(1, 0))
#       )
#       , spec3 = list(
#         mean.model = list(armaOrder = c(1, 0))
#       )
#     )
#   )
# 
# wflw_fit_garch_multi_var <- workflow() %>%
#   add_recipe(recipe = recipe_final) %>%
#   add_model(model_spec_garch_multi_var) %>%
#   fit(training(splits))

# Bayesmodels -------------------------------------------------------------
library(bayesmodels)
model_spec_bayes <- sarima_reg() %>%
  set_engine(engine = "stan")

# wflw_fit_bayes <- workflow() %>%
#   add_recipe(recipe = recipe_fourier_final) %>%
#   add_model(model_spec_bayes) %>%
#   fit(training(splits))

# H2O AutoML --------------------------------------------------------------
h2o.init(
  nthreads = -1
  , ip = 'localhost'
  , port = 54321
)

model_spec <- automl_reg(mode = 'regression') %>%
  set_engine(
    engine                     = 'h2o',
    max_runtime_secs           = 5,
    max_runtime_secs_per_model = 3,
    max_models                 = 3,
    nfolds                     = 5,
    #exclude_algos              = c("DeepLearning"),
    verbosity                  = NULL,
    seed                       = 786
  )

model_spec

model_fitted <- model_spec %>%
  fit(excess_days ~ ., data = training(splits))

model_fitted

model_final <- automl_leaderboard(model_fitted) %>% 
  head(1) %>% 
  pull(model_id)

automl_update_model(model_fitted, model_final)

#predict(model_fitted, testing(splits))

#h2o.shutdown()

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
    model_spec_bayes,
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
    data = data_final_tbl
    , control = control_fit_workflowset(
      allow_par = TRUE
      , cores   = 4
    )
  )

wf_fits

# Model Table -------------------------------------------------------------

h2o_model_tbl <- modeltime_table(model_fitted)

models_tbl <- combine_modeltime_tables(
  wf_fits,
  h2o_model_tbl
)

# Model Ensemble Table ----------------------------------------------------
resample_tscv <- training(splits) %>%
  time_series_cv(
    date_var      = date_col
    , assess      = "12 months"
    , initial     = "24 months"
    , skip        = "3 months"
    , slice_limit = 1
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

calibration_tbl <- models_tbl %>%
  modeltime_refit(training(splits)) %>%
  modeltime_calibrate(new_data = testing(splits))

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
  table_modeltime_accuracy(resizable = TRUE, bordered = TRUE)

# Residuals ---------------------------------------------------------------

residuals_out_tbl <- calibration_tbl %>%
  modeltime_residuals()

residuals_in_tbl  <- calibration_tbl %>%
  modeltime_residuals(
    training(splits) %>% drop_na()
  )

# * Time Plot ----

# Out-of-Sample 

residuals_out_tbl %>% 
  plot_modeltime_residuals(
    .y_intercept = 0,
    .y_intercept_color = "blue"
  )

# In-Sample

residuals_in_tbl %>% 
  plot_modeltime_residuals()


# * ACF Plot ----

# Out-of-Sample 

residuals_out_tbl %>%
  plot_modeltime_residuals(
    .type = "acf"
  )


# In-Sample

residuals_in_tbl %>%
  plot_modeltime_residuals(
    .type = "acf"
  )


# * Seasonality ----

# Out-of-Sample 

residuals_out_tbl %>%
  plot_modeltime_residuals(
    .type = "seasonality"
  )

calibration_tbl %>%
  modeltime_forecast(
    new_data = testing(splits),
    actual_data = data_final_tbl
  ) %>%
  plot_modeltime_forecast()


# Refit to all Data -------------------------------------------------------

refit_tbl <- calibration_tbl %>%
  modeltime_refit(
    data        = data_tbl
    , resamples = resample_tscv
    #, control   = control_resamples(verbose = TRUE)
  )

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

refit_tbl %>%
  filter(.model_id %in% model_choices$.model_id) %>%
  modeltime_forecast(h = "1 year", actual_data = data_tbl) %>%
  plot_modeltime_forecast(
    .legend_max_width     = 25
    , .interactive        = FALSE
    , .conf_interval_show = FALSE
    , .title = "IP Discharges Excess Days Forecast 12 Months Out"
  )

# Shut Down H2O -----------------------------------------------------------

h2o.shutdown()

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
  .data = query
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
  .data = query
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


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
  "stringr"
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

ra_excess_summary_tbl <- query %>%
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

start_date <- min(ra_excess_summary_tbl$date_col)
end_date   <- max(ra_excess_summary_tbl$date_col)

plot_time_series(
  .data = ra_excess_summary_tbl
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
  .data = ra_excess_summary_tbl
  , .date_var = date_col
  , .value = value
)

plot_stl_diagnostics(
  .data = ra_excess_summary_tbl
  , .date_var = date_col
  , .value = value
)

plot_anomaly_diagnostics(
  .data = ra_excess_summary_tbl
  , .date_var = date_col
  , .value = value
)

ra_excess_summary_tbl %>%
  tk_anomaly_diagnostics(
    .date_var = date_col
    , .value = value
  )

# Data Split --------------------------------------------------------------

splits <- initial_time_split(
  ra_excess_summary_tbl
  , prop = 0.8
  , cumulative = TRUE
)

# Time Series Regressions
ra_excess_summary_tbl %>%
  plot_time_series_regression(
    .date_var = date_col
    , .formula = value ~ as.numeric(date_col)
    + lubridate::month(date_col, label = TRUE)
  )

# Features ----------------------------------------------------------------

recipe_base <- recipe(value ~ ., data = training(splits)) %>%
  step_timeseries_signature(date_col)

recipe_final <- recipe_base %>%
  step_rm(matches("(iso$)|(xts$)|(hour)|(min)|(sec)|(am.pm)")) %>%
  step_normalize(contains("index.num"), date_col_year) %>%
  step_dummy(contains("lbl"), one_hot = TRUE) %>%
  step_fourier(date_col, period = 365/12, K = 2) %>%
  step_YeoJohnson(value, limits = c(0,1))

# Models ------------------------------------------------------------------

# Auto ARIMA --------------------------------------------------------------

model_spec_arima_no_boost <- arima_reg() %>%
  set_engine(engine = "auto_arima")

wflw_fit_arima_no_boost <- workflow() %>%
  add_recipe(recipe = recipe_base) %>%
  add_model(model_spec_arima_no_boost) %>%
  fit(training(splits))


# Boosted Auto ARIMA ------------------------------------------------------

model_spec_arima_boosted <- arima_boost(
  min_n = 2
  , learn_rate = 0.015
) %>%
  set_engine(engine = "auto_arima_xgboost")

wflw_fit_arima_boosted <- workflow() %>%
  add_recipe(recipe = recipe_final) %>%
  add_model(model_spec_arima_boosted) %>%
  fit(training(splits))


# ETS ---------------------------------------------------------------------

model_spec_ets <- exp_smoothing() %>%
  set_engine(engine = "ets") 

wflw_fit_ets <- workflow() %>%
  add_recipe(recipe = recipe_final) %>%
  add_model(model_spec_ets) %>%
  fit(training(splits))

model_spec_croston <- exp_smoothing() %>%
  set_engine(engine = "croston")

wflw_fit_croston <- workflow() %>%
  add_recipe(recipe = recipe_final) %>%
  add_model(model_spec_croston) %>%
  fit(training(splits))

model_spec_theta <- exp_smoothing() %>%
  set_engine(engine = "theta")

wflw_fit_theta <- workflow() %>%
  add_recipe(recipe = recipe_final) %>%
  add_model(model_spec_theta) %>%
  fit(training(splits))


# STLM ETS ----------------------------------------------------------------

model_spec_stlm_ets <- seasonal_reg() %>%
  set_engine("stlm_ets")

wflw_fit_stlm_ets <- workflow() %>%
  add_recipe(recipe = recipe_final) %>%
  add_model(model_spec_stlm_ets) %>%
  fit(training(splits))

model_spec_stlm_tbats <- seasonal_reg() %>%
  set_engine("tbats")

wflw_fit_stlm_tbats <- workflow() %>%
  add_recipe(recipe = recipe_final) %>%
  add_model(model_spec_stlm_tbats) %>%
  fit(training(splits))

model_spec_stlm_arima <- seasonal_reg() %>%
  set_engine("stlm_arima")

wflw_fit_stlm_arima <- workflow() %>%
  add_recipe(recipe = recipe_final) %>%
  add_model(model_spec_stlm_arima) %>%
  fit(training(splits))

# NNETAR ------------------------------------------------------------------

model_spec_nnetar <- nnetar_reg() %>%
  set_engine("nnetar")

wflw_fit_nnetar <- workflow() %>%
  add_recipe(recipe = recipe_final) %>%
  add_model(model_spec_nnetar) %>%
  fit(training(splits))

# Prophet -----------------------------------------------------------------

model_spec_prophet <- prophet_reg() %>%
  set_engine(engine = "prophet")

wflw_fit_prophet <- workflow() %>%
  add_recipe(recipe = recipe_final) %>%
  add_model(model_spec_prophet) %>%
  fit(training(splits))

model_spec_prophet_boost <- prophet_boost(learn_rate = 0.1) %>% 
  set_engine("prophet_xgboost") 

wflw_fit_prophet_boost <- workflow() %>%
  add_recipe(recipe = recipe_final) %>%
  add_model(model_spec_prophet_boost) %>%
  fit(training(splits))

# TSLM --------------------------------------------------------------------

model_spec_lm <- linear_reg() %>%
  set_engine("lm")

wflw_fit_lm <- workflow() %>%
  add_recipe(recipe = recipe_final) %>%
  add_model(model_spec_lm) %>%
  fit(training(splits))


# MARS --------------------------------------------------------------------

model_spec_mars <- mars(mode = "regression") %>%
  set_engine("earth")

wflw_fit_mars <- workflow() %>%
  add_recipe(recipe = recipe_final) %>%
  add_model(model_spec_mars) %>%
  fit(training(splits))

# Bayesmodels -------------------------------------------------------------
library(bayesmodels)
model_spec_bayes <- sarima_reg() %>%
  set_engine(engine = "stan")

wflw_fit_bayes <- workflow() %>%
  add_recipe(recipe = recipe_final) %>%
  add_model(model_spec_bayes) %>%
  fit(training(splits))

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
  fit(value ~ ., data = training(splits))

model_fitted

model_final <- automl_leaderboard(model_fitted) %>% 
  head(1) %>% 
  pull(model_id)
automl_update_model(model_fitted, model_final)
predict(model_fitted, testing(splits))

#h2o.shutdown()

# Model Table -------------------------------------------------------------

models_tbl <- modeltime_table(
  #wflw_fit_arima_no_boost,
  wflw_fit_arima_boosted,
  wflw_fit_ets,
  wflw_fit_theta,
  wflw_fit_stlm_ets,
  wflw_fit_stlm_tbats,
  wflw_fit_nnetar,
  wflw_fit_prophet,
  wflw_fit_prophet_boost,
  wflw_fit_lm, 
  wflw_fit_mars,
  wflw_fit_bayes,
  model_fitted
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

submodel_predictions <- models_tbl %>%
  modeltime_fit_resamples(
    resamples = resample_tscv
    , control = control_resamples(verbose = TRUE)
  )

ensemble_fit <- submodel_predictions %>%
  ensemble_model_spec(
    model_spec = linear_reg(
      penalty  = tune()
      , mixture = tune()
    ) %>%
      set_engine("glmnet")
    , kfold    = 5
    , grid     = 6
    , control  = control_grid(verbose = TRUE)
  )

fit_mean_ensemble <- models_tbl %>%
  ensemble_average(type = "mean")

fit_median_ensemble <- models_tbl %>%
  ensemble_average(type = "median")

# Model Table -------------------------------------------------------------

models_tbl <- modeltime_table(
  #wflw_fit_arima_no_boost,
  wflw_fit_arima_boosted,
  wflw_fit_ets,
  wflw_fit_theta,
  wflw_fit_stlm_ets,
  wflw_fit_stlm_tbats,
  wflw_fit_nnetar,
  wflw_fit_prophet,
  wflw_fit_prophet_boost,
  wflw_fit_lm, 
  wflw_fit_mars,
  model_fitted,
  wflw_fit_bayes,
  fit_mean_ensemble,
  fit_median_ensemble
)

models_tbl

# Calibrate Model Testing -------------------------------------------------

calibration_tbl <- models_tbl %>%
  modeltime_calibrate(new_data = testing(splits))

calibration_tbl

# Testing Accuracy --------------------------------------------------------

calibration_tbl %>%
  modeltime_forecast(
    new_data    = testing(splits),
    actual_data = ra_excess_summary_tbl
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

# Refit to all Data -------------------------------------------------------

refit_tbl <- calibration_tbl %>%
  modeltime_refit(
    data        = ra_excess_summary_tbl
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
  filter(.model_id %in% top_two_models$.model_id) %>%
  modeltime_forecast(h = "1 year", actual_data = ra_excess_summary_tbl) %>%
  filter_by_time(
    .date_var = .index
    , .start_date = FLOOR_YEAR(end_date - dyears(2)) %>% 
      as.Date()
  ) %>%
  plot_modeltime_forecast(
    .legend_max_width = 25
    , .interactive = FALSE
    , .title = "Monthly Excess IP Readmit Rates Forecast 1 Year Out"
  )


# Shut Down H2O -----------------------------------------------------------

h2o.shutdown()
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
  .data = ra_excess_summary_tbl
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
  .data = ra_excess_summary_tbl
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


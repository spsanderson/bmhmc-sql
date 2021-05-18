
# Lib Load ----------------------------------------------------------------

if(!require(pacman)) install.packages("pacman")
pacman::p_load(
  "tidymodels",
  "modeltime",
  "tidyverse",
  "lubridate",
  "timetk",
  "odbc",
  "DBI",
  "janitor",
  "timetk",
  "tidyquant",
  "modeltime.ensemble",
  "modeltime.resample",
  "modeltime.h2o"
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

query <- query %>%
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
  mutate(date_col = ymd(date_col))

# TS Plot -----------------------------------------------------------------

start_date <- min(query$date_col)
end_date   <- max(query$date_col)

plot_time_series(
  .data = query
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
  .data = query
  , .date_var = date_col
  , .value = excess_days
)

plot_anomaly_diagnostics(
  .data = query
  , .date_var = date_col
  , .value = excess_days
)


# Data Split --------------------------------------------------------------
data_tbl <- query %>%
  select(date_col, excess_days)

splits <- initial_time_split(data_tbl, prop = 0.9, cumulative = TRUE)

# Features ----------------------------------------------------------------

recipe_base <- recipe(excess_days ~ ., data = training(splits)) %>%
  step_timeseries_signature(date_col)

recipe_final <- recipe_base %>%
  step_rm(
    contains("iso")
    , contains("second")
    , contains("minute")
    , contains("hour")
    , contains("am.pm")
    , contains("xts")
  ) %>%
  step_normalize(contains("index.num"), date_col_year) %>%
  step_dummy(contains("lbl"), one_hot = TRUE) %>%
  step_fourier(date_col, period = 365/12, K = 2) %>%
  step_holiday_signature(date_col) %>%
  step_YeoJohnson(excess_days)

# Models ------------------------------------------------------------------

# Auto ARIMA --------------------------------------------------------------

model_spec_arima_no_boost <- arima_reg() %>%
  set_engine(engine = "auto_arima")

wflw_fit_arima_no_boost <- workflow() %>%
  add_recipe(recipe = recipe_final) %>%
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
    exclude_algos              = c("DeepLearning"),
    verbosity                  = NULL,
    seed                       = 786
  ) 

model_spec

model_fitted <- model_spec %>%
  fit(excess_days ~ ., data = training(splits))

model_fitted

predict(model_fitted, testing(splits))

# Model Table -------------------------------------------------------------

models_tbl <- modeltime_table(
  #wflw_fit_arima_no_boost,
  wflw_fit_arima_boosted,
  wflw_fit_ets,
  wflw_fit_prophet,
  wflw_fit_prophet_boost,
  wflw_fit_lm, 
  wflw_fit_mars
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

# Model Table -------------------------------------------------------------

models_tbl <- modeltime_table(
  #wflw_fit_arima_no_boost,
  wflw_fit_arima_boosted,
  wflw_fit_ets,
  wflw_fit_prophet,
  wflw_fit_prophet_boost,
  wflw_fit_lm, 
  wflw_fit_mars,
  ensemble_fit
)

models_tbl

# Calibrate Model Testing -------------------------------------------------

calibration_tbl <- models_tbl %>%
  modeltime_calibrate(new_data = testing(splits))
calibration_tbl

# Testing Accuracy --------------------------------------------------------

calibration_tbl %>%
  modeltime_forecast(
    new_data = testing(splits),
    actual_data = query
  ) %>%
  plot_modeltime_forecast(
    .legend_max_width = 25,
    .interactive = interactive
  )

calibration_tbl %>%
  modeltime_accuracy() %>%
  arrange(mae) %>%
  table_modeltime_accuracy(resizable = TRUE, bordered = TRUE)

# Refit to all Data -------------------------------------------------------

refit_tbl <- calibration_tbl %>%
  modeltime_refit(
    data        = data_tbl
    , resamples = resample_tscv
    , control   = control_resamples(verbose = TRUE)
  )

top_two_models <- refit_tbl %>% 
  modeltime_accuracy() %>% 
  arrange(mae) %>% 
  head(2)

refit_tbl %>%
  filter(.model_id %in% top_two_models$.model_id) %>%
  modeltime_forecast(h = "1 year", actual_data = data_tbl) %>%
  plot_modeltime_forecast(
    .legend_max_width = 25
    , .interactive = FALSE
    , .title = "IP Discharges Excess Days Forecast 1 Year Out"
  )

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
  , .value_col = excess_days
  , .x_axis = mn
  , .ggplt_group_var = yr
  , yr
  , mn
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
  , .x_axis = mn
  , .ggplt_group_var = yr
  , .secondary_grp_var = mn
  , yr
  , mn
) +
  labs(
    x = "Month of Discharge"
    , y = "Excess of Median (+/-)"
    , title = "Median Excess Days for IP Discharges by Month"
    , subtitle = "Redline is current year"
  )
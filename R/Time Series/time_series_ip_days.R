
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
  "anomalize"
)

interactive <- TRUE

# DB Connection -----------------------------------------------------------

db_con <- dbConnect(
  odbc(),
  Driver = "SQL Server",
  Server = "BMH-HIDB",
  Database = "SMSPHDSSS0X0",
  Trusted_Connection = T
)

# Query -------------------------------------------------------------------

query <- dbGetQuery(
  conn = db_con
  , statement = paste0(
    "
    SELECT CAST(Dsch_Date as date) AS [dsch_date]
    , SUM(Days_Stay) AS [los]
    
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
  mutate(date_col = EOMONTH(dsch_date)) %>%
  group_by(date_col) %>%
  summarise(sum_days = sum(los, na.rm = TRUE)) %>%
  ungroup()

# DB Disconnect -----------------------------------------------------------

dbDisconnect(db_con)


# TS Plot -----------------------------------------------------------------

start_date <- min(query$date_col)
end_date   <- max(query$date_col)

plot_time_series(
  .data = query
  , .date_var = date_col
  , .value = sum_days
  , .title = paste0(
    "Total IP Days for Discharges from: "
    , start_date
    , " to "
    , end_date
  )
  , .plotly_slider = TRUE
)

plot_seasonal_diagnostics(
  .data = query
  , .date_var = date_col
  , .value = sum_days
)

# plot_anomaly_diagnostics(
#   .data = query
#   , .date_var = date_col
#   , .value = sum_days
# )


# Anomalize Data ----------------------------------------------------------

df_anomalized_tbl <- query %>%
  tibbletime::as_tbl_time(index = date_col) %>%
  arrange(date_col) %>%
  time_decompose(sum_days, method = "twitter") %>%
  anomalize(remainder, method = "gesd") %>%
  clean_anomalies() %>%
  time_recompose() %>%
  select(date_col, observed_cleaned)

# Data Split --------------------------------------------------------------

splits <- initial_time_split(df_anomalized_tbl, prop = 0.9)

# Models ----

# Auto ARIMA --------------------------------------------------------------

model_fit_arima_no_boost <- arima_reg() %>%
  set_engine(engine = "auto_arima") %>%
  fit(observed_cleaned ~ date_col, data = training(splits))


# Boosted Auto ARIMA ------------------------------------------------------

model_fit_arima_boosted <- arima_boost(
  min_n = 2
  , learn_rate = 0.015
) %>%
  set_engine(engine = "auto_arima_xgboost") %>%
  fit(
    observed_cleaned ~ date_col + as.numeric(date_col) + factor(month(date_col, label = TRUE), ordered = FALSE)
    , data = training(splits)
  )

# ETS ---------------------------------------------------------------------

model_fit_ets <- exp_smoothing() %>%
  set_engine(engine = "ets") %>%
  fit(observed_cleaned ~ date_col, data = training(splits))

# Prophet -----------------------------------------------------------------

model_fit_prophet <- prophet_reg() %>%
  set_engine(engine = "prophet") %>%
  fit(observed_cleaned ~ date_col, data = training(splits))

# TSLM --------------------------------------------------------------------

model_fit_lm <- linear_reg() %>%
  set_engine("lm") %>%
  fit(
    observed_cleaned ~ as.numeric(date_col) + factor(month(date_col, label = TRUE), ordered = FALSE)
    , data = training(splits)
  )

# MARS --------------------------------------------------------------------

model_spec_mars <- mars(mode = "regression") %>%
  set_engine("earth")

recipe_spec <- recipe(observed_cleaned ~ date_col, data = training(splits)) %>%
  step_date(date_col, features = "month", ordinal = FALSE) %>%
  step_mutate(date_num = as.numeric(date_col)) %>%
  step_normalize(date_num) %>%
  step_rm(date_col)

wflw_fit_mars <- workflow() %>%
  add_recipe(recipe_spec) %>%
  add_model(model_spec_mars) %>%
  fit(training(splits))

# Model Table -------------------------------------------------------------

models_tbl <- modeltime_table(
  model_fit_arima_no_boost,
  model_fit_arima_boosted,
  model_fit_ets,
  model_fit_prophet,
  model_fit_lm, 
  wflw_fit_mars
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
    actual_data = df_anomalized_tbl
  ) %>%
  plot_modeltime_forecast(
    .legend_max_width = 25,
    .interactive = interactive
  )

calibration_tbl %>%
  modeltime_accuracy() %>%
  mutate(tot_err = mae + mape + mase +smape + rmse + rsq) %>%
  arrange(tot_err) %>%
  table_modeltime_accuracy(resizable = TRUE, bordered = TRUE)

# Refit to all Data -------------------------------------------------------

refit_tbl <- calibration_tbl %>%
  modeltime_refit(data = df_anomalized_tbl)

top_two_models <- refit_tbl %>% 
  modeltime_accuracy() %>% 
  arrange(mae) %>% 
  slice(1:2)

refit_tbl %>%
  filter(.model_id %in% top_two_models$.model_id) %>%
  modeltime_forecast(h = "1 year", actual_data = df_anomalized_tbl) %>%
  plot_modeltime_forecast(
    .legend_max_width = 25
    , .interactive = interactive
    , .title = "Monthly IP Days Forecast 1 Year Out"
  )

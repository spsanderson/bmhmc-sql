
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
    SELECT Arrival AS [Arrival_Date]
    , COUNT(ACCOUNT) AS [visit_count]
    
    FROM [SQL-WS\\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
    
    WHERE ARRIVAL >= '2010-01-01'
    AND ARRIVAL < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
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
  mutate(date_col = floor_date(arrival_date, unit = "hour")) %>%
  select(-arrival_date) %>%
  group_by(date_col) %>%
  summarise(value = sum(visit_count, na.rm = TRUE)) %>%
  ungroup() %>%
  pad_by_time(
    .date_var = date_col
    , .by = "hour"
    , .pad_value = 0
  )

# DB Disconnect -----------------------------------------------------------

dbDisconnect(db_con)


# TS Plot -----------------------------------------------------------------

start_date <- min(query$date_col)
end_date   <- max(query$date_col)

plot_time_series(
  .data = query %>%
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
)

plot_seasonal_diagnostics(
  .data = query %>%
    filter(date_col >= end_date - dhours(365*24))
  , .date_var = date_col
  , .value = value
  , .feature_set = c("hour", "wday.lbl","month.lbl","year")
  , .title = "Seasonal Diagnostics Last 365 Days"
  , .geom_outlier_color = "#FF0000"
  , .interactive = interactive
)

plot_stl_diagnostics(
  .data = query %>%
    filter(date_col >= end_date - dhours(30*24))
  , .date_var = date_col
  , .value = value
  , .title = "STL Diagnositcs Last 30 Days"
)

# plot_anomaly_diagnostics(
#     .data = filter_by_time(
#     .data = query
#     , .date_var = date_col
#     , .start_date = CEILING_MONTH(end_date - dhours(30*24))
#   )
#   , .date_var = date_col
#   , .value = value
#   , .title = "Anomaly Diagnostics Last 30 Days"
# )

filter_by_time(
  .data = query
  , .date_var = date_col
  , .start_date = FLOOR_MONTH(end_date - dhours(30*24))
) %>%
  time_decompose(value) %>%
  anomalize(remainder) %>%
  plot_anomaly_decomposition() +
  labs(title = "Anomaly Diagnostics")

# Anomalize Data ----------------------------------------------------------

df_anomalized_tbl <- filter_by_time(
    .data = query
    , .date_var = date_col
    , .start_date = CEILING_MONTH(end_date - dhours(60*24))
  ) %>%
  tibbletime::as_tbl_time(index = date_col) %>%
  arrange(date_col) %>%
  time_decompose(value, method = "twitter") %>%
  anomalize(remainder, method = "gesd") %>%
  clean_anomalies() %>%
  time_recompose() %>%
  select(date_col, observed, observed_cleaned)

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
    observed_cleaned ~ date_col + as.numeric(date_col) + factor(hour(date_col), ordered = FALSE)
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
    observed_cleaned ~ as.numeric(date_col) + factor(hour(date_col), ordered = FALSE)
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
  modeltime_calibrate(new_data = testing(splits)) %>%
  filter(!is.na(.type))
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
  arrange(mae) %>%
  table_modeltime_accuracy(resizable = TRUE, bordered = TRUE)

# Refit to all Data -------------------------------------------------------

refit_tbl <- calibration_tbl %>%
  modeltime_refit(data = df_anomalized_tbl) %>%
  filter(!is.na(.type))

top_two_models <- refit_tbl %>% 
  modeltime_accuracy() %>% 
  arrange(mae) %>% 
  slice(1:2)

refit_tbl %>%
  filter(.model_id %in% top_two_models$.model_id) %>%
  modeltime_forecast(h = 48, actual_data = df_anomalized_tbl) %>%
  filter_by_time(
    .date_var = .index
    , .start_date = (end_date - dhours(7*24))
    #, .end_date = end_date
  ) %>%
  plot_modeltime_forecast(
    .legend_max_width = 25
    , .interactive = interactive
    , .title = "Hourly ED Arrivals Forecast 48 Hours Out"
  )


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

my_path <- ("S:/Global Finance/1 REVENUE CYCLE/Steve Sanderson II/Code/R/Functions/time_series/")
file_list <- list.files(my_path, "*.R")
map(paste0(my_path, file_list), source)

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
    , COUNT(ACCOUNT) AS [visit_Count]
    
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
  mutate(arrival_date = as.Date.character(arrival_date, format = c("%Y-%m-%d"))) %>%
  mutate(date_col = arrival_date) %>%
  select(-arrival_date)

# DB Disconnect -----------------------------------------------------------

dbDisconnect(db_con)

# Manipulate --------------------------------------------------------------

query <- query %>%
    summarise_by_time(
      .date_var = date_col
      , .by = "day"
      , value = sum(visit_count, na.rm = TRUE)
    )

# TS Plot -----------------------------------------------------------------

start_date <- min(query$date_col)
end_date   <- max(query$date_col)

plot_time_series(
  .data = query %>%
    filter(date_col >= end_date - 365)
  , .date_var = date_col
  , .value = value
  , .title = paste0(
    "Daily ED Arrivals from: "
    , end_date - 365
    , " to "
    , end_date
  )
  , .plotly_slider = TRUE
)

plot_seasonal_diagnostics(
  .data = query
  , .date_var = date_col
  , .value = value
)

plot_stl_diagnostics(
  .data = query
  , .date_var = date_col
  , .value = value
)

plot_anomaly_diagnostics(
  .data = query
  , .date_var = date_col
  , .value = value
)


# Data Split --------------------------------------------------------------

splits <- initial_time_split(query, prop = 0.9)

# Models ----

# Auto ARIMA --------------------------------------------------------------

model_fit_arima_no_boost <- arima_reg() %>%
  set_engine(engine = "auto_arima") %>%
  fit(value ~ date_col, data = training(splits))


# Boosted Auto ARIMA ------------------------------------------------------

model_fit_arima_boosted <- arima_boost(
  min_n = 2
  , learn_rate = 0.015
) %>%
  set_engine(engine = "auto_arima_xgboost") %>%
  fit(
    value ~ date_col + as.numeric(date_col) 
    + month(date_col, label = TRUE)
    + week(date_col)
    + factor(wday(date_col, label = TRUE), ordered = FALSE)
    , data = training(splits)
  )

# ETS ---------------------------------------------------------------------

model_fit_ets <- exp_smoothing() %>%
  set_engine(engine = "ets") %>%
  fit(value ~ date_col, data = training(splits))

# Prophet -----------------------------------------------------------------

model_fit_prophet <- prophet_reg() %>%
  set_engine(engine = "prophet") %>%
  fit(value ~ date_col, data = training(splits))

model_fit_prophet_boost <- prophet_boost(learn_rate = 0.1) %>% 
  set_engine("prophet_xgboost") %>%
  fit(
    value ~ date_col + as.numeric(date_col) 
    + month(date_col, label = TRUE)
    + week(date_col)
    + factor(wday(date_col, label = TRUE), ordered = FALSE)
    , data = training(splits)
  )

# TSLM --------------------------------------------------------------------

model_fit_lm <- linear_reg() %>%
  set_engine("lm") %>%
  fit(
    value ~ date_col + as.numeric(date_col) 
    + month(date_col, label = TRUE)
    + week(date_col)
    + factor(wday(date_col, label = TRUE), ordered = FALSE)
    , data = training(splits)
  )

# MARS --------------------------------------------------------------------

model_spec_mars <- mars(mode = "regression") %>%
  set_engine("earth")

recipe_spec <- recipe(value ~ date_col, data = training(splits)) %>%
  step_date(date_col, features = "dow", ordinal = FALSE) %>%
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
  model_fit_prophet_boost,
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
  modeltime_refit(data = query)

top_two_models <- refit_tbl %>% 
  modeltime_accuracy() %>% 
  arrange(mae) %>% 
  slice(1:2)

refit_tbl %>%
  filter(.model_id %in% top_two_models$.model_id) %>%
  modeltime_forecast(h = "30 days", actual_data = query) %>%
  filter_by_time(.date_var = .index, .start_date = end_date - 365) %>%
  plot_modeltime_forecast(
    .legend_max_width = 25
    , .interactive = interactive
    , .title = "Daily ED Arrivals Forecast 30 Days Out"
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
    binwidth = 10
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
  , .x_axis = wk
  , .ggplt_group_var = yr
  , yr
  , wk
) + 
  labs(
    x = "Week of Arrival"
    , y = "Total Arrivals"
    , title = "Total ED Arrivals by Week - Grouped by Year"
    , subtitle = "Redline indicates current year."
  )

ts_sum_arrivals_plt(
  .data = query
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
    , title = "Total ED Arrivals by Day - Grouped by Week of the Year"
    , subtitle = "Redline indicates current year."
  )

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
    x = "Month of Arrival"
    , y = "Total Arrivals"
    , title = "Total ED Arrivals by Month - Grouped by Year"
    , subtitle = "Redline indicates current year."
  )

ts_median_excess_plt(
  .data = query
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
    , y = "Excess of Median (+/-)"
    , title = "Median Excess (+/-) ED Arrivals by Week"
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
    x = "Month of Arrival"
    , y = "Excess of Median (+/-)"
    , title = "Median Excess (+/-) ED Arrivals by Month"
    , subtitle = "Redline indicates current year"
  )

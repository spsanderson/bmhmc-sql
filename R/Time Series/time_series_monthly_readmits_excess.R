
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
    DECLARE @START DATE;
    DECLARE @END   DATE;
    
    SET @START = '2014-04-01';
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
  mutate(dsch_date = as.Date.character(dsch_date, format = c("%Y-%m-%d"))) %>%
  mutate(date_col = EOMONTH(dsch_date)) %>%
  select(-dsch_date) %>%
  select(date_col, dsch, ra_flag, rr_bench) %>%
  group_by(date_col) %>%
  summarise(
    dsch_count      = sum(dsch, na.rm = TRUE)
    , readmit_count = sum(ra_flag, na.rm = TRUE)
    , readmit_rate  = round(readmit_count / dsch_count, 4) * 100
    , readmit_bench = round(mean(rr_bench, na.rm = TRUE), 4)  * 100
    , value         = round((readmit_rate - readmit_bench), 2)
  ) %>%
  #select(date_col, value) %>%
  ungroup() %>%
  select(date_col, value) %>%
  filter(year(date_col) >= 2016)

# DB Disconnect -----------------------------------------------------------

dbDisconnect(db_con)


# TS Plot -----------------------------------------------------------------

start_date <- min(query$date_col)
end_date   <- max(query$date_col)

plot_time_series(
  .data = query
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
  .data = query
  , .date_var = date_col
  , .value = value
)

plot_stl_diagnostics(
  .data = query
  , .date_var = date_col
  , .value = value
)

# plot_anomaly_diagnostics(
#   .data = query
#   , .date_var = date_col
#   , .value = value
# )


# Anomalize Data ----------------------------------------------------------

df_anomalized_tbl <- query %>%
  tibbletime::as_tbl_time(index = date_col) %>%
  arrange(date_col) %>%
  time_decompose(value, method = "twitter") %>%
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

model_fit_prophet_boost <- prophet_boost(learn_rate = 0.1) %>% 
  set_engine("prophet_xgboost") %>%
  fit(
    observed_cleaned ~ date_col + as.numeric(date_col) + factor(month(date_col, label = TRUE), ordered = FALSE)
    , data = training(splits)
  )

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
  modeltime_refit(data = df_anomalized_tbl)

top_two_models <- refit_tbl %>% 
  modeltime_accuracy() %>% 
  arrange(mae) %>% 
  slice(1:2)

refit_tbl %>%
  filter(.model_id %in% top_two_models$.model_id) %>%
  modeltime_forecast(h = "1 year", actual_data = df_anomalized_tbl) %>%
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
    , y = "Excess Readmit Rate"
    , title = "Excess Readmit Rate by Month"
    , subtitle = "Readline indicates current year"
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
    x = "Month of Discharge"
    , y = "Excess of Median (+/-)"
    , title = "Median Excess (+/-) Readmit Rate by Month"
    , subtitle = "Redline indicates current year. Grouped by Year."
  )

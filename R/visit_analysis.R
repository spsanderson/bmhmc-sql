
# Lib Load ----------------------------------------------------------------

pacman::p_load(
  "tidyverse",
  "odbc",
  "DBI",
  "LICHospitalR",
  "janitor",
  "lubridate",
  "timetk",
  "patchwork"
)


# Query -------------------------------------------------------------------

db_con <- db_connect()

query <- dbGetQuery(
  conn = db_con,
  statement = paste0(
    "
    DECLARE @START_DATE DATE;
    DECLARE @END_DATE   DATE;
    DECLARE @TODAY      DATE;
    
    SET @TODAY      = GETDATE();
    SET @START_DATE = DATEADD(YEAR, DATEDIFF(YEAR, 0, @TODAY) - 15, 0);
    SET @END_DATE   = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY), 0);
    
    SELECT CAST(PAV.Adm_Date AS DATE) AS [adm_date],
    	PAV.PtNo_Num AS [ptno_num],
    	PAV.Plm_Pt_Acct_Type AS [visit_type]
    FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
    WHERE CAST(PAV.Adm_Date AS DATE) >= @START_DATE
    	AND CAST(PAV.Adm_Date AS DATE) < @END_DATE
    "
  )
) %>% 
  tibble()

db_disconnect(.connection = db_con)

# Data Manipulate ---------------------------------------------------------

data_tbl <- query %>%
  mutate_if(is.character, str_squish) %>%
  mutate(adm_date = ymd(adm_date)) %>%
  mutate(ptno_num = as.character(ptno_num)) %>%
  mutate(visit_type = as.factor(visit_type))

data_daily_tbl <- data_tbl %>%
  group_by(visit_type) %>%
  summarise_by_time(
    .date_var = adm_date,
    .by       = "day",
    value     = n()
  ) %>%
  ungroup()

# Plots -------------------------------------------------------------------


op_cal_heat_plt <- data_daily_tbl %>%
  filter(visit_type == "O") %>%
  filter_by_time(
    .date_var = adm_date,
    .start_date = "2020"
  ) %>%
  ts_calendar_heatmap_plt(
    .date_col = adm_date,
    .value_col = value,
    .plt_title = "Outpatient Arrival Heatmap",
    .interactive = FALSE
  ) +
  labs(
    x = "Week of the Month",
    y = ""
  ) + 
  theme_bw()

ip_cal_heat_plt <- data_daily_tbl %>%
  filter(visit_type == "I") %>%
  filter_by_time(
    .date_var = adm_date,
    .start_date = "2020"
  ) %>%
  ts_calendar_heatmap_plt(
    .date_col = adm_date,
    .value_col = value,
    .plt_title = "Inpatient Arrival Heatmap",
    .interactive = FALSE
  ) +
  labs(
    x = "",
    y = ""
  ) + 
  theme_bw()

ip_cal_heat_plt / op_cal_heat_plt

ip_median_plt <- data_daily_tbl %>%
  filter(visit_type == "I") %>%
  ts_ymwdh_tbl(
    .date_col = adm_date
  ) %>%
  ts_median_excess_plt(
    .date_col = adm_date,
    .value_col = value,
    .x_axis = mn,
    .ggplot_group_var = yr,
    .years_back = 5
  ) +
  labs(
    title = "Median Excess +/- Inpatient Admits",
    subtitle = "Red line indicates current year."
  )
  
op_median_plt <- data_daily_tbl %>%
  filter(visit_type == "O") %>%
  ts_ymwdh_tbl(
    .date_col = adm_date
  ) %>%
  ts_median_excess_plt(
    .date_col = adm_date,
    .value_col = value,
    .x_axis = mn,
    .ggplot_group_var = yr,
    .years_back = 5
  ) +
  labs(
    title = "Median Excess +/- Outpatient Admits",
    subtitle = "Red line indicates current year."
  )

ip_median_plt / op_median_plt

data_daily_tbl %>%
  group_by(visit_type) %>%
  plot_seasonal_diagnostics(
    .date_var = adm_date,
    .value = value,
    .feature_set = c("year","month.lbl","wday.lbl")
  )

# Lib Load ----------------------------------------------------------------

if(!require(pacman)){install.packages("pacman")}
pacman::p_load(
  "tidyverse"
  , "odbc"
  , "DBI"
  , "LICHospitalR"
  , "timetk"
  , "tidyquant"
  , "janitor"
  , "tidytable"
  , "lubridate"
  , "healthyR.ts"
)


# Get Data ----------------------------------------------------------------

db_con <- db_connect()

query <- dbGetQuery(
  conn = db_con
  , statement = paste0(
    "
    DECLARE @Today     DATE;
    DECLARE @StartDate DATE;
    SET @Today     = GETDATE();
    SET @StartDate = DATEADD(YEAR, DATEDIFF(YEAR, 0, @Today) - 10, 0);
    
    SELECT PtNo_Num AS ptno_num,
        Plm_Pt_Acct_Type AS [ip_op_flag],
        CAST(Adm_Date AS DATE) AS [adm_date]
    FROM SMSDSS.BMH_PLM_PtAcct_V
    WHERE LEFT(PtNo_Num, 1) != '2'
        AND LEFT(PtNo_Num, 4) != '1999'
        AND Adm_Date >= @StartDate
        AND tot_chg_amt > 0
    "
  )
)

db_disconnect(.connection = db_con)

# Manipulation ------------------------------------------------------------

data_tbl <- query %>%
  as_tidytable() %>%
  mutate.(across.(where(is.character), str_squish)) %>%
  mutate.(ptno_num = as.character(ptno_num)) %>%
  mutate.(adm_date = ymd(adm_date)) %>%
  mutate.(ip_op_flag = ifelse(ip_op_flag == "O", "Outpatient","Inpatient")) %>%
  group_by(ip_op_flag) %>%
  summarise_by_time(
    .date_var = adm_date
    , .by = "week"
    , value = n()
  ) %>%
  ungroup()

data_tbl %>%
  group_by(ip_op_flag) %>%
  filter_by_time(
    .date_var     = adm_date
    , .start_date = "2018"
  ) %>%
  slice(1:n() - 1) %>%
  plot_time_series(
    .date_var      = adm_date
    , .value       = value
    , .color_var   = ip_op_flag
    , .smooth      = TRUE
    , .facet_ncol  = 1
    , .legend_show = FALSE
    , .interactive = FALSE
    , .title       = "Admissions by IP/OP" 
  )


ip_vva <- data_tbl %>%
  filter(ip_op_flag == "Inpatient") %>%
  filter_by_time(
    .date_var     = adm_date
    , .start_date = "2019"
  ) %>%
  slice(1:n() - 1) %>%
  healthyR.ts::ts_vva_plot(
    .date_col = adm_date,
    .value_col = value
  )

ip_vva$plots$static_plot +
  labs(
    title = "Inpatient Registration Trend, Velocity and Acceleration",
    x = "Date",
    y = "",
    color = ""
  )

df <- data_tbl %>%
  filter(ip_op_flag == "Outpatient") %>%
  filter_by_time(
    .date_var     = adm_date
    , .start_date = "2019"
  ) %>%
  slice(1:n() - 1) %>%
  healthyR.ts::ts_vva_plot(
    .date_col = adm_date,
    .value_col = value
  )

df$plots$static_plot +
  labs(
    title = "Outpatient Registration Trend, Velocity and Acceleration",
    x = "Date",
    y = "",
    color = ""
  )

ip_out <- data_tbl %>%
  filter(ip_op_flag == "Inpatient") %>%
  filter_by_time(
    .date_var     = adm_date
    , .start_date = "2019"
  ) %>%
  slice(1:n() - 1) %>%
  ts_ma_plot(
    .date_col = adm_date
    , .value_col = value
    , .ts_frequency = "weekly"
    , .main_title = "Inpatient Registration"
  )

ip_out$pgrid

op_out <- data_tbl %>%
  filter(ip_op_flag == "Outpatient") %>%
  filter_by_time(
    .date_var     = adm_date
    , .start_date = "2019"
  ) %>%
  slice(1:n() - 1) %>%
  ts_ma_plot(
    .date_col = adm_date
    , .value_col = value
    , .ts_frequency = "weekly"
    , .main_title = "Outpatient Registration"
  )

op_out$pgrid

sma_o_plt <- data_tbl %>%
  filter(ip_op_flag == "Outpatient") %>%
  filter_by_time(
    .date_var     = adm_date
    , .start_date = "2019"
  ) %>%
  slice(1:n() - 1) %>%
  select(-ip_op_flag) %>%
  ts_sma_plot(
    .date_col = adm_date
    , .sma_order = c(3,6)
    , .partial = TRUE
  )
sma_o_plt$plots$static_plot

sma_i_plt <- data_tbl %>%
  filter(ip_op_flag == "Inpatient") %>%
  filter_by_time(
    .date_var     = adm_date
    , .start_date = "2019"
  ) %>%
  slice(1:n() - 1) %>%
  select(-ip_op_flag) %>%
  ts_sma_plot(
    .date_col = adm_date
    , .sma_order = c(3,6)
    , .partial = TRUE
  )
sma_i_plt$plots$static_plot



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
  , "healthyverse"
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
    , .start_date = "2019"
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

data_tbl %>%
  filter(ip_op_flag == "Inpatient") %>%
  filter_by_time(
    .date_var     = adm_date
    , .start_date = "2019"
  ) %>%
  slice(1:n() - 1) %>%
  tk_augment_differences(.value = value, .differences = 1) %>%
  tk_augment_differences(.value = value, .differences = 2) %>%
  rename(velocity = contains("_diff1")) %>%
  rename(acceleration = contains("_diff2")) %>%
  pivot_longer(c(-adm_date, -ip_op_flag)) %>%
  mutate(name = str_to_title(name)) %>%
  mutate(name = as_factor(name)) %>%
  ggplot(aes(x = adm_date, y = value, group = name, color = name)) +
  geom_line() +
  geom_smooth(se = FALSE) +
  facet_wrap(name ~ ., ncol = 1, scale = "free") +
  theme_minimal() +
  labs(
    title = "Inpatient Registration Trend, Velocity and Acceleration",
    x = "Date",
    y = "",
    color = ""
  ) +
  scale_color_tq()

data_tbl %>%
  filter(ip_op_flag == "Outpatient") %>%
  filter_by_time(
    .date_var     = adm_date
    , .start_date = "2019"
  ) %>%
  slice(1:n() - 1) %>%
  tk_augment_differences(.value = value, .differences = 1) %>%
  tk_augment_differences(.value = value, .differences = 2) %>%
  rename(velocity = contains("_diff1")) %>%
  rename(acceleration = contains("_diff2")) %>%
  pivot_longer(c(-adm_date, -ip_op_flag)) %>%
  mutate(name = str_to_title(name)) %>%
  mutate(name = as_factor(name)) %>%
  ggplot(aes(x = adm_date, y = value, group = name, color = name)) +
  geom_line() +
  geom_smooth(se = FALSE) +
  facet_wrap(name ~ ., ncol = 1, scale = "free") +
  theme_minimal() +
  labs(
    title = "Outpatient Registration Trend, Velocity and Acceleration",
    x = "Date",
    y = "",
    color = ""
  ) +
  scale_color_tq()

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
    .sma_order = c(3,6)
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
    .sma_order = c(3,6)
    , .partial = TRUE
  )
sma_i_plt$plots$static_plot

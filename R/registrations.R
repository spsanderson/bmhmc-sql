
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
  mutate_across.(where(is.character), str_squish) %>%
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


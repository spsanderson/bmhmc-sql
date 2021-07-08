
# Library Load ------------------------------------------------------------

if(!require(pacman)){install.packages("pacman")}
pacman::p_load(
  "DBI"
  ,"odbc"
  ,"readr"
  ,"dplyr"
  ,"tibble"
  ,"lubridate"
  ,"timetk"
  ,"stringr"
  ,"healthyR"
)


# Read BD File ----------------------------------------------------------

daily_bd_tbl <- readr::read_table2("S:\\Global Finance\\dailybd\\dailybd.txt")


# Manipulate BD File -------------------------------------------------------

bd_file_tbl <- daily_bd_tbl %>%
  tibble::as_tibble() %>%
  select(1:10) %>%
  purrr::set_names(
    "POST_DATE","SERVICE_DATE","PT_NO","SOURCE","DR_ACCOUNT","DR_AMT"
    ,"CR_ACCOUNT","CR_AMT","TRANS_TYPE","IMPACT"
  ) %>%
  select(1:5, 10, 7:9) %>%
  filter(POST_DATE != "POST") %>%
  filter(!is.na(SERVICE_DATE)) %>%
  rename("DR_AMT" = IMPACT) %>%
  mutate(POST_DATE = mdy(POST_DATE)) %>%
  mutate(SERVICE_DATE = mdy(SERVICE_DATE)) %>%
  arrange(POST_DATE)

# Charity Care Accounts ---------------------------------------------------

db_conn <- LICHospitalR::db_connect()

query <- dbGetQuery(
  conn = db_conn,
  statement = paste0(
    "
    SELECT pt_id,
    tot_pay_adj_amt,
    CAST(pay_dtime as date) as pay_dtime
    FROM SMSDSS.c_charity_care_v
    WHERE pay_dtime >= '2020-01-01'
    AND pay_dtime < '2021-01-01'
    AND Pay_Cd != '09722240';
    "
  )
)

dbDisconnect(conn = db_conn)

charity_accts_tbl <- tibble::as_tibble(query) %>%
  mutate_if(is.character, stringr::str_squish) %>%
  select(pt_id) %>%
  unique()
  

bd_file_tbl %>%
  filter(PT_NO %in% charity_accts_tbl$pt_id) %>%
  select(PT_NO, DR_AMT, POST_DATE, TRANS_TYPE) %>%
  LICHospitalR::save_to_excel(.file_name = "bad_debt_file")

pacman::p_load(
  "tidyverse",
  "odbc",
  "DBI",
  "LICHospitalR",
  "timetk"
)

db_con <- db_connect()

query <- dbGetQuery(
  conn = db_con
  , statement = paste0(
    "
    SELECT nurs_sta
    , pt_id
    , CAST(cen_date as date) AS cen_date
    , CAST(tot_cen as float) AS tot_cen
    
    FROM smsdss.dly_cen_occ_fct_v
    
    WHERE cen_date >= '2021-01-01'
    AND cen_date < '2021-10-01'
    AND nurs_sta IN ('4SOU','2NOR','3NOR','2SOU','3SOU','2PED','2CAD','4NOR',
    'MICU','SICU','CCU')
    "
  )
)

db_disconnect(.connection = db_con)

data_tbl <- query %>%
  as_tibble() %>%
  mutate(nurs_sta = case_when(
    nurs_sta %in% c('CCU','MICU','SICU') ~ nurs_sta
    , TRUE ~ 'MED_SURG'
  )) %>%
  mutate(nurs_sta = as.factor(nurs_sta)) %>%
  mutate(pt_id = pt_id %>% str_squish()) %>%
  mutate(cen_date = anytime::anydate(cen_date))

time_grouping = "quarter"

data_tbl %>%
  group_by(nurs_sta, pt_id) %>%
  summarise_by_time(
    .date_var = cen_date
    , .by     = time_grouping
    , alos    = sum(tot_cen, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  group_by(nurs_sta) %>%
  summarise_by_time(
    .date_var = cen_date
    , .by     = time_grouping
    , value   = mean(alos, na.rm = TRUE)
  ) %>% 
  ungroup() %>%
  pivot_wider(
    names_from = nurs_sta,
    values_from = value
  )

library(tidyverse)
library(timetk)
library(openxlsx)
library(janitor)
library(LICHospitalR)
library(DBI)
library(odbc)
library(dbplyr)

file <- read.xlsx(
  xlsxFile = "//homedir-cifs.nyumc.org//sandes05//apps//xp//desktop//orsos_post_case_2019_2022.xlsx"
)

orsos_tbl <- file %>%
  as_tibble() %>%
  clean_names() %>%
  mutate(across(where(is.character), str_squish)) %>%
  mutate(date = lubridate::mdy(date)) %>%
  mutate(cr_dte = lubridate::mdy(cr_dte))

# orsos_tbl %>%
#   healthyR::save_to_excel(.file_name = "orsos_file_to_dss")

dbWriteTable(
  conn = db_connect(),
  Id(
    schema = "smsdss",
    table = "c_orsos_2019_fwd_tbl"
  ),
  orsos_tbl,
  overwrite = TRUE
)

orsos_tbl %>%
  group_by(patient_type) %>%
  filter(!patient_type %in% c("Z", "DS23","Inpatient","EOR")) %>%
  summarise_by_time(
    .date_var = date,
    .by = "month",
    case_count = n()
  ) %>%
  ungroup() %>%
  plot_time_series(
    .date_var = date,
    .value = case_count,
    .facet_vars = patient_type,
    .facet_ncol = 2,
    .smooth = FALSE
  )

orsos_tbl %>%
  group_by(patient_type, pri_group) %>%
  filter(!patient_type %in% c("Z", "DS23","Inpatient","EOR")) %>%
  summarise_by_time(
    .date_var = date,
    .by = "month",
    case_count = n()
  ) %>%
  ungroup() %>%
  plot_time_series(
    .date_var = date,
    .value = case_count,
    .facet_vars = patient_type,
    .facet_ncol = 2,
    .color_var = pri_group,
    .smooth = FALSE
  )

orsos_tbl %>% 
  filter(pri_group %in% c("ORTHO","UROL")) %>% 
  group_by(pri_group) %>% 
  summarise_by_time(
    .date_var = date, 
    .by = "month", 
    case_count = n()
  ) %>% 
  ungroup() %>% 
  plot_time_series(
    .date_var = date, 
    .value = case_count, 
    .facet_vars = pri_group
  )

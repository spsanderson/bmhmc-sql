
# Lib Load ----------------------------------------------------------------

library(tidyverse)
library(readxl)
library(odbc)
library(DBI)
library(LICHospitalR)
library(tidyquant)


# Data --------------------------------------------------------------------

data_raw_tbl <- read_excel(
  path = "C:/Users/bha485/Desktop/PSIEditsI10.xls"
)

data_working_tbl <- data_raw_tbl %>%
  select(1:(ncol(data_raw_tbl) - 2)) %>%
  filter(complete.cases(.)) %>%
  slice(2:n()) %>%
  set_names("account_no","admit_date","discharge_date","coder","coding_status","psi_edit")

data_final_tbl <- data_working_tbl %>%
  filter(!admit_date == "Admit") %>%
  mutate(admit_date = as.Date(as.numeric(admit_date), origin = "1899-12-30")) %>%
  mutate(discharge_date = as.Date(as.numeric(discharge_date), origin = "1899-12-30")) %>%
  mutate(across(where(is.character), str_squish)) %>%
  mutate(data_inserted_dtime = lubridate::now())

dbWriteTable(
  con = db_connect(),
  Id(
    schema = "smsdss",
    table  = "c_psi_edits_tbl"
  ),
  data_final_tbl,
  append = TRUE
)

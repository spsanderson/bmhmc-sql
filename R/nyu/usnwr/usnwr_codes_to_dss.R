library(readxl)
library(DBI)
library(LICHospitalR)
library(tidyverse)
library(odbc)

file <- read_xlsx(
  path = "P:/NYU Requests/Revenue Cycle/Performance_Analytics/USNWR_SS/dss_spinal_fusion_dx_exclude.xlsx"
)

clean_file <- file %>%
  mutate(proc_cd = str_squish(proc_cd))

db_con <- db_connect()  

DBI::dbWriteTable(
  conn = db_con,
  Id(
    schema = "smsdss",
    table = "c_nyu_usnwr_spinal_fusion_proc_exclusion_tbl"
  ),
  clean_file,
  overwrite = TRUE
)

db_disconnect()


# Lib Load ----------------------------------------------------------------
if(!require(pacman)){install.packages("pacman")}
pacman::p_load(
  "odbc"
  ,"LICHospitalR"
  ,"DBI"
  ,"readxl"
  ,"dplyr"
)

# Excel File --------------------------------------------------------------

excel_file <- read_excel(
  path = "G:/Wound Care/wound_care_daily_batch.xlsx"
)

# DB Connect --------------------------------------------------------------

db_con <- LICHospitalR::db_connect()

# Query -------------------------------------------------------------------

dbWriteTable(
  conn = db_con
  , Id(
    schema  = "smsdss"
    , table = "c_wound_care_daily_batch"
  )
  , excel_file
  , overwrite = TRUE
)

# DB Disconnect -----------------------------------------------------------

db_disconnect(.connection = db_con)


# Clear Env ---------------------------------------------------------------

rm(list = ls())


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
  path = "G:/Finance/Experian/dss_experian_backup/experian_return_file_for_dss.xlsx"
)

# DB Connect --------------------------------------------------------------

db_con <- LICHospitalR::db_connect()

# Query -------------------------------------------------------------------

dbWriteTable(
  conn = db_con
  , Id(
    schema  = "smsdss"
    , table = "c_fin_experian_return_file"
  )
  , excel_file
  , overwrite = TRUE
)

# DB Disconnect -----------------------------------------------------------

db_disconnect(.connection = db_con)


# Clear Env ---------------------------------------------------------------

rm(list = ls())


# Source and Load ---------------------------------------------------------


source("00_Scripts/library_load.R")
source("00_Scripts/db_con_obj.R")
source("01_Queries/query_functions.R")
source("02_Data_Manipulation/data_functions.R")
source("03_Viz/viz_functions.R")
source("04_TS_Modeling/ts_functions.R")
library_load()


# Get Data ----------------------------------------------------------------


admits_tbl     <- admits_query()
discharges_tbl <- discharges_query()

# Make workbook -----------------------------------------------------------

fdate <- Sys.Date()
fname <- "ed_throughput_"
full_fname <- paste0(fname, fdate, ".xlsx")
wb <- xlsx::createWorkbook()
admits_sheet <- xlsx::createSheet(wb, sheetName = "admits")
discharges_sheet <- xlsx::createSheet(wb, sheetName = "discharges")
xlsx::addDataFrame(x = admits_tbl, sheet = admits_sheet)
xlsx::addDataFrame(x = discharges_tbl, sheet = discharges_sheet)
xlsx::saveWorkbook(wb, file = paste0("00_Data/",full_fname))

# Clean Up ----------------------------------------------------------------

rm(list = ls())

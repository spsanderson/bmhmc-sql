
# Source Files ------------------------------------------------------------

source("00_Scripts/db_con_obj.R")
source("00_Scripts/library_load.R")
source("01_Queries/query_functions.R")
source("02_Data_Manipulation/data_functions.R")
source("03_Viz/viz_functions.R")
source("04_TS_Modeling/ts_functions.R")


# Lib Load ----------------------------------------------------------------

library_load()

# Data --------------------------------------------------------------------

denials_tbl <- denials_tbl() %>%
  denials_tbl_formatter()

discharges_tbl <- discharges_query() %>%
  discharges_tbl_formatter()


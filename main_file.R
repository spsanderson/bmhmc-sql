
# Source Files ------------------------------------------------------------


source("00_Scripts/source_file.R")

# Get Data ----------------------------------------------------------------

df_tbl <- covid_uninsured_query()
df_tbl <- tibble::as_tibble(df_tbl) %>%
  mutate(across(.fns = as.character))

file_date <- base::as.Date(base::Sys.Date())
file_name <- base::paste0(
  "covid_uninsured_rundate_"
  , file_date
  , ".csv"
)

# Write File --------------------------------------------------------------

readr::write_excel_csv(
  x = df_tbl
  , file = base::paste0("00_Data\\",file_name)
)

# Clean Environment -------------------------------------------------------

rm(list = ls())

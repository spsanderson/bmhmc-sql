# Library Load ----
library(tidyverse)
library(DBI)
library(odbc)
library(dbplyr)
library(janitor)
library(stringr)

# Set file path ----
folder <- "Treatment"
path   <- "G:/IS/C Wurtz/Sepsis/csv_files30/"
full_path <- paste0(path,folder,"/")

# File List ----
file_list <- dir(full_path
                 , pattern = "\\.csv$"
                 , full.names = T)

# Read Files ----
files <- file_list %>%
  map(read.csv) %>%
  map(as_tibble)

# Clean File Names ----
file_names <- file_list %>%
  str_remove(full_path) %>%
  str_replace(pattern = "_VerD3.0.csv", replacement = "_v30.csv")

names(files) <- file_names

# Clean column names ----
files <- map(files, clean_names)

# Columns to Characters ----
files <- map(
  files,
  ~ .x %>%
    mutate(across(everything(), ~ str_squish(.x)))
)

# Load to DSS ----
con <- LICHospitalR::db_connect()
for(i in 1:length(files)){
  file_to_dss_name <- paste0("c_nysdoh_sepsis_", names(files[i]))
  file_name_clean  <- file_to_dss_name %>% str_replace("_v30.csv","")
  file_tbl         <- files[[i]]
  print(paste0("Inserting ",file_name_clean, " into DSS"))
  DBI::dbWriteTable(
    conn = con
    , Id(
      schema = "smsdss"
      , table = file_name_clean %>% as.character()
    )
    , file_tbl
    , overwrite = TRUE
  )
}
LICHospitalR::db_disconnect(con)

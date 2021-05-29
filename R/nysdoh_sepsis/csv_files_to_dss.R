library(tidyverse)
library(DBI)
library(odbc)
library(dbplyr)

folder <- "Treatment"
path   <- "G:/IS/C Wurtz/Sepsis/csv_files211/"
full_path <- paste0(path,folder,"/")

file_list <- dir(full_path
                 , pattern = "\\.csv$"
                 , full.names = T)

files <- file_list %>%
  map(read.csv)

file_names <- file_list %>%
  #str_remove("G:/IS/C Wurtz/Sepsis/csv_files21/Treatment/") %>%
  str_remove(full_path) %>%
  str_replace(pattern = "_VerD2.1.1.csv", replacement = "_v211.csv")

names(files) <- file_names

column_names <- c(
  "pcs_code"
  ,"pcs_code_description"
  ,"subcategory"
)

for(i in 1:length(files)){
  print(names(files[[i]]))
  if(ncol(files[[i]]) <= 3){
    colnames(files[[i]]) <- column_names
    }
  print(names(files[[i]]))
}

con <- LICHospitalR::db_connect()
for(i in 1:length(files)){
  file_to_dss_name <- paste0("c_nysdoh_sepsis_", names(files[i]))
  file_name_clean  <- file_to_dss_name %>% str_replace("_v211.csv","")
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

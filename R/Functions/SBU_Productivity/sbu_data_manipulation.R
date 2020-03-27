# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse",
    "lubridate",
    "janitor",
    "readxl"
)

# Data Load ----
# Read in excel file
excel_tbl <- read_excel("00_data/practice_pofile_data.xlsx")
# Write out as RDS file
write_rds(excel_tbl, "00_data/excel_to_rds.rds")
# Read in RDS file
df_tbl <- read_rds("00_data/excel_to_rds.rds")
# Drop excel_tbl
rm(excel_tbl)


# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse"
    , "dbplyr"
    , "DBI"
    , "odbc"
    , "readxl"
)

# Load Excel File ----
df <- read_excel(
        path = "G:\\Desktop Working Files\\Friday Experian File.xlsx"
        , sheet = "Sheet1"
    )

# Make sure records are distinct
df <- df %>% 
    distinct()

# DB Connection ----
db_con <- dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "BMH-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = T
)

# Insert Records ----
dbWriteTable(
    db_con
    , Id(
        schema = "smsdss"
        , table = "c_friday_experian_file"
    )
    , df
    , overwrite = TRUE
)

# DB Disconnect
dbDisconnect(db_con)

# Clean Env
rm(list = ls())

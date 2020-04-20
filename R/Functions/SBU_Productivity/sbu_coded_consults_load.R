# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "odbc",
    "DBI",
    "tidyverse",
    "dbplyr",
    "janitor",
    "lubridate"
)

# DB Connection ----
db_con <- dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "BMH-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = T
)

# Data ----
coded_consults_tbl <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        SELECT *
        FROM smsdss.c_coded_consults_v AS A
        INNER JOIN smsdss.c_sbu_provider_tbl AS B
        ON A.RespParty = B.pract_no
    	AND Dsch_Date >= '2018-01-01'
        "
    )
) %>%
    as_tibble() %>%
    clean_names()

# DB Disconnect ----
dbDisconnect(db_con)

# Write out RDS to be used in mainp script
write_rds(
    coded_consults_tbl, 
    "G:\\R Studio Projects\\SBU_Productivity\\00_data\\coded_consults_rds.rds"
    )

coded_consults_tbl <- read_rds(
    "G:\\R Studio Projects\\SBU_Productivity\\00_data\\coded_consults_rds.rds"
)

coded_consults_tbl <- coded_consults_tbl %>%
    select(
        -consultant_spec
        , -clasf_cd
        , -last_name
        , -first_name
        , -pract_no
        , -spclty_cd1
        , -consultant
        , -department
    )

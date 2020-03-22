# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse"
    , "dbplyr"
    , "DBI"
    , "odbc"
    , "RDCOMClient"
    , "janitor"
)

# DB Connection ----
db_con <- dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "BMH-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = T
)

# Get Data ----
query <- dbGetQuery(
    conn = db_con
    , paste0(
        "
        DECLARE @TODAY DATE;
        DECLARE @START DATE;
        DECLARE @END   DATE;
        
        SET @TODAY = GETDATE();
        SET @START = DATEADD(WEEK, DATEDIFF(WEEK, 0, @TODAY) - 1, -1);
        SET @END   = DATEADD(WEEK, DATEDIFF(WEEK, 0, @TODAY), -1);
        
        SELECT PAV.Med_Rec_No
        , CAST(PAV.DSCH_DATE AS date) AS [Discharge_Date]
        
        FROM SMSDSS.BMH_PLM_PTACCT_V AS PAV
        
        WHERE PAV.hosp_svc = 'PSY'
        AND LEFT(PAV.PTNO_NUM, 1) != '2'
        AND LEFT(PAV.PTNO_NUM, 4) != '1999'
        AND PAV.Dsch_Date >= @START
        AND PAV.Dsch_Date < @END
        
        ORDER BY CAST(PAV.DSCH_DATE AS DATE)
        "
    )
)

query <- query %>%
    as_tibble() %>%
    clean_names()

# DB Disconnect ----
dbDisconnect(db_con)

# Write File ----
query %>%
    write.csv("G:\\Psych\\weekly_psy_discharges.csv")

# Compose Email ----
# Open Outlook
Outlook <- COMCreate("Outlook.Application")

# Create Email
Email = Outlook$CreateItem(0)

# Set the recipeitn, subject, and body
Email[["to"]] = ""
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = "Weekly PSY Discharges"
Email[["body"]] = "Please see the attached for weekly PSY Discharges."
Email[["attachments"]]$Add("G:\\Psych\\weekly_psy_discharges.csv")

# Send the email
Email$Send()

# Clost Outlook, clear the message
rm(list = ls())

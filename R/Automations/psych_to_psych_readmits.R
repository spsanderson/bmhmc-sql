# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse"
    , "dbplyr"
    , "DBI"
    , "odbc"
    , "RDCOMClient"
)

# Source function ----
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\clean_names.R")


# DB Connection ----
db_con <- dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "BMH-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = T
)

# Get CDI Records ----
query <- dbGetQuery(
    db_con
    , paste0(
        "
        DECLARE @ThisDate DATETIME;
        DECLARE @START DATETIME;
        DECLARE @END   DATETIME;
        
        SET @ThisDate = GETDATE();
        SET @START = dateadd(mm, datediff(mm, 0, @ThisDate) - 2, 0);
        SET @END   = dateadd(mm, datediff(mm, 0, @ThisDate) - 1, 0);
        
        WITH CTE AS (
        	SELECT Med_Rec_No
        	, PtNo_Num
        	, Adm_Date
        	, Dsch_Date
        	, Days_Stay
        	, hosp_svc
        	, vst_start_dtime
        	, RN = ROW_NUMBER() OVER(PARTITION BY MED_REC_NO ORDER BY VST_START_DTIME)
        	
        	FROM smsdss.BMH_PLM_PtAcct_V
        	
        	WHERE hosp_svc = 'PSY'
        	AND Dsch_Date >= @START
        	AND Dsch_Date < @END
        )
        
        SELECT C1.Med_Rec_No
        , C1.PtNo_Num AS [INDEX ENC]
        , C1.Adm_Date AS [INDEX ADM DATE]
        , C1.Dsch_Date AS [INDEX DSCH DATE]
        , DATEPART(MONTH, C1.DSCH_DATE) AS [INDEX DSCH MONTH]
        , C2.PtNo_Num AS [READMIT ENC]
        , C2.Adm_Date AS [READMIT ADM DATE]
        , C2.Dsch_Date AS [READMIT DSCH DATE]
        , DATEDIFF(D, C1.DSCH_DATE, C2.ADM_DATE) AS [INTERIM]
        
        FROM CTE AS C1
        INNER JOIN CTE AS C2
        ON C1.Med_Rec_No = C2.Med_Rec_No
        
        WHERE C1.vst_start_dtime < C2.vst_start_dtime
        AND C1.RN + 1 = C2.RN
        AND DATEDIFF(D, C1.DSCH_DATE, C2.Adm_Date) > 0
        AND DATEDIFF(D, C1.DSCH_DATE, C2.ADM_DATE) < 31
        
        ORDER BY C1.Dsch_Date
        
        OPTION(FORCE ORDER);
        "
    )
)

query_tbl <- query %>%
    as_tibble() %>%
    clean_names()

# DB Disconnect ----
dbDisconnect(db_con)

# Write File ----
query_tbl %>%
    write.csv("G:\\Psych\\psych_to_psych_readmits.csv")

# Compose Email ----
# Open Outlook
Outlook <- COMCreate("Outlook.Application")

# Create Email
Email = Outlook$CreateItem(0)

# Set the recipeitn, subject, and body
Email[["to"]] = "email-placeholder"
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = "PSY to PSY Readmits"
Email[["body"]] = "Please see the attached for Psych to Psych Readmits. Remeber this data is about 45 days lagged."
Email[["attachments"]]$Add("G:\\Psych\\psych_to_psych_readmits.csv")

# Send the email
Email$Send()

# Clost Outlook, clear the message
rm(list = ls())

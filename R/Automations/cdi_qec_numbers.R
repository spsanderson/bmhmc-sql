# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse"
    , "dbplyr"
    , "DBI"
    , "odbc"
    , "RDCOMClient"
)

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
        SET @START = dateadd(mm, datediff(mm, 0, @ThisDate) - 1, 0);
        SET @END   = dateadd(mm, datediff(mm, 0, @ThisDate), 0);
        
        -- Total Admits All Payers Including PSY
        SELECT 'Total Admits All Payers Including PSY' AS [Category]
        , DATEPART(MONTH, ADM_DATE) AS [Month]
        , COUNT(DISTINCT(PTNO_nUM)) AS [PT_Count]
        
        FROM smsdss.BMH_PLM_PtAcct_V
        
        WHERE Adm_Date >= @START
        AND Adm_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'
        
        GROUP BY DATEPART(MONTH, Adm_Date)
        
        UNION
        
        -- Total Admits All Payers Excluding PSY
        SELECT 'Total Admits All Payers Excluding PSY' AS [Category]
        , DATEPART(MONTH, ADM_DATE) AS [Month]
        , COUNT(DISTINCT(PTNO_nUM)) AS [PT_Count]
        
        FROM smsdss.BMH_PLM_PtAcct_V
        
        WHERE Adm_Date >= @START
        AND Adm_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'
        AND hosp_svc != 'PSY'
        
        GROUP BY DATEPART(MONTH, Adm_Date)
        
        UNION
        
        -- Total Admits Medicare Including PSY
        SELECT 'Total Admits Medicare Including PSY' AS [Category]
        , DATEPART(MONTH, ADM_DATE) AS [Month]
        , COUNT(DISTINCT(PTNO_nUM)) AS [PT_Count]
        
        FROM smsdss.BMH_PLM_PtAcct_V
        
        WHERE Adm_Date >= @START
        AND Adm_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'
        AND User_Pyr1_Cat IN ('AAA', 'ZZZ')
        
        GROUP BY DATEPART(MONTH, Adm_Date)
        
        UNION
        
        -- Total Admits Medicare Excluding PSY
        SELECT 'Total Admits Medicare Excluding PSY' AS [Category]
        , DATEPART(MONTH, ADM_DATE) AS [Month]
        , COUNT(DISTINCT(PTNO_nUM)) AS [PT_Count]
        
        FROM smsdss.BMH_PLM_PtAcct_V
        
        WHERE Adm_Date >= @START
        AND Adm_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'
        AND User_Pyr1_Cat IN ('AAA', 'ZZZ')
        AND hosp_svc != 'PSY'
        
        GROUP BY DATEPART(MONTH, Adm_Date)
        
        UNION
        
        -- Total Discharges All Payers Including PSY
        SELECT 'Total Discharges All Payers Including PSY' AS [Category]
        , DATEPART(MONTH, Dsch_Date) AS [Month]
        , COUNT(DISTINCT(PtNo_Num)) AS [PT_Count]
        
        FROM smsdss.BMH_PLM_PtAcct_V
        
        WHERE Dsch_Date >= @START
        AND Dsch_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'
        
        GROUP BY DATEPART(MONTH, Dsch_Date)
        
        UNION
        
        -- Total Discharges All Payers Excluding PSY
        SELECT 'Total Discharges All Payers Excluding PSY' AS [Category]
        , DATEPART(MONTH, Dsch_Date) AS [Month]
        , COUNT(DISTINCT(PtNo_Num)) AS [PT_Count]
        
        FROM smsdss.BMH_PLM_PtAcct_V
        
        WHERE Dsch_Date >= @START
        AND Dsch_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'
        AND hosp_svc != 'PSY'
        
        GROUP BY DATEPART(MONTH, Dsch_Date)
        
        UNION
        
        -- Total Discharges Medicare Including PSY
        SELECT 'Total Discharges Medicare Including PSY' AS [Category]
        , DATEPART(MONTH, Dsch_Date) AS [Month]
        , COUNT(DISTINCT(PtNo_Num)) AS [PT_Count]
        
        FROM smsdss.BMH_PLM_PtAcct_V
        
        WHERE Dsch_Date >= @START
        AND Dsch_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'
        AND User_Pyr1_Cat IN ('AAA', 'ZZZ')
        
        GROUP BY DATEPART(MONTH, Dsch_Date)
        
        UNION
        
        -- Total Discharges Medicare Excluding PSY
        SELECT 'Total Discharges Medicare Excluding PSY' AS [Category]
        , DATEPART(MONTH, Dsch_Date) AS [Month]
        , COUNT(DISTINCT(PtNo_Num)) AS [PT_Count]
        
        FROM smsdss.BMH_PLM_PtAcct_V
        
        WHERE Dsch_Date >= @START
        AND Dsch_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'
        AND User_Pyr1_Cat IN ('AAA', 'ZZZ')
        AND hosp_svc != 'PSY'
        
        GROUP BY DATEPART(MONTH, Dsch_Date)
        ;
        "
    )
)

query <- query %>%
    as_tibble() %>%
    write.csv("G:\\CDI\\cdi.csv")

# DB Disconnect ----
dbDisconnect(db_con)

# Compose Email ----
# Open Outlook
Outlook <- COMCreate("Outlook.Application")

# Create Email
Email = Outlook$CreateItem(0)

# Set the recipeitn, subject, and body
Email[["to"]] = ""
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = "CDI QEC Numbers"
Email[["body"]] = "Please see the attached for the latest CDI QEC numbers"
Email[["attachments"]]$Add("G:\\CDI\\cdi.csv")

# Send the email
Email$Send()

# Clost Outlook, clear the message
rm(list = ls())

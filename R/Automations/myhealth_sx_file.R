# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse"
    , "dbplyr"
    , "DBI"
    , "odbc"
    , "RDCOMClient"
    , "lubridate"
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

# Query ----
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
        
        WITH CTE AS (
        SELECT A.CASE_NO
        , C.FACILITY_ACCOUNT_NO
        , E.RESOURCE_ID
        , A.PROVIDER_SHORT_NAME
        , A.ROOM_ID
        , CAST(A.START_DATE AS DATE)              AS [START_DATE]
        , CAST(A.ENTER_PROC_ROOM_TIME AS TIME(0)) AS [ENTER_PROC_ROOM_TIME]
        , CAST(A.LEAVE_PROC_ROOM_TIME AS TIME(0)) AS [LEAVE_PROC_ROOM_TIME]
        , B.[DESCRIPTION] AS PROCEDURE_DESCRIPTION
        , CAST(D.ANES_START_DATE AS DATE)         AS [ANES_START_DATE]
        , CAST(D.ANES_START_TIME AS TIME(0))      AS [ANES_START_TIME]
        , CAST(D.ANES_STOP_DATE AS DATE)          AS [ANES_STOP_DATE]
        , CAST(D.ANES_STOP_TIME AS TIME(0))       AS [ANES_STOP_TIME]
        , C.PATIENT_TYPE
        , CAST(A.ADMIT_RECOVERY_DATE AS DATE)     AS [ADMIT_RECOVERY_DATE]
        , CAST(A.ADMIT_RECOVERY_TIME AS TIME(0))  AS [ADMIT_RECOVERY_TIME]
        , CAST(A.LEAVE_RECOVERY_DATE AS DATE)     AS [LEAVE_RECOVERY_DATE]
        , CAST(A.LEAVE_RECOVERY_TIME AS TIME(0))  AS [LEAVE_RECOVERY_TIME]
        
        FROM 
        (
        (
        [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_CASE]              AS A
        INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[PROCEDURES]  AS B
        ON A.MAIN_PROCEDURE_ID = B.PROCEDURE_ID
        )
        INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL]        AS C
        ON A.ACCOUNT_NO = C.ACCOUNT_NO
        )
        LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_ANES_TYPE] AS D
        ON A.CASE_NO = D.CASE_NO
        LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_RESOURCE]  AS E
        ON A.CASE_NO = E.CASE_NO
        AND E.ROLE_CODE = '1'
        LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CODES_ROLE]     AS F
        ON E.ROLE_CODE = F.CODE
        
        WHERE (
        A.DELETE_FLAG IS NULL
        OR 
        (
        A.DELETE_FLAG = ''
        OR
        A.DELETE_FLAG = 'Z'
        )
        )
        AND (
        (A.START_DATE >= @START AND A.START_DATE < @END)
        )
        AND RIGHT(C.FACILITY_ACCOUNT_NO, 1) != 'J'
        AND E.RESOURCE_ID IN ('00593','014241')
        )
        
        SELECT * FROM CTE;
        "
    )
)

query_tbl <- query %>%
    as_tibble() %>%
    set_names(
        'ORSOS Case No',
        'DSS Case No',
        'ORSOS MD ID',
        'Provider Name',
        'ORSOS Room ID',
        'ORSOS Start Date',
        'Ent Proc Rm Time',
        'Leave Proc Rm Time',
        'Procedure',
        'Anes Start Date',
        'Anes Start Time',
        'Anes End Date',
        'Anes End Time',
        'Patient Type',
        'Adm Recovery Date',
        'Adm Recovery Time',
        'Leave Recovery Date',
        'Leave Recovery Time'
    ) %>%
    clean_names() %>%
    mutate(
        orsos_start_date = orsos_start_date %>% ymd()
        , anes_start_date = anes_start_date %>% ymd()
        , anes_end_date = anes_end_date %>% ymd()
        , adm_recovery_date = adm_recovery_date %>% ymd()
        , leave_recovery_date = leave_recovery_date %>% ymd()
    )

# DB Disconnect ----
dbDisconnect(db_con)

# Write File ----
dt <-  Sys.Date() %>% as_date()
dt_fname <- dt %m-% months(1)
f_month <- month(dt_fname, label = TRUE, abbr = FALSE) %>% as.character()
f_year <- year(dt) %>% as.character()
f_name <- str_c(
    f_month
    , f_year
    , "_rundate_"
    , str_sub(dt, 6, 7)
    , str_sub(dt, 9, 10)
    , str_sub(dt, 1, 4)
    , ".csv"
)

query_tbl %>%
    as_tibble() %>%
    write.csv(
        paste0(
            "G:\\MyHealth\\Monthly Sx Reports\\"
            , f_name
        )
    )

# Compose Email ----
# file path
f_path <- paste0("G:\\MyHealth\\Monthly Sx Reports\\", f_name)

# Open Outlook
Outlook <- COMCreate("Outlook.Application")

# Create Email
Email = Outlook$CreateItem(0)

# Set the recipeitn, subject, and body
Email[["to"]] = "email-placeholder"
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = "Monthly MyHealth Sx Report"
Email[["body"]] = "Please see the attached for the latest report"
Email[["attachments"]]$Add(
    paste0(
        f_path
        )
    )

# Send the email
Email$Send()

# Clost Outlook, clear the message
rm(list = ls())

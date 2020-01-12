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

# Get J Accounts ----
query <- dbGetQuery(
    db_con
    , paste0(
        "
        DECLARE @ThisDate       DATETIME;
        DECLARE @ORSOS_START_DT DATETIME;
        DECLARE @ORSOS_END_DT   DATETIME;
        
        SET @ThisDate       = GETDATE();
        SET @ORSOS_START_DT = dateadd(yy, datediff(yy, 0, @ThisDate), 0);
        SET @ORSOS_END_DT   = dateadd(wk, datediff(wk, 0, @ThisDate),  -1);
        
        SELECT A.CASE_NO
        , C.FACILITY_ACCOUNT_NO
        
        FROM 
        (
        	(
        		[BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_CASE] AS A
        		INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[PROCEDURES] AS B
        		ON A.MAIN_PROCEDURE_ID = B.PROCEDURE_ID
        	)
        	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS C
        	ON A.ACCOUNT_NO = C.ACCOUNT_NO
        )
        LEFT JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_ANES_TYPE] AS D
        ON A.CASE_NO = D.CASE_NO
        LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CODES_ANES_TYPE] AS E
        ON D.ANES_TYPE_CODE = E.CODE
        
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
        	A.START_DATE >= @ORSOS_START_DT
        	AND
        	A.START_DATE <  @ORSOS_END_DT 
        )
        
        AND RIGHT(c.FACILITY_ACCOUNT_NO, 1) = 'J'
        
        ORDER BY C.FACILITY_ACCOUNT_NO
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
    write.csv("G:\\IS\\j_accounts.csv")

# Compose Email ----
# Open Outlook
Outlook <- COMCreate("Outlook.Application")

# Create Email
Email = Outlook$CreateItem(0)

# Set the recipeitn, subject, and body
Email[["to"]] = "CAKeenan@LICommunityHospital.org"
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = "ORSOS J Accounts"
Email[["body"]] = "Please see the attached for J Accounts."
Email[["attachments"]]$Add("G:\\IS\\j_accounts.csv")

# Send the email
Email$Send()

# Clost Outlook, clear the message
rm(list = ls())
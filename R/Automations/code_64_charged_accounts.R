
# Lib Load ----------------------------------------------------------------

if(!require(pacman)) {
  install.packages("pacman")
}
pacman::p_load(
  "tidyverse"
  , "dplyr"
  , "DBI"
  , "odbc"
  , "RDCOMClient"
  , "janitor"
)

# DB Connection -----------------------------------------------------------

db_con_obj <- dbConnect(
  odbc(),
  Driver = "SQL Server",
  Server = "BMH-HIDB",
  Database = "SMSPHDSSS0X0",
  Trusted_Connection = T
)


# Query -------------------------------------------------------------------

df_tbl <- dbGetQuery(
  conn = db_con_obj,
  statement = paste0(
    "
    DECLARE @START_DATE DATE;
    DECLARE @END_DATE   DATE;
    
    SET @START_DATE = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0)
    SET @END_DATE   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
    
    SELECT substring(pt_id, 5, 8) AS [ptno_num],
    	unit_seq_no,
    	from_file_ind,
    	actv_date,
    	sum(actv_tot_qty) AS [tot_qty],
    	sum(chg_tot_amt) AS [tot_code_chg]
    FROM smsmir.actv
    WHERE actv_cd IN ('01000504', '01000553')
    	AND actv_date >= @START_DATE
    	AND actv_date < @END_DATE
    GROUP BY pt_id,
    	unit_seq_no,
    	from_file_ind,
    	actv_date
    ORDER BY ptno_num,
    	actv_date
    "
  )
)

# DB Disconnect -----------------------------------------------------------

dbDisconnect(db_con_obj)

# Write File --------------------------------------------------------------

dt <- Sys.Date() %>% str_replace_all(pattern = "-", replacement = "_")
folder_yr <- str_sub(dt, 1, 4)
file_name <- paste0("code64_cases","_",dt,".csv")
f_path <- paste0("G:\\Performance_Improvement\\Code64_Data\\",folder_yr,"\\")

# Does dir exist?
if(!fs::dir_exists(f_path)){
  fs::dir_create(f_path)
}

df_tbl %>%
  filter(tot_qty > 0) %>%
  write_csv(paste0(f_path, file_name))

# Compose Email -----------------------------------------------------------

w_path <- paste0(f_path, file_name)

Outlook <- COMCreate("Outlook.Application")

# Create Email
Email <- Outlook$CreateItem(0)

# Set the recipient, subject, body, and attachment
Email[["to"]] = ""
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = "Code 64 Charged Accounts"
Email[["body"]] = "Please see the attached for the latest report"
Email[["attachments"]]$Add(paste0(w_path))

# Send the email
Email$Send()

# Close Outlook, clear the message
rm(list = ls())

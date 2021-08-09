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
    Server = "LI-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = T
)

# Data ----
query <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        DECLARE @ThisDate DATETIME2;
        SET @ThisDate = GETDATE();
        
        SELECT [Patient_ID]
        , [episode_no]
        , [Coder]
        , [Date_Coded]
        , b.adm_dtime
        , b.dsch_dtime
        , DATEDIFF(dd,b.dsch_dtime, a.date_coded) As [Lag]
        , DATEPART(YEAR, A.[Date_Coded]) AS [Year_Coded]
        , DATEPART(MONTH, A.[Date_Coded]) AS [Month_Coded]
             
        FROM [SMSPHDSSS0X0].[smsdss].[c_bmh_coder_activity_v] as a 
        left outer join smsmir.mir_acct as b
        ON a.Patient_ID = b.pt_id 
          
        where Date_Coded >= dateadd(mm, datediff(mm, 0, @ThisDate) - 1, 0)
        AND Date_Coded < dateadd(mm, datediff(mm, 0, @ThisDate), 0)
        AND LEFT(patient_id,5) = '00001'
        "
    )
) %>%
    as_tibble() %>%
    clean_names()

# DB Disconnect ----
dbDisconnect(db_con)

# Data Summary ----
coder_tbl <- query %>%
    select(coder, lag) %>%
    group_by(coder) %>%
    summarise(
        count = n()
        , avg_lag = round(mean(lag), 2)
    ) %>%
    ungroup()

gt_tbl <- query %>%
    summarise(
        coder = "Grand Totals"
        , count = n()
        , avg_lag = round(mean(lag), 2)
    )

final_tbl <- rbind(coder_tbl, gt_tbl)

# Write to file ----
today <- Sys.Date()
rpt_date <- floor_date(today, "month") - months(1)
f_year <- lubridate::year(rpt_date)
f_month <- lubridate::month(rpt_date, abbr = FALSE, label = TRUE) %>% 
    as.character()
f_name <- paste0(f_month,f_year,"_IP_Coding_Lag-test.csv")

# Check file path
f_path <- paste0("G:\\HIM\\Rosemarie\\Coding Lag\\",f_year,"\\")
if(!fs::dir_exists(f_path)){
    fs::dir_create(f_path)
}

# Write file
w_path <- paste0(f_path,f_name)
write_csv(x = final_tbl, path = w_path)

# Compose Email ----
# Open Outlook
Outlook <- COMCreate("Outlook.Application")

# Create Email
Email = Outlook$CreateItem(0)

# Set the recipeitn, subject, and body
Email[["to"]] = ""
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = "IP Coding Lag Report"
Email[["body"]] = "Please see the attached for the latest report"
Email[["attachments"]]$Add(
    paste0(
        w_path
    )
)

# Send the email
Email$Send()

# Clost Outlook, clear the message
rm(list = ls())

# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse"
    , "dbplyr"
    , "DBI"
    , "odbc"
    , "RDCOMClient"
    , "janitor"
    , "xlsx"
    , "tidyquant"
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
tempa <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        DECLARE @ThisDate DATETIME2;
        DECLARE @SD DATETIME2;
        DECLARE @ED DATETIME2;
        
        SET @ThisDate = GETDATE();
        SET @SD = dateadd(mm, datediff(mm, 0, @ThisDate) - 1, 0);
        SET @ED = dateadd(mm, datediff(mm, 0, @ThisDate), 0);
        
        SELECT A.pt_id
        , a.hosp_svc
        , a.nurs_sta
        , CAST(a.cen_date AS date) AS [cen_date]
        , DATEPART(YEAR, A.CEN_DATE) AS [cen_yr]
        , DATEPART(MONTH, A.CEN_DATE) AS [cen_mo]
        , a.tot_cen
        , a.pract_no AS [Attending_ID]
        , UPPER(B.pract_rpt_name) AS [Attending_Name]
        , CASE
        	WHEN B.src_spclty_cd = 'HOSIM'
        		THEN 'Hospitalist'
        		ELSE 'Private'
          END AS [Hospitalist_Private]
        , CASE
        	WHEN B.src_spclty_cd = 'HOSIM'
        		THEN '1'
        		ELSE '0'
          END AS [Hospitalist_Atn_Flag]
        , CASE
        	WHEN B.src_spclty_cd != 'HOSIM'
        		THEN '1'
        		ELSE '0'
          END AS [Private_Atn_Flag]
        , CAST(C.Adm_Date AS date) AS [Adm_Date]
        , CAST(C.Dsch_Date AS date) AS [Dsch_Date]
        -- IF THE DSCH_DATE IS NOT NULL AND THERE ARE $0.00 CHARGES KICK IT OUT
        , CASE
        	WHEN C.Dsch_Date IS NOT NULL
        	AND C.tot_chg_amt <= 0
        		THEN 1
        		ELSE 0
          END AS [Kick_Out_Flag]
        
        FROM smsdss.dly_cen_occ_fct_v AS A
        LEFT OUTER JOIN smsdss.pract_dim_v AS B
        ON A.pract_no = B.src_pract_no
        	AND B.orgz_cd = 's0x0'
        LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS C
        ON A.pt_id = C.Pt_No
        
        WHERE cen_date >= @SD
        AND cen_date < @ED
        
        ORDER BY pt_id
        , cen_date
        ;
        "
    )
) %>% 
    as_tibble() %>%
    clean_names()

# DB Disconnect ----
dbDisconnect(db_con)

# Data Manipulation ----
data_tbl <- tempa %>%
    select(
        pt_id
        , hosp_svc
        , nurs_sta
        , cen_date
        , cen_yr
        , cen_mo
        , tot_cen
        , attending_id
        , attending_name
        , hospitalist_private
        , hospitalist_atn_flag
        , private_atn_flag
        , adm_date
        , dsch_date
        , kick_out_flag
    ) %>%
    group_by(pt_id, cen_date) %>%
    mutate(
        rn = with_order(
            order_by = cen_date
            , fun = row_number
            , x = cen_date
        )
    ) %>%
    ungroup() %>%
    filter(kick_out_flag == 0) %>%
    filter(rn == 1)

summary_tbl <- data_tbl %>%
    group_by(attending_id, attending_name) %>%
    summarise(tot_cen = sum(tot_cen, na.rm = TRUE)) %>%
    ungroup() %>%
    arrange(attending_name) %>%
    mutate(attending_name = str_to_title(attending_name))

# Write to file ----
today <- Sys.Date()
rpt_date <- floor_date(today, "month") - months(1)
f_year <- lubridate::year(rpt_date)
f_month <- lubridate::month(rpt_date, abbr = FALSE, label = TRUE) %>% 
    as.character()
f_name <- paste0(
    f_month
    , "_"
    , f_year
    , "_patient_days_by_md_rundate_"
    , today
    , ".xlsx"
)

# Check file path
f_path <- paste0("G:\\Infection Control\\Patient Days\\",f_year,"\\")
if(!fs::dir_exists(f_path)){
    fs::dir_create(f_path)
}

# Write file
w_path <- paste0(f_path,f_name)
wb <- createWorkbook(type="xlsx")
data_sheet <- createSheet(wb, sheetName = "data")
summary_sheet <- createSheet(wb, sheetName = "summary")
addDataFrame(
    x = data_tbl
    , sheet = data_sheet
)
addDataFrame(
    x = summary_tbl
    , sheet = summary_sheet
)
saveWorkbook(
    wb
    , file = w_path
)

# Compose Email ----
# Open Outlook
Outlook <- COMCreate("Outlook.Application")

# Create Email
Email = Outlook$CreateItem(0)

# Set the recipeitn, subject, and body
Email[["to"]] = ""
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = "Patient Days Report"
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

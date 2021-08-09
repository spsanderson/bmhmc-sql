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
tempa <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        SELECT B.Pt_Name
        , B.Pt_Birthdate
        , B.Med_Rec_No
        , A.pt_id
        , A.proc_eff_date
        , A.proc_cd
        , A.proc_cd_modf1
        
        FROM smsmir.sproc AS A
        LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS B
        ON A.PT_ID = B.Pt_No
        
        WHERE A.proc_eff_date >= dateadd(MM, datediff(MM, 0, GETDATE()), 0) 
        AND A.proc_cd IN ('66820', '66821', '66830', '66982', '66983', '66984')
        AND LEFT(pt_id, 4) = '0000'
        
        ORDER BY B.MED_REC_NO
        , A.proc_eff_date
        "
    )
) %>%
    as_tibble() %>%
    clean_names()

tempb <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        SELECT B.Pt_Name
    	, B.Pt_Birthdate
    	, B.Med_Rec_No
    	, A.pt_id
    	, A.proc_eff_date
    	, A.proc_cd
    	, A.proc_cd_modf1
    
    	FROM smsmir.sproc AS A
    	LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS B
    	ON A.PT_ID = B.Pt_No
    	
    	WHERE A.proc_cd IN ('66820', '66821', '66830', '66982', '66983', '66984')
    	AND LEFT(A.PT_ID, 4) = '0000'
        "
    )
) %>% 
    as_tibble() %>%
    clean_names() %>%
    filter(med_rec_no %in% tempa$med_rec_no) %>%
    filter(!pt_id %in% tempa$pt_id)

# DB Disconnect ----
dbDisconnect(db_con)

# Manip Data ----
unioned_tbl <- dplyr::union(x = tempa, y = tempb) 

unioned_tbl %>%
    group_by(med_rec_no, proc_cd_modf1) %>%
    mutate(
        rn = with_order(
            order_by = proc_eff_date
            , fun = row_number
            , x = proc_eff_date
        )
    ) %>%
    ungroup() %>%
    arrange(med_rec_no, proc_eff_date) %>%
    filter(rn > 1) %>%
    write_csv(file = "G:/HIM/dupe_cataracts.csv")

# Compose Email ----
# Files
f_path <- paste0("G:\\HIM\\dupe_cataracts.csv")

# Open Outlook
Outlook <- COMCreate("Outlook.Application")

# Create Email
Email = Outlook$CreateItem(0)

# Set the recipeitn, subject, and body
Email[["to"]] = ""
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = "Duplicate Cataracts"
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

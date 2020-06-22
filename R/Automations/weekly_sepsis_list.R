# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse"
    , "dbplyr"
    , "DBI"
    , "odbc"
    , "RDCOMClient"
    , "janitor"
    , "fs"
    , "writexl"
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
# File: daily_sepsis_list.sql
query <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        SELECT A.Med_Rec_No
    	, A.PtNo_Num
    	, CAST(A.ADM_DATE AS date) AS [Adm_Date]
    	, A.Pt_Name
    	, B.ins1_pol_no
    	, CAST(A.Pt_Birthdate AS DATE) AS [Pt_Birthdate]
    	, A.Pt_Sex
    	, C.Pt_Addr_City
    	, C.Pt_Addr_State
    	, C.Pt_Phone_No
    	, D.pract_rpt_name AS [Attending_Provider]
    	, F.pract_rpt_name AS [Primary_Procedure_Provider]
    
    	FROM SMSDSS.BMH_PLM_PTACCT_V AS A
    	LEFT OUTER JOIN smsmir.vst_rpt AS B
    	ON A.PT_NO = B.pt_id
    	AND A.unit_seq_no = B.unit_seq_no
    	AND A.from_file_ind = B.from_file_ind
    	LEFT OUTER JOIN SMSDSS.c_patient_demos_v AS C
    	ON A.PT_NO = C.pt_id
    	AND A.from_file_ind = C.from_file_ind
    	LEFT OUTER JOIN SMSDSS.PRACT_DIM_V AS D
    	ON A.Atn_Dr_No = D.src_pract_no
    		AND A.Regn_Hosp = D.orgz_cd
    	LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS E
    	ON A.Pt_No = E.Pt_No
    		AND A.prin_dx_cd_schm = E.Proc_Cd_Schm
    		AND E.ClasfPrio = '01'
    	LEFT OUTER JOIN SMSDSS.pract_dim_v AS F
    	ON E.RespParty = F.src_pract_no
    		AND A.Regn_Hosp = F.orgz_cd
    
    	WHERE A.drg_no IN ('870','871','872')
    	AND A.User_Pyr1_Cat IN ('AAA','ZZZ')
    	AND A.Dsch_Date >= '2020-01-01'
    	AND A.tot_chg_amt > 0
    	AND LEFT(A.PTNO_NUM, 1) != '2'
    	AND LEFT(A.PTNO_NUM, 4) != '1999'
    	-- Participating Providers
    	AND A.Atn_Dr_No NOT IN (
    		'019190',
    		'017236',
    		'019299',
    		'021261',
    		'019679',
    		'017285',
    		'017202',
    		'021493',
    		'021428',
    		'017863',
    		'019158',
    		'019166',
    		'904326',
    		'021683',
    		'017236',
    		'019299',
    		'021261',
    		'015669',
    		'021758',
    		'018739',
    		'021733',
    		'021766',
    		'021667',
    		'021782',
    		'020206',
    		'904334',
    		'016857',
    		'021493',
    		'021550',
    		'021600',
    		'021428',
    		'021675',
    		'017863',
    		'018697'
    	)
        "
    )
) %>%
    as_tibble() %>%
    clean_names() %>%
    mutate(pt_no_num = str_squish(pt_no_num))

# Currently In sepsis tbl
query_b <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        SELECT MED_REC_NO
		FROM SMSDSS.C_ARCHWAY_SEPSIS_TBL
        "
    )
) %>%
    as_tibble() %>%
    clean_names() %>%
    mutate_all(as.character) %>%
    mutate(med_rec_no = str_squish(med_rec_no)) %>%
    mutate(flag = 1)

readmits <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        SELECT *
        FROM SMSDSS.vReadmits
        "
    )
) %>%
    as_tibble() %>%
    clean_names() %>%
    mutate_all(as.character) %>%
    filter(readmit %in% query$pt_no_num)

current_sepsis_encounters <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        SELECT PtNo_Num
        FROM smsdss.c_archway_sepsis_tbl
        "
    )
) %>%
    as_tibble() %>%
    clean_names() %>%
    mutate(pt_no_num = str_squish(pt_no_num))

# DB Disconnect ----
dbDisconnect(db_con)

# Data Manipulation ----
query_c <- query %>%
    left_join(query_b, by = c("med_rec_no" = "med_rec_no")) %>%
    mutate(mrn_in_tbl = case_when(
        flag == 1 ~ 1
        , TRUE ~ 0
    )) %>%
    select(-flag) %>%
    left_join(readmits, by = c("pt_no_num" = "readmit", "med_rec_no" = "mrn")) %>%
    mutate(previous_discharge = initial_discharge) %>%
    mutate(within_90days = difftime(adm_date, initial_discharge, units = "days")) %>%
    mutate(within_90days = as.integer(within_90days))

final_tbl <- query_c %>%
    select(
        med_rec_no
        , pt_no_num
        , adm_date
        , pt_name
        , ins1_pol_no
        , pt_birthdate
        , pt_sex
        , pt_addr_city
        , pt_addr_state
        , pt_phone_no
        , attending_provider
        , primary_procedure_provider
        , mrn_in_tbl
        , within_90days
    ) %>%
    filter(
        (mrn_in_tbl == 0) |
            (
                !pt_no_num %in% current_sepsis_encounters$pt_no_num &
                mrn_in_tbl == 1 &
                within_90days > 90
            )
    )

# Write to file ----
t <- Sys.Date()
f_name <- str_c(
    "Sepsis_List_rundate_"
    , str_sub(t, 6, 7)
    , str_sub(t, 9, 10)
    , str_sub(t, 1, 4)
    , ".xlsx"
)

if(nrow(final_tbl) == 0) {
    #rm(list = ls())
    stop("No precords")
}

write_xlsx(
    x = final_tbl
    , path = paste0(
        "G:\\Finance\\Mary Silva\\Daily_Sepsis_List\\"
        , f_name
    )
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
Email[["subject"]] = "Weekly Sepsis List"
Email[["body"]] = "Please see attached"
Email[["attachments"]]$Add(paste0(
  "G:\\Finance\\Mary Silva\\Daily_Sepsis_List\\"
  , f_name
))

# Send the email
Email$Send()

# Reconnect to DB ----
db_con <- dbConnect(
  odbc(),
  Driver = "SQL Server",
  Server = "BMH-HIDB",
  Database = "SMSPHDSSS0X0",
  Trusted_Connection = T
)

# Add records to DB ----
dbWriteTable(
  conn = db_con
  , Id(
    schema = "smsdss"
    , table = "c_archway_sepsis_tbl"
  )
  , final_tbl %>%
    select(med_rec_no, pt_no_num, adm_date, pt_name, ins1_pol_no, pt_birthdate,
           pt_sex, pt_addr_city, pt_addr_state, pt_phone_no, attending_provider, 
           primary_procedure_provider) %>%
    set_names(
      "Med_Rec_No",
      "PtNo_Num",
      "Adm_Date",
      "Pt_Name",
      "ins1_pol_no",
      "Pt_Birthdate",
      "Pt_Sex",
      "Pt_Addr_City",
      "Pt_Addr_State",
      "Pt_Phone_No",
      "Attending_Provider",
      "Primary_Procedure_Provider"
    )
  , append = T
)

# DB Disconnect ----
dbDisconnect(conn = db_con)

# Clear Env ----
rm(list = ls())

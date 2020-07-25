mhli_ds_query <-
function() {
  
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
      conn = db_con
      , statement = paste0(
          "
          DECLARE @ACTV_CD_START VARCHAR(10);
          DECLARE @ACTV_CD_END   VARCHAR(10);
          DECLARE @TODAY DATE;
          DECLARE @START DATE;
          DECLARE @END   DATE;
          
          SET @ACTV_CD_START  = '07200000';
          SET @ACTV_CD_END    = '07299999';
          SET @TODAY = GETDATE();
          SET @START = DATEADD(MM, DATEDIFF(MM, 0, @TODAY) - 1, 0);
          SET @END   = DATEADD(MM, DATEDIFF(MM, 0, @TODAY), 0);
          
          SELECT ECW.FULL_NAME
          , ECW.SEX
          , ECW.DOB
          , PAV.Med_Rec_No
          , PAV.PtNo_Num
          , PAV.Pt_No
          , PAV.Plm_Pt_Acct_Type
          , PAV.pt_type
          , PTYPE.pt_type_desc
          , PAV.hosp_svc
          , HSVC.hosp_svc_name
          , CASE
          WHEN COALESCE(
          PAV.Prin_Hcpc_Proc_Cd
          , PAV.Prin_Icd10_Proc_Cd
          , PAV.Prin_Icd9_Proc_Cd
          ) IS NULL
          THEN 'NON-SURGICAL'
          ELSE 'SURGICAL'
            END AS [Surg_Case_Type]
          , COALESCE(
          PAV.Prin_Hcpc_Proc_Cd
          , PAV.Prin_Icd9_Proc_Cd
          , PAV.Prin_Icd10_Proc_Cd
          )
            AS [Prin_Proc_Cd]
          , PAV.Atn_Dr_No            AS [Attending_Provider_ID]
          , ATTENDING.pract_rpt_name AS [Attending_Provider_Name]
          , PAV.Adm_Dr_No            AS [Admitting_Provider_ID]
          , ADMITTING.pract_rpt_name AS [Admitting_Provider_Name]
          , CASE
          WHEN ATTENDING.src_spclty_cd = 'HOSIM'
          THEN 'HOSPITALIST'
          ELSE 'PRIVATE'
            END AS [Hospitalist_Private]
          , PAV.tot_chg_amt
          , ISNULL(
          (
          SELECT SUM(p.chg_tot_amt)
          FROM smsmir.mir_actv AS p
          WHERE p.actv_cd BETWEEN @ACTV_CD_START AND @ACTV_CD_END
          AND PAV.PT_NO = p.pt_id 
          AND PAV.pt_id_start_dtime = p.pt_id_start_dtime 
          AND PAV.unit_seq_no = p.unit_seq_no
          HAVING SUM(p.chg_tot_amt) > 0
          )
          , 0
          )                          AS [Implant_Chgs]
          
          , CASE
              WHEN PAV.Plm_Pt_Acct_Type = 'I'
                  THEN ISNULL(tot_pymts_w_pip, 0)
                  ELSE PAV.tot_pay_amt
            END AS [TOT_PMTS]
          , PAV.Tot_Amt_Due
          , PAV.User_Pyr1_Cat
          , PDV.pyr_group2
          , PAV.Pyr1_Co_Plan_Cd
          , PDV.pyr_name
          , YEAR(PAV.ADM_DATE) AS [ADM_YR]
          , YEAR(PAV.DSCH_DATE) AS [DSCH_YR]
          , CAST(Dsch_Date AS DATE) AS [Dsch_Date]
          
          FROM smsdss.c_ecw_2019_pt_list_june AS ECW
          INNER JOIN smsdss.BMH_PLM_PtAcct_V AS PAV
          ON ECW.FULL_NAME = PAV.Pt_Name
              AND ECW.SEX = PAV.Pt_Sex
              AND ECW.DOB = PAV.Pt_Birthdate
          LEFT OUTER JOIN smsdss.pt_type_dim AS PTYPE
          ON PAV.pt_type = PTYPE.pt_type
              AND PAV.Regn_Hosp = PTYPE.orgz_cd
          LEFT OUTER JOIN smsdss.hosp_svc_dim_v AS HSVC
          ON PAV.hosp_svc = HSVC.hosp_svc
              AND PAV.Regn_Hosp = HSVC.orgz_cd
          LEFT OUTER JOIN smsdss.pract_dim_v AS ATTENDING
          ON PAV.Atn_Dr_No = ATTENDING.src_pract_no
              AND PAV.Regn_Hosp = ATTENDING.orgz_cd
          LEFT OUTER JOIN smsdss.pract_dim_v AS ADMITTING
          ON PAV.Adm_Dr_No = ADMITTING.src_pract_no
              AND PAV.Regn_Hosp = ADMITTING.orgz_cd
          LEFT OUTER JOIN smsdss.c_tot_pymts_w_pip_v AS PIP
          ON PAV.Pt_No = PIP.pt_id
              AND PAV.unit_seq_no = PIP.unit_seq_no
          LEFT OUTER JOIN smsdss.pyr_dim_v AS PDV
          ON PAV.Pyr1_Co_Plan_Cd = PDV.pyr_cd
          AND PAV.Regn_Hosp = PDV.orgz_cd
          
          WHERE PAV.tot_chg_amt > 0
          AND LEFT(PAV.PTNO_NUM, 1) != '2'
          AND LEFT(PAV.PTNO_NUM, 4) != '1999'
          AND PAV.Adm_Date IS NOT NULL
          AND PAV.Dsch_Date >= @START
          AND PAV.Dsch_Date < @END
          "
      )
  ) %>% 
    as_tibble() %>%
    clean_names() %>%
    mutate(dsch_date = as.Date(dsch_date)) %>%
    mutate(end_of_month = EOMONTH(dsch_date) %>% as.character())
  
  # DB Disconnect ----
  dbDisconnect(conn = db_con)
  
  # Return Data ----
  return(query)
}
mhli_rad_ref_query <-
function(){
  
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
    conn = db_con
    , statement = paste0(
      "
      SELECT ECW.*
      , CAST(PAV.ADM_DATE AS DATE) AS [Adm_Date]
      , PAV.Med_Rec_No
      , PAV.PtNo_Num
      , PAV.Pt_No
      , PAV.Plm_Pt_Acct_Type
      , PAV.pt_type
      , PTYPE.pt_type_desc
      , PAV.hosp_svc
      , HSVC.hosp_svc_name
      , CASE
      WHEN COALESCE(
      		PAV.Prin_Hcpc_Proc_Cd
      		, PAV.Prin_Icd10_Proc_Cd
      		, PAV.Prin_Icd9_Proc_Cd
      	) IS NULL
      	THEN 'NON-SURGICAL'
      	ELSE 'SURGICAL'
      END AS [Surg_Case_Type]
      , COALESCE(
      	PAV.Prin_Hcpc_Proc_Cd
      	, PAV.Prin_Icd9_Proc_Cd
      	, PAV.Prin_Icd10_Proc_Cd
      ) AS [Prin_Proc_Cd]
      , PAV.Atn_Dr_No            AS [Attending_Provider_ID]
      , ATTENDING.pract_rpt_name AS [Attending_Provider_Name]
      , PAV.Adm_Dr_No            AS [Admitting_Provider_ID]
      , ADMITTING.pract_rpt_name AS [Admitting_Provider_Name]
      , CASE
      	WHEN ATTENDING.src_spclty_cd = 'HOSIM'
      		THEN 'HOSPITALIST'
      		ELSE 'PRIVATE'
      END AS [Hospitalist_Private]
      , PAV.tot_chg_amt
      , CASE
          WHEN PAV.Plm_Pt_Acct_Type = 'I'
              THEN ISNULL(tot_pymts_w_pip, 0)
              ELSE PAV.tot_pay_amt
      END AS [TOT_PMTS]
      , PAV.Tot_Amt_Due
      , PAV.User_Pyr1_Cat
      , PDV.pyr_group2
      , PAV.Pyr1_Co_Plan_Cd
      , PDV.pyr_name
      , YEAR(PAV.ADM_DATE) AS [ADM_YR]
      , YEAR(PAV.DSCH_DATE) AS [DSCH_YR]
      , CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date]
      FROM smsdss.c_mhli_rad_referrals_tbl AS ECW
      OUTER APPLY (
      	SELECT TOP 1 *
      	FROM SMSDSS.BMH_PLM_PTACCT_V AS PAV
      	WHERE ECW.pt_sex = PAV.Pt_Sex
      	AND ECW.patient_date_of_birth = PAV.Pt_Birthdate
      	AND ECW.full_name = PAV.Pt_Name
      	AND ECW.referral_date <= PAV.Adm_Date
      	AND PAV.tot_chg_amt > 0
      	AND LEFT(PAV.PtNo_Num, 1) != '2'
      	AND LEFT(PAV.PtNo_Num, 4) != '1999'
      	AND PAV.pt_type = 'U'
      	ORDER BY PAV.Adm_Date
      ) AS PAV
      LEFT OUTER JOIN smsdss.pt_type_dim AS PTYPE
      ON PAV.pt_type = PTYPE.pt_type
          AND PAV.Regn_Hosp = PTYPE.orgz_cd
      LEFT OUTER JOIN smsdss.hosp_svc_dim_v AS HSVC
      ON PAV.hosp_svc = HSVC.hosp_svc
          AND PAV.Regn_Hosp = HSVC.orgz_cd
      LEFT OUTER JOIN smsdss.pract_dim_v AS ATTENDING
      ON PAV.Atn_Dr_No = ATTENDING.src_pract_no
          AND PAV.Regn_Hosp = ATTENDING.orgz_cd
      LEFT OUTER JOIN smsdss.pract_dim_v AS ADMITTING
      ON PAV.Adm_Dr_No = ADMITTING.src_pract_no
          AND PAV.Regn_Hosp = ADMITTING.orgz_cd
      LEFT OUTER JOIN smsdss.c_tot_pymts_w_pip_v AS PIP
      ON PAV.Pt_No = PIP.pt_id
          AND PAV.unit_seq_no = PIP.unit_seq_no
      LEFT OUTER JOIN smsdss.pyr_dim_v AS PDV
      ON PAV.Pyr1_Co_Plan_Cd = PDV.pyr_cd
      AND PAV.Regn_Hosp = PDV.orgz_cd
      
      WHERE PAV.PtNo_Num IS NOT NULL
      ORDER BY PAV.Med_Rec_No
      , PAV.Adm_Date

      "
    )
  ) %>% 
    as_tibble() %>%
    clean_names() %>%
    mutate(dsch_date = as.Date(dsch_date)) %>%
    mutate(end_of_month = EOMONTH(dsch_date) %>% as.character())
  
  # DB Disconnect ----
  dbDisconnect(conn = db_con)
  
  # Return Data ----
  return(query)
  
}
mhli_pivot_tbl <-
function(.data) {
  
  # Get last Date of data
  end_date <- .data %>%
    pull(end_of_month) %>%
    pluck(1) %>%
    as.Date.character(format = "%Y-%m-%d")
  
  # Get end_date format
  yr <- year(end_date)
  mnth <- month(end_date, label = TRUE, abbr = FALSE)
  end_date <- paste0(mnth, ", ", yr)
  
  mhli_pvt_tbl <-  pivot_table(
      .data = .data
      , .rows = c(surg_case_type, ~ (pyr_group2))
      , .values = c(
        ~ COUNT(pt_no_num)
        , ~ SUM(tot_chg_amt)
        , ~ SUM(implant_chgs)
        , ~ SUM(tot_chg_amt) - SUM(implant_chgs)
        , ~ SUM(tot_pmts)
        , ~ SUM(tot_amt_due)
        , ~ (SUM(tot_pmts) / SUM(tot_chg_amt)) * -1
        )
      , fill_na = 0
    ) %>% 
    set_names(
      "case_type"
      , "pyr_group"
      , "visit_count"
      , "tot_chgs"
      , "implant_chgs"
      , "chgs_net_implants"
      , "pmts"
      , "amt_due"
      , "pmt_to_chg_ratio"
    ) %>%
    mutate(case_type = str_to_title(case_type)) %>%
    gt(
      rowname_col = "pyr_group"
      , groupname_col = "case_type"
    ) %>%
    tab_header(
      title = paste(
        "MyHealth Long Island Down Stream Revenue"
      )
      , subtitle = paste(
        "For discharges in"
        , end_date
      )
    ) %>%
    fmt_currency(
      columns = vars(
        tot_chgs
        , implant_chgs
        , chgs_net_implants
        , pmts
        , amt_due
      )
    ) %>%
    fmt_percent(
      columns = vars(pmt_to_chg_ratio)
    ) %>%
    cols_label(
     visit_count = "Visits"
      , tot_chgs = "Total Charges"
      , implant_chgs = "Implant Charges"
      , chgs_net_implants = "Charges Net Of Implants"
      , pmts = "Payments"
      , amt_due = "Amount Due"
      , pmt_to_chg_ratio = "Payment to Charge Ratio"
    )
  
  # Return Table
  return(mhli_pvt_tbl)
}
mhli_rad_pvt_tbl <-
function(.data) {

  mhli_rad_pvt_tbl <- pivot_table(
    .data = .data
    , .rows = c(referral_grouping, ~(pyr_group2))
    , .values = c(
      ~ COUNT(pt_no_num)
      , ~ SUM(tot_chg_amt)
      , ~ SUM(tot_pmts)
      , ~ SUM(tot_amt_due)
      , ~ (SUM(tot_pmts) / SUM(tot_chg_amt)) * -1
    )
    , fill_na = 0
  ) %>%
    set_names(
      "referral_group"
      , "pyr_group"
      , "visit_count"
      , "tot_chgs"
      , "pmts"
      , "amt_due"
      , "pmt_to_chg_ratio"
    ) %>%
    mutate(referral_group = str_replace(referral_group, "_", " ")) %>%
    gt(
      rowname_col = "pyr_group"
      , groupname_col = "referral_group"
    ) %>%
    tab_header(
      title = "MyHealth Long Island Radiology"
    ) %>%
    fmt_currency(
      columns = vars(
        tot_chgs
        , pmts
        , amt_due
      )
    ) %>%
    fmt_percent(
      columns = vars(pmt_to_chg_ratio)
    ) 
    
  # Return Table
  return(mhli_rad_pvt_tbl)
}
mhli_ds_summary_tbl <-
function(.data) {
  
  # Get last Date of data
  end_date <- .data %>%
    pull(end_of_month) %>%
    pluck(1) %>%
    as.Date.character(format = "%Y-%m-%d")
  
  # Get end_date format
  yr <- year(end_date)
  mnth <- month(end_date, label = TRUE, abbr = FALSE)
  end_date <- paste0(mnth, ", ", yr)
  
  # Table
  data_tbl <- .data %>%
    select(surg_case_type, contains(c("amt","chgs","pmt"))) %>%
    group_by(surg_case_type) %>%
    summarise(
      visits = n()
      , tot_chgs = sum(tot_chg_amt, na.rm = TRUE)
      , tot_implant_chgs = sum(implant_chgs, na.rm = TRUE)
      , tot_pmts = sum(tot_pmts)
      , tot_due = sum(tot_amt_due)
      , chg_cost_net_implants = (tot_chgs - tot_implant_chgs) * 0.18
      , implant_cost = tot_implant_chgs * 0.18
      , tot_cost = chg_cost_net_implants + implant_cost
      , net_rev = ((-1 * tot_pmts) - tot_cost) + (0.5 * tot_due)
    ) %>%
    ungroup() %>% 
    adorn_totals() %>%
    mutate_if(is.double, scales::dollar) %>%
    mutate(surg_case_type = str_to_title(surg_case_type)) %>%
    gt() %>%
    cols_label(
      surg_case_type = "Case Type"
      , visits = "Visits"
      , tot_chgs = "Total Charges"
      , tot_implant_chgs = "Implant Charges"
      , tot_pmts = "Payments"
      , tot_due = "Amount Due"
      , chg_cost_net_implants = "Charges Cost net Implants"
      , implant_cost = "Implants Cost"
      , tot_cost = "Total Cost"
      , net_rev = "Net Revenue"
    ) %>%
    tab_header(
      title = paste(
        "MyHealth Long Island Down Stream Revenue Summary"
      )
      , subtitle = paste(
        "For discharges in"
        , end_date
      )
    )
  
  # Return Table
  return(data_tbl)
}
mhli_rad_summary_tbl <-
function(.data) {
  
  data_tbl <- .data %>%
    select(referral_grouping, contains(c("amt","chgs","pmt"))) %>%
    group_by(referral_grouping) %>%
    summarise(
      visits = n()
      , tot_chgs = sum(tot_chg_amt, na.rm = TRUE)
      , tot_pmts = sum(tot_pmts)
      , tot_due = sum(tot_amt_due)
      , tot_cost = tot_chgs * 0.18
      , net_rev = ((-1 * tot_pmts) - tot_cost) + (0.5 * tot_due)
    ) %>%
    ungroup() %>%
    adorn_totals() %>%
    mutate_if(is.double, scales::dollar) %>%
    mutate(
      referral_grouping = referral_grouping %>% 
        str_replace("_"," ")
    ) %>%
    gt() %>%
    cols_label(
      referral_grouping = "Referral To"
      , visits = "Visits"
      , tot_chgs = "Total Charges"
      , tot_pmts = "Total Payments"
      , tot_due = "Total Due"
      , tot_cost = "Total Cost"
      , net_rev = "Current Net Revenue"
    ) %>%
    tab_header(
      title = "MyHealth Long Island Radiology Down Stream Revenue Summary"
    )
  
  # Return Data
  return(data_tbl)
  
}
mhli_rad_facility_provider_count_tbl <-
function(.data){
  
  data_tbl <- .data %>%
    count(from_facility_name, referral_from_provider_name) %>%
    arrange(
      from_facility_name
      , desc(n)
    ) %>%
    gt(
      rowname_col = "referral_from_provider_name"
      , groupname_col = "from_facility_name"
    ) %>%
    cols_label(
      from_facility_name = "Practice"
      , referral_from_provider_name = "Referral Provider"
      , n = "Referral Count"
    ) %>%
    tab_header(
      title = "MyHealth Long Island Radiology Referral Counts"
    )
  
  return(data_tbl)
  
}
mhli_rad_ref_lag <-
function(.data) {
  
  data_tbl <- .data %>% 
    select(
      referral_grouping
      , referral_date
      , adm_date
    ) %>% 
    mutate(adm_date = ymd(adm_date)) %>% 
    mutate(referral_date = as.Date(referral_date, format = c("%Y-%m-%d"))) %>% 
    mutate(month_end = EOMONTH(referral_date)) %>% 
    mutate(time_lag = difftime(adm_date, referral_date, units = "days")) %>% 
    group_by(
      referral_grouping
      , month_end
    ) %>% 
    summarise(avg_lag = round(mean(time_lag, na.rm = TRUE), 0)) %>% 
    ungroup() %>%
    select(month_end, referral_grouping, avg_lag) %>%
    mutate(
      referral_grouping = referral_grouping %>%
        str_replace(pattern = "_", replacement = " ")
    ) %>%
    gt() %>%
    cols_label(
      month_end = "Month End"
      , referral_grouping = "Referral To"
      , avg_lag = "Average Lag in Days"
    ) %>%
    tab_header(
      title = "MyHealth Long Island Radiology Referral to Test Lag in Days"
    )
  
  return(data_tbl)
  
}
mhli_pt_registry_data <-
function(.user_input){
  
  # Function
  if(run_pt_reg_files){
    
    # File Path ----
    file_in_path <- paste0(
      "G:\\R Studio Projects\\MyHealth_Referrals\\00_Data_In\\"
    )
    
    # Get file date ----
    t <- Sys.Date() 
    t <- t %>% tidyquant::FLOOR_MONTH(t) %>% t %m-% months(1)
    t_year <- year(t)
    t_month <- month(t, label = TRUE, abbr = FALSE)
    
    # Get Data ----
    pt_registry_tbl <- read_excel(
      paste0(
        file_in_path
        ,"mhli_pt_registry.xlsx"
      )
    ) %>%
      clean_names() %>%
      mutate_if(is.character, str_squish) %>%
      mutate(patient_name = str_to_upper(patient_name)) %>%
      mutate(dob = as.Date.character(x = dob, format = "%Y-%m-%d")) %>%
      mutate(sex = as_factor(sex)) %>%
      mutate(age = str_replace(
        string = age
        , pattern = " Y"
        , replacement = ""
      ) %>%
        as.integer()
      ) %>%
      select(-tel_no) %>%
      filter(!str_detect(patient_name, "TEST")) %>%
      distinct(.keep_all = TRUE) %>%
      mutate(full_name = str_replace(
        patient_name
        , ","
        , " ,"
      ))
    
    # Write Historical File ----
    write_excel_csv(
      x = pt_registry_tbl
      , path = paste0(
        "G:/MyHealth/MyHealth_File_History/mhli_pt_registry_"
        , t_year
        , "_"
        , t_month
        , ".csv"
      )
    )
    
    # Import to DSS ----
    # DB Connection ----
    db_con <- dbConnect(
      odbc(),
      Driver = "SQL Server",
      Server = "BMH-HIDB",
      Database = "SMSPHDSSS0X0",
      Trusted_Connection = T
    )
    
    # DB Write ----
    dbWriteTable(
      conn = db_con
      , Id(
        schema = "smsdss"
        , table = "c_mhli_pt_registry_tbl"
      )
      , pt_registry_tbl
      , overwrite = TRUE
    )
    
    # DB Disconnect ----
    dbDisconnect(conn = db_con)
  }
  
  message("Patient Registry Function Not Run")
}
mhli_pt_rad_data <-
function(.user_input){
  
  # Function
  if(run_pt_rad_files){
    
    # File Path ----
    file_in_path <- paste0(
      "G:\\R Studio Projects\\MyHealth_Referrals\\00_Data_In\\"
    )
    
    # Get file date ----
    t <- Sys.Date() 
    t <- t %>% tidyquant::FLOOR_MONTH(t) %>% t %m-% months(1)
    t_year <- year(t)
    t_month <- month(t, label = TRUE, abbr = FALSE)
    
    # Get Data ----
    referrals_tbl   <- read_excel(paste0(file_in_path,"mhli_referrals.xlsx")) %>%
      clean_names() %>%
      select(
        from_facility_name
        , starts_with("referral")
        , speciality_name
        , starts_with("patient")
      ) %>%
      mutate_if(is.character, str_squish) %>%
      mutate(full_name = str_replace(
        patient_name
        , ", "
        , " ,"
      )) %>%
      distinct(.keep_all = TRUE)
    
    # Write Historical File ----
    write_excel_csv2(
      x = referrals_tbl
      , path = paste0(
        "G:/MyHealth/MyHealth_File_History/mhli_referral_log_"
        , t_year
        , "_"
        , t_month
        , ".csv"
      )
    )
    
    # Data Manip ----
    df_rad_tbl <- referrals_tbl %>%
      select(-patient_race, -patient_ethnicity, -patient_account_number) %>%
      filter(
        referral_to_provider_name %in% c(
          "WOMEN'S IMAGIN CENTER, ."
          , "WOMENS IMAGING SERVICES, BMH"
          , "LICH OUTPATIENT RADIOLOGY, ."
          , "LICH RADIOLOGY"
        )
      ) %>%
      mutate(
        referral_grouping = case_when(
          referral_to_provider_name %in% c(
            "WOMEN'S IMAGIN CENTER, ."
            , "WOMENS IMAGING SERVICES, BMH"
          ) ~ "BWIS",
          TRUE ~ "OP_Radiology"
        )
      ) %>%
      mutate(
        patient_name = str_replace(
          string = patient_name
          , pattern = ", "
          , replacement = " ,"
        )
      ) %>%
      mutate(patient_gender = str_to_lower(patient_gender)) %>%
      mutate(pt_sex = case_when(
        patient_gender == "female" ~ "F",
        TRUE ~ "M"
      ))
    
    # Import to DSS ----
    # DB Connection ----
    db_con <- dbConnect(
      odbc(),
      Driver = "SQL Server",
      Server = "BMH-HIDB",
      Database = "SMSPHDSSS0X0",
      Trusted_Connection = T
    )
    
    # DB Write ----
    dbWriteTable(
      conn = db_con
      , Id(
        schema = "smsdss"
        , table = "c_mhli_referrals_tbl"
      )
      , referrals_tbl
      , overwrite = TRUE
    )
    
    dbWriteTable(
      conn = db_con
      , Id(
        schema = "smsdss"
        , table = "c_mhli_rad_referrals_tbl"
      )
      , df_rad_tbl
      , overwrite = TRUE
    )
    
    # DB Disconnect ----
    dbDisconnect(conn = db_con)
  }
  
  message("Patient Radiology Function Not Run")
}

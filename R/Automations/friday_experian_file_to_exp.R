# Lib Load ----
if(!require(pacman)) install.packages("pacman")

pacman::p_load(
    "tidyverse"
    , "DBI"
    , "odbc"
    , "dbplyr"
    , "lubridate"
    , "writexl"
)

# DB Connection ----
db_con <- dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "LI-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = T
)

# Source functions
source("I:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\clean_names.R")

# Get Exp Records ----
# Get extra records that would typically fail auto process
exp_extra_rec_tbl <- tbl(
    db_con
    , in_schema(
        schema = "smsdss"
        , table = "c_friday_experian_file"
        )
    ) %>%
    as_tibble() %>%
    clean_names() %>%
    select(pt_no) %>%
    mutate(pt_no = pt_no %>% str_squish())

mir_acct_tbl <- dbGetQuery(
    db_con
    , paste0(
        "
        SELECT pt_id
        , acct_no
        , unit_seq_no
        , fc
        , pt_bal_amt
        , adm_dtime
        , pt_id_start_dtime
        , from_file_ind
        , resp_cd
        , cr_rating
        FROM smsmir.mir_acct
        WHERE (
            RIGHT(from_file_ind, 1) in ('A','T')
            AND fc in ('P','J','G','T')
            AND unit_seq_no not in (-1)
            AND pt_bal_amt > 0
            AND (
		    resp_cd NOT IN ('4', '5', '6', '9', 'K', 'O')
		    OR (
			    resp_cd IS NULL
			    OR
			    resp_cd IN (
				    '*', '-', '0', '1', '2', '3', '7', '8', 'A', 'B', 'C', 
				    'D', 'E', 'F', 'G', 'I', 'H', 'J', 'L', 'M', 'N',
				    'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
				    )
			    )
		    )
		    -- End resp_cd edit
	
    	    -- Get rid of Hemo Test Pt
    	    AND acct_no != '000074006123'
    
    	    -- Get rid of unitized accounts
    	    AND LEFT(acct_no, 5) != '00000'
    	    AND LEFT(acct_no, 5) != '00007'
    	
    	    -- Get rid of accounts that hae a credit rating
    	    AND cr_rating IS NULL
        )
        OR PT_ID IN (
           SELECT pt_no
            FROM smsdss.c_friday_experian_file
            WHERE LEN(pt_no) < 13
        )
        "
        )
    )

mir_acct_tbl <- mir_acct_tbl %>%
    as_tibble() %>%
    mutate_if(is.character, str_squish) %>%
    mutate(
        pt_id_start_dtime = ymd(pt_id_start_dtime)
    )

guarantor_demos_tbl <- tbl(
        db_con
        , in_schema(
            schema = "smsdss"
            , table = "c_guarantor_demos_v"
        )
    ) %>%
    as_tibble() %>%
    select(
        pt_id
        , pt_id_start_dtime
        , from_file_ind
        , GuarantorFirst
        , GuarantorLast
        , GuarantorAddress
        , GurantorCity
        , GuarantorState
        , GuarantorZip
        , GuarantorSocial
        , GuarantorDOB
        , GuarantorPhone
    ) %>%
    clean_names() %>%
    mutate_if(is.character, str_squish) %>%
    mutate(pt_id_start_dtime = pt_id_start_dtime %>% ymd()) %>%
    filter(pt_id %in% mir_acct_tbl$pt_id)

plm_pav_tbl <- tbl(
    db_con
    , in_schema(
        schema = "smsdss"
        , table = "bmh_plm_ptacct_v"
        )
    ) %>%
    as_tibble() %>%
    select(
        Pt_No
        , unit_seq_no
        , Adm_Date
        , User_Pyr1_Cat
        , Plm_Pt_Acct_Type
        , prin_dx_cd
        , Days_Stay
    ) %>%
    clean_names() %>%
    mutate_if(is.character, str_squish) %>%
    mutate(adm_date = adm_date %>% ymd()) %>%
    filter(pt_no %in% mir_acct_tbl$pt_id)

pt_demos_tbl <- tbl(
    db_con
    , in_schema(
        schema = "smsdss"
        , table = "c_patient_demos_v"
        )
    ) %>%
    as_tibble() %>%
    select(
        pt_id
        , pt_id_start_dtime
        , pt_first
        , pt_last
        , pt_middle
        , pt_dob
        , gender_cd
        , Pt_Social
        , marital_sts_desc
    ) %>%
    clean_names() %>%
    mutate_if(is.character, str_squish) %>%
    mutate(
        pt_id_start_dtime = pt_id_start_dtime %>% ymd()
        , pt_dob = pt_dob %>% ymd()
    ) %>%
    filter(pt_id %in% mir_acct_tbl$pt_id)

pt_employer_demos_tbl <- tbl(
    db_con
    , in_schema(
        schema = "smsdss"
        , table = "c_patient_employer_demos_v"
        )
    ) %>%
    as_tibble() %>%
    select(
        pt_id
        , pt_id_start_dtime
        , from_file_ind
        , Pt_Employer
    ) %>%
    clean_names() %>%
    mutate_if(is.character, str_squish) %>%
    mutate(pt_id_start_dtime = pt_id_start_dtime %>% ymd()) %>%
    filter(pt_id %in% mir_acct_tbl$pt_id)

pt_payments_tbl <- tbl(
    db_con
    , in_schema(
        schema = "smsdss"
        , table = "c_pt_payments_v"
        )
    ) %>%
    as_tibble() %>%
    select(
        pt_id
        , unit_seq_no
        , Pymt_Rank
        , pay_entry_date
        , Tot_Pt_Pymts
    ) %>%
    clean_names() %>%
    mutate_if(is.character, str_squish) %>%
    mutate(pay_entry_date = pay_entry_date %>% ymd()) %>%
    filter(
        pt_id %in% mir_acct_tbl$pt_id
        , (pymt_rank == 1 | is.na(pymt_rank))
    )

# Batch Table
batch_tbl <- mir_acct_tbl %>%
    left_join(
        guarantor_demos_tbl
        , by = c(
            "pt_id" = "pt_id"
            , "pt_id_start_dtime" = "pt_id_start_dtime"
            , "from_file_ind" = "from_file_ind"
        )
    ) %>%
    left_join(
        plm_pav_tbl
        , by = c(
            "pt_id" = "pt_no"
            , "unit_seq_no" = "unit_seq_no"
        )
    ) %>%
    left_join(
        pt_demos_tbl
        , by = c(
            "pt_id" = "pt_id"
            , "pt_id_start_dtime" = "pt_id_start_dtime"
        )
    ) %>%
    left_join(
        pt_employer_demos_tbl
        , by = c(
            "pt_id" = "pt_id"
            , "pt_id_start_dtime" = "pt_id_start_dtime"
            , "from_file_ind" = "from_file_ind"
        )
    ) %>%
    left_join(
        pt_payments_tbl
        , by = c(
            "pt_id" = "pt_id"
            , "unit_seq_no" = "unit_seq_no"
        )
    ) %>%
    arrange(pay_entry_date) %>%
    group_by(pt_id) %>%
    mutate(rn2 = row_number(paste0(pt_id, pay_entry_date))) %>%
    ungroup() %>%
    filter(rn2 == 1)

# Fist/Last FC ----
first_fc_tbl <- dbGetQuery(
    db_con
    , paste0(
        "
        SELECT pt_id
    	, cmnt_cre_dtime
    	, LTRIM(RTRIM(acct_hist_cmnt)) AS ACCT_HIST_CMNT
    	, ROW_NUMBER() OVER(
    		PARTITION BY PT_ID
    		ORDER BY CMNT_CRE_DTIME ASC
    	) AS RN
    
    	FROM SMSMIR.mir_acct_hist
    
    	WHERE acct_hist_cmnt LIKE 'FIN.%'
    	OR PT_ID IN (
           SELECT pt_no
            FROM smsdss.c_friday_experian_file
            WHERE LEN(pt_no) < 13
        )
        "
        )
    )

first_fc_tbl <- first_fc_tbl %>%
    as_tibble() %>%
    select(
        pt_id
        , cmnt_cre_dtime
        , ACCT_HIST_CMNT
        , RN
    ) %>%
    clean_names() %>%
    filter(rn == 1) %>%
    mutate_if(is.character, str_squish) %>%
    mutate(cmnt_cre_dtime = cmnt_cre_dtime %>% ymd()) %>%
    filter(pt_id %in% mir_acct_tbl$pt_id)

last_fc_tbl <- dbGetQuery(
    db_con
    , paste0(
        "
        SELECT pt_id
    	, cmnt_cre_dtime
    	, LTRIM(RTRIM(acct_hist_cmnt)) AS ACCT_HIST_CMNT
    	, ROW_NUMBER() OVER(
    		PARTITION BY PT_ID
    		ORDER BY CMNT_CRE_DTIME DESC
    	) AS RN
    
    	FROM SMSMIR.mir_acct_hist
    
    	WHERE acct_hist_cmnt LIKE 'FIN.%'
    	OR pt_id IN (
           SELECT pt_no
            FROM smsdss.c_friday_experian_file
            WHERE LEN(pt_no) < 13
        )
        "
        )
    )

last_fc_tbl <- last_fc_tbl %>%
    as_tibble() %>%
    select(
        pt_id
        , cmnt_cre_dtime
        , ACCT_HIST_CMNT
        , RN
    ) %>%
    clean_names() %>%
    filter(rn == 1) %>%
    mutate_if(is.character, str_squish) %>%
    mutate(cmnt_cre_dtime = cmnt_cre_dtime %>% ymd()) %>%
    filter(pt_id %in% mir_acct_tbl$pt_id)

# DB Disconnect ----
dbDisconnect(db_con)

# Pull Together ----
batch_tbl <- batch_tbl %>%
    left_join(
        first_fc_tbl
        , by = c("pt_id" = "pt_id")
    ) %>%
    left_join(
        last_fc_tbl
        , by = c("pt_id" = "pt_id")
    ) %>%
    select(
        pt_id
        , guarantor_first
        , guarantor_last
        , guarantor_address
        , gurantor_city
        , guarantor_state
        , guarantor_zip
        , pt_dob
        , adm_date
        , pt_social
        , guarantor_social
        , guarantordob
        , pt_first
        , pt_last
        , guarantor_phone
        , pt_middle
        , user_pyr1_cat # get u/i ind
        , plm_pt_acct_type
        , fc
        , pt_bal_amt
        , marital_sts_desc
        , prin_dx_cd
        , pt_employer
        , days_stay
        , pay_entry_date
        , cmnt_cre_dtime.x
        , cmnt_cre_dtime.y
        , gender_cd
    ) %>%
    mutate(
        days_since_last_pt_pay_date = as.difftime(
            Sys.Date() - pay_entry_date
        ) %>% 
            as.numeric()
    ) %>%
    mutate(
        insured_flag = if_else(
            user_pyr1_cat %in% c("MIS","???")
            , "U"
            , "I"
        )
    ) %>%
    mutate(
        adm_minus_dob = as.difftime(adm_date - pt_dob) %>% as.numeric()
        , adm_minus_dob_yrs = round(adm_minus_dob / 365.25, 0)
        , guarantor_social = if_else(
            adm_minus_dob_yrs >= 21
            , pt_social
            , guarantor_social
        )
    ) %>%
    select(-adm_minus_dob, -adm_minus_dob_yrs)

batch_final_tbl <- batch_tbl %>%
    # filter(
    #     (days_since_last_pt_pay_date >= 90 |
    #         is.na(days_since_last_pt_pay_date))
    #     | pt_id %in% exp_extra_rec_tbl$pt_no
    # ) %>%
  filter(pt_id %in% exp_extra_rec_tbl$pt_no) %>%
    filter(
        (as.difftime(Sys.Date() - cmnt_cre_dtime.y) %>% as.numeric() >= 118   
        & str_sub(pt_id, 1, 5) != "00000"
        & str_sub(pt_id, 1, 5) != "00007"
        & str_sub(pt_id, 1, 5) != "00009"
        & guarantor_last != 'BROOKHAVEN MEMORIAL HOSPITAL') |
        pt_id %in% exp_extra_rec_tbl$pt_no
    ) %>% 
    filter(
        !guarantor_social %in% c(
            '999999999', '999999991', '888888888', '111111111', '000000000'
        ) |
            pt_id %in% exp_extra_rec_tbl$pt_no
    ) %>%
    select(
        pt_id,
        guarantor_first,
        guarantor_last,
        guarantor_address,
        gurantor_city,
        guarantor_state,
        guarantor_zip,
        guarantor_social,
        guarantordob,
        pt_first,
        pt_last,
        guarantor_phone,
        pt_middle,
        pt_dob,
        gender_cd,
        pt_social,
        insured_flag,
        plm_pt_acct_type,
        fc,
        pt_bal_amt,
        marital_sts_desc,
        prin_dx_cd,
        pt_employer,
        days_stay
    ) %>%
    rename(
        "Visit Number / Account Number" = pt_id,
        "Guarantor First Name" = guarantor_first,
        "Guarantor Last Name" = guarantor_last,
        "Guarantor Address" = guarantor_address,
        "Guarantor City" = gurantor_city,
        "Guarantor State" = guarantor_state,
        "Guarantor Zip" = guarantor_zip,
        "Guarantor SSN" = guarantor_social,
        "Guarantor DOB" = guarantordob,
        "Patient First Name" = pt_first,
        "Patient Last Name" = pt_last,
        "Guarantor Phone" = guarantor_phone,
        "Patient Middle Name" = pt_middle,
        "Patient DOB" = pt_dob,
        "Patient Gender" = gender_cd,
        "Patient SSN" = pt_social,
        "Uninsured Insured" = insured_flag,
        "Patient Type" = plm_pt_acct_type,
        "Financial Class" = fc,
        "Client Balance" = pt_bal_amt,
        "Marital Status" = marital_sts_desc,
        "Diagnosis" = prin_dx_cd,
        "Employer" = pt_employer,
        "Length of Stay" = days_stay
    )
    
# Write File ----
f_name <- str_c(
    "bmhmc-batchtype-"
    , str_sub(Sys.Date(), 6, 7)
    , str_sub(Sys.Date(), 9, 10)
    , str_sub(Sys.Date(), 3, 4)
    , "-1.xlsx"
)

write_xlsx(
    x = batch_final_tbl
    , path = paste0(
        "G:\\Finance\\Experian\\Outbound\\"
        , f_name
    )
)

rm(list = ls())

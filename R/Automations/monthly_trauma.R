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
    Server = "LI-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = T
)

# Query ----
# Admit Queries ----
admit_query_a <- dbGetQuery(
    db_con
    , paste0(
        "
        DECLARE @ThisDate DATETIME;
        DECLARE @START DATETIME;
        DECLARE @END   DATETIME;
        
        SET @ThisDate = GETDATE();
        SET @START = dateadd(mm, datediff(mm, 0, @ThisDate) - 3, 0);
        SET @END   = dateadd(mm, datediff(mm, 0, @ThisDate) - 2, 0);
        
        SELECT PAV.PT_NO
        , PAV.PtNo_Num
        , PAV.unit_seq_no
        , PAV.from_file_ind
        , PAV.Med_Rec_No
        , PAV.Pt_Name
        , PAV.Pt_Age
        , CAST(PAV.ADM_DATE AS DATE) AS [ADM_DATE]
        , CAST(PAV.DSCH_DATE AS DATE) AS [DSCH_DATE]
        , PAV.Plm_Pt_Acct_Type
        , PAV.dsch_disp
        
        FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
        
        WHERE Adm_Date >= @START
        AND Adm_Date < @END
        AND LEFT(PAV.PTNO_NUM, 1) != '2'
        AND LEFT(PAV.PTNO_NUM, 4) != '1999'
        AND PAV.tot_chg_amt > 0
        AND PAV.Plm_Pt_Acct_Type = 'I'
        "
       )
    ) %>%
    as_tibble() %>%
    clean_names() %>%
    mutate(pt_no = pt_no %>% str_squish())

admit_query_b <- dbGetQuery(
    db_con
    , paste0(
        "
    	SELECT pt_id
    	, unit_seq_no
    	, from_file_ind
    	, dx_cd
    	, dx_cd_prio
    
    	FROM SMSMIR.dx_grp AS DX
        
    	WHERE PT_ID IN (
    		SELECT DX.pt_id
    		FROM SMSMIR.DX_GRP AS DX
    		WHERE (
    			    LEFT(DX.dx_cd, 2) IN (
    				    'S0','S1','S2','S3','S4','S5','S6','S7','S8','S9'
    			    )
        			AND RIGHT(DX.DX_CD, 1) IN ('A', 'B', 'C')
                )
        
    		    OR LEFT(Dx.dx_cd, 3) IN (
        			'T07','T14','T30','T31','T32'
    		    )
    
    		    OR (
    			    LEFT(DX.DX_CD, 3) IN (
    				    'T20','T21','T22','T23','T24',
        				'T25','T26','T27','T28'
    			    )
    			    AND SUBSTRING(DX.DX_CD, 8, 1) = 'A'
        		)
    			
    		    OR (
    			    LEFT(DX.dx_cd, 5) = 'T79.A'
        			AND RIGHT(DX.DX_CD, 1) = 'A'
    		    )
    	    )
        
    	    AND PT_ID IN (
    		    SELECT PT_ID
    		    FROM SMSMIR.dx_grp AS DX
    	    	WHERE LEFT(DX.DX_CD, 3) BETWEEN 'V00' AND 'Y38'
        		AND RIGHT(DX.DX_CD, 1) = 'A'
        	)
    
    	    AND LEFT(DX.DX_CD_TYPE, 2) = 'DF'
    	    AND DX.dx_cd_prio < 11
        "
        )
    ) %>%
    as_tibble() %>%
    mutate_if(is.character, str_squish) %>%
    filter(pt_id %in% admit_query_a$pt_no) %>%
    arrange(pt_id, dx_cd_prio) %>%
    pivot_wider(
        names_from = dx_cd_prio
        , values_from = dx_cd
    ) %>%
    rename(
        "DX01" = "01",
        "DX02" = "02",
        "DX03" = "03",
        "DX04" = "04",
        "DX05" = "05",
        "DX06" = "06",
        "DX07" = "07",
        "DX08" = "08",
        "DX09" = "09",
        "DX10" = "10"
    )

admit_query_c <- dbGetQuery(
    db_con
    , paste0(
        "
        SELECT [Readmit]
        , INTERIM
        
        FROM smsdss.vReadmits
        
        WHERE INTERIM < 31
        AND [READMIT SOURCE DESC] != 'SCHEDULED ADMISSION'
        "
        )
    ) %>%
    as_tibble() %>%
    clean_names() %>%
    mutate_if(is.character, str_squish) %>%
    filter(readmit %in% admit_query_a$pt_no_num)

# Discharge Queries ----
dsch_query_a <- dbGetQuery(
    db_con
    , paste0(
        "
        DECLARE @ThisDate DATETIME;
        DECLARE @START DATETIME;
        DECLARE @END   DATETIME;
        
        SET @ThisDate = GETDATE();
        SET @START = dateadd(mm, datediff(mm, 0, @ThisDate) - 3, 0);
        SET @END   = dateadd(mm, datediff(mm, 0, @ThisDate) - 2, 0);
        
        SELECT PAV.PT_NO
        , PAV.PtNo_Num
        , PAV.unit_seq_no
        , PAV.from_file_ind
        , PAV.Med_Rec_No
        , PAV.Pt_Name
        , PAV.Pt_Age
        , CAST(PAV.ADM_DATE AS DATE) AS [ADM_DATE]
        , CAST(PAV.DSCH_DATE AS DATE) AS [DSCH_DATE]
        , PAV.Plm_Pt_Acct_Type
        , PAV.dsch_disp
        
        FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
        
        WHERE Dsch_Date >= @START
        AND Dsch_Date < @END
        AND LEFT(PAV.PTNO_NUM, 1) != '2'
        AND LEFT(PAV.PTNO_NUM, 4) != '1999'
        AND PAV.tot_chg_amt > 0
        AND PAV.Plm_Pt_Acct_Type = 'I'
        "
    )
) %>%
    as_tibble() %>%
    clean_names() %>%
    mutate(pt_no = pt_no %>% str_squish())

dsch_query_b <- dbGetQuery(
    db_con
    , paste0(
        "
    	SELECT pt_id
    	, unit_seq_no
    	, from_file_ind
    	, dx_cd
    	, dx_cd_prio
    
    	FROM SMSMIR.dx_grp AS DX
        
    	WHERE PT_ID IN (
    		SELECT DX.pt_id
    		FROM SMSMIR.DX_GRP AS DX
    		WHERE (
    			    LEFT(DX.dx_cd, 2) IN (
    				    'S0','S1','S2','S3','S4','S5','S6','S7','S8','S9'
    			    )
        			AND RIGHT(DX.DX_CD, 1) IN ('A', 'B', 'C')
                )
        
    		    OR LEFT(Dx.dx_cd, 3) IN (
        			'T07','T14','T30','T31','T32'
    		    )
    
    		    OR (
    			    LEFT(DX.DX_CD, 3) IN (
    				    'T20','T21','T22','T23','T24',
        				'T25','T26','T27','T28'
    			    )
    			    AND SUBSTRING(DX.DX_CD, 8, 1) = 'A'
        		)
    			
    		    OR (
    			    LEFT(DX.dx_cd, 5) = 'T79.A'
        			AND RIGHT(DX.DX_CD, 1) = 'A'
    		    )
    	    )
        
    	    AND PT_ID IN (
    		    SELECT PT_ID
    		    FROM SMSMIR.dx_grp AS DX
    	    	WHERE LEFT(DX.DX_CD, 3) BETWEEN 'V00' AND 'Y38'
        		AND RIGHT(DX.DX_CD, 1) = 'A'
        	)
    
    	    AND LEFT(DX.DX_CD_TYPE, 2) = 'DF'
    	    AND DX.dx_cd_prio < 11
        "
    )
) %>%
    as_tibble() %>%
    mutate_if(is.character, str_squish) %>%
    filter(pt_id %in% admit_query_a$pt_no) %>%
    arrange(pt_id, dx_cd_prio) %>%
    pivot_wider(
        names_from = dx_cd_prio
        , values_from = dx_cd
    ) %>%
    rename(
        "DX01" = "01",
        "DX02" = "02",
        "DX03" = "03",
        "DX04" = "04",
        "DX05" = "05",
        "DX06" = "06",
        "DX07" = "07",
        "DX08" = "08",
        "DX09" = "09",
        "DX10" = "10"
    )

dsch_query_c <- dbGetQuery(
    db_con
    , paste0(
        "
        SELECT [Readmit]
        , INTERIM
        
        FROM smsdss.vReadmits
        
        WHERE INTERIM < 31
        AND [READMIT SOURCE DESC] != 'SCHEDULED ADMISSION'
        "
    )
) %>%
    as_tibble() %>%
    clean_names() %>%
    mutate_if(is.character, str_squish) %>%
    filter(readmit %in% admit_query_a$pt_no_num)

# DB Disconnect ----
dbDisconnect(db_con)

# Pull all together
admit_data_tbl <- admit_query_a %>%
    inner_join(
        admit_query_b, by = c(
            "pt_no" = "pt_id"
            , "unit_seq_no" = "unit_seq_no"
            , "from_file_ind" = "from_file_ind"
        )
    ) %>%
    left_join(
        admit_query_c
        , by = c("pt_no_num" = "readmit")
    ) %>%
    select(
        pt_no_num
        , med_rec_no
        , pt_name
        , pt_age
        , adm_date
        , dsch_date
        , plm_pt_acct_type
        , dsch_disp
        , DX01
        , DX02
        , DX03
        , DX04
        , DX05
        , DX06
        , DX07
        , DX08
        , DX09
        , DX10
        , interim
    ) %>%
    mutate(
        readmit_flag = if_else(
            !is.na(interim)
            , 1
            , 0
        )
    )

dsch_data_tbl <- dsch_query_a %>%
    inner_join(
        dsch_query_b, by = c(
            "pt_no" = "pt_id"
            , "unit_seq_no" = "unit_seq_no"
            , "from_file_ind" = "from_file_ind"
        )
    ) %>%
    left_join(
        dsch_query_c
        , by = c("pt_no_num" = "readmit")
    ) %>%
    select(
        pt_no_num
        , med_rec_no
        , pt_name
        , pt_age
        , adm_date
        , dsch_date
        , plm_pt_acct_type
        , dsch_disp
        , DX01
        , DX02
        , DX03
        , DX04
        , DX05
        , DX06
        , DX07
        , DX08
        , DX09
        , DX10
        , interim
    ) %>%
    mutate(
        readmit_flag = if_else(
            !is.na(interim)
            , 1
            , 0
        )
    )

# Write files ----
dt <- Sys.Date()
folder_yr <- str_sub(dt, 1, 4)
admit_file_name_month <- min(admit_data_tbl$adm_date) %>%
    month(label = TRUE, abbr = FALSE) %>%
    as.character()
admit_file_rundate <- Sys.Date() %>% as.character()
admit_file_name <- str_c(
    admit_file_name_month
    , "_Monthly_Trauma_Admit_List_rundate_"
    , admit_file_rundate
    , ".csv"
)

dsch_file_name_month <- min(dsch_data_tbl$dsch_date) %>%
    month(label = TRUE, abbr = FALSE) %>%
    as.character()
dsch_file_rundate <- Sys.Date() %>% as.character()
dsch_file_name <- str_c(
    dsch_file_name_month
    , "_Monthly_Trauma_Discharge_List_rundate_"
    , dsch_file_rundate
    , ".csv"
)

# Admit File
f_path <- paste0("G:\\Trauma\\Monthly_Data\\",folder_yr,"\\")
admit_data_tbl %>%
    write.csv(
        paste0(
            f_path
            , admit_file_name
        )
    )

# Discharge File
dsch_data_tbl %>%
    write.csv(
        paste0(
            f_path
            , dsch_file_name
        )
    )

# Compose Email ----
# Files
admit_f_path <- paste0(f_path, admit_file_name)
dsch_f_path  <- paste0(f_path, dsch_file_name)

# Open Outlook
Outlook <- COMCreate("Outlook.Application")

# Create Email
Email = Outlook$CreateItem(0)

# Set the recipeitn, subject, and body
Email[["to"]] = ""
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = "Monthly Trauma Files"
Email[["body"]] = "Please see the attached for the latest report"
Email[["attachments"]]$Add(
    paste0(
        admit_f_path
    )
)
Email[["attachments"]]$add(
    paste0(
        dsch_f_path
    )
)

# Send the email
Email$Send()

# Clost Outlook, clear the message
rm(list = ls())

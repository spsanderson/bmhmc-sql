# Blue Cross  (B03, B04, B05, B06, B08, B09, B11, S20, E18 & E28)
# Aetna   (E13, K04, K08, X02)
# Cigna   (K11, X01)
# UHC   (E08, I10, J10, K15, K70, X22, X52)
# United Behavioral Health (K70)
# Oxford   (E10, J30, K10, 
#           Oxford Behavioral Optum  ( K90)
#           HIP  (E12, I08, K12, K68, K88, X50)
#           HealthCare Partners - E19, I18, K19, K69, K89)
# Health First - I04, J14, K64, K74, K84, 
# GHI - E27, K07, X26, X27)
# Affinity - E14,  I01, J01, K61, K71, K81)
# American Indian - X37
# MagnaCare - X15, X25
# Fidelis - E26, I06, J06, K66, K76, K86,)
# Humana - E47, X47
# Local 1199 - X45


# Lib Load ----------------------------------------------------------------

pacman::p_load(
    "tidyverse",
    "tidyquant",
    "odbc",
    "DBI",
    "writexl"
)


# DB Connection ----

db_con <- dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "BMH-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = T
)


# Query -------------------------------------------------------------------

query_tbl <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        SELECT INSBAL.pt_id
        , INSBAL.UNIT_SEQ_NO
        , INSBAL.FROM_FILE_IND
        , PAV.Pt_Name
        , INSBAL.pyr_cd
        , INSBAL.pyr_cd_desc
        , INSBAL.pyr_group
        , CASE
            WHEN INSBAL.PYR_CD IN ('B03','B04','B05','B06','B08','B09','B11','S20','E18','E28')
                THEN 'BLUE_CROSS'
            WHEN INSBAL.PYR_CD IN ('E13','K04','K08','X02')
                THEN 'AETNA'
            WHEN INSBAL.PYR_CD IN ('K11','X01')
                THEN 'CIGNA'
            WHEN INSBAL.PYR_CD IN ('E08','I10','J10','K15','K70','X22','X52')
                THEN 'UHC'
            WHEN INSBAL.PYR_CD IN ('K70')
                THEN 'UNITED_BEHAVIORAL_HEALTH'
            WHEN INSBAL.PYR_CD IN ('E10','J30','K10')
                THEN 'OXFORD'
            WHEN INSBAL.PYR_CD IN ('K90')
                THEN 'OXFORED_BEHAVIORAL_OPTUM'
            WHEN INSBAL.PYR_CD IN ('E12','I08','K12','K68','K88','X50')
                THEN 'HIP'
            WHEN INSBAL.PYR_CD IN ('E19','I18','K19','K69','K89')
                THEN 'HEALTHCARE_PARTNERS'
            WHEN INSBAL.PYR_CD IN ('I04','J14','K64','K74','K84')
                THEN 'HEALTH_FIRST'
            WHEN INSBAL.PYR_CD IN ('E27','K07','X26','X27')
                THEN 'GHI'
            WHEN INSBAL.PYR_CD IN ('E14','I01','J01','K61','K71','K81')
                THEN 'AFFINITY'
            WHEN INSBAL.PYR_CD IN ('X37')
                THEN 'AMERICAN_INDIAN'
            WHEN INSBAL.PYR_CD IN ('X15','X25')
                THEN 'MAGNACARE'
            WHEN INSBAL.PYR_CD IN ('E26','I06','J06','K66','K76','K86')
                THEN 'FIDELIS'
            WHEN INSBAL.PYR_CD IN ('E47','X47')
                THEN 'HUMANA'
            WHEN INSBAL.PYR_CD IN ('X45')
                THEN 'LOCAL_1199'
            END AS [Pyr_Grouping]
        , VST.ins1_pol_no
        , CAST(PAV.Adm_Date AS DATE) AS [Adm_Date]
        , CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date]
        , PAV.tot_chg_amt
        , '' [Date_Of_First_Bill]
        , PYRPLAN.reimb_amt AS [Expected_Reimb]
        , INSBAL.ins_cd_bal
        
        FROM smsdss.c_ins_cd_bal_tbl AS INSBAL
        LEFT OUTER JOIN SMSDSS.BMH_PLM_PtAcct_V AS PAV
        ON INSBAL.pt_id = PAV.Pt_No
            AND INSBAL.UNIT_SEQ_NO = PAV.unit_seq_no
            AND INSBAL.FROM_FILE_IND = PAV.from_file_ind
        LEFT OUTER JOIN SMSMIR.pyr_plan AS PYRPLAN
        ON INSBAL.pt_id = PYRPLAN.pt_id
            AND INSBAL.pyr_cd = PYRPLAN.pyr_cd
            AND INSBAL.UNIT_SEQ_NO = PYRPLAN.unit_seq_no
            AND INSBAL.FROM_FILE_IND = PYRPLAN.from_file_ind
        LEFT OUTER JOIN smsmir.vst_rpt AS VST
        ON INSBAL.pt_id = VST.pt_id
            AND INSBAL.UNIT_SEQ_NO = VST.unit_seq_no
            AND INSBAL.FROM_FILE_IND = VST.from_file_ind
        WHERE INSBAL.pyr_cd IN (
            'B03','B04','B05','B06','B08','B09','B11','S20','E18','E28',
            'E13','K04','K08','X02',
            'K11','X01',
            'E08','I10','J10','K15','K70','X22','X52',
            'K70',
            'E10','J30','K10',
            'K90',
            'E12','I08','K12','K68','K88','X50',
            'E19','I18','K19','K69','K89',
            'I04','J14','K64','K74','K84',
            'E27','K07','X26','X27',
            'E14','I01','J01','K61','K71','K81',
            'X37',
            'X15','X25',
            'E26','I06','J06','K66','K76','K86',
            'E47','X47',
            'X45'
        )
        AND INSBAL.RUNDATE = (SELECT MAX(RUNDATE) FROM SMSDSS.c_ins_cd_bal_tbl)
        AND (
        	(
        		LEFT(INSBAL.pt_id, 5) = '00007'
        		AND INSBAL.UNIT_SEQ_NO = 0
        		AND INSBAL.from_file_ind = '0A'
        	)
        	OR
        	(
        		LEFT(INSBAL.pt_id, 5) != '00007'
        	)
        )
        "
    )
) %>% 
    as_tibble()


# DB Disconnect -----------------------------------------------------------

dbDisconnect(conn = db_con)


# Data Manipulation -------------------------------------------------------

query_tbl %>%
    group_nest(Pyr_Grouping, keep = TRUE) %>%
    pwalk(function(Pyr_Grouping, data) {
        path_csv <- file.path(
            "G:\\Finance\\Katie Desposito\\Circular_Letter_8\\"
            , glue::glue('df_{Pyr_Grouping}.csv')
            )
        path_xlsx <- file.path(
            "G:\\Finance\\Katie Desposito\\Circular_Letter_8\\"
            , glue::glue('df_{Pyr_Grouping}.xlsx')
        )
	write_csv(data, path_csv)
	writexl::write_xlsx(x = data, path = path_xlsx)
})

summary_tbl <- query_tbl %>%
    select(Pyr_Grouping, ins_cd_bal) %>%
    group_by(Pyr_Grouping) %>%
    summarise(Total_Bal = sum(ins_cd_bal, na.rm = TRUE)) %>%
    ungroup()


# Write Data --------------------------------------------------------------

writexl::write_xlsx(summary_tbl, "G:\\Finance\\Katie Desposito\\Circular_Letter_8\\ins_cd_bal_rundate_06092020.xlsx")

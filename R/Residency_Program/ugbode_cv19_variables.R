
# Lib Load ----------------------------------------------------------------

if (!require(pacman)) {
  install.packages("pacman")
  pacman::p_load(
    "tidyverse",
    "odbc",
    "DBI",
    "janitor",
    "fastDummies",
    "lubridate"
  )
} else {
  pacman::p_load(
    "tidyverse",
    "odbc",
    "DBI",
    "janitor",
    "fastDummies",
    "lubridate"
  )
}


# DB Connect --------------------------------------------------------------

db_conn <- dbConnect(
  odbc(),
  Driver = "SQL Server",
  Server = "BMH-HIDB",
  Database = "SMSPHDSSS0X0",
  Trusted_Connection = T
)


# Query -------------------------------------------------------------------
hml_tbl <- dbGetQuery(
  conn = db_conn,
  statement = paste0(
    "
        SELECT c.PatientAccountID
        , C.Patient_oid
        , C.StartingVisitOID
        , a.GenericName
        , A.BrandName
        FROM smsmir.mir_sc_vw_MRC_Medlist AS a
        INNER JOIN smsmir.mir_sc_XMLDocStorage AS b
        ON a.XMLDocStorageOid = b.XMLDocStorageOid
        INNER JOIN smsmir.mir_sc_PatientVisit AS c
        ON b.Patient_OID = c.Patient_oid
            AND b.PatientVisit_OID = c.StartingVisitOID
        WHERE a.DocumentType = 'hml'
        AND (
        		(
        			A.BrandName LIKE '%prednisone%'
        			OR
        			A.BrandName LIKE '%METHYLPREDNISOLONE%'
        			OR
        			A.BrandName LIKE '%AZITHROMYCIN%'
        			OR
        			A.BrandName LIKE '%DEXAMETHASONE%'
        			OR
        			A.BrandName LIKE '%NOREPINEPHRINE%'
        			OR
        			A.BrandName LIKE '%LEVOPHED%'
        			OR
        			A.BrandName LIKE '%VASOPRESSIN%'
        			OR
        			A.BrandName LIKE '%DOPAMINE%'
        			OR
        			A.BrandName LIKE '%PHENYLEPHRINE%'
        			OR
        			A.BrandName LIKE '%CHLOROQUINE%'
        			OR
        			A.BrandName LIKE '%PLAQUENIL%'
        		)
        		OR
        		(
        			a.GenericName LIKE '%prednisone%'
        			OR
        			A.GenericName LIKE '%METHYLPREDISOLONE%'
        			OR
        			A.GenericName LIKE '%AZITHROMYCIN%'
        			OR
        			A.GenericName LIKE '%DEXAMETHASONE%'
        			OR
        			A.GenericName LIKE '%NOREPINEPHRINE%'
        			OR
        			A.GenericName LIKE '%LEVOPHED%'
        			OR
        			A.GenericName LIKE '%VASOPRESSIN%'
        			OR
        			A.GenericName LIKE '%DOPAMINE%'
        			OR
        			A.GenericName LIKE '%PHENYLEPHRINE%'
        			OR
        			A.GenericName LIKE '%CHLOROQUINE%'
        			OR
        			A.GenericName LIKE '%PLAQUENIL%'
        		)
        	)
        
        --AND b.PatientVisit_OID = '2077400'
        AND a.DocumentStatus = 'Complete'
        "
  )
)

population_tbl <- dbGetQuery(
  conn = db_conn,
  statement = paste0(
    "
        SELECT PAV.Med_Rec_No,
    	PAV.PtNo_Num,
    	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
    	CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date],
    	PAV.Pt_Sex,
    	CASE 
    		WHEN PAV.Pt_Race = '1'
    			THEN 'Central American'
    		WHEN PAV.Pt_Race = '2'
    			THEN 'Cuban'
    		WHEN PAV.Pt_Race = '3'
    			THEN 'Dominican'
    		WHEN PAV.Pt_Race = '4'
    			THEN 'Latin American'
    		WHEN PAV.Pt_Race = '5'
    			THEN 'Mexican'
    		WHEN PAV.Pt_Race = '6'
    			THEN 'Puerto Rican'
    		WHEN PAV.Pt_Race = '7'
    			THEN 'South American'
    		WHEN PAV.Pt_Race = '8'
    			THEN 'Spaniard'
    		WHEN PAV.Pt_Race = 'H'
    			THEN 'Hispanic'
    		WHEN PAV.Pt_Race = 'A'
    			THEN 'Asian'
    		WHEN PAV.Pt_Race = 'B'
    			THEN 'Black or African-American'
    		WHEN PAV.Pt_Race = 'I'
    			THEN 'American Indian or Alaska Native'
    		WHEN PAV.Pt_Race = 'N'
    			THEN 'Native Hawaiian or Pacific Islander'
    		WHEN PAV.Pt_Race = 'O'
    			THEN 'Other'
    		WHEN PAV.Pt_Race = 'S'
    			THEN 'Asian Indian'
    		WHEN PAV.Pt_Race = 'W'
    			THEN 'White'
    		WHEN PAV.Pt_Race = 'X'
    			THEN 'Declined'
    		END AS [RACE_DESC],
    	[ETHNICITY] = CASE 
    		WHEN PAV.Pt_Race IN ('1', '2', '3', '4', '5', '6', '7', '8', '9', 'H')
    			THEN 'HISPANIC'
    		ELSE 'NON-HISPANIC'
    		END,
    	MARITAL_STATUS.marital_sts_desc,
    	[MORTALITY] = CASE 
    		WHEN LTRIM(RTRIM(LEFT(PAV.dsch_disp, 1))) IN ('C', 'D')
    			THEN 1
    		ELSE 0
    		END,
    	[COPD] = CASE 
    		WHEN (
    				SELECT DISTINCT a.pt_id
    				FROM smsmir.dx_grp AS a
    				WHERE (
    						(
    							-- icd-9 codes
    							A.dx_cd BETWEEN '491.0'
    								AND '491.22'
    							OR A.dx_cd BETWEEN '493.20'
    								AND '493.22'
    							OR A.dx_cd = '496'
    							-- icd-10 codes
    							OR A.dx_cd IN ('J41.0', 'J41.1', 'J44.9', 'J44.1', 'J44.0', 'J44.9', 'J44.0', 'J44.1', 'J44.9')
    							)
    						AND LEFT(A.dx_cd_type, 2) = 'DF'
    						)
    					AND A.pt_id = PAV.Pt_No
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[ASTHMA] = CASE 
    		WHEN (
    				SELECT DISTINCT a.pt_id
    				FROM smsmir.dx_grp AS a
    				WHERE (
    						(
    							-- icd-9 codes
    							LEFT(A.dx_cd, 3) = '493'
    							-- icd-10 codes
    							OR LEFT(A.DX_CD, 3) = 'J45'
    							)
    						AND LEFT(A.dx_cd_type, 2) = 'DF'
    						)
    					AND A.pt_id = PAV.Pt_No
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[MRSA] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM SMSMIR.dx_grp AS A
    				WHERE (
    						(
    							A.DX_CD = '041.12'
    							OR A.DX_CD = 'A49.02'
    							)
    						AND LEFT(A.dx_cd_type, 2) = 'DF'
    						)
    					AND A.PT_ID = PAV.PT_NO
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[HEART_FAILURE] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM smsmir.dx_grp AS A
    				WHERE (
    						(
    							LEFT(A.DX_CD, 3) = 'I50'
    							OR LEFT(A.DX_CD, 3) = '428'
    							)
    						AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    						)
    					AND A.PT_ID = PAV.PT_NO
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[NSTEMI] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM smsmir.dx_grp AS A
    				WHERE (
    						(
    							A.dx_cd = 'I21.4'
    							OR A.DX_CD IN ('410.70', '410.71', '410.72')
    							)
    						AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    						)
    					AND A.PT_ID = PAV.PT_NO
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[STEMI] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM smsmir.dx_grp AS A
    				WHERE (
    						(
    							A.dx_cd = 'I21.3'
    							OR A.DX_CD BETWEEN '410.0'
    								AND '410.6'
    							)
    						AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    						)
    					AND A.PT_ID = PAV.PT_NO
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[DIABETES] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM smsmir.dx_grp AS A
    				WHERE (
    						(
    							LEFT(A.dx_cd, 3) = 'E11'
    							OR LEFT(A.DX_CD, 3) = '250'
    							)
    						AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    						)
    					AND A.PT_ID = PAV.PT_NO
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[HYPERTENSION] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM smsmir.dx_grp AS A
    				WHERE (
    						(
    							A.DX_CD = 'I10'
    							OR LEFT(A.DX_CD, 3) = '401'
    							)
    						AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    						)
    					AND A.PT_ID = PAV.PT_NO
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[HYPERTHYROIDISM] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM smsmir.dx_grp AS A
    				WHERE (
    						(
    							LEFT(A.DX_CD, 3) = 'E05'
    							OR LEFT(A.DX_CD, 3) = '242'
    							)
    						AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    						)
    					AND A.PT_ID = PAV.PT_NO
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[STROKE] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM SMSMIR.DX_GRP AS A
    				WHERE (
    						(
    							A.DX_CD IN ('I63.0', 'I63.1', 'I63.2', 'I63.5', 'I63.6', 'I63.81', 'I63.9', 'i97.810', 'I97.811', 'I97.820', 'I97.821')
    							OR LEFT(A.DX_CD, 3) = 'I64'
    							OR LEFT(A.DX_CD, 3) = '434'
    							)
    						AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    						)
    					AND A.PT_ID = PAV.Pt_No
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[CAD] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM SMSMIR.dx_grp AS A
    				WHERE (
    						(
    							A.DX_CD = 'I25.10'
    							OR A.DX_CD BETWEEN '414.00'
    								AND '414.07'
    							)
    						AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    						)
    					AND A.PT_ID = PAV.Pt_No
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[ACS] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM SMSMIR.dx_grp AS A
    				WHERE (
    						(A.DX_CD IN ('I24.9', '411.1'))
    						AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    						)
    					AND A.pt_id = PAV.Pt_No
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[AKI] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM smsmir.dx_grp AS A
    				WHERE (
    						(A.DX_CD IN ('N17.9', '584.9'))
    						AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    						)
    					AND A.pt_id = PAV.Pt_NO
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[CKD] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM SMSMIR.dx_grp AS A
    				WHERE (
    						(
    							(
    								LEFT(A.DX_CD, 3) = 'N18'
    								AND RIGHT(A.DX_CD, 1) IN ('1', '2', '3', '4', '5')
    								)
    							OR (
    								LEFT(A.DX_CD, 5) = '585.9'
    								AND RIGHT(A.DX_CD, 1) IN ('1', '2', '3', '4', '5')
    								)
    							)
    						AND LEFT(A.dx_cd_type, 2) = 'DF'
    						)
    					AND A.PT_ID = PAV.Pt_No
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[ESRD] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM smsmir.dx_grp AS A
    				WHERE A.DX_CD IN ('N18.6', '585.6')
    					AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    					AND A.PT_ID = PAV.Pt_No
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[DVT] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM smsmir.dx_grp AS A
    				WHERE (
    						A.DX_CD BETWEEN 'I82.0'
    							AND '182.91'
    						OR A.DX_CD BETWEEN '453.40'
    							AND '453.9'
    						)
    					AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    					AND A.PT_ID = PAV.Pt_No
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[PE] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM smsmir.dx_grp AS A
    				WHERE A.DX_CD IN ('I26.99', '435.19', 'I27.82', '416.2')
    					AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    					AND A.PT_ID = PAV.Pt_No
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[DEPRESSION] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM smsmir.dx_grp AS A
    				WHERE A.DX_CD IN ('F32.9', '311')
    					AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    					AND A.PT_ID = PAV.PT_NO
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[ANXIETY] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM smsmir.dx_grp AS A
    				WHERE A.DX_CD IN ('F41.9', '300.00')
    					AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    					AND A.pt_id = PAV.Pt_No
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[ICU_DAYS] = ISNULL((
    			SELECT COUNT(A.pt_id) AS [ICU_DAYS]
    			FROM SMSDSS.dly_cen_occ_fct_v AS A
    			WHERE A.nurs_sta IN ('CCU', 'MICU', 'SICU')
    				AND A.pt_id = PAV.Pt_No
    			GROUP BY A.pt_id
    			), 0),
    	[HAS_TOKOTSUBO] = CASE 
    		WHEN (
    				SELECT DISTINCT A.PT_ID
    				FROM smsmir.dx_grp AS A
    				WHERE A.DX_CD IN ('I51.81', '429.83')
    					AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    					AND A.PT_ID = PAV.PT_NO
    				) IS NOT NULL
    			THEN 1
    		ELSE 0
    		END,
    	[TOKOTSUBO_PRIN_DX] = CASE 
    		WHEN PAV.prin_dx_cd IN ('I51.81', '429.83')
    			THEN 1
    		ELSE 0
    		END,
    	[prin_dx_desc] = DX_CD.alt_clasf_desc
    FROM smsdss.BMH_PLM_PtAcct_V AS PAV
    LEFT OUTER JOIN SMSDSS.marital_sts_dim_v AS MARITAL_STATUS ON PAV.Pt_Marital_Sts = MARITAL_STATUS.src_marital_sts
    	AND MARITAL_STATUS.src_sys_id = '#PASS0X0'
    LEFT OUTER JOIN SMSDSS.DX_CD_DIM_V AS DX_CD ON PAV.prin_dx_cd = DX_CD.dx_cd
    WHERE PAV.Pt_No IN (
    		SELECT DISTINCT A.PT_ID
    		FROM smsmir.dx_grp AS A
    		WHERE (
    				A.DX_CD IN ('U07.1','B97.29','O98.5')
    				)
    			AND LEFT(A.DX_CD_TYPE, 2) = 'DF'
    		)
    	AND PAV.Pt_Age >= 18
    	AND PAV.tot_chg_amt > 0
    	AND PAV.Plm_Pt_Acct_Type = 'I'
    	AND LEFT(PAV.PTNO_NUM, 1) != '2'
    	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
    --WHERE PAV.PtNo_Num = ''
    ORDER BY PAV.Adm_Date;
        "
  )
)

vitals_tbl <- dbGetQuery(
  conn = db_conn,
  statement = paste0(
    "
        SELECT episode_no,
    	obsv_cd_name,
    	obsv_cd,
    	perf_dtime,
    	obsv_cre_dtime,
    	REPLACE(REPLACE(REPLACE(REPLACE(dsply_val, CHAR(43), ' '), CHAR(45), ' '), CHAR(13), ' '), CHAR(10), ' ') AS [dsply_val],
    	form_usage,
    	id_num = row_number() OVER (
    		PARTITION BY episode_no,
    		obsv_cd_name ORDER BY episode_no,
    			perf_dtime ASC
    		)
    FROM SMSMIR.sr_obsv
    WHERE form_usage = 'Admission'
    	--AND episode_no = '14617765'
    	AND LEN(EPISODE_NO) = 8
    	AND OBSV_CD IN (
    		'A_BMH_DoYouSomeD', 'A_BMI', 'HT', 'WT', 'A_BP', 'A_PULSE', 'a_respirations', 'A_DC O2 Sat. %', 'A_Temperature',
    		-- SMOKING
    		'A_BMH_CurrentUse', 'A_BMH_OtherTobac', 'A_BMH_TobacUse', 'A_BMH_TobLastUse', 'A_BMH_TobSurvey', 'A_BMH_TobUseInPa', 'A_TobaccoFreq', 'A_TobUsCesCnsPrf', 'A_TobUseScrnPerf', 'CA_Tobacco',
    		--'A_BMH_Advise',
    		'A_Tobacco?',
    		-- street drugs
    		'A_BMH_OthNonPres',
    		-- Admit Reason
    		'A_Adm Reason'
    		);
        "
  )
) %>%
  as_tibble() %>%
  filter(id_num == 1)

labs_tbl <- dbGetQuery(
  conn = db_conn,
  statement = paste0(
    "
        SELECT episode_no,
    	obsv_cd_name,
    	obsv_cd,
    	perf_dtime,
    	obsv_cre_dtime,
    	REPLACE(REPLACE(REPLACE(REPLACE(dsply_val, CHAR(43), ' '), CHAR(45), ' '), CHAR(13), ' '), CHAR(10), ' ') AS [dsply_val],
    	form_usage,
    	id_num = row_number() OVER (
    		PARTITION BY episode_no,
    		obsv_cd_name ORDER BY episode_no,
    			perf_dtime ASC
    		)
    FROM smsmir.SR_obsv
    WHERE obsv_cd IN (
    		'1010' --hgb
    		, '00407296' --hct
    		, '00402958' --plt
    		, '00408492' --TROPONIN
    		, '00400945' --CREATININE
    		, '00400937' -- crp
    		, '00409656' -- D-Dimer
    		, '00406090' -- ferritin
    		, '00009522' -- ABS LYMPH COUNT
    		, '00403576' -- ast
    		, '00403493' -- alt
    		, '00401695' -- ggt
    		, '00425389' -- nt-probnp
    		, 'A_BIPAPNasalCPAP' -- BIPAP
    		-- Echocardiograms
    		, '8409', '00720011', '00720060', '00720052', 'EC', '00720011', '00720037', '00720045', '00720078', 'MQ_TransEcho', 'TE', '00720029'
    		)
        "
  )
) %>%
  as_tibble() %>%
  filter(id_num == 1)

icu_first_day_tbl <- dbGetQuery(
  conn = db_conn,
  statement = paste0(
    "
        SELECT pt_id,
        	nurs_sta,
        	cen_date,
        	id_num = ROW_NUMBER() OVER (
        		PARTITION BY PT_ID ORDER BY CEN_DATE
        		)
        FROM SMSDSS.dly_cen_occ_fct_v
        WHERE nurs_sta IN ('CCU', 'MICU', 'SICU')
        "
  )
) %>%
  as_tibble() %>%
  filter(id_num == 1)


# DB Disconnect -----------------------------------------------------------

dbDisconnect(conn = db_conn)

# Data Manip --------------------------------------------------------------

population_tbl <- population_tbl %>%
  as_tibble() %>%
  clean_names() %>%
  mutate_if(is.character, str_squish) %>%
  mutate(pt_no_num = as.character(pt_no_num))

hml_tbl <- hml_tbl %>%
  select(-BrandName) %>%
  mutate_if(is.character, str_squish) %>%
  dummy_cols(select_columns = "GenericName") %>%
  as_tibble() %>%
  select(-GenericName) %>%
  pivot_longer(
    cols = c(
      -PatientAccountID,
      -Patient_oid,
      -StartingVisitOID
    ),
    names_to = "home_med"
  ) %>%
  pivot_wider(
    id_cols = c(PatientAccountID, Patient_oid, StartingVisitOID),
    names_from = "home_med",
    values_from = "value",
    values_fn = max
  ) %>%
  clean_names()

hml_tbl <- hml_tbl %>%
  mutate(
    total_home_meds = hml_tbl %>%
      select(starts_with("generic_name")) %>%
      rowSums()
  ) %>%
  filter(patient_account_id %in% population_tbl$pt_no_num)

icu_first_day_tbl <- icu_first_day_tbl %>%
  mutate_if(is.character, str_squish) %>%
  mutate(cen_date = format(cen_date, "%Y-%m-%d") %>% ymd()) %>%
  mutate(pt_no_num = str_sub(pt_id, start = 5)) %>%
  filter(pt_no_num %in% population_tbl$pt_no_num) %>%
  select(-id_num)

labs_tbl <- labs_tbl %>%
  mutate_if(is.character, str_squish) %>%
  filter(episode_no %in% population_tbl$pt_no_num) %>%
  set_names(
    "episode_no",
    "lab_cd_name",
    "lab_cd",
    "lab_perf_dtime",
    "lab_obsv_cre_dtime",
    "lab_value",
    "lab_form_name",
    "id_num"
  ) %>%
  select(-id_num)

labs_wide_tbl <- labs_tbl %>%
  select(episode_no, lab_cd_name, lab_value) %>%
  pivot_wider(
    id_cols = episode_no,
    names_from = lab_cd_name,
    values_from = lab_value
  )

vitals_tbl <- vitals_tbl %>%
  mutate_if(is.character, str_squish) %>%
  filter(episode_no %in% population_tbl$pt_no_num) %>%
  set_names(
    "episode_no",
    "vitals_cd_name",
    "vitals_cd",
    "vitals_perf_dtime",
    "vitals_obsv_cre_dtime",
    "vitals_value",
    "vitals_form_name",
    "id_num"
  ) %>%
  select(-id_num)

vitals_wide_tbl <- vitals_tbl %>%
  select(episode_no, vitals_cd_name, vitals_value) %>%
  pivot_wider(
    id_cols = episode_no,
    names_from = vitals_cd_name,
    values_from = vitals_value
  )

# Join Data ---------------------------------------------------------------

final_tbl <- population_tbl %>%
  left_join(
    hml_tbl,
    by = c("pt_no_num" = "patient_account_id")
  ) %>%
  left_join(
    icu_first_day_tbl,
    by = c("pt_no_num" = "pt_no_num")
  ) %>%
  left_join(
    labs_wide_tbl,
    by = c("pt_no_num" = "episode_no")
  ) %>%
  left_join(
    vitals_wide_tbl,
    by = c("pt_no_num" = "episode_no")
  )

# Write Data --------------------------------------------------------------

f_name <- "covid19_with_variables_rundate_"
f_date <- Sys.Date() %>% format("%m%d%Y")
writexl::write_xlsx(
  x = final_tbl,
  path = paste0(
    "G:/Residency Program/Dr Franklin Ugbode/",
    f_name,
    f_date,
    ".xlsx"
  )
)

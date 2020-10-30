
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
# Population ----
population_tbl <- dbGetQuery(
  conn = db_conn,
  statement = paste0(
    "
        SELECT PAV.Med_Rec_No,
    	PAV.PtNo_Num,
    	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
    	CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date],
    	PAV.Pt_Sex,
    	PAV.Pt_Age,
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
    	[prin_dx_desc] = DX_CD.alt_clasf_desc,
    	[dialysis] = CASE
		WHEN (
				SELECT DISTINCT A.Pt_No
				FROM SMSDSS.BMH_PLM_PtAcct_Svc_V_Hold AS A
				WHERE LEFT(A.SVC_CD, 3) = '054'
					AND A.Pt_No = PAV.Pt_No
					AND A.Bl_Unit_key = PAV.Bl_Unit_Key
					AND A.Pt_Key = PAV.Pt_Key
				) IS NOT NULL
			THEN 1
		ELSE 0
		END
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
    	--AND PAV.Plm_Pt_Acct_Type = 'I'
    	AND LEFT(PAV.PTNO_NUM, 1) != '2'
    	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
    --WHERE PAV.PtNo_Num = ''
    ORDER BY PAV.Adm_Date;
        "
  )
) %>%
  as_tibble() %>%
  mutate_if(is.character, str_squish) %>%
  mutate(PtNo_Num = as.character(PtNo_Num))

# HML ----
hml_tbl <- dbGetQuery(
  conn = db_conn,
  statement = paste0(
    "
    SELECT c.PatientAccountID
    , C.Patient_oid
    , C.StartingVisitOID
    , B.DocumentDTime
    , B.LastCngDTime
    , [Home_Med] = COALESCE(A.GenericName, A.BrandName)
    , [rn] = ROW_NUMBER() OVER(
    	PARTITION BY C.PatientAccountID, 
    	A.GenericName
    	ORDER BY B.DocumentDTime DESC
    	)
    FROM smsmir.mir_sc_vw_MRC_Medlist AS a
    INNER JOIN smsmir.mir_sc_XMLDocStorage AS b
    ON a.XMLDocStorageOid = b.XMLDocStorageOid
    INNER JOIN smsmir.mir_sc_PatientVisit AS c
    ON b.Patient_OID = c.Patient_oid
        AND b.PatientVisit_OID = c.StartingVisitOID
    WHERE a.DocumentType = 'hml'
    "
  )
) %>%
  as_tibble() %>%
  filter(PatientAccountID %in% population_tbl$PtNo_Num)

# Inhouse Meds ----
inhouse_meds_tbl <- dbGetQuery(
  conn = db_conn,
  statement = paste0(
    "
    SELECT EpisodeNo,
  	GnrcName,
  	BrandName,
  	[med_name] = COALESCE(GnrcName, BrandName)
  FROM smsmir.mir_PHM_Ord
  WHERE (
  		(
  			BrandName LIKE '%prednisone%'
  			OR BrandName LIKE '%METHYLPREDNISOLONE%'
  			OR BrandName LIKE '%AZITHROMYCIN%'
  			OR BrandName LIKE '%DEXAMETHASONE%'
  			OR BrandName LIKE '%NOREPINEPHRINE%'
  			OR BrandName LIKE '%LEVOPHED%'
  			OR BrandName LIKE '%VASOPRESSIN%'
  			OR BrandName LIKE '%DOPAMINE%'
  			OR BrandName LIKE '%PHENYLEPHRINE%'
  			OR BrandName LIKE '%CHLOROQUINE%'
  			OR BrandName LIKE '%PLAQUENIL%'
  			OR BrandName LIKE '%ACTEMRA%'
  			)
  		OR (
  			GnrcName LIKE '%prednisone%'
  			OR GnrcName LIKE '%METHYLPREDISOLONE%'
  			OR GnrcName LIKE '%AZITHROMYCIN%'
  			OR GnrcName LIKE '%DEXAMETHASONE%'
  			OR GnrcName LIKE '%NOREPINEPHRINE%'
  			OR GnrcName LIKE '%LEVOPHED%'
  			OR GnrcName LIKE '%VASOPRESSIN%'
  			OR GnrcName LIKE '%DOPAMINE%'
  			OR GnrcName LIKE '%PHENYLEPHRINE%'
  			OR GnrcName LIKE '%CHLOROQUINE%'
  			OR GnrcName LIKE '%PLAQUENIL%'
  			OR GnrcName LIKE '%ACTEMRA%'
  			)
  		)
    "
  )
) %>%
  as_tibble() %>%
  filter(EpisodeNo %in% population_tbl$PtNo_Num)

# Vitals ----
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
    --WHERE form_usage = 'Admission'
    	--AND episode_no = '14617765'
    WHERE LEN(EPISODE_NO) = 8
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
  filter(id_num == 1) %>%
  filter(episode_no %in% population_tbl$PtNo_Num)

# Labs ----
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
    		, '00407296' -- hct
    		, '00402958' -- plt
    		, '00408492' -- TROPONIN
    		, '00400945' -- CREATININE
    		, '00400937' -- crp
    		, '00409656' -- D-Dimer
    		, '00406090' -- ferritin
    		, '00009522' -- ABS LYMPH COUNT
    		, '00403576' -- ast
    		, '00403493' -- alt
    		, '00401695' -- ggt
    		, '00425389' -- nt-probnp
    		, '2012'     -- inr
    		, '00411769' -- A1c
    		, '00400929' -- CPK
    		, '00404061' -- TSH
    		, '00400408' -- Total Bilirubin
    		, '73990'    -- Culture Report
    		)
        "
  )
) %>%
  as_tibble() %>%
  filter(episode_no %in% population_tbl$PtNo_Num)

# Respiratory ----
respiratory_tbl <- dbGetQuery(
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
    'A_BIPAPNasalCPAP' -- BIPAP
    , 'A_BMH_VFSTART'  -- Vent Start
    , 'A_BMH_VFSTOP'   -- Vent Stop
    )
    "
  )
) %>%
  as_tibble() %>%
  filter(episode_no %in% population_tbl$PtNo_Num)

# Imaging ----
imaging_tbl <- dbGetQuery(
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
    -- Echocardiograms
    '8409'
    , '00720011'
    , '00720060'
    , '00720052'
    , 'EC'
    , '00720011'
    , '00720037'
    , '00720045'
    , '00720078'
    , 'MQ_TransEcho'
    , 'TE'
    , '00720029'
    )
    "
  )
) %>% 
  as_tibble() %>%
  filter(episode_no %in% population_tbl$PtNo_Num)

# ICU First Date ----
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

# ICU Last Date ----
icu_last_day_tbl <- dbGetQuery(
  conn = db_conn,
  statement = paste0(
    "
    SELECT pt_id,
    	nurs_sta,
    	cen_date,
    	id_num = ROW_NUMBER() OVER (
    		PARTITION BY PT_ID ORDER BY CEN_DATE DESC
    		)
    FROM SMSDSS.dly_cen_occ_fct_v
    WHERE nurs_sta IN ('CCU', 'MICU', 'SICU')
    "
  )
) %>%
  as_tibble() %>%
  filter(id_num == 1)

# Comorbidities ----
# Check covid extract from Admit assessment
comorbidity_tbl <- dbGetQuery(
  conn = db_conn,
  statement = paste0(
    "
    SELECT episode_no,
  	obsv_cd_name,
  	obsv_cd,
  	perf_dtime,
  	obsv_cre_dtime,
  	REPLACE(REPLACE(REPLACE(REPLACE(dsply_val, CHAR(43), ' '), CHAR(45), ' '), CHAR(13), ' '), CHAR(10), ' ') AS [Display_Value],
  	form_usage,
  	id_num = row_number() OVER (
  		PARTITION BY episode_no,
  		obsv_cd_name ORDER BY episode_no,
  			perf_dtime DESC
  		)
    FROM SMSMIR.obsv
    WHERE obsv_cd IN (
    		'A_BMH_ListCoMorb'
    	)
    	AND form_usage = 'Admission'
    	AND LEN(EPISODE_NO) = 8
    ORDER BY episode_no,
    	perf_dtime DESC;
    "
  )
) %>%
  as_tibble() %>%
  filter(id_num == 1) %>%
  filter(episode_no %in% population_tbl$PtNo_Num)

# Nasal Cannula ----
nasal_cannula_tbl <- dbGetQuery(
  conn = db_conn,
  statement = paste0(
    "
    SELECT episode_no,
  	obsv_cd_name,
  	obsv_cd,
  	perf_dtime,
  	obsv_cre_dtime,
  	REPLACE(REPLACE(REPLACE(REPLACE(dsply_val, CHAR(43), ' '), CHAR(45), ' '), CHAR(13), ' '), CHAR(10), ' ') AS [Display_Value],
  	form_usage,
  	id_num = row_number() OVER (
  		PARTITION BY episode_no,
  		obsv_cd_name ORDER BY episode_no,
  			perf_dtime DESC
  		)
    FROM SMSMIR.obsv
    WHERE obsv_cd IN (
    		'A_O2 Del Device','A_O2 Del Method'
    	)
    	AND dsply_val = 'Nasal Cannula'
    	AND LEN(EPISODE_NO) = 8
    ORDER BY episode_no,
    	perf_dtime DESC;
    "
  )
) %>%
  as_tibble() %>%
  filter(id_num == 1) %>%
  filter(episode_no %in% population_tbl$PtNo_Num)

# Cultures Table ----
cultures_tbl <- dbGetQuery(
  conn = db_conn,
  statement = paste0(
    "
  SELECT episode_no,
  	obsv_cd_name,
  	obsv_cd,
  	perf_dtime,
  	obsv_cre_dtime,
  	coll_dtime,
    ord_occr_no,
    ord_occr_obj_id,
    ord_seq_no,
  	REPLACE(REPLACE(REPLACE(REPLACE(dsply_val, CHAR(43), ' '), CHAR(45), ' '), CHAR(13), ' '), CHAR(10), ' ') AS [Display_Value]
  FROM SMSMIR.obsv
  WHERE obsv_cd IN (
  		'73990',
  		'70021'
  	)
	AND LEN(EPISODE_NO) = 8
  ORDER BY episode_no,
  	perf_dtime,
  	obsv_cre_dtime,
  	coll_dtime,
    ord_occr_no,
    ord_occr_obj_id,
    ord_seq_no
    "
  )
) %>%
  as_tibble() %>%
  filter(episode_no %in% population_tbl$PtNo_Num)

# Isolate ID ----
isolate_id_tbl <- dbGetQuery(
  conn = db_conn,
  statement = paste0(
    "
    SELECT episode_no,
    	obsv_cd_name,
    	obsv_cd,
    	perf_dtime,
    	obsv_cre_dtime,
    	coll_dtime,
    	ord_occr_no,
    	ord_occr_obj_id,
    	ord_seq_no,
    	REPLACE(REPLACE(REPLACE(REPLACE(dsply_val, CHAR(43), ' '), CHAR(45), ' '), CHAR(13), ' '), CHAR(10), ' ') AS [Display_Value]
    FROM SMSMIR.obsv
    WHERE obsv_cd IN (
    		'74000'
    	)
    	AND LEN(EPISODE_NO) = 8
    ORDER BY episode_no,
    	perf_dtime DESC;
    "
  )
) %>%
  as_tibble() %>%
  # filter(id_num == 1) %>%
  filter(episode_no %in% population_tbl$PtNo_Num)

# DB Disconnect -----------------------------------------------------------

dbDisconnect(conn = db_conn)

# Data Manip --------------------------------------------------------------

population_tbl <- population_tbl %>%
  as_tibble() %>%
  clean_names() %>%
  mutate_if(is.character, str_squish) %>%
  mutate(pt_no_num = as.character(pt_no_num))

hml_tbl <- hml_tbl %>%
  as_tibble() %>%
  filter(rn == 1) %>%
  clean_names() %>%
  mutate_if(is.character, str_squish) %>%
  mutate(patient_account_id = as.character(patient_account_id)) %>%
  select(-rn, -document_d_time, -last_cng_d_time) %>%
  filter(patient_account_id %in% population_tbl$pt_no_num) %>%
  group_by(patient_account_id, patient_oid, starting_visit_oid) %>%
  mutate(home_med_num = paste0("home_med_", row_number())) %>%
  ungroup() %>%
  pivot_wider(
    id_cols = c(patient_account_id, patient_oid, starting_visit_oid)
    , names_from = "home_med_num"
    , values_from = "home_med"
  )

inhouse_meds_wide_tbl <- inhouse_meds_tbl %>%
  clean_names() %>%
  mutate_if(is.character, str_squish) %>%
  select(episode_no, med_name) %>%
  distinct(episode_no, med_name) %>%
  count(episode_no, med_name) %>%
  mutate(med_name = str_to_title(med_name)) %>%
  pivot_wider(
    id_cols = episode_no
    , names_from = med_name
    , values_from = med_name
  ) %>%
  clean_names()

icu_first_day_tbl <- icu_first_day_tbl %>%
  mutate_if(is.character, str_squish) %>%
  mutate(cen_date = format(cen_date, "%Y-%m-%d") %>% ymd()) %>%
  mutate(pt_no_num = str_sub(pt_id, start = 5)) %>%
  filter(pt_no_num %in% population_tbl$pt_no_num) %>%
  select(-id_num) %>%
  set_names("pt_id","first_icu_station","icu_admit_date","pt_no_num") %>%
  select(-pt_id)

icu_last_day_tbl <- icu_last_day_tbl %>%
  mutate_if(is.character, str_squish) %>%
  mutate(cen_date = format(cen_date, "%Y-%m-%d") %>% ymd()) %>%
  mutate(pt_no_num = str_sub(pt_id, start = 5)) %>%
  filter(pt_no_num %in% population_tbl$pt_no_num) %>%
  select(-id_num) %>%
  set_names("pt_id","last_icu_station","icu_discharge_date","pt_no_num") %>%
  select(-pt_id)

respiratory_tbl <- respiratory_tbl %>%
  clean_names() %>%
  mutate_if(is.character, str_squish) %>%
  filter(episode_no %in% population_tbl$pt_no_num) %>%
  filter(id_num == 1) %>%
  select(episode_no, obsv_cd, obsv_cd_name, perf_dtime, dsply_val) %>%
  mutate(obsv_desc = case_when(
    obsv_cd == 'A_BMH_VFStart' ~ "Vent_Start_DTime"
    , obsv_cd == 'A_BMH_VFStop' ~ "Vent_Stop_DTime"
    , obsv_cd == 'A_BIPAPNasalCPAP' ~ "Bipap"
  )) %>%
  mutate(
    resp_value = ifelse(
      obsv_cd %in% c('A_BMH_VFStart','A_BMH_VFStop')
      , as.character(perf_dtime)
      , dsply_val
    )
  ) %>%
  pivot_wider(
    id_cols = c(episode_no, obsv_cd)
    , names_from = obsv_desc
    , values_from = resp_value
  )

imaging_tbl <- imaging_tbl %>%
  clean_names() %>%
  mutate_if(is.character, str_squish) %>%
  filter(episode_no %in% population_tbl$pt_no_num) %>%
  filter(id_num == 1)

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
  )

first_labs_tbl <- labs_tbl %>%
  filter(id_num == 1) %>%
  filter(lab_cd %in% c(
    "1010","00406090","00407296","00411769","73990"
  ))  %>%
  select(episode_no, lab_cd_name, lab_cd, lab_value)

highest_labs_tbl <- labs_tbl %>%
  filter(
    lab_cd %in% c(
      "00400937"
      ,"00400945"
      ,"2012"
      ,'00403576'
      ,'00403493'
      ,'00401695'
      ,'00400929'
      ,'00400408'
    )
  ) %>%
  group_by(episode_no, lab_cd_name, lab_cd) %>%
  summarise(lab_value = max(lab_value)) %>%
  ungroup()

fixed_highest_labs_tbl <- labs_tbl %>%
  filter(
    lab_cd %in% c(
      "00409656"
      ,"00408492"
      ,"00425389"
    )
  ) %>%
  mutate(
    clean_lab_value = str_squish(lab_value) %>%
      str_replace_all("<", "") %>%
      str_replace_all(">", "") %>%
      str_squish() %>%
      str_sub(1, str_locate(lab_value, ' ')[,1]) %>%
      str_squish() %>%
      as.character()
  ) %>%
  group_by(episode_no, lab_cd_name, lab_cd) %>%
  summarise(lab_value = max(clean_lab_value)) %>%
  ungroup()

high_labs_tbl <- union_all(highest_labs_tbl, fixed_highest_labs_tbl) %>%
  arrange(episode_no)

lowest_labs_tbl <- labs_tbl %>%
  filter(
    lab_cd %in% c(
      "00402958"
      ,"00009522"
    )
  ) %>%
  group_by(episode_no, lab_cd_name, lab_cd) %>%
  summarise(lab_value = min(lab_value)) %>%
  ungroup() %>%
  arrange(episode_no)

fixed_lowest_labs_tbl <- labs_tbl %>%
  filter(lab_cd == "00404061") %>%
  mutate(
    clean_lab_value = str_squish(lab_value) %>%
      str_replace_all("<", "") %>%
      str_replace_all(">", "") %>%
      str_squish() %>%
      str_sub(1, str_locate(lab_value, ' ')[,1]) %>%
      str_squish() %>%
      as.character()
  ) %>%
  group_by(episode_no, lab_cd_name, lab_cd) %>%
  summarise(lab_value = min(clean_lab_value)) %>%
  ungroup()

low_labs_tbl <- union_all(lowest_labs_tbl, fixed_lowest_labs_tbl) %>%
  arrange(episode_no)

labs_union_tbl <- union_all(
  high_labs_tbl
  , low_labs_tbl
  , first_labs_tbl
)

labs_wide_tbl <- labs_union_tbl %>%
  select(episode_no, lab_cd_name, lab_value) %>%
  pivot_wider(
    id_cols = episode_no,
    names_from = lab_cd_name,
    values_from = lab_value
  ) %>%
  clean_names()

imaging_wide_tbl <- imaging_tbl %>%
  set_names(
    "episode_no",
    "imaging_cd_name",
    "imaging_cd",
    "imaging_perf_dtime",
    "imaging_obsv_cre_dtime",
    "imaging_value",
    "imaging_form_name",
    "id_num"
  ) %>%
  select(episode_no, imaging_cd, imaging_cd_name, imaging_value) %>%
  pivot_wider(
    id_cols = episode_no
    , names_from = imaging_cd_name
    , values_from = imaging_value
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
  ) %>%
  clean_names()

comorbidity_wide_tbl <- comorbidity_tbl %>%
  set_names(
    "episode_no",
    "comorbidity_cd_name",
    "comorbidity_cd",
    "comorbidity_perf_dtime",
    "comorbidity_obsv_cre_dtime",
    "comorbidity_value",
    "comorbidity_form_name",
    "id_num"
  ) %>%
  select(episode_no, comorbidity_value) %>%
  mutate(comorbidity_value = str_to_upper(comorbidity_value)) %>%
  separate(
    col = comorbidity_value,
    into = str_c("comorbidity_", 1:50),
    sep = "[,;]",
    remove = FALSE,
    fill = "right"
  ) %>%
  # select a column if any of the rows are not NA
  select_if(function(x) any(!is.na(x))) %>%
  mutate_if(is.character, str_squish)

cultures_wide_tbl <- cultures_tbl %>% 
  mutate_if(is.character, str_squish) %>% 
  select(episode_no, contains("ord"), obsv_cd_name, Display_Value) %>% 
  filter(!is.na(ord_occr_no), !is.na(ord_occr_obj_id), !is.na(ord_seq_no)) %>%
  pivot_wider(names_from = obsv_cd_name, values_from = Display_Value) %>% 
  set_names(
    "episode_no","ord_occr_no","ord_occr_obj_id","ord_seq_no",
    "test_name","report_value"
  ) %>% 
  group_by(episode_no, test_name) %>%
  mutate(max_ord_occr_no = (ord_occr_no == max(ord_occr_no))) %>%
  ungroup() %>%
  filter(max_ord_occr_no == TRUE) %>%
  select(episode_no, test_name, report_value) %>%
  pivot_wider(names_from = test_name, values_from = report_value) %>% 
  clean_names() %>% 
  select(
    episode_no, urine_culture, blood_culture, 
    sputum_culture, urine_culture, gram_stain, body_fluid_culture, 
    anaerobic_culture, fungal_culture, acid_fast_culture)

# Get last isolate id
isolate_id_wide_tbl <- isolate_id_tbl %>%
  mutate_if(is.character, str_squish) %>%
  select(episode_no, ord_occr_no, obsv_cd_name, Display_Value) %>% 
  group_by(episode_no) %>%
  mutate(max_ord_occr_no = (ord_occr_no == max(ord_occr_no))) %>%
  ungroup() %>%
  filter(max_ord_occr_no == TRUE) %>%
  select(-max_ord_occr_no, -ord_occr_no, -obsv_cd_name) %>%
  set_names(
    "episode_no","isolate_report_value"
  )


# Join Data ---------------------------------------------------------------

final_tbl <- population_tbl %>%
  left_join(
    hml_tbl,
    by = c("pt_no_num" = "patient_account_id")
  ) %>%
  left_join(
    inhouse_meds_wide_tbl,
    by = c("pt_no_num" = "episode_no")
  ) %>%
  left_join(
    icu_first_day_tbl,
    by = c("pt_no_num" = "pt_no_num")
  ) %>%
  left_join(
    icu_last_day_tbl,
    by = c("pt_no_num" = "pt_no_num")
  ) %>%
  left_join(
    labs_wide_tbl,
    by = c("pt_no_num" = "episode_no")
  ) %>%
  left_join(
    vitals_wide_tbl,
    by = c("pt_no_num" = "episode_no")
  ) %>%
  left_join(
    respiratory_tbl,
    by = c("pt_no_num" = "episode_no")
  ) %>%
  left_join(
    imaging_wide_tbl,
    by = c("pt_no_num" = "episode_no")
  ) %>%
  left_join(
    cultures_wide_tbl,
    by = c("pt_no_num" = "episode_no")
  ) %>%
  left_join(
    isolate_id_wide_tbl,
    by = c("pt_no_num" = "episode_no")
  )


# Write Data --------------------------------------------------------------

f_name <- "covid19_with_variables_rundate_"
f_date <- Sys.Date() %>% format("%m_%d_%Y")
writexl::write_xlsx(
  x = final_tbl,
  path = paste0(
    "G:/Residency Program/Dr Franklin Ugbode/",
    f_name,
    f_date,
    ".xlsx"
  )
)

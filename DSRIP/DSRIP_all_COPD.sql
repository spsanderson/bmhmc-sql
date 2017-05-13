-- copd
-- Variable declaration and setting -----------------------------------
DECLARE @SD DATETIME;
DECLARE @ED DATETIME;

SET @SD = '2016-01-01';
SET @ED = '2016-09-01';

/*
=======================================================================
Initial Eligible Admissions
=======================================================================
*/
DECLARE @InitPop TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           INT
	, MRN                 INT
	, Adm_Date            DATE
	, Discharge_Date      DATE
	, Adm_Source          VARCHAR(2)
	, Adm_Source_Desc     VARCHAR(30)
	, Dispo               VARCHAR(3)
	, Dispo_Desc          VARCHAR(50)
	, Age                 INT
	, Payer_Cat           VARCHAR(15)
	, MS_DRG              VARCHAR(3)
	, Prin_Dx             VARCHAR(10)
	, Dx_Cd_2             VARCHAR(10)
	, Prin_Proc_Cd        VARCHAR(10)
	, AHRQ_Dx_Cd          VARCHAR(7)
	, AHRQ_Dx_Cd_Desc     VARCHAR(MAX)
	, Diagnosis           VARCHAR(MAX)
	, Visit_Type          VARCHAR(10)
	, Visit_SEQ_No        INT
)

INSERT INTO @InitPop
SELECT A.*
FROM (
	-- Variables selected ---------------------------------------------
	SELECT A.PtNo_Num
	, A.Med_Rec_No
	, CAST(A.Adm_Date AS DATE) AS [Adm_Date]
	, CAST(A.Dsch_Date AS DATE) AS [Dsch_Date]
	, A.Adm_Source
	, E.adm_src_desc
	, A.dsch_disp
	, CASE
		WHEN LEFT(C.src_dsch_disp, 1) IN ('C' , 'D')
			THEN 'Death'
		WHEN C.src_dsch_disp = 'ATW'
			THEN 'Referred to Home Care'
		WHEN C.src_dsch_disp = 'ATL'
			THEN 'Transferred to a Medicare Certified LTCH'
		WHEN C.src_dsch_disp = 'ATT'
			THEN 'Discharged to Hospice'
		WHEN C.src_dsch_disp IN ('AHI', 'HI')
			THEN 'Discharged home under home IV provider'
		ELSE C.dsch_disp_desc
	  END AS [Discharge_Description]
	, A.Pt_Age AS [Pt_Age_At_Admit]
	, CASE
		WHEN A.User_Pyr1_Cat IN ('AAA', 'ZZZ')
			THEN 'Medicare'
		WHEN A.User_Pyr1_Cat = 'WWW'
			THEN 'Medicaid'
		ELSE 'Other'
	  END AS [Payer_Category]
	, A.drg_no
	, A.prin_dx_cd
	, d.dx_cd
	, A.proc_cd
	, B.CC_Code
	, B.CC_Desc
	, B.Diagnosis
	, 'COPD' AS Visit_Type
	, RN = ROW_NUMBER() OVER(PARTITION BY A.MED_REC_NO ORDER BY A.VST_START_DTIME)

	-- Where the data comes from --------------------------------------
	FROM SMSDSS.BMH_PLM_PTACCT_V                   AS A
	LEFT OUTER MERGE JOIN SMSDSS.c_AHRQ_Dx_CC_Maps AS B
	ON REPLACE(A.PRIN_DX_CD, '.','') = B.ICDCode
	LEFT OUTER MERGE JOIN SMSDSS.dsch_disp_dim_v   AS C
	ON RTRIM(LTRIM(RIGHT(A.dsch_disp, 2))) = RTRIM(LTRIM(RIGHT(C.src_dsch_disp, 2)))
		AND C.src_sys_id = '#PMSNTX0'
	LEFT OUTER JOIN SMSMIR.mir_dx_grp              AS D
	ON A.Pt_No = D.pt_id
		AND A.pt_id_start_dtime = D.pt_id_start_dtime
		AND A.unit_seq_no = D.unit_seq_no
		AND D.dx_cd_prio = '02'
		AND LEFT(DX_CD_TYPE, 2) = 'DF'
	LEFT OUTER MERGE JOIN smsdss.adm_src_dim_v     AS E
	ON A.Adm_Source = E.src_adm_src
		AND E.src_sys_id = '#PMSNTX0'

	-- Filters --------------------------------------------------------
	WHERE 
	-- Only Inpatients and ED Visits
	LEFT(A.PtNo_Num, 1) IN ('1', '8')
	AND A.Dsch_Date >= @SD
	AND A.Dsch_Date < @ED
	-- Patient must have total charges greater than 0 to help identify 
	-- viable admissions
	AND A.tot_chg_amt > '0'
	-- Exclude those that were discharged AMA, Transfer to another
	-- acute facility
	AND A.dsch_disp NOT IN ('AMA', 'ATA', 'ATS', 'ATF', 'ATH', 'ATN', 'MA')
	-- Specific ICD-9 codes used in CMS specs for cohort inclusion
	AND (
		A.prin_dx_cd IN (
		-- ICD-9 Codes
		'491.21', '491.22', '491.8', '491.9' ,'492.8'
		, '493.20', '493.21', '493.22', '496',
		-- ICD-10 Codes
		'J44.1', 'J44.0', 'J41.8', 'J42', 'J43.9',
		'J44.9'
		)
		OR
		A.prin_dx_cd = '518.81' AND d.dx_cd IN (
		'491.21', '491.22', '493.21', '493.22'
		)
		-- ICD-10 Version
		OR
		A.prin_dx_cd IN ('J96.00', 'J96.90') AND d.dx_cd IN (
		'J44.1', 'J44.0'
		)
		OR 
		A.prin_dx_cd = '518.82' AND d.dx_cd IN (
		'491.21', '491.22', '493.21', '493.22'
		)
		-- ICD-10 Version
		OR
		A.prin_dx_cd = 'J80' AND d.dx_cd IN (
		'J44.1', 'J44.0'
		)
		OR 
		A.prin_dx_cd = '518.84' AND d.dx_cd IN (
		'491.21', '491.22', '493.21', '493.22'
		)
		-- ICD-10 Version
		OR
		A.prin_dx_cd = 'J96.20' AND d.dx_cd IN (
		'J44.1', 'J44.0'
		)
		OR
		A.prin_dx_cd = '799.1' AND d.dx_cd IN (
		'491.21', '491.22', '493.21', '493.22'
		)
		-- ICD-10 Version
		OR
		A.prin_dx_cd = 'R09.2' AND  d.dx_cd IN (
		'J44.1', 'J44.0'
		)
	)
	-- LOS cannot be longer than 1 year
	AND A.Days_Stay <= 365
) A;



---------------------------------------------------------------------------------------------------
-- GET NON COPD VISITS
DECLARE @InitPop_NonCOPD TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter           INT
	, MRN                 INT
	, Adm_Date            DATE
	, Discharge_Date      DATE
	, Adm_Source          VARCHAR(2)
	, Adm_Source_Desc     VARCHAR(30)
	, Dispo               VARCHAR(3)
	, Dispo_Desc          VARCHAR(50)
	, Age                 INT
	, Payer_Cat           VARCHAR(15)
	, MS_DRG              VARCHAR(3)
	, Prin_Dx             VARCHAR(10)
	, Dx_Cd_2             VARCHAR(10)
	, Prin_Proc_Cd        VARCHAR(10)
	, AHRQ_Dx_Cd          VARCHAR(7)
	, AHRQ_Dx_Cd_Desc     VARCHAR(MAX)
	, Diagnosis           VARCHAR(MAX)
	, Visit_Type          VARCHAR(10)
	, Visit_SEQ_No        INT
)

INSERT INTO @InitPop_NonCOPD
SELECT A.*
FROM (
	-- Variables selected ---------------------------------------------
	SELECT A.PtNo_Num
	, A.Med_Rec_No
	, CAST(A.Adm_Date AS DATE) AS [Adm_Date]
	, CAST(A.Dsch_Date AS DATE) AS [Dsch_Date]
	, A.Adm_Source
	, E.adm_src_desc
	, A.dsch_disp
	, CASE
		WHEN LEFT(C.src_dsch_disp, 1) IN ('C' , 'D')
			THEN 'Death'
		WHEN C.src_dsch_disp = 'ATW'
			THEN 'Referred to Home Care'
		WHEN C.src_dsch_disp = 'ATL'
			THEN 'Transferred to a Medicare Certified LTCH'
		WHEN C.src_dsch_disp = 'ATT'
			THEN 'Discharged to Hospice'
		WHEN C.src_dsch_disp IN ('AHI', 'HI')
			THEN 'Discharged home under home IV provider'
		ELSE C.dsch_disp_desc
	  END AS [Discharge_Description]
	, A.Pt_Age AS [Pt_Age_At_Admit]
	, CASE
		WHEN A.User_Pyr1_Cat IN ('AAA', 'ZZZ')
			THEN 'Medicare'
		WHEN A.User_Pyr1_Cat = 'WWW'
			THEN 'Medicaid'
		ELSE 'Other'
	  END AS [Payer_Category]
	, A.drg_no
	, A.prin_dx_cd
	, d.dx_cd
	, A.proc_cd
	, B.CC_Code
	, B.CC_Desc
	, B.Diagnosis
	, 'Non COPD' AS Visit_Type
	, RN = ROW_NUMBER() OVER(PARTITION BY A.MED_REC_NO ORDER BY A.VST_START_DTIME)

	-- Where the data comes from --------------------------------------
	FROM SMSDSS.BMH_PLM_PTACCT_V                   AS A
	LEFT OUTER MERGE JOIN SMSDSS.c_AHRQ_Dx_CC_Maps AS B
	ON REPLACE(A.PRIN_DX_CD, '.','') = B.ICDCode
	LEFT OUTER MERGE JOIN SMSDSS.dsch_disp_dim_v   AS C
	ON RTRIM(LTRIM(RIGHT(A.dsch_disp, 2))) = RTRIM(LTRIM(RIGHT(C.src_dsch_disp, 2)))
		AND C.src_sys_id = '#PMSNTX0'
	LEFT OUTER JOIN SMSMIR.mir_dx_grp              AS D
	ON A.Pt_No = D.pt_id
		AND A.pt_id_start_dtime = D.pt_id_start_dtime
		AND A.unit_seq_no = D.unit_seq_no
		AND D.dx_cd_prio = '02'
		AND LEFT(DX_CD_TYPE, 2) = 'DF'
	LEFT OUTER MERGE JOIN smsdss.adm_src_dim_v     AS E
	ON A.Adm_Source = E.src_adm_src
		AND E.src_sys_id = '#PMSNTX0'

	-- Filters --------------------------------------------------------
	WHERE A.PtNo_Num NOT IN (
		SELECT DISTINCT(XXX.Encounter)
		FROM @InitPop AS XXX
	)
	AND LEFT(A.PTNO_NUM, 1) IN ('1', '8')
	AND A.tot_chg_amt > 0
	AND A.Days_Stay <= 365
	AND A.dsch_disp NOT IN ('AMA', 'ATA', 'ATS', 'ATF', 'ATH', 'ATN', 'MA')
	AND A.Dsch_Date >= @SD
	AND A.Dsch_Date < @ED
	AND A.Med_Rec_No IN (
		SELECT DISTINCT(XXX.MRN)
		FROM @InitPop AS XXX
	)
) A;

---------------------------------------------------------------------------------------------------
-- COPD VISITS
SELECT A.*
, CASE
	WHEN LEFT(A.Encounter, 1) = '1'
		THEN '1'
		ELSE '0'
  END AS [IP Flag]
, CASE
	WHEN LEFT(A.Encounter, 1) = '8'
		THEN '1'
		ELSE '0'
  END AS [ED Flag]
  
INTO #INIT_POP_FINAL

FROM @InitPop AS A

WHERE A.MRN NOT IN (
	SELECT ZZZ.MRN
	FROM @InitPop AS ZZZ
	WHERE ZZZ.Dispo_Desc = 'Death'
);

--SELECT * FROM #INIT_POP_FINAL;
---------------------------------------------------------------------------------------------------
-- NON COPD VISITS
 SELECT A.*
 , CASE
	WHEN LEFT(A.Encounter, 1) = '1'
		THEN '1'
		ELSE '0'
  END AS [IP Flag]
, CASE
	WHEN LEFT(A.Encounter, 1) = '8'
		THEN '1'
		ELSE '0'
  END AS [ED Flag]

INTO #NON_COPD_VISITS_FINAL
 
FROM @InitPop_NonCOPD AS A
 
WHERE A.MRN NOT IN (
	SELECT XXX.MRN
	FROM @InitPop_NonCOPD AS XXX
	WHERE XXX.Dispo_Desc = 'Death'
);
 
--SELECT * FROM #NON_COPD_VISITS_FINAL;
 
---------------------------------------------------------------------------------------------------
-- UNION ALL RESULTS TOGETHER INTO VARIABLE TABLE
DECLARE @COPD_Tbl TABLE (
	ID                    INT
	, Encounter           INT
	, MRN                 INT
	, Adm_Date            DATE
	, Discharge_Date      DATE
	, Adm_Source          VARCHAR(2)
	, Adm_Source_Desc     VARCHAR(30)
	, Dispo               VARCHAR(3)
	, Dispo_Desc          VARCHAR(50)
	, Age                 INT
	, Payer_Cat           VARCHAR(15)
	, MS_DRG              VARCHAR(3)
	, Prin_Dx             VARCHAR(10)
	, Dx_Cd_2             VARCHAR(10)
	, Prin_Proc_Cd        VARCHAR(10)
	, AHRQ_Dx_Cd          VARCHAR(7)
	, AHRQ_Dx_Cd_Desc     VARCHAR(MAX)
	, Diagnosis           VARCHAR(MAX)
	, Visit_Type          VARCHAR(10)
	, Visit_Type_Seq_No   INT
	, IP_Flag             INT
	, ED_Flag             INT
)

INSERT INTO @COPD_Tbl
SELECT A.*
FROM (
	SELECT A.*
	FROM #INIT_POP_FINAL AS A

	UNION

	SELECT A.*
	FROM #NON_COPD_VISITS_FINAL AS A
) A;
---------------------------------------------------------------------------------------------------
-- ADD TOTAL VISIT SEQ NO TO NEW VARIABLE TABLE OVER COPD AND NON-COPD VISITS
DECLARE @COPD_Final_Tbl TABLE (
	ID                    INT
	, Encounter           INT
	, MRN                 INT
	, Adm_Date            DATE
	, Discharge_Date      DATE
	, Adm_Source          VARCHAR(2)
	, Adm_Source_Desc     VARCHAR(30)
	, Dispo               VARCHAR(3)
	, Dispo_Desc          VARCHAR(50)
	, Age                 INT
	, Payer_Cat           VARCHAR(15)
	, MS_DRG              VARCHAR(3)
	, Prin_Dx             VARCHAR(10)
	, Dx_Cd_2             VARCHAR(10)
	, Prin_Proc_Cd        VARCHAR(10)
	, AHRQ_Dx_Cd          VARCHAR(7)
	, AHRQ_Dx_Cd_Desc     VARCHAR(MAX)
	, Diagnosis           VARCHAR(MAX)
	, Visit_Type          VARCHAR(10)
	, Visit_Type_Seq_No   INT
	, IP_Flag             INT
	, ED_Flag             INT
	, Visit_Seq_No        INT
	, MAX_Series_Flag     INT
	, COPD_FLAG           INT
	, NON_COPD_FLAG       INT
)

INSERT INTO @COPD_Final_Tbl
SELECT A.*
FROM (
	SELECT A.*
	, RN = ROW_NUMBER() OVER(PARTITION BY A.MRN ORDER BY A.ADM_DATE)
	, CASE
		WHEN B.Med_Rec_No IS NOT NULL
			THEN '1'
			ELSE '0'
	  END AS MAX_Series_Flag
	, CASE
		WHEN A.Visit_Type = 'COPD'
			THEN '1'
			ELSE '0'
	  END AS COPD_FLAG
	, CASE
		WHEN A.Visit_Type = 'Non COPD'
			THEN '1'
			ELSE '0'
	END AS NON_COPD_FLAG

	FROM @COPD_Tbl AS A
	LEFT JOIN smsdss.c_DSRIP_COPD AS B
	ON A.MRN = B.Med_Rec_No
) A;

SELECT * FROM @COPD_Final_Tbl
---------------------------------------------------------------------------------------------------
-- DROP TABLE STATEMENTS
DROP TABLE #INIT_POP_FINAL;
DROP TABLE #NON_COPD_VISITS_FINAL;
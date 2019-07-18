-- hf
-- Variable declaration and setting -----------------------------------
DECLARE @SD DATETIME;
DECLARE @ED DATETIME;

SET @SD = '2016-01-01';
SET @ED = '2016-05-01';


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
	, Dispo               VARCHAR(3)
	, Age                 INT
	, Dispo_Desc          VARCHAR(50)
	, Payer_Cat           VARCHAR(15)
	, MS_DRG              VARCHAR(3)
	, Prin_Dx             VARCHAR(10)
	, Dx_Cd_2             VARCHAR(10)
	, Prin_Dx_Scheme      VARCHAR(2)
	, Prin_ICD9_Dx        VARCHAR(10)
	, Prin_ICD10_Dx       VARCHAR(10)
	, Prin_Proc_Cd        VARCHAR(10)
	, Prin_ICD9_Proc_Cd   VARCHAR(10)
	, Prin_ICD10_Proc_Cd  VARCHAR(10)
	, AHRQ_Dx_Cd          VARCHAR(7)
	, AHRQ_Dx_Cd_Desc     VARCHAR(MAX)
	, Diagnosis           VARCHAR(MAX)
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
	, A.dsch_disp
	, a.Pt_Age AS [Pt_Age_At_Admit]
	, CASE
		WHEN LEFT(C.src_dsch_disp, 1) IN ('C' , 'D')
			THEN 'Death'
		WHEN C.src_dsch_disp = 'ATW'
			THEN 'Referred to Home Care'
		WHEN C.src_dsch_disp = 'ATL'
			THEN 'Transferred to a Medicare Certified LTCH'
		WHEN C.src_dsch_disp = 'ATT'
			THEN 'Discharged to Hospice'
		ELSE C.dsch_disp_desc
	  END AS [Discharge_Description]
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
	, A.prin_dx_cd_schm
	, A.prin_dx_icd9_cd
	, A.prin_dx_icd10_cd
	, A.proc_cd
	, A.Prin_Icd9_Proc_Cd
	, A.Prin_Icd10_Proc_Cd
	, B.CC_Code
	, B.CC_Desc
	, B.Diagnosis

	-- Where the data comes from --------------------------------------
	FROM SMSDSS.BMH_PLM_PTACCT_V                 AS A
	LEFT OUTER JOIN SMSDSS.c_AHRQ_Dx_CC_Maps     AS B
	ON REPLACE(A.PRIN_DX_CD, '.','') = B.ICDCode
	LEFT OUTER JOIN SMSDSS.dsch_disp_dim_v       AS C
	ON A.dsch_disp = C.src_dsch_disp
		AND C.src_sys_id = '#PMSNTX0'
	LEFT OUTER JOIN SMSMIR.mir_dx_grp            AS D
	ON A.Pt_No = D.pt_id
		AND A.pt_id_start_dtime = D.pt_id_start_dtime
		AND A.unit_seq_no = D.unit_seq_no
		AND D.dx_cd_prio = '02'
		AND LEFT(DX_CD_TYPE, 2) = 'DF'

	-- Filters --------------------------------------------------------
	WHERE 
	-- Only Inpatients
	A.Plm_Pt_Acct_Type = 'I'
	AND A.PtNo_Num < '20000000'
	-- During Discharge time frame CMS uses
	AND A.Dsch_Date >= @SD
	AND A.Dsch_Date < @ED
	-- Patient must have total charges greater than 0 to help identify 
	-- viable admissions
	AND A.tot_chg_amt > '0'
	-- Primary and secondary insurance must be Medicare A or B
	AND A.User_Pyr1_Cat IN ('WWW') -- comment out per Z,'ZZZ')

	-- comment out per Z
	--AND LEFT(A.Pyr2_Co_Plan_Cd, 1) IN ('A','Z')
	-- Exclude those that were discharged AMA, Transfer to another
	-- acute facility or mortality
	AND A.dsch_disp NOT IN ('AMA', 'ATA', 'ATS', 'ATF', 'ATH', 'ATN')
	AND LEFT(A.dsch_disp, 1) NOT IN ('C' , 'D')
	-- Specific ICD-9 codes used in CMS specs for cohort inclusion
	AND A.prin_dx_cd IN (
	'402.01','402.11','402.91','404.01','404.03','404.11','404.13',
	'404.91','404.93','428.0','428.1','428.20','428.21','428.22',
	'428.23','428.30','428.31','428.32','428.33','428.40','428.41',
	'428.42','428.43','428.9',
	-- icd-10 codes
	'I11.9', 'I11.0', 'I11.0', 'I13.0', 'I13.2', 'I13.0', 'I13.2', 
	'I13.0', 'I13.2', 'I50.9', 'I50.1', 'I50.20', 'I50.21', 'I50.22', 
	'I50.23', 'I50.30', 'I50.31', 'I50.32'
	)
	-- Patient must be 65 years of age or older upon admission.
	AND A.Pt_Age >= 65
	-- LOS cannot be longer than 1 year
	AND A.Days_Stay <= 365
) A
--END

/*
=======================================================================
All cause readmission table (30 days interim from index)
=======================================================================
*/
DECLARE @ReadmitTbl TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, MRN               INT
	, Readmit_Encounter INT
	, Initial_Index     INT
	, Initial_Dsch_Date DATE
	, Interim           INT
	, Readmit_Date      DATE
	, Readmit_Source    VARCHAR(50)
)

INSERT INTO @ReadmitTbl
SELECT *

FROM (
	SELECT IP.MRN
	, RA.[READMIT]
	, RA.[INDEX]
	, RA.[INITIAL DISCHARGE]
	, RA.INTERIM
	, RA.[READMIT DATE]
	, RA.[READMIT SOURCE DESC]

	FROM @InitPop                     AS IP
	INNER MERGE JOIN smsdss.vReadmits AS RA
	ON IP.Encounter = RA.[INDEX]
		AND IP.MRN = RA.MRN
		AND RA.[INTERIM] < 31
) B
-- END

/*
=======================================================================
Planned Readmission Algorith Version 3.0 Excluding final CASE STATEMENT 
=======================================================================
*/
DECLARE @PlannedReadmit TABLE (
	PK INT IDENTITY(1, 1)                   PRIMARY KEY
	, Encounter                             INT
	, Readmit                               INT -- should equal Encounter
	, Readmit_Date                          DATE
	, Readmit_Dsch_Date                     DATE
	, AHRQ_Proc_CC_Code                     VARCHAR(10)
	, AHRQ_Dx_CC_Code                       VARCHAR(10)
	, Planned_Procedure                     INT
	, Planned_Diagnosis                     INT
	, Potentially_Planned_Proc              INT
	, Prin_Dx_Acute_or_Complication_of_Care INT
)

INSERT INTO @PlannedReadmit
SELECT C.PtNo_Num
, C.CREADMIT
, C.Adm_Date
, C.Dsch_Date
, C.CC_Code
, C.CC_DX_CODE
, C.[Proc Planned RA (1 = Y, 0 = N)]
, C.[Dx Planned RA (1 = Y, 0 = N)]
, C.[Potentially Planned Proc (1 = Y, 0 = N)]
, C.[Prin Dx is Acute OR Complication of Care (1 = Y, 0 = N)]

FROM (
	SELECT A.PtNo_Num
	, B.READMIT AS CREADMIT
	, A.Adm_Date
	, A.Dsch_Date
	, C.CC_Code
	, D.CC_Code AS CC_DX_CODE
	, A.Prin_Icd9_Proc_Cd
	-- TABLE PR.1
	, CASE
		WHEN C.CC_Code IN (
		'PX_64', 'PX_105','PX_134','PX_135','PX_176'
		)
			THEN 1
		ELSE 0
	  END AS [Proc Planned RA (1 = Y, 0 = N)]
	-- TABLE PR.2
	, CASE
		WHEN D.CC_Code IN (
		'DX_45','DX_194','DX_196','DX_254'
		)
			THEN 1
		ELSE 0
	  END AS [Dx Planned RA (1 = Y, 0 = N)]
	-- Table PR.3
	, CASE
		WHEN C.CC_Code IN (
		'PX_3',	'PX_104', 'PX_5',	'PX_106',
		'PX_9',	'PX_107', 'PX_10',	'PX_109',
		'PX_12', 'PX_112', 'PX_33',	'PX_113',
		'PX_36', 'PX_114', 'PX_38', 'PX_119',
		'PX_40', 'PX_120', 'PX_43', 'PX_124',
		'PX_44', 'PX_129', 'PX_45', 'PX_132',
		'PX_47', 'PX_142', 'PX_48', 'PX_152',
		'PX_49', 'PX_153', 'PX_51', 'PX_154',
		'PX_52', 'PX_157', 'PX_53', 'PX_158',
		'PX_55', 'PX_159', 'PX_56', 'PX_166',
		'PX_59', 'PX_167', 'PX_62', 'PX_169',
		'PX_66', 'PX_170', 'PX_77', 'PX_172',
		'PX_74', 'PX_78', 'PX_79', 'PX_84',	
		'PX_85', 'PX_86', 'PX_99'
		)
			THEN 1
		ELSE 0
	  END AS [Potentially Planned Proc (1 = Y, 0 = N)]
	-- Table PR.4
	--, CASE
	--	WHEN A.Prin_Icd9_Proc_Cd IN (
	--	'30.1','30.29','30.3','30.4','31.74','34.6',
	--	'38.18','55.03','55.04','94.26','94.27'
	--	)
	--		THEN 1
	--	ELSE 0
	--  END AS [Prin Dx is Acute OR Complication of Care (1 = Y, 0 = N)]
	, CASE
		WHEN A.Prin_Icd10_Proc_Cd IN (
		'0CBS0ZZ', '0CBS3ZZ', '0CBS4ZZ', '0CBS7ZZ', '0CBS8ZZ', '0CTS0ZZ',
		'0CTS4ZZ', '0CTS8ZZ', '0CTS8ZZ', '0CTS8ZZ', '0CTS8ZZ', '0CTS8ZZ', 
		'0CTS8ZZ', '0CTS8ZZ', '0CTS7ZZ', '0BW10FZ', '0BW13FZ', '0BW14FZ', 
		'0WB6XZ2', '0WQ6XZ2', '0B5N0ZZ', '0B5N3ZZ', '0B5N4ZZ', '0B5P0ZZ', 
		'0B5P3ZZ', '0B5P4ZZ', '04CK0ZZ', '04CK3ZZ', '04CK4ZZ', '04CL0ZZ', 
		'04CL3ZZ', '04CL4ZZ', '04CM0ZZ', '04CM3ZZ', '04CM4ZZ', '04CN0ZZ', 
		'04CN3ZZ', '04CN4ZZ', '04CP0ZZ', '04CP3ZZ', '04CP4ZZ', '04CQ0ZZ', 
		'04CQ3ZZ', '04CQ4ZZ', '04CR0ZZ', '04CR3ZZ', '04CR4ZZ', '04CS0ZZ', 
		'04CS3ZZ', '04CS4ZZ', '04CT0ZZ', '04CT3ZZ', '04CT4ZZ', '04CU0ZZ', 
		'04CU3ZZ', '04CU4ZZ', '04CV0ZZ', '04CV3ZZ', '04CV4ZZ', '04CW0ZZ', 
		'04CW3ZZ', '04CW4ZZ', '04CY0ZZ', '04CY3ZZ', '04CY4ZZ', '0T9030Z', 
		'0T9040Z', '0T9130Z', '0T9140Z', '0TC03ZZ', '0TC04ZZ', '0TC13ZZ', 
		'0TC14ZZ', '0TF33ZZ', '0TF34ZZ', '0TF43ZZ', '0TF44ZZ', 'GZB4ZZZ', 
		'GZB0ZZZ', 'GZB1ZZZ', 'GZB2ZZZ', 'GZB3ZZZ', 'GZB4ZZZ'
		)
			THEN 1
		ELSE 0
	  END AS [Prin Dx is Acute OR Complication of Care (1 = Y, 0 = N)]


	FROM SMSDSS.BMH_PLM_PTACCT_V             AS A
	-- CHANGED FROM LEFT OUTER TO INNER
	INNER MERGE JOIN SMSDSS.vReadmits        AS B
	ON A.PtNo_Num = B.[READMIT]
	LEFT OUTER JOIN SMSDSS.c_AHRQ_Px_CC_Maps AS C
	ON REPLACE(A.Prin_Icd10_Proc_Cd,'.','') = C.ICDCode
		--AND C.ICD_Ver_Flag = '09'
		AND C.ICD_Ver_Flag = '10'
	LEFT OUTER JOIN SMSDSS.c_AHRQ_Dx_CC_Maps AS D
	ON REPLACE(A.prin_dx_icd10_cd, '.','') = D.ICDCode
		--AND D.ICD_Ver_Flag = '09'
		AND D.ICD_Ver_Flag = '10'

	WHERE A.Dsch_Date >= @SD
	AND A.Dsch_Date < GETDATE()
	AND A.Plm_Pt_Acct_Type = 'I'
	AND A.PtNo_Num < '20000000'
) C
-- END

/*
=======================================================================
Put it all together
=======================================================================
*/
SELECT 
IP.Encounter             AS [Index Encounter]
, RA.[Readmit_Encounter] AS [Readmit Encounter]
, CASE
	WHEN RA.Readmit_Encounter IS NOT NULL
		THEN 'NO'
	ELSE 'YES'
  END                    AS [Index Stay]
, CASE
	WHEN RA.Readmit_Encounter IS NOT NULL
		THEN RA.INTERIM
	ELSE NULL
  END                    AS [Interim]
, IP.MRN
, IP.Adm_Date
, IP.Discharge_Date
, RA.Initial_Dsch_Date
, IP.Adm_Source
, IP.DISPO
, IP.Dispo_Desc
, IP.Payer_Cat
, IP.MS_DRG
, IP.Prin_Dx
, IP.Dx_Cd_2
, IP.Prin_Dx_Scheme
, IP.Prin_ICD9_Dx
, IP.Prin_ICD10_Dx
, IP.Prin_Proc_Cd
, IP.Prin_ICD9_Proc_Cd
, IP.Prin_ICD10_Proc_Cd
, IP.AHRQ_Dx_Cd
, IP.AHRQ_Dx_Cd_Desc
, IP.Diagnosis
, PL.*
, CASE
	WHEN PL.Planned_Diagnosis = 1
      OR PL.Planned_Procedure = 1
	  THEN 1
	WHEN PL.Potentially_Planned_Proc = 1
	  AND PL.Prin_Dx_Acute_or_Complication_of_Care = 0
	  THEN 1
    ELSE 0
  END                    AS [(Un)Planned]
  
FROM @InitPop                          AS IP
LEFT OUTER MERGE JOIN @ReadmitTbl      AS RA
-- CHANGED TO INITIAL_INDEX INSTEAD OF READMIT
ON IP.Encounter = RA.Initial_Index
LEFT OUTER MERGE JOIN @PlannedReadmit  AS PL
ON RA.Readmit_Encounter = PL.Encounter

ORDER BY IP.MRN
, IP.Encounter
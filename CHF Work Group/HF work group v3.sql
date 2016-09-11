-- variables
DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2015-04-01';
SET @END   = '2016-04-01';

DECLARE @INIT_POP TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [MRN]               VARCHAR(8)
	, [Encounter]         INT
	, [Admit Date]        DATE
	, [Discharge Date]    DATE
	, [Encounter Type]    VARCHAR(30)
	, [Prin Dx Code]      VARCHAR(10)
	, [Prin Dx Desc]      VARCHAR(MAX)
	, [Insurance Type]    VARCHAR(15)
	, [Primary Ins]       CHAR(3)
	, [Secondary Ins]     CHAR(3)
);

WITH CTE1 AS (
	SELECT A.Med_Rec_No
	, A.PtNo_Num
	, A.Adm_Date
	, A.Dsch_Date
	, CASE
		WHEN A.Pt_No >= '000080000000'
		AND A.Pt_No < '000090000000'
			THEN 'ER'
		WHEN A.Pt_No < '000020000000'
		AND A.Adm_Source NOT IN ('RA', 'RP')
			THEN 'Inpatient Admit From ER'
		WHEN A.Pt_No < '000020000000'
		AND A.Adm_Source IN ('RA', 'RP')
			THEN 'Direct Admit'
		ELSE A.Adm_Source
	  END AS [Encounter Type]
	, A.prin_dx_cd
	, B.clasf_desc
	, CASE
		WHEN A.User_Pyr1_Cat IN ('AAA')
			THEN 'FFS Medicare'
		ELSE 'Other'
	  END AS [Ins Type]
	, Pyr1_Co_Plan_Cd
	, Pyr2_Co_Plan_Cd

	FROM smsdss.BMH_PLM_PtAcct_V AS A
	LEFT OUTER JOIN smsmir.mir_clasf_mstr AS B
	ON A.prin_dx_cd = B.clasf_cd
	AND A.prin_dx_cd_schm = B.clasf_schm

	-- WE WANT PATIENTS WITH AT LEAST ONE PRINCIPAL DX OF CHF
	WHERE A.prin_dx_cd IN (
	-- icd-9 codes
	'402.01','402.11','402.91','404.01','404.03','404.11','404.13',
	'404.91','404.93','428.0','428.1','428.20','428.21','428.22',
	'428.23','428.30','428.31','428.32','428.33','428.40','428.41',
	'428.42','428.43','428.9',
	-- icd-10 codes
	'I11.9', 'I11.0', 'I11.0', 'I13.0', 'I13.2', 'I13.0', 'I13.2', 
	'I13.0', 'I13.2', 'I50.9', 'I50.1', 'I50.20', 'I50.21', 'I50.22', 
	'I50.23', 'I50.30', 'I50.31', 'I50.32'
	)
	
	-- MAKE SURE WE GET BOTH ER AND IP ACCOUNTS
	AND (
		A.Pt_No BETWEEN '000010000000' AND '000019999999' -- INPATIENT
		OR 
		A.Pt_No BETWEEN '000080000000' AND '000099999999' -- ED
	)
	
	-- TIME RANGE FOR SELECTION
	AND A.Dsch_Date >= @START
	AND A.Dsch_Date < @END
	
	-- ENSURE THERE ARE POSITIVE TOTAL CHARGES ON THE ACCOUNT
	AND A.tot_chg_amt > 0
	
	-- GET RID OF PRE-REG
	AND LEFT(A.PtNo_Num, 4) != '1999'
	
	-- MAKE SURE THE PT IS NOT IN THE MAX COPD COHORT
	AND A.Med_Rec_No NOT IN (
		SELECT Med_Rec_No
		FROM smsdss.c_DSRIP_COPD
	)
	
	---- NO PERSONS ALREADY IN COHORT
	--AND a.Med_Rec_No NOT IN (
	--	SELECT Med_Rec_No
	--	FROM smsdss.c_HF_Cohort
	--)
	
	-- DISCHARGE STATUS CANNOT BE MORTALITY
	AND LEFT(A.dsch_disp, 1) NOT IN ('C', 'D')
	
	-- No discharges in this list
	AND A.dsch_disp NOT IN ('AMA', 'ATA', 'ATS', 'ATF', 'ATH', 'ATN')
	
	-- Patient must be 65 years of age or older upon admission.
	AND A.Pt_Age >= 65
	
	-- LOS cannot be longer than 1 year
	AND A.Days_Stay <= 365
)
INSERT INTO @INIT_POP
SELECT * FROM CTE1;

--SELECT A.* FROM @INIT_POP AS A
---------------------------------------------------------------------------------------------------
-- GET CHF IP AND ED VISIT COUNTS
DECLARE @CHF_IP TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [MRN]               VARCHAR(10)
	, [CHF_IP_Count]      INT
);

WITH CTE2 AS (
	SELECT MRN
	, COUNT(Encounter) AS IP_COUNT

	FROM @INIT_POP

	WHERE LEFT(Encounter, 1) = '1'

	GROUP BY MRN
)
INSERT @CHF_IP
SELECT * FROM CTE2;

--SELECT * FROM @CHF_IP
------------------------------
-- GET ED VISIT COUNT
DECLARE @CHF_ED TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [MRN]                       VARCHAR(10)
	, [CHF_ED_TreatRelease_Count] INT
);

WITH CTE3 AS (
	SELECT MRN
	, COUNT(Encounter) AS ED_COUNT

	FROM @INIT_POP

	WHERE LEFT(Encounter, 1) = '8'

	GROUP BY MRN
)
INSERT @CHF_ED
SELECT * FROM CTE3;

--SELECT * FROM @CHF_ED
---------------------------------------------------------------------------------------------------
-- GET NON CHF RELATED IP AND ED VISITS WHERE MRN IS IN INIT_POP TABLE
DECLARE @NON_CHF_IP TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [MRN]                     VARCHAR(10)
	, [Non CHF IP Visit Count]  INT
);

WITH CTE4 AS (
	SELECT Med_Rec_No
	, COUNT(PtNo_Num) AS NON_CHF_IP_COUNT 

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE prin_dx_cd NOT IN (
		-- icd-9 codes
		'402.01','402.11','402.91','404.01','404.03','404.11','404.13',
		'404.91','404.93','428.0','428.1','428.20','428.21','428.22',
		'428.23','428.30','428.31','428.32','428.33','428.40','428.41',
		'428.42','428.43','428.9',
		-- icd-10 codes
		'I11.9', 'I11.0', 'I11.0', 'I13.0', 'I13.2', 'I13.0', 'I13.2', 
		'I13.0', 'I13.2', 'I50.9', 'I50.1', 'I50.20', 'I50.21', 'I50.22', 
		'I50.23', 'I50.30', 'I50.31', 'I50.32'
	)
	-- MAKE SURE WE GET BOTH ER AND IP ACCOUNTS
	AND Plm_Pt_Acct_Type = 'I'
	AND PtNo_Num < '20000000'
	-- TIME RANGE FOR SELECTION
	AND Dsch_Date >= @START
	AND Dsch_Date < @END
	-- ENSURE THERE ARE POSITIVE TOTAL CHARGES ON THE ACCOUNT
	AND tot_chg_amt > 0
	-- GET RID OF PRE-REG
	AND LEFT(PtNo_Num, 4) != '1999'
	-- MAKE SURE MRN IS IN INIT_POP
	AND Med_Rec_No IN (
		SELECT DISTINCT(MRN)
		FROM @INIT_POP
	)
	
	GROUP BY Med_Rec_No
)
INSERT INTO @NON_CHF_IP
SELECT * FROM CTE4;

--SELECT * FROM @NON_CHF_IP
---------------------------------------------------------------------------------------------------
DECLARE @NON_CHF_ED TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [MRN]                    VARCHAR(10)
	, [Non CHF ED Visit Count] INT
);

WITH CTE5 AS (
	SELECT Med_Rec_No
	, COUNT(PtNo_Num) AS NON_CHF_ED_VISIT_COUNT

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE Med_Rec_No IN (
		SELECT DISTINCT(MRN)
		FROM @INIT_POP
	)
	AND LEFT(PtNo_Num, 1) = '8'
	AND prin_dx_cd NOT IN (
		-- icd-9 codes
		'402.01','402.11','402.91','404.01','404.03','404.11','404.13',
		'404.91','404.93','428.0','428.1','428.20','428.21','428.22',
		'428.23','428.30','428.31','428.32','428.33','428.40','428.41',
		'428.42','428.43','428.9',
		-- icd-10 codes
		'I11.9', 'I11.0', 'I11.0', 'I13.0', 'I13.2', 'I13.0', 'I13.2', 
		'I13.0', 'I13.2', 'I50.9', 'I50.1', 'I50.20', 'I50.21', 'I50.22', 
		'I50.23', 'I50.30', 'I50.31', 'I50.32'
	)
	-- TIME RANGE FOR SELECTION
	AND Dsch_Date >= @START
	AND Dsch_Date < @END
	-- ENSURE THE PATIENT HAS SOME ER ACTIVITY
	AND Pt_No IN (
		SELECT DISTINCT(pt_id)
		FROM smsmir.mir_actv
		WHERE LEFT(actv_cd, 3) = '046'
		AND chg_tot_amt > 0
	)
	-- ENSURE THERE ARE POSITIVE TOTAL CHARGES ON THE ACCOUNT
	AND tot_chg_amt > 0
	GROUP BY Med_Rec_No
)
INSERT INTO @NON_CHF_ED
SELECT * FROM CTE5;

-----------------------------------------------------------------------
-- PULL IT ALL TOGETHER
SELECT A.MRN
, A.Encounter
, A.[Admit Date]
, A.[Discharge Date]
, A.[Encounter Type]
, A.[Prin Dx Code]
, A.[Prin Dx Desc]
, ISNULL(B.CHF_IP_Count, 0)              AS [CHF IP Visit Count]
, ISNULL(C.CHF_ED_TreatRelease_Count, 0) AS [CHF ED Treat/Release Visit Count]
, ISNULL(D.[Non CHF IP Visit Count], 0)  AS [Non CHF IP Visit Count]
, ISNULL(E.[Non CHF ED Visit Count], 0)  AS [Non CHF ED Visit Count]
, A.[Insurance Type]
, A.[Primary Ins]
, G.ins_co_name AS INS_A
, A.[Secondary Ins]
, H.ins_co_name AS INS_B
, F.READMIT

INTO #ACTIVITY_TBL

FROM @INIT_POP              AS A
LEFT OUTER JOIN @CHF_IP     AS B
ON A.MRN = B.MRN
LEFT OUTER JOIN @CHF_ED     AS C
ON A.MRN = C.MRN
LEFT OUTER JOIN @NON_CHF_IP AS D
ON A.MRN = D.MRN
LEFT OUTER JOIN @NON_CHF_ED AS E
ON A.MRN = E.MRN
LEFT OUTER MERGE JOIN smsdss.vReadmits AS F
ON A.Encounter = F.[INDEX]
	AND F.[INTERIM] < 31
	AND F.[READMIT SOURCE DESC] <> 'SCHEDULED ADMISSION'
INNER JOIN smsmir.mir_pyr_mstr AS G
ON A.[Primary Ins] = G.pyr_cd
INNER JOIN smsmir.mir_pyr_mstr AS H
ON A.[Secondary Ins] = H.pyr_cd

WHERE A.MRN NOT IN (
	SELECT A.MRN
	FROM @INIT_POP
	INNER JOIN smsdss.BMH_PLM_PtAcct_V ZZZ
	ON A.MRN = ZZZ.Med_Rec_No
	WHERE LEFT(ZZZ.dsch_disp, 1) IN ('C','D')
)

ORDER BY A.MRN, A.[Admit Date]
---------------------------------------------------------------------------------------------------
-- DATA GOES INTO "Initial Patient Population v2 - NO DIALYSIS" excel file
SELECT A.*
INTO #ACTIVITY_TBL_2
FROM #ACTIVITY_TBL AS A
--WHERE A.MRN NOT IN (
--	SELECT AA.MRN
--	FROM #ACTIVITY_TBL AS AA
--	INNER JOIN smsdss.BMH_PLM_PtAcct_V AS BB
--	ON AA.MRN = BB.Med_Rec_No
--	WHERE BB.hosp_svc IN ('DIA', 'DMS')
--)

SELECT A.*
FROM #ACTIVITY_TBL_2 AS A
---------------------------------------------------------------------------------------------------
-- DATA GOES INTO "HF FFS Cohort Activity - NO DIALYSIS" excel file
SELECT a.Med_Rec_No          AS mrn
, a.PtNo_Num                 AS encounter
, a.Adm_Date                 AS admit_date
, a.Dsch_Date                AS discharge_date
, a.Days_Stay                AS los
, a.dsch_disp                AS disposition_cd
, x.dsch_disp                AS disposition_desc
, DATEPART(YEAR, Dsch_Date)  AS dsch_year
, DATEPART(month, dsch_date) AS dsch_month

INTO #temp

FROM smsdss.bmh_plm_ptacct_V AS a

CROSS APPLY (
	SELECT
		CASE 
			WHEN a.dsch_disp = 'AHB' THEN 'Drug/Alcohol Rehab Non-Hospital Facility' 
			WHEN a.dsch_disp = 'ATF' THEN 'Transferred to cancer center or childrens hospital'
			WHEN a.dsch_disp = ' TF' THEN 'Transferred to cancer center of childrens hospital'
			WHEN a.dsch_disp = 'AHI' THEN 'Hospice at Hospice Facility, SNF or Inpatient Facility'
			WHEN a.dsch_disp = 'AHR' THEN 'Home, Home with Public Health Nurse, Adult Home, Assisted Living'
			WHEN A.dsch_disp = ' HR' THEN 'Home, Home with Public Health Nurse, Adult Home, Assisted Living'
			WHEN a.dsch_disp = 'AMA' THEN 'Left Against Medical Advice, Elopement'
			WHEN A.dsch_disp = ' MA' THEN 'Left Against Medical Advice, Elopement'
			WHEN a.dsch_disp = 'ATB' THEN 'Correctional Institution'
			WHEN a.dsch_disp = 'ATE' THEN 'SNF -Sub Acute'
			WHEN A.dsch_disp = ' TE' THEN 'SNF -Sub Acute'
			WHEN a.dsch_disp = 'ATH' THEN 'Hospital - Med/Surg (i.e Stony Brook)'
			WHEN A.dsch_disp = ' TH' THEN 'Hospital - Med/Surg (i.e Stony Brook)'
			WHEN a.dsch_disp = 'ATL' THEN 'SNF - Long Term'
			WHEN a.dsch_disp = 'ATN' THEN 'Hospital - VA'
			WHEN a.dsch_disp = 'ATP' THEN 'Hospital - Psych or Drug/Alcohol (i.e BMH 1EAST, South Oaks)'
			WHEN A.dsch_disp = ' TP' THEN 'Hospital - Psych or Drug/Alcohol (i.e BMH 1EAST, South Oaks)'
			WHEN a.dsch_disp = 'ATT' THEN 'Hospice at Home, Adult Home, Assisted Living'
			WHEN A.dsch_disp = ' TT' THEN 'Hospice at Home, Adult Home, Assisted Living'
			WHEN a.dsch_disp = 'ATW' THEN 'Home, Adult Home, Assisted Living with Homecare'
			WHEN A.dsch_disp = ' TW' THEN 'Home, Adult Home, Assisted Living with Homecare'
			WHEN left(a.dsch_disp, 1) in ('c', 'd') THEN 'Mortality'
			ELSE a.dsch_disp
	END AS dsch_disp
) x

WHERE a.Med_Rec_No IN (
	SELECT AAA.MRN
	FROM #ACTIVITY_TBL_2 AS AAA
	WHERE AAA.[Insurance Type] = 'FFS Medicare'
)
AND a.Dsch_Date >= '2015-04-01'
AND a.Dsch_Date < '2016-08-01'
AND LEFT(a.ptno_num, 1) IN ('1','8')

OPTION(FORCE ORDER)

-----
SELECT A.*

FROM #temp AS A

WHERE a.mrn NOT IN (
	SELECT xxx.mrn
	FROM #temp AS xxx
	LEFT JOIN smsdss.bmh_plm_ptacct_v AS zzz
	ON xxx.mrn = zzz.Med_Rec_No
	WHERE LEFT(xxx.disposition_cd, 1) IN ('c', 'd')
)
--AND a.mrn NOT IN (
--	SELECT aaa.mrn
--	FROM #TEMP AS AAA
--	LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS BBB
--	ON aaa.mrn = bbb.Med_Rec_No
--	WHERE bbb.hosp_svc IN ('dia', 'dms')
--)

DROP TABLE #TEMP
DROP TABLE #ACTIVITY_TBL
DROP TABLE #ACTIVITY_TBL_2
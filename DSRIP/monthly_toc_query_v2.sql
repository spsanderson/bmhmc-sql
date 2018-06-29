/*
Monthly DSRIP TOC query

v1	- 2018-06-28	- Initial Creation

Section 1
Total number of unique medicaid patients admitted
	1. Medicaid patients that include FFS and Managed
	2. Patients can have Mediciad Primary OR Secondary (ie dual eligible)

Section 2
Total number of unique medicaid readmitted within 30 days
	1. Medicaid Patients that include FFS and Managed
	2. Patients can have Medicaid Primary OR Secondary
	3. Current admission is a 30 day readmission

Section 3
Total number of unique medicaid patients flagged for TOC Services
	1. Medicaid Patients that include FFS and Managed
	2. Patients can have Medicaid Primary OR Secondary
	3. Patient has 3 or More ED Visits in last 12 months AND 1 or more IP Readmissions in last 12 months
*/

DECLARE @START DATETIME;
DECLARE @END   DATETIME;
DECLARE @TODAY DATETIME;

SET @TODAY = GETDATE();
SET @START = dateadd(mm, datediff(mm, 0, @TODAY) - 1, 0);
SET @END   = dateadd(mm, datediff(mm, 0, @TODAY), 0);
----------
-- Section 1
SELECT A.Med_Rec_No
, A.Pt_Name

FROM smsdss.BMH_PLM_PtAcct_V AS A

WHERE A.ADM_DATE >= @START
AND A.Adm_Date < @END
AND (
	-- This gets patients with primary insurance of FFS Caid or Managed Caid
	A.User_Pyr1_Cat IN ('WWW','III')
	OR
	LEFT(A.Pyr2_Co_Plan_Cd, 1) IN ('W','I')
)
AND A.tot_chg_amt > 0
AND LEFT(A.PTNO_NUM, 1) != '2'
AND LEFT(A.PtNo_Num, 4) != '1999'
AND A.Plm_Pt_Acct_Type = 'I'
;

-- Section 2
SELECT A.Med_Rec_No
, A.Pt_Name

FROM smsdss.BMH_PLM_PtAcct_V AS A
INNER JOIN smsdss.vReadmits AS B
ON A.PtNo_Num = B.[READMIT]
	AND B.[INTERIM] < 31

WHERE A.ADM_DATE >= @START
AND A.Adm_Date < @END
AND (
	-- This gets patients with primary insurance of FFS Caid or Managed Caid
	A.User_Pyr1_Cat IN ('WWW','III')
	OR
	LEFT(A.Pyr2_Co_Plan_Cd, 1) IN ('W','I')
)
AND A.tot_chg_amt > 0
AND LEFT(A.PTNO_NUM, 1) != '2'
AND LEFT(A.PtNo_Num, 4) != '1999'
AND A.Plm_Pt_Acct_Type = 'I'
;

-- Section 3
-- GET BASE POPULATION
SELECT A.Med_Rec_No
, A.Pt_Name

INTO #TEMPA -- BASE POPULATION

FROM smsdss.BMH_PLM_PtAcct_V AS A

WHERE A.ADM_DATE >= @START
AND A.Adm_Date < @END
AND (
	-- This gets patients with primary insurance of FFS Caid or Managed Caid
	A.User_Pyr1_Cat IN ('WWW','III')
	OR
	LEFT(A.Pyr2_Co_Plan_Cd, 1) IN ('W','I')
)
AND A.tot_chg_amt > 0
AND LEFT(A.PTNO_NUM, 1) != '2'
AND LEFT(A.PtNo_Num, 4) != '1999'
AND A.Plm_Pt_Acct_Type = 'I'

GROUP BY A.Med_Rec_No, A.Pt_Name
;

-- GET ED COUNTS
SELECT A.Med_Rec_No
, COUNT(DISTINCT(A.PtNo_Num)) AS [ED_COUNT]

INTO #EDCOUNTS

FROM smsdss.BMH_PLM_PtAcct_V AS A

WHERE LEFT(A.PtNo_Num, 1) = '8'
AND A.Med_Rec_No IN (
	SELECT ZZZ.MED_REC_NO
	FROM #TEMPA AS ZZZ
)
AND A.Adm_Date >= DATEADD(MM, DATEDIFF(MM, 0, @START) - 12, 0)
AND A.Adm_Date < DATEADD(MM, DATEDIFF(MM, 0, @END) -1 , 0)

GROUP BY A.Med_Rec_No
;

-- GET IP READMIT COUNTS
SELECT B.MRN
, COUNT(DISTINCT(B.[READMIT])) AS [RA_COUNT]

INTO #RACOUNTS

FROM smsdss.vReadmits AS B

WHERE B.[INTERIM] < 31
AND B.[READMIT SOURCE DESC] != 'Scheduled Admission'
AND B.MRN IN (
	SELECT ZZZ.MED_REC_NO
	FROM #TEMPA AS ZZZ
)
AND B.[READMIT DATE] >= DATEADD(MM, DATEDIFF(MM, 0, @START) - 12, 0)
AND B.[READMIT DATE] < DATEADD(MM, DATEDIFF(MM, 0, @END) -1 , 0)

GROUP BY B.MRN
;

SELECT A.Med_Rec_No
, A.Pt_Name
, ISNULL(B.ED_COUNT, 0) AS [ED_COUNT]
, ISNULL(C.RA_COUNT, 0) AS [RA_COUNT]

FROM #TEMPA AS A
LEFT OUTER JOIN #EDCOUNTS AS B
ON A.Med_Rec_No = B.Med_Rec_No
LEFT OUTER JOIN #RACOUNTS AS C
ON A.Med_Rec_No = C.MRN

WHERE ISNULL(B.ED_COUNT, 0) >= 3
AND ISNULL(C.RA_COUNT, 0) > 0

----- DROP TABLES
DROP TABLE #TEMPA, #EDCOUNTS, #RACOUNTS
;
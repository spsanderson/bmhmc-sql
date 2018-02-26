/*
Description:

The percentage of paitents discharged from the ED by provider that are
subsequently admitted to the hospital within 72 hours of ED discharge.

Example:
MRN 123456 ED Encounter 87654321 Discharge 01/01/2018
MRN 123456 IP Encounter 12345678 Admit     01/03/2018

The ED Encounter of 87654321 would qualify, and if this is the only 
patient seen, then the rate would be 100%

Criteria:
	1. Mortalities are excluded
	2. Must have positive total charges greater than $0.00
	3. Initial visit must be ED only

Data Source: Wellsoft and DSS, with Wellsoft being the Primary Data Source

Author: Steven P Sanderson II, MPH

v1 - 2018-02-13 - Initial query creation
*/

DECLARE @START DATETIME;
DECLARE @END   DATETIME;

SET @START = '2017-01-01';
SET @END   = '2017-12-31';

----------
WITH CTE AS (
	SELECT A.Med_Rec_No
	, A.PtNo_Num
	, A.Atn_Dr_No
	, B.pract_rpt_name
	, D.EDMDID
	, D.ED_MD
	, A.dsch_disp
	, CASE 
		WHEN LEFT(A.dsch_disp, 1) IN ('C', 'D')
			THEN 'Mortality'
		WHEN RTRIM(LTRIM(A.DSCH_DISP)) = 'TW'
			THEN 'Homecare'
		ELSE C.dsch_disp_desc
	  END AS [Dispo_Desc]
	, CAST(A.Adm_Date AS date) AS [Adm_Date]
	, CAST(A.Dsch_Date AS date) AS [Dsch_Date]
	, CAST(A.Days_Stay AS int) AS [LOS]
	, A.vst_start_dtime
	, A.vst_end_dtime
	, [RN] = ROW_NUMBER() OVER(
		PARTITION BY A.MED_REC_NO
		ORDER BY A.ADM_DATE
		)

	FROM smsdss.BMH_PLM_PtAcct_V AS A
	LEFT OUTER JOIN smsdss.pract_dim_v AS B
	ON A.Atn_Dr_No = B.src_pract_no
		AND A.Regn_Hosp = B.orgz_cd
	LEFT OUTER JOIN smsdss.dsch_disp_dim_v AS C
	ON RTRIM(LTRIM(A.dsch_disp)) = RTRIM(LTRIM(C.DSCH_DISP))
		AND A.Regn_Hosp = C.orgz_cd
	INNER JOIN smsdss.c_Wellsoft_Rpt_tbl AS D
	ON A.PtNo_Num = D.Account

	WHERE LEFT(A.PTNO_NUM, 1) IN('1', '8')
	AND A.Dsch_Date BETWEEN @START AND @END
	AND A.tot_chg_amt > 0
	AND LEFT(A.PTNO_nUM, 1) != '2'
	AND LEFT(A.PTNO_NUM, 4) != '1999'
	AND LEFT(A.DSCH_DISP, 1) NOT IN ('C', 'D')
)

SELECT C1.Med_Rec_No
, C1.PtNo_Num AS [Initial_Visit]
, C1.EDMDID AS [Init_MDID]
, C1.ED_MD AS [Init_MD]
, C1.dsch_disp AS [Init_Disp_CD]
, C1.Dispo_Desc AS [Init_Disp_Desc]
, C1.Adm_Date AS [Init_Admit_Date]
, C1.Dsch_Date AS [Initi_Dsch_Date]
, C1.LOS AS [Init_LOS]
, C1.RN AS [Event_Num]
, C2.PtNo_Num AS [Secondary_Visit]
, C2.Adm_Date AS [Secondary_Admit_Date]
, DATEDIFF(HOUR, C1.vst_end_dtime, C2.vst_start_dtime) AS [Interim_Hours]
, C2.Adm_Date AS [Second_Admit]
, C2.Dsch_Date AS [Second_Dsch]
, C2.RN AS [Secondary_Event]
, 1 AS [Visit_Flag]
, CASE
	WHEN C2.Med_Rec_No IS NOT NULL
		THEN 1
		ELSE 0
  END AS [Sec_Visit_Flag]
, CASE
	WHEN RTRIM(LTRIM(C1.dsch_disp)) IN ('MA', 'AMA')
		THEN 1
		ELSE 0
  END AS [AMA_Flag]

INTO #TEMP_A

FROM CTE AS C1
LEFT OUTER JOIN CTE AS C2
ON C1.Med_Rec_No = C2.Med_Rec_No
	AND C1.Adm_Date <> C2.Adm_Date
	AND C1.RN + 1 = C2.RN
	AND LEFT(C1.PTNO_NUM, 1) = '8'
	AND LEFT(C2.PTNO_NUM, 1) = '1'
	AND DATEDIFF(HOUR, C1.vst_end_dtime, C2.vst_start_dtime) <= 72

WHERE LEFT(C1.PTNO_NUM, 1) = '8'
-- Uncomment below to see only those records that meet the left join criteria
--WHERE C1.Adm_Date <> C2.Adm_Date
--AND C1.RN + 1 = C2.RN
--AND LEFT(C1.PTNO_NUM, 1) = '8'
--AND LEFT(C2.PTNO_NUM, 1) = '1'
--AND DATEDIFF(HOUR, C1.vst_end_dtime, C2.vst_start_dtime) <= 72

ORDER BY C1.Med_Rec_No
, C1.Adm_Date

OPTION (FORCE ORDER)

GO
;

SELECT *
FROM #TEMP_A
ORDER BY Med_Rec_No
, Init_Admit_Date
GO
;

--DROP TABLE #TEMP_A
--GO
--;
/*
***********************************************************************
File: daily_sepsis_list.sql

Input Parameters:
	None

Tables/Views:
	[SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
    SMSDSS.C_SOARIAN_REAL_TIME_CENSUS_CDI_V
	SMSMIR.VST_RPT
	SMSDSS.C_PATIENT_DEMOS_V
	smsdss.c_archway_sepsis_tbl

Creates Table:
	smsdss.c_archway_sepsis_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get a daily list of potential stroke patients

Revision History:
Date		Version		Description
----		----		----
2020-03-05	v1			Initial Creation
2020-03-12	v2			Insert new records into smsdss.c_archway_sepsis_tbl
2020-03-13	v3			Check for MRN_IN_TBL
						Check if visit is a readmit at interim >= 91
2020-03-19	v4			Use real time census to get policy number
***********************************************************************
*/

SELECT *
INTO #TEMPA
FROM (
	SELECT A.Med_Rec_No
	, A.PtNo_Num
	, CAST(A.ADM_DATE AS date) AS [Adm_Date]
	, A.Pt_Name
	, B.ins1_pol_no
	, CAST(A.Pt_Birthdate AS DATE) AS [Pt_Birthdate]
	, A.Pt_Sex
	, C.Pt_Addr_City
	, C.Pt_Addr_State
	, C.Pt_Phone_No

	FROM SMSDSS.BMH_PLM_PTACCT_V AS A
	LEFT OUTER JOIN smsmir.vst_rpt AS B
	ON A.PT_NO = B.pt_id
	AND A.unit_seq_no = B.unit_seq_no
	AND A.from_file_ind = B.from_file_ind
	LEFT OUTER JOIN SMSDSS.c_patient_demos_v AS C
	ON A.PT_NO = C.pt_id
	AND A.from_file_ind = C.from_file_ind

	WHERE A.drg_no IN ('870','871','872')
	AND A.User_Pyr1_Cat IN ('AAA','ZZZ')
	AND A.Dsch_Date >= '2020-01-01'
	AND A.tot_chg_amt > 0
	AND LEFT(A.PTNO_NUM, 1) != '2'
	AND LEFT(A.PTNO_NUM, 4) != '1999'

	UNION

	SELECT A.pt_med_rec_no
	, A.pt_no_num
	, CAST(A.adm_dtime AS date) AS [Adm_Date]
	, CAST(A.PT_LAST_NAME AS varchar) +
	  ', ' +
	  CAST(A.PT_FIRST_NAME AS VARCHAR)
	--, A.pt_last_name
	--, A.pt_first_name
	, A.pol_no
	, CAST(B.birth_date AS DATE) AS [DOB]
	, B.gender_cd
	, C.Pt_Addr_City
	, C.Pt_Addr_State
	, c.Pt_Phone_No
	FROM SMSDSS.c_soarian_real_time_census_CDI_v AS A
	LEFT OUTER JOIN smsmir.vst_rpt AS B
	ON A.PT_ID = B.PT_ID
	LEFT OUTER JOIN SMSDSS.c_patient_demos_v AS C
	ON A.pt_id = C.pt_id
	WHERE LEFT(A.ins_plan_no, 1) IN ('A','Z')
	AND (
	A.desc_as_written LIKE '%SEPSIS%'
	OR
	A.desc_as_written LIKE '%SEPTIC%'
	OR
	A.desc_as_written LIKE '%SIRS%'
	)
) AS A
;

SELECT A.*
, [MRN_IN_TBL] = CASE
	WHEN (
			SELECT TOP 1 ZZZ.MED_REC_NO
			FROM SMSDSS.C_ARCHWAY_SEPSIS_TBL AS ZZZ
			WHERE ZZZ.Med_Rec_No = A.Med_Rec_No
		) IS NOT NULL
		THEN 1
		ELSE 0
  END
, RA.[INITIAL DISCHARGE] AS [Previous_Discharge]
, [Within_90Days] = DATEDIFF(DAY, RA.[INITIAL DISCHARGE], A.ADM_DATE)
INTO #TEMPB
FROM #TEMPA AS A
LEFT OUTER JOIN SMSDSS.vReadmits AS RA
ON A.Med_Rec_No = RA.MRN
	AND A.PtNo_Num = RA.[READMIT]
;

SELECT *
INTO #TEMPC
FROM #TEMPB
WHERE (
	(
		-- IS MRN IS NOT IN smsdss.c_archway_sepsis_tbl
		-- meaning pt has not been adm for bundle yet
		[MRN_IN_TBL] = 0
	)
	OR
	(
		-- pt has been here in bundle already
		-- current visit is not in the table
		-- the current visit is subsequent to a previous visit at 91 days or more
		PtNo_Num NOT IN (SELECT DISTINCT PtNo_Num FROM SMSDSS.c_archway_sepsis_tbl)
		AND [MRN_IN_TBL] = 1
		AND [Within_90Days] > 90
	)
)
ORDER BY Med_Rec_No
;

SELECT Med_Rec_No
, PtNo_Num
, Adm_Date
, Pt_Name
, ins1_pol_no
, Pt_Birthdate
, Pt_Sex
, Pt_Addr_City
, Pt_Addr_State
, Pt_Phone_No
FROM #TEMPC
;


INSERT INTO smsdss.c_archway_sepsis_tbl
SELECT Med_Rec_No
, PtNo_Num
, Adm_Date
, Pt_Name
, ins1_pol_no
, Pt_Birthdate
, Pt_Sex
, Pt_Addr_City
, Pt_Addr_State
, Pt_Phone_No
FROM #TEMPC
;

DROP TABLE #TEMPA
DROP TABLE #TEMPB
DROP TABLE #TEMPC
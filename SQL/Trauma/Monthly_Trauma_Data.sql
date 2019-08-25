/*
***********************************************************************
File: Monthly_Trauma_Data.sql

Input Parameters:
	NONE

Tables/Views:
	smsdss.bmh_plm_ptacct_v
	smsmir.dx_grp
	smsdss.vReadmits

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	To provide Trauma Department with monthly data on Trauma patients - Inpatients

	1.	Injury ICD10 codes: (Diagnosis-Final)
		Injury ICD10:
		S00-S99 with 7th character modifiers of A, B, or C ONLY. (Injuries to specific body parts – initial encounter) XXXX
		T07 (unspecified multiple injuries) XXXX
		T14 (injury of unspecified body region) XXXX
		T20-T28 with 7th character modifier of A ONLY (burns by specific body parts – initial encounter) 
		T30-T32 (burn by TBSA percentages) XXXX
		T79.A1-T79.A9 with 7th character modifier of A ONLY (Traumatic Compartment Syndrome – initial encounter)XXXX
         
		Excluding the following isolated injuries:
		S10 (Superficial injuries of the neck) 
		S20 (Superficial injuries of the thorax) 
		S30 (Superficial injuries of the abdomen, pelvis, lower back and external genitals) 
	    S40 (Superficial injuries of shoulder and upper arm) 
		S50 (Superficial injuries of elbow and forearm) 
		S60 (Superficial injuries of wrist, hand and fingers) 
		S70 (Superficial injuries of hip and thigh) 
		S80 (Superficial injuries of knee and lower leg) 
		S90 (Superficial injuries of ankle, foot and toes)

	And    

	2.	Has at least one Injury E-Code 1CD10: V00 – Y38 7th character of A only


Revision History:
Date		Version		Description
----		----		----
2019-05-23	v1			Initial Creation
2019-07-25	v2			Complete re-write. Break query into three parts
						place records in temp tables and join at the 
						bottom.
***********************************************************************
*/

DECLARE @START DATETIME;
DECLARE @END   DATETIME;

SET @START = '2018-01-01';
SET @END   = '2019-01-01';


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

INTO #TEMPA

FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV

WHERE Adm_Date >= @START
AND Adm_Date < @END
--WHERE PAV.Dsch_Date >= @START
--AND PAV.Dsch_Date < @END
AND LEFT(PAV.PTNO_NUM, 1) != '2'
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
AND PAV.tot_chg_amt > 0
AND PAV.Plm_Pt_Acct_Type = 'I'
;


SELECT PVT.pt_id
, PVT.unit_seq_no
, PVT.from_file_ind
, ISNULL(PVT.[01], '') AS [DX1]
, ISNULL(PVT.[02], '') AS [DX2]
, ISNULL(PVT.[03], '') AS [DX3]
, ISNULL(PVT.[04], '') AS [DX4]
, ISNULL(PVT.[05], '') AS [DX5]
, ISNULL(PVT.[06], '') AS [DX6]
, ISNULL(PVT.[07], '') AS [DX7]
, ISNULL(PVT.[08], '') AS [DX8]
, ISNULL(PVT.[09], '') AS [DX9]
, ISNULL(PVT.[10], '') AS [DX10]

INTO #TEMPB

FROM (
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
) AS A

PIVOT(
	MAX(DX_CD)
	FOR DX_CD_PRIO IN (
		"01","02","03","04","05","06","07","08","09","10"
	)
) AS PVT

WHERE pt_id IN (
	SELECT DISTINCT ZZZ.PT_NO
	FROM #TEMPA AS ZZZ
)
;

SELECT RA.[READMIT]

INTO #TEMPC

FROM SMSDSS.vReadmits AS RA

WHERE RA.INTERIM < 31
AND RA.[READMIT SOURCE DESC] != 'Scheduled Admission'
AND RA.[INDEX] IN (
	SELECT DISTINCT ZZZ.PTNO_NUM
	FROM #TEMPA AS ZZZ
)
;

SELECT A.PtNo_Num
, A.Med_Rec_No
, A.Pt_Name
, A.Pt_Age
, CAST(A.ADM_DATE AS DATE) AS [ADM_DATE]
, CAST(A.DSCH_DATE AS DATE) AS [DSCH_DATE]
, A.Plm_Pt_Acct_Type
, A.dsch_disp
, B.DX1
, B.DX2
, B.DX3
, B.DX4
, B.DX5
, B.DX6
, B.DX7
, B.DX8
, B.DX9
, B.DX10
, CASE
	WHEN C.READMIT IS NULL
		THEN ''
		ELSE C.READMIT
  END AS [30Day_Readmit_EncounterID]

FROM #TEMPA AS A
INNER JOIN #TEMPB AS B
ON A.Pt_No = B.pt_id
	AND A.unit_seq_no = B.unit_seq_no
	AND A.from_file_ind = B.from_file_ind
LEFT OUTER JOIN #TEMPC AS C
ON A.PtNo_Num = C.[READMIT]
;

DROP TABLE #TEMPA
DROP TABLE #TEMPB
DROP TABLE #TEMPC
;
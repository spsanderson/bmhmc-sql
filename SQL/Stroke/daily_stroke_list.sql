/*
***********************************************************************
File: daily_stroke_list.sql

Input Parameters:
	None

Tables/Views:
	[SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
    SMSDSS.BMH_UserTwoFact_V AS A
    SMSDSS.BMH_UserTwoField_Dim_V AS B
    SMSDSS.BMH_PLM_PtAcct_V 
    smsdss.dx_cd_dim_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get a daily list of potential stroke patients

Revision History:
Date		Version		Description
----		----		----
2019-11-21	v1			Initial Creation
2019-11-22	v2			Add many more key words/phrases
***********************************************************************
*/

DECLARE @START_DATE DATE;
DECLARE @TODAY DATE;

SET @TODAY = CAST(GETDATE() AS DATE);
SET @START_DATE = DATEADD(DAY, - 1, @TODAY);

SELECT A.ACCOUNT AS [PtNo_Num],
	A.ICD9 AS [UserDataCd],
	B.alt_clasf_desc AS [alt_clasf_desc],
	A.ARRIVAL AS [Adm_Date],
	A.PATIENT AS [Pt_Name],
	DATEDIFF(YEAR, A.AGEDOB, ARRIVAL) AS [Pt_Age],
	A.SEX AS [Pt_Sex]
INTO #ED
FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
LEFT OUTER JOIN SMSDSS.dx_cd_dim_v AS B ON A.ICD9 = B.dx_cd
WHERE (
		A.ICD9 IN ('I60.00', 'I60.30', 'I60.8', 'I62.1', 'I60.01', 'I60.31', 'I60.9', 'I62.9', 'I60.02', 'I60.32', 'I60.10', 'I60.4', 'I62.00', 'I60.11', 'I60.5', 'I62.01', 'I60.12', 'I60.6', 'I62.02', 'I60.2', 'I60.7', 'I62.03')
		OR LEFT(A.ICD9, 3) = 'I61' -- BETWEEN '161.0' AND 'I61.9'
		--STROKE:
		OR A.ICD9 IN ('I63.0', 'I63.1', 'I63.2', 'I63.5', 'I63.6', 'I63.81', 'I63.9', 'I64.XX', 'i97.810', 'I97.811', 'I97.820', 'I97.821')
		)
	AND A.ARRIVAL >= @START_DATE;

-- 2CHFCOMP
SELECT A.PtNo_Num,
	B.UserDataCd
	--, A.UserDataKey
	,
	A.UserDataText,
	PAV.Adm_Date,
	PAV.Pt_Name,
	PAV.Pt_Age,
	PAV.Pt_Sex
INTO #CHFCOMP
FROM SMSDSS.BMH_UserTwoFact_V AS A
INNER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS B ON A.UserDataKey = B.UserTwoKey
INNER JOIN SMSDSS.BMH_PLM_PtAcct_V AS PAV ON A.PtNo_Num = PAV.PtNo_Num
WHERE PAV.Adm_Date >= @START_DATE
	AND (
		B.UserDataCd = '2CHFCOMP'
		AND (
			A.UserDataText LIKE '%HEADAC%'
			OR A.UserDataText LIKE '%STROKE%'
			OR A.UserDataText LIKE '%TIA%'
			OR A.UserDataText LIKE '%CVA%'
			OR A.UserDataText LIKE '%SLUR%SPEECH%'
			OR A.UserDataText LIKE '%WEAKNESS%'
			OR A.UserDataText LIKE '%HEMIPARESIS%'
			OR A.UserDataText LIKE '%AMNESIA%'
			OR A.UserDataText LIKE '%Infarction%'
			OR A.UserDataText LIKE '%infarct%'
			OR A.UserDataText LIKE '%Ischemic%'
			OR A.UserDataText LIKE '%Transient Ischemic Attack%'
			OR A.UserDataText LIKE '%Stroke%'
			OR A.UserDataText LIKE '%Thrombosis%'
			OR A.UserDataText LIKE '%Cerebral%'
			OR A.UserDataText LIKE '%ICH%'
			OR A.UserDataText LIKE '%SAH%'
			OR A.UserDataText LIKE '%Intracerebral%'
			OR A.UserDataText LIKE '%Hemorrhage%'
			OR A.UserDataText LIKE '%Intracranial%Bleed%'
			OR A.UserDataText LIKE '%Bleed%Intracranial%'
			OR A.UserDataText LIKE '%Bleed%Brain%'
			OR A.UserDataText LIKE '%Brain%Bleed%'
			OR A.UserDataText LIKE '%Bleed%Cerebral%'
			OR A.UserDataText LIKE '%Cerebral%Bleed%'
			OR A.UserDataText LIKE '%Embolism%'
			OR A.UserDataText LIKE '%Intracranial%'
			OR A.UserDataText LIKE '%Subarachnoid%'
			OR A.UserDataText LIKE '%Non-traumatic%'
			OR A.UserDataText LIKE '%Blurred vision%'
			OR A.UserDataText LIKE '%Hemiparesis%'
			OR A.UserDataText LIKE '%Hemiplegia%'
			OR A.UserDataText LIKE '%Ataxia%'
			OR A.UserDataText LIKE '%Difficulty walking%'
			OR A.UserDataText LIKE '%Double vision%'
			OR A.UserDataText LIKE '%Diplopia%'
			OR A.UserDataText LIKE '%Dysarthria%'
			OR A.UserDataText LIKE '%Difficulty speaking%'
			OR A.UserDataText LIKE '%Headache%'
			OR A.UserDataText LIKE '%Dystaxia%'
			OR A.UserDataText LIKE '%Vision loss%'
			OR A.UserDataText LIKE '%Loss of balance%'
			OR A.UserDataText LIKE '%Lack of coordination%'
			OR A.UserDataText LIKE '%Seizure%'
			OR A.UserDataText LIKE '%Dizziness%'
			OR A.UserDataText LIKE '%Unresponsive%'
			)
		);

-- ADMDIAG
SELECT A.PtNo_Num,
	B.UserDataCd
	--, A.UserDataKey
	,
	A.UserDataText,
	PAV.Adm_Date,
	PAV.Pt_Name,
	PAV.Pt_Age,
	PAV.Pt_Sex
INTO #ADMDIAG
FROM SMSDSS.BMH_UserTwoFact_V AS A
INNER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS B ON A.UserDataKey = B.UserTwoKey
INNER JOIN SMSDSS.BMH_PLM_PtAcct_V AS PAV ON A.PtNo_Num = PAV.PtNo_Num
WHERE PAV.Adm_Date >= @START_DATE
	AND (
		B.UserDataCd = '2ADMDIAG'
		AND (
			A.UserDataText LIKE '%HEADAC%'
			OR A.UserDataText LIKE '%STROKE%'
			OR A.UserDataText LIKE '%TIA%'
			OR A.UserDataText LIKE '%CVA%'
			OR A.UserDataText LIKE '%SLUR%SPEECH%'
			OR A.UserDataText LIKE '%WEAKNESS%'
			OR A.UserDataText LIKE '%HEMIPARESIS%'
			OR A.UserDataText LIKE '%AMNESIA%'
			OR A.UserDataText LIKE '%Infarction%'
			OR A.UserDataText LIKE '%infarct%'
			OR A.UserDataText LIKE '%Ischemic%'
			OR A.UserDataText LIKE '%Transient Ischemic Attack%'
			OR A.UserDataText LIKE '%Stroke%'
			OR A.UserDataText LIKE '%Thrombosis%'
			OR A.UserDataText LIKE '%Cerebral%'
			OR A.UserDataText LIKE '%ICH%'
			OR A.UserDataText LIKE '%SAH%'
			OR A.UserDataText LIKE '%Intracerebral%'
			OR A.UserDataText LIKE '%Hemorrhage%'
			OR A.UserDataText LIKE '%Intracranial%Bleed%'
			OR A.UserDataText LIKE '%Bleed%Intracranial%'
			OR A.UserDataText LIKE '%Bleed%Brain%'
			OR A.UserDataText LIKE '%Brain%Bleed%'
			OR A.UserDataText LIKE '%Bleed%Cerebral%'
			OR A.UserDataText LIKE '%Cerebral%Bleed%'
			OR A.UserDataText LIKE '%Embolism%'
			OR A.UserDataText LIKE '%Intracranial%'
			OR A.UserDataText LIKE '%Subarachnoid%'
			OR A.UserDataText LIKE '%Non-traumatic%'
			OR A.UserDataText LIKE '%Blurred vision%'
			OR A.UserDataText LIKE '%Hemiparesis%'
			OR A.UserDataText LIKE '%Hemiplegia%'
			OR A.UserDataText LIKE '%Ataxia%'
			OR A.UserDataText LIKE '%Difficulty walking%'
			OR A.UserDataText LIKE '%Double vision%'
			OR A.UserDataText LIKE '%Diplopia%'
			OR A.UserDataText LIKE '%Dysarthria%'
			OR A.UserDataText LIKE '%Difficulty speaking%'
			OR A.UserDataText LIKE '%Headache%'
			OR A.UserDataText LIKE '%Dystaxia%'
			OR A.UserDataText LIKE '%Vision loss%'
			OR A.UserDataText LIKE '%Loss of balance%'
			OR A.UserDataText LIKE '%Lack of coordination%'
			OR A.UserDataText LIKE '%Seizure%'
			OR A.UserDataText LIKE '%Dizziness%'
			OR A.UserDataText LIKE '%Unresponsive%'
			)
		);

-- ADMDIA2
SELECT A.PtNo_Num,
	B.UserDataCd
	--, A.UserDataKey
	,
	A.UserDataText,
	PAV.Adm_Date,
	PAV.Pt_Name,
	PAV.Pt_Age,
	PAV.Pt_Sex
INTO #ADMDIA2
FROM SMSDSS.BMH_UserTwoFact_V AS A
INNER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS B ON A.UserDataKey = B.UserTwoKey
INNER JOIN SMSDSS.BMH_PLM_PtAcct_V AS PAV ON A.PtNo_Num = PAV.PtNo_Num
WHERE PAV.Adm_Date >= @START_DATE
	AND (
		B.UserDataCd = '2ADMDIA2'
		AND (
			A.UserDataText LIKE '%HEADAC%'
			OR A.UserDataText LIKE '%STROKE%'
			OR A.UserDataText LIKE '%TIA%'
			OR A.UserDataText LIKE '%CVA%'
			OR A.UserDataText LIKE '%SLUR%SPEECH%'
			OR A.UserDataText LIKE '%WEAKNESS%'
			OR A.UserDataText LIKE '%HEMIPARESIS%'
			OR A.UserDataText LIKE '%AMNESIA%'
			OR A.UserDataText LIKE '%Infarction%'
			OR A.UserDataText LIKE '%infarct%'
			OR A.UserDataText LIKE '%Ischemic%'
			OR A.UserDataText LIKE '%Transient Ischemic Attack%'
			OR A.UserDataText LIKE '%Stroke%'
			OR A.UserDataText LIKE '%Thrombosis%'
			OR A.UserDataText LIKE '%Cerebral%'
			OR A.UserDataText LIKE '%ICH%'
			OR A.UserDataText LIKE '%SAH%'
			OR A.UserDataText LIKE '%Intracerebral%'
			OR A.UserDataText LIKE '%Hemorrhage%'
			OR A.UserDataText LIKE '%Intracranial%Bleed%'
			OR A.UserDataText LIKE '%Bleed%Intracranial%'
			OR A.UserDataText LIKE '%Bleed%Brain%'
			OR A.UserDataText LIKE '%Brain%Bleed%'
			OR A.UserDataText LIKE '%Bleed%Cerebral%'
			OR A.UserDataText LIKE '%Cerebral%Bleed%'
			OR A.UserDataText LIKE '%Embolism%'
			OR A.UserDataText LIKE '%Intracranial%'
			OR A.UserDataText LIKE '%Subarachnoid%'
			OR A.UserDataText LIKE '%Non-traumatic%'
			OR A.UserDataText LIKE '%Blurred vision%'
			OR A.UserDataText LIKE '%Hemiparesis%'
			OR A.UserDataText LIKE '%Hemiplegia%'
			OR A.UserDataText LIKE '%Ataxia%'
			OR A.UserDataText LIKE '%Difficulty walking%'
			OR A.UserDataText LIKE '%Double vision%'
			OR A.UserDataText LIKE '%Diplopia%'
			OR A.UserDataText LIKE '%Dysarthria%'
			OR A.UserDataText LIKE '%Difficulty speaking%'
			OR A.UserDataText LIKE '%Headache%'
			OR A.UserDataText LIKE '%Dystaxia%'
			OR A.UserDataText LIKE '%Vision loss%'
			OR A.UserDataText LIKE '%Loss of balance%'
			OR A.UserDataText LIKE '%Lack of coordination%'
			OR A.UserDataText LIKE '%Seizure%'
			OR A.UserDataText LIKE '%Dizziness%'
			OR A.UserDataText LIKE '%Unresponsive%'
			)
		);

SELECT A.*,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY A.PTNO_NUM ORDER BY A.PTNO_NUM
		)
INTO #JOINED_DATA
FROM (
	SELECT *
	FROM #ED
	
	UNION ALL
	
	SELECT *
	FROM #CHFCOMP
	
	UNION ALL
	
	SELECT *
	FROM #ADMDIAG
	
	UNION ALL
	
	SELECT *
	FROM #ADMDIA2
	) A;

SELECT PtNo_Num,
	UserDataCd,
	alt_clasf_desc,
	Adm_Date,
	Pt_Name,
	Pt_Age,
	Pt_Sex
FROM #JOINED_DATA
--WHERE RN = 1
ORDER BY PtNo_Num;

DROP TABLE #ED;

DROP TABLE #CHFCOMP;

DROP TABLE #ADMDIAG;

DROP TABLE #ADMDIA2;

DROP TABLE #JOINED_DATA;

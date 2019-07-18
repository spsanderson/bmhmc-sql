/*
***********************************************************************
File: Orders_assessmentsNutritional_Pre_Workflow_v2.sql

Input Parameters:
	NONE

Tables/Views:
	smsmir.mir_sc_Assessment AS A
	smsmir.mir_sc_Observation AS B
	smsmir.mir_sr_vst_pms AS VISIT

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get Admit Assessments with a Nutritional Assessment if it exists
	Get elapsed time in minutes

Revision History:
Date		Version		Description
----		----		----
2019-03-01	v1			Initial Creation
2019-03-07	v2			CAST datetime columns to date
***********************************************************************
*/
DECLARE @START DATETIME;
DECLARE @END   DATETIME;

SET @START = GETDATE()-9; --Run on Mondays Looking at the weeks prior to Sat to the last friday ie starting 9 days from Monday.
SET @END   = GETDate()-2;

SELECT VISIT.episode_no
, visit.vst_start_dtime
, A.FormUsage
, B.[CreationTime] AS 'Assessment Completed'
, B.[InternalValue]
, B.FindingAbbr
, CASE
	WHEN b.InternalValue = '4'
		THEN 'Manual Order'
	WHEN b.InternalValue = '7'
		THEN 'Workflow Order'
	WHEN (
		b.InternalValue = '6'
		AND b.FindingAbbr = 'A_BMH_NSAct18-74'
	)
		THEN 'Manual Order'
		ELSE 'Workflow Order'
  END AS [Order_Type] 
, B.[Value] AS 'Assessment Value'
, A.AssessmentID
, B.CreationTime

INTO #TEMPA

FROM smsmir.mir_sc_Assessment AS A
LEFT OUTER JOIN smsmir.mir_sc_Observation AS B
ON A.AssessmentID = B.AssessmentID
LEFT OUTER JOIN smsmir.mir_sr_vst_pms AS VISIT
ON A.PATIENTVISIT_OID = VISIT.vst_no

WHERE A.FormUsage = 'Admission'
--AND Visit.episode_no = 
AND (
	(
		B.FindingAbbr= 'A_BMH_NSAct18-74'
		AND B.InternalValue in ('6' , '7')
	)
	OR
	(
		B.FindingAbbr= 'A_BMH_NS75Action'
		AND B.InternalValue in ('4' , '6')
	)
)
AND B.EndDT IS NULL
AND B.CreationTime > @START
AND B.CreationTime < @END
AND A.[Version] = (
					SELECT MAX(zzz.[Version]) 
					FROM [SMSPHDSSS0X0].[smsmir].[mir_sc_Assessment] AS zzz 
					WHERE zzz.Patient_oid = A.patient_oid
					AND zzz.PatientVisit_oid = A.patientvisit_oid
					AND zzz.AssessmentID = A.AssessmentID
					)
--GO
;

-- NUTRIIONAL ASSESSMENT ---------------------------------------------------------------------
SELECT VISIT.episode_no
, visit.vst_start_dtime
, A.FormUsage
, A.CollectedDT AS 'Nutritional Consult Completed'
, [RN] = ROW_NUMBER() OVER(PARTITION BY VISIT.EPISODE_NO ORDER BY B.[CREATIONTIME] ASC)

INTO #TEMPB

FROM smsmir.mir_sc_Assessment AS A
LEFT OUTER JOIN smsmir.mir_sc_Observation AS B
ON A.AssessmentID = B.AssessmentID
LEFT OUTER JOIN smsmir.mir_sr_vst_pms AS VISIT
ON A.PATIENTVISIT_OID = VISIT.vst_no

WHERE A.FormUsage = 'Nutritional Assessment'
--AND Visit.episode_no = 
AND B.EndDT IS NULL
AND B.CreationTime > @START
AND B.CreationTime < @END
AND A.CollectedDT < B.CreationTime
AND A.[Version] = (
					SELECT MAX(zzz.[Version]) 
					FROM [SMSPHDSSS0X0].[smsmir].[mir_sc_Assessment] AS zzz 
					WHERE zzz.Patient_oid = A.patient_oid
					AND zzz.PatientVisit_oid = A.patientvisit_oid
					AND zzz.AssessmentID = A.AssessmentID
					)

--GO
;

SELECT A.episode_no
, A.vst_start_dtime
, A.[Assessment Completed]
, A.Order_Type
, A.[Assessment Value]
, B.[Nutritional Consult Completed] AS [Nutritional Consult Completed]
, DATEDIFF(MINUTE, A.[Assessment Completed], B.[Nutritional Consult Completed]) AS [Elapsed_Minutes]
, CASE
	WHEN B.[Nutritional Consult Completed] IS NULL
		THEN 0
		ELSE 1
  END AS [Nutritional Consult Flag]
, CASE
	WHEN datediff(minute,a.[Assessment Completed], b.[Nutritional Consult Completed]) < 0
		THEN 'Negative Number'
	WHEN b.[Nutritional Consult Completed] IS NULL
		THEN 'Nutrition Assessment Not Done'
		ELSE 'Positive Number'
  END AS [Negative Elapsed Minutes]

FROM #TEMPA AS A
LEFT OUTER JOIN #TEMPB AS B
ON A.episode_no = B.episode_no
	AND B.RN = 1
	--AND B.[Nutritional Consult Completed] >= A.CreationTime  --"Removes Negatives from Elasped Minutes"

WHERE A.episode_no IS NOT NULL
--AND B.[Nutritional Consult Completed] >= A.CreationTime "KEEPS negatives in elasped minutes"

ORDER BY a.[Assessment Completed]
;

DROP TABLE #TEMPA
DROP TABLE #TEMPB
;
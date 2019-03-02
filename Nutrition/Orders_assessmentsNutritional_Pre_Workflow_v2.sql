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
***********************************************************************
*/
DECLARE @START DATETIME;
DECLARE @END   DATETIME;

SET @START = '2017-08-01';
SET @END   = '2019-02-27';

SELECT VISIT.episode_no
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
AND B.CreationTime BETWEEN @START AND @END
AND A.[Version] = (
					SELECT MAX(zzz.[Version]) 
					FROM [SMSPHDSSS0X0].[smsmir].[mir_sc_Assessment] AS zzz 
					WHERE zzz.Patient_oid = A.patient_oid
					AND zzz.PatientVisit_oid = A.patientvisit_oid
					AND zzz.AssessmentID = A.AssessmentID
					)
;

-- NUTRIIONAL ASSESSMENT ---------------------------------------------------------------------
SELECT VISIT.episode_no
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
AND B.CreationTime BETWEEN @START AND @END
AND A.CollectedDT < B.CreationTime
AND A.[Version] = (
					SELECT MAX(zzz.[Version]) 
					FROM [SMSPHDSSS0X0].[smsmir].[mir_sc_Assessment] AS zzz 
					WHERE zzz.Patient_oid = A.patient_oid
					AND zzz.PatientVisit_oid = A.patientvisit_oid
					AND zzz.AssessmentID = A.AssessmentID
					)
;

SELECT A.episode_no
, A.[Assessment Completed]
, A.Order_Type
, A.[Assessment Value]
, B.[Nutritional Consult Completed]
, DATEDIFF(MINUTE, A.[Assessment Completed], B.[Nutritional Consult Completed]) AS [Elapsed_Minutes]

FROM #TEMPA AS A
LEFT OUTER JOIN #TEMPB AS B
ON A.episode_no = B.episode_no
	AND B.RN = 1

WHERE A.episode_no IS NOT NULL

ORDER BY A.episode_no
;

DROP TABLE #TEMPA
DROP TABLE #TEMPB
;
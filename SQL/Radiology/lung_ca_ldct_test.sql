/*
***********************************************************************
File: lung_ca_ldct_test.sql

Input Parameters:
	DATE
    MINAGE
    MAXAGE

Tables/Views:
	HAssessment AS HA
    HObservation AS HO
    HPatientVisit AS PV
    HPatient AS PT
    HPerson AS PER

Creates Table:
	None

Functions:
	.DBO.FN_ORE_GETPATIENTAGE

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get test paitents from SC_Test for LD Lung CA CT Screening

Revision History:
Date		Version		Description
----		----		----
2020-02-11	v1			Initial Creation
***********************************************************************
*/

DECLARE @START DATE;
DECLARE @MINAGE INT;
DECLARE @MAXAGE INT;

SET @START = (GETDATE() - 1);
SET @MINAGE = 55.0;
SET @MAXAGE = 79.0;

SELECT HA.Patient_oid
, HA.PatientVisit_oid
, PV.PatientAccountID
, PT.FirstName
, PT.LastName
, PV.PatientLocationName
, HO.FindingAbbr
, HO.CreationTime
, HO.CreatedUserId
, HO.Value
--, ROUND(CAST(HO.Value AS FLOAT) / 365.25, 1) AS [Packs_Per_Day]
, AgeY = (.DBO.FN_ORE_GETPATIENTAGE(PER.BIRTHDATE, HO.CreationTime))
, Age = DATEDIFF(MONTH, PER.BirthDate, HO.CreationTime)/12

INTO #TEMPA

FROM HAssessment AS HA
INNER JOIN HObservation AS HO
ON HA.AssessmentID = HO.AssessmentID
	AND HA.Patient_oid = HO.Patient_oid
INNER JOIN HPatientVisit AS PV
ON HA.PatientVisit_oid = PV.ObjectID
	AND PV.IsDeleted = 0
INNER JOIN HPatient AS PT
ON PV.Patient_oid = PT.ObjectID
INNER JOIN HPerson AS PER WITH(NOLOCK)
ON PT.ObjectID = PER.ObjectID
	AND PER.IsDeleted = 0

WHERE FindingAbbr IN (
	'A_BMH_CSNUMPASMO',
	'A_BMH_FSNUMPASMO',
	'A_BMH_QUITWI15YE',
	'A_BMH_HowMaYaQui'
)
;

SELECT PVT.Patient_oid
, PVT.PatientVisit_oid
, PVT.PatientAccountID
, PVT.FirstName
, PVT.LastName
, PVT.PatientLocationName
, PVT.CreationTime
, PVT.AgeY
, PVT.Age
, PVT.A_BMH_CSNUMPASMO AS [CurrentSmoker_Packs]
, PVT.A_BMH_FSNUMPASMO AS [FormerSmoker_Packs]
, PVT.A_BMH_QUITWI15YE AS [QuitWithin_15Yr]
, PVT.A_BMH_HowMaYaQui AS [QuitHowManyYearsAgo]
INTO #TEMPB
FROM #TEMPA
PIVOT(
	MAX(VALUE)
	FOR FINDINGABBR IN (
		"A_BMH_CSNUMPASMO",
		"A_BMH_FSNUMPASMO",
		"A_BMH_QUITWI15YE",
		"A_BMH_HowMaYaQui"
	)
) PVT
;

SELECT *
, CASE
	WHEN CAST(A.CurrentSmoker_Packs AS FLOAT) >= 30.0
		THEN 1
	WHEN (
			CAST(A.FormerSmoker_Packs AS FLOAT) >= 30.0
			AND (
					CAST(A.QuitHowManyYearsAgo AS FLOAT) <= 15.0
					OR
					CAST(A.QuitWithin_15Yr AS FLOAT) <= 15.0
				)
		)
		THEN 1
		ELSE 0
  END AS [LDCT_Flag]
INTO #TEMPC
FROM #TEMPB AS A
;

SELECT *
FROM #TEMPC
WHERE LDCT_Flag = 1
AND Age >= @MINAGE
AND Age <= @MAXAGE

DROP TABLE #TEMPA;
DROP TABLE #TEMPB;
DROP TABLE #TEMPC;
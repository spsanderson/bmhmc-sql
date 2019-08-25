DECLARE @iUseroid INT,
	@iEntityOID INT,
	@vchEnterpriseName VARCHAR(75),
	@vchReportUserName VARCHAR(184),
	@dtStartDate DATETIME,
	@dtEndDate DATETIME

SET @dtStartDate = GETDATE()
SET @dtEndDate = @dtStartDate - 1

-- START QUERY

SELECT DISTINCT HPV.ObjectID AS VisitOID
, HPV.Patient_oid AS PatientOID
, HPV.PatientAccountID
, HPV.PatientLocationName AS LocationName

INTO #CensusVisitOIDs 

FROM SMSMIR.sc_Bed AS HBED WITH(NOLOCK)
INNER JOIN SMSMIR.sc_HealthCareUnit AS HHCU WITH(NOLOCK)
ON HBED.HealthCareUnit_oid = HHCU.ObjectID
INNER JOIN smsmir.sc_PatientVisit AS HPV WITH(NOLOCK)
ON HHCU.HealthcareUnitName = HPV.PatientLocationName
	AND HPV.IsDeleted = '0'
	AND HBED.BedTypeName = HPV.LatestBedName
	AND HHCU.EntityMappingID = HPV.Entity_oid
	AND HPV.VisitStatus IN ('0','4')

WHERE HBED.BedTypeName IS NOT NULL
AND HBED.Active = '1'

--SEELCT * FROM #CensusVisitOIDs
;

SELECT LocationName
, COUNT(Visitoid) AS PatientsInBedCount

INTO #PatientsInBedCount

FROM #CensusVisitOIDs

GROUP BY LocationName

--SELECT * FROM #PatientsInBedCount
;


SELECT HA.AssessmentID
, HA.CollectedDT
, CV.VisitOID
, CV.LocationName

INTO #VentAssessments

FROM SMSMIR.sc_Observation AS HO WITH(NOLOCK)
INNER JOIN SMSMIR.sc_Assessment AS HA WITH(NOLOCK)
ON HO.ASSESSMENTID = HA.AssessmentID
INNER JOIN #CensusVisitOIDs AS CV ON
HA.PatientVisit_oid = CV.PatientOID
	AND HA.Patient_oid = CV.PatientOID

WHERE FindingAbbr = 'A_O2 Del Method'
	--AND Value = 'Tracheostomy with Ventilator Precautions'  
	AND ha.AssessmentStatusCode IN (1, 3)
	AND ho.EndDT IS NULL
	AND ha.EndDt IS NULL
	AND CollectedDT BETWEEN @dtStartDate AND @dtEndDate
ORDER BY LocationName,
	VisitOID,
	CollectedDT DESC

ALTER TABLE #VentAssessments ADD ID_NUM INT IDENTITY(1, 1)

-- Delete everything but the last assessment for each location, patient
DELETE
FROM #VentAssessments
WHERE ID_NUM NOT IN (
	SELECT MIN(ZZZ.AssessmentID)
	FROM #VentAssessments AS ZZZ
	GROUP BY ZZZ.VisitOID, ZZZ.LocationName
)

SELECT * FROM #VentAssessments
;

-- DROP TABLE STATEMENTS
DROP TABLE #CensusVisitOIDs;
DROP TABLE #PatientsInBedCount;
DROP TABLE #VentAssessments;
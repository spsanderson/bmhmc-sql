--USE [SMSPHDSSS0X0]
--GO
/****** Object:  StoredProcedure [dbo].[ORE_BMH_DOH_Denominators_V3]    Script Date: 8/5/2019 9:18:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* 
File: ORE_BMH_DOH_Denominators.sql  
  
Input  Parameters:   
    EntityName  - Used to select patients for a specific entity    
    Location    - Used to select a specific Nursing Station's   
                patients for the report  
    HSF_SESSION_USEROID - Used to get user name of user who printed  
                        the report  
    @HSF_SESSION_ENTITYID  as EntityOID used to identify entity which the report should be run for.  
    @pchReportUsage - Used to indicate how the report is being run  
        1 = Context Senstive (CSP)  
        2 = Operational Reporting (OPR)  
        3 = Job Scheduler (JS)  
        4 = Event Driven Routing (EDR)    
        5 = Modal Print - From Patient Record   
  
Purpose:  This procedure generates totals for a Denominators for Intensive Care
    Number of patients, by unit, at time report was run  
    Number of patients, by unit, with 1 or more central lines (looking at assessments from "yesterday")  
    Number of patients, by unit, with 1 or more other lines (looking at assessments from "yesterday")  
    Number of patients, by unit, with a urinary catherer (looking at assessments from "yesterday")  
    Number of patients, by unit, on a ventilator (looking at assessments from current "yesterday")  

Tables: 
    HSUser
    HPatient  
    HPatientvisit  
    HObservation  
    HAssessment  

Views: 
    vw_ORE_Beds  

Functions: 
    fn_ORE_GetEnterprisename 

Revision History:  
   
Date         Author            Description  
----         ------           -----------  
18-May-2011  Megan Sibley		Added Endotracheal as Value
16-Dec-2009  Girish GH			Added additional column PatientOid to temporay table @CensusVisitOIDs and then used 
    							to join with tables HAssessment to improve performance. C5 To C6 Uplift
09-10-2009   Tharik				EVTS :5454437 .Observation value change for 'A_IV[1-4] Type'  
07-Jan-2009  Matt Heilman		New Procedure - Loosely based off of ORE_0119  
*/

ALTER PROC [dbo].[ORE_BMH_DOH_Denominators_V3] @pvchEntityName AS VARCHAR(2000) = NULL,
	@pvchLocation AS TEXT,
	@HSF_SESSION_USEROID AS VARCHAR(20) = NULL,
	@HSF_SESSION_ENTITYID AS VARCHAR(20) = NULL,
	@pchReportUsage AS CHAR(1) = '2'
AS
SET NOCOUNT ON

DECLARE @iUseroid INT,
	@iEntityOID INT,
	@vchEnterpriseName VARCHAR(75),
	@vchReportUserName VARCHAR(184),
	@dtStartDate DATETIME,
	@dtEndDate DATETIME
-- Table Variable declaration area  
--  
DECLARE @CensusVisitOIDs TABLE (
	VisitOID INT,
	PatientOID INT,
	LocationName VARCHAR(75),
	PatientAccountID VARCHAR(20)
	)
DECLARE @PatientsInBedCount TABLE (
	Location VARCHAR(75),
	PatientsInBedCount INT
	)
-- Table to vent assessments  
DECLARE @VentAssessments TABLE (
	id_num INT IDENTITY(1, 1),
	AssessmentID INTEGER,
	CollectedDT DATETIME,
	PatientVisitOID INTEGER,
	LocationName VARCHAR(75)
	)
DECLARE @VentPatients TABLE (
	LocationName VARCHAR(75),
	PatientVisit_oid INT
	)
-- Table to Foey assessments  
DECLARE @FoleyAssessments TABLE (
	id_num INT IDENTITY(1, 1),
	AssessmentID INTEGER,
	CollectedDT DATETIME,
	PatientVisitOID INTEGER,
	LocationName VARCHAR(75)
	)
DECLARE @FoleyPatients TABLE (
	LocationName VARCHAR(75),
	PatientVisit_oid INT
	)
-- Table to Central Line assessments  
DECLARE @CentralLineAssessments TABLE (
	id_num INT IDENTITY(1, 1),
	AssessmentID INTEGER,
	CollectedDT DATETIME,
	PatientVisitOID INTEGER,
	LocationName VARCHAR(75)
	)
DECLARE @CentralLinePatients TABLE (
	LocationName VARCHAR(75),
	PatientVisit_oid INT
	)
-- Table to Other Line assessments  
DECLARE @OtherLineAssessments TABLE (
	id_num INT IDENTITY(1, 1),
	AssessmentID INTEGER,
	CollectedDT DATETIME,
	PatientVisitOID INTEGER,
	LocationName VARCHAR(75)
	)
-- Table to hold final counts  
DECLARE @OtherLinePatients TABLE (
	LocationName VARCHAR(75),
	PatientVisit_oid INT
	)
--Table to hold parsed visit oids from incoming @ptxMicroDisplayGrpNames parameter  
DECLARE @tblLocation TABLE (Location VARCHAR(75))
--Table to hold parsed entities from incoming @pvchEntityName parameter - Multiple  
--entities are passed only for Job Scheduler usage.   
DECLARE @tblEntities TABLE (EntityOID INT)

-- if incoming user oid is numeric convert to int  
IF IsNumeric(@HSF_SESSION_USEROID) = 1
	SET @iUserOID = cast(@HSF_SESSION_USEROID AS INT)
ELSE
	SET @iUserOID = - 1

-- if incoming user oid is numeric convert to int  
IF IsNumeric(@HSF_SESSION_ENTITYID) = 1
	SET @iEntityOID = cast(@HSF_SESSION_ENTITYID AS INT)
ELSE
	SET @iEntityOID = - 1

IF @pchReportUsage <> '3'
BEGIN
	IF (@pvchEntityName LIKE '%,%,%')
	BEGIN
		RAISERROR (
				'OMSErrorNo=[65601], OMSErrorDesc = [Only one entity can be passed as a parameter for usages other than JS]',
				16,
				1
				)

		RETURN
	END
END

IF @pchReportUsage = '3'
BEGIN
	IF (
			@pvchEntityName LIKE '%,All,%'
			OR @pvchEntityName LIKE 'All,%'
			)
	BEGIN
		INSERT INTO @tblEntities (EntityOID)
		SELECT objectid
		FROM HHealthCareUnit WITH (NOLOCK)
		WHERE OrganizationType = 0
			AND active = 1
	END
	ELSE
	BEGIN
		INSERT INTO @tblEntities (EntityOID)
		SELECT objectid
		FROM HHealthCareUnit WITH (NOLOCK)
		WHERE HealthCareUnitName IN (
				SELECT *
				FROM fn_GetStrParmTable(@pvchEntityName)
				)
			AND OrganizationType = 0
	END
END
ELSE
BEGIN
	INSERT INTO @tblEntities (EntityOID)
	VALUES (@iEntityOID)
END

-- parse formusage name parameters  
IF (@pvchLocation IS NOT NULL)
	AND (@pvchLocation NOT LIKE '%All,%')
BEGIN
	INSERT INTO @tblLocation (Location)
	SELECT *
	FROM fn_GetStrParmTable(@pvchLocation)
END
ELSE
	INSERT INTO @tblLocation (Location)
	SELECT DISTINCT HealthcareUnitName
	FROM HHealthcareunit HHealthCareUnit WITH (NOLOCK)
	INNER JOIN HBed Hbed WITH (NOLOCK) ON HBed.HealthCareUnit_oid = HHealthCareUnit.ObjectID
		AND Hbed.BedTypeName IS NOT NULL
		AND Hbed.Active = 1
	WHERE HHealthCareUnit.active = 1
		AND HHealthCareUnit.organizationtype = 2

-- set @Location = 'All'  
--Get Enterprise name -   
SET @vchEnterpriseName = isnull(.dbo.fn_ORE_GetEnterprisename(), '')

IF @pchReportUsage = '3'
BEGIN
	SET @vchReportUserName = 'Job Scheduler - JS'
END
ELSE
BEGIN
	--Get Name of User requesting the report  
	SET @vchReportUserName = isnull(dbo.fn_ORE_GetPersonName((
					SELECT Person_OID
					FROM HSUser WITH (NOLOCK)
					WHERE ObjectID = @iUserOID
					), 6), '')
END

-- Set begin and end date so they cover the last 24 hours      
SET @dtEndDate = getdate()
SET @dtStartDate = @dtEndDate - 1

INSERT INTO @CensusVisitOIDs
SELECT DISTINCT
	--HBed.ObjectID,  
	HPatientVisit.ObjectID,
	HPatientVisit.Patient_OID,
	HPatientVisit.PatientLocationName,
	HPatientVisit.PatientAccountID
--t2.Location  
FROM HBed HBed WITH (NOLOCK)
INNER JOIN HHealthCareUnit HHealthCareUnit WITH (NOLOCK) ON HBed.HealthCareUnit_oid = HHealthCareUnit.ObjectID
INNER JOIN @tblEntities t1 ON HHealthCareUnit.EntityMappingID = t1.EntityOID
INNER JOIN @tblLocation t2 ON t2.Location = HHealthCareUnit.HealthcareUnitName
INNER JOIN HPatientVisit HPatientVisit WITH (NOLOCK) ON HHealthCareUnit.HealthCareUnitName = HPatientVisit.PatientLocationName
	AND HPatientVisit.IsDeleted = 0
	AND Hbed.BedTypeName = HPatientVisit.LatestBedName
	AND HHealthCareUnit.EntityMappingID = HPatientVisit.Entity_oid
	AND HpatientVisit.VisitStatus IN (0, 4)
WHERE Hbed.BedTypeName IS NOT NULL
	AND Hbed.Active = 1

INSERT INTO @PatientsInBedCount
SELECT LocationName,
	COUNT(VisitOID)
FROM @CensusVisitOIDs
GROUP BY LocationName

----------------------------------------------------------------------------------------  
--Get all the assessments within the last 24 hours that contain  
-- A_02 Del Method and sort them by Collected Date.    
INSERT INTO @VentAssessments (
	AssessmentID,
	CollectedDT,
	PatientVisitOID,
	LocationName
	)
SELECT ha.AssessmentID,
	ha.CollectedDT,
	cv.VisitOID,
	cv.LocationName
FROM hobservation ho WITH (NOLOCK)
INNER JOIN hassessment ha WITH (NOLOCK) ON ho.assessmentid = ha.assessmentid
INNER JOIN @CensusVisitOIDs cv ON ha.PatientVisit_OID = cv.VisitOID
	AND ha.Patient_OID = cv.PatientOID -- Performance Improvement
WHERE FindingAbbr = 'A_O2 Del Method'
	--AND Value = 'Tracheostomy with Ventilator Precautions'  
	AND ha.AssessmentStatusCode IN (1, 3)
	AND ho.EndDT IS NULL
	AND ha.EndDt IS NULL
	AND CollectedDT BETWEEN @dtStartDate
		AND @dtEndDate
ORDER BY LocationName,
	VisitOID,
	CollectedDT DESC

--Delete everything but the last assessment for each location, patient  
DELETE
FROM @VentAssessments
WHERE id_num NOT IN (
		SELECT MIN(id_num)
		FROM @VentAssessments
		GROUP BY PatientVisitOID,
			LocationName
		)

INSERT INTO @VentPatients
SELECT DISTINCT va.LocationName,
	va.PatientVisitOID
FROM hobservation ho WITH (NOLOCK)
INNER JOIN hassessment ha WITH (NOLOCK) ON ho.assessmentid = ha.assessmentid
INNER JOIN @VentAssessments va ON ha.PatientVisit_OID = va.PatientVisitOID
	AND ha.AssessmentID = va.AssessmentID
WHERE (
		FindingAbbr = 'A_O2 Del Method'
		AND Value = 'Tracheostomy with Ventilator Precautions'
		OR FindingAbbr = 'A_O2 Del Method'
		AND Value = 'Endotracheal'
		)
	AND ha.AssessmentStatusCode IN (1, 3)
	AND ho.EndDT IS NULL
	AND ha.EndDt IS NULL
	AND ha.CollectedDT BETWEEN @dtStartDate
		AND @dtEndDate

-- Now get the final count for the assessments that have a  
-- O2 Del Method with a 'Tracheostomy with Ventilator Precautions'  
----------------------------------------------------------------------------------------  
----------------------------------------------------------------------------------------  
--Get all the assessments within the last 24 hours that contain  
-- Urin Foley and sort them by Collected Date.    
INSERT INTO @FoleyAssessments (
	AssessmentID,
	CollectedDT,
	PatientVisitOID,
	LocationName
	)
SELECT ha.AssessmentID,
	ha.CollectedDT,
	cv.VisitOID,
	cv.LocationName
FROM hobservation ho WITH (NOLOCK)
INNER JOIN hassessment ha WITH (NOLOCK) ON ho.assessmentid = ha.assessmentid
INNER JOIN @CensusVisitOIDs cv ON ha.PatientVisit_OID = cv.VisitOID
	AND ha.Patient_OID = cv.PatientOID -- Performance Improvement 
WHERE FindingAbbr = 'A_Urine Chars'
	AND ha.AssessmentStatusCode IN (1, 3)
	AND ho.EndDT IS NULL
	AND ha.EndDt IS NULL
	AND CollectedDT BETWEEN @dtStartDate
		AND @dtEndDate
ORDER BY LocationName,
	VisitOID,
	CollectedDT DESC

--Delete everything but the last assessment for each location, patient  
DELETE
FROM @FoleyAssessments
WHERE id_num NOT IN (
		SELECT MIN(id_num)
		FROM @FoleyAssessments
		GROUP BY PatientVisitOID,
			LocationName
		)

INSERT INTO @FoleyPatients
SELECT DISTINCT va.LocationName,
	va.PatientVisitOID
FROM hobservation ho WITH (NOLOCK)
INNER JOIN hassessment ha WITH (NOLOCK) ON ho.assessmentid = ha.assessmentid
INNER JOIN @FoleyAssessments va ON ha.PatientVisit_OID = va.PatientVisitOID
	AND ha.AssessmentID = va.AssessmentID
WHERE FindingAbbr = 'A_Urine Chars'
	AND Value = 'Foley Catheter'
	AND ha.AssessmentStatusCode IN (1, 3)
	AND ho.EndDT IS NULL
	AND ha.EndDt IS NULL
	AND ha.CollectedDT BETWEEN @dtStartDate
		AND @dtEndDate

----------------------------------------------------------------------------------------  
---------------------------------------------------------------------------------------  
--Get all the assessments within the last 24 hours that contain  
-- Central Line and sort them by Collected Date.    
INSERT INTO @CentralLineAssessments (
	AssessmentID,
	CollectedDT,
	PatientVisitOID,
	LocationName
	)
SELECT ha.AssessmentID,
	ha.CollectedDT,
	cv.VisitOID,
	cv.LocationName
FROM hobservation ho WITH (NOLOCK)
INNER JOIN hassessment ha WITH (NOLOCK) ON ho.assessmentid = ha.assessmentid
INNER JOIN @CensusVisitOIDs cv ON ha.PatientVisit_OID = cv.VisitOID
	AND ha.Patient_OID = cv.PatientOID -- Performance Improvement  
WHERE FindingAbbr IN ('A_IV1 Type', 'A_IV2 Type', 'A_IV3 Type', 'A_IV4 Type')
	AND ha.AssessmentStatusCode IN (1, 3)
	AND ho.EndDT IS NULL
	AND ha.EndDt IS NULL
	AND CollectedDT BETWEEN @dtStartDate
		AND @dtEndDate
ORDER BY LocationName,
	VisitOID,
	CollectedDT DESC

--Delete everything but the last assessment for each location, patient  
DELETE
FROM @CentralLineAssessments
WHERE id_num NOT IN (
		SELECT MIN(id_num)
		FROM @CentralLineAssessments
		GROUP BY PatientVisitOID,
			LocationName
		)

INSERT INTO @CentralLinePatients
SELECT DISTINCT va.LocationName,
	va.PatientVisitOID
FROM hobservation ho WITH (NOLOCK)
INNER JOIN hassessment ha WITH (NOLOCK) ON ho.assessmentid = ha.assessmentid
INNER JOIN @CentralLineAssessments va ON ha.PatientVisit_OID = va.PatientVisitOID
	AND ha.AssessmentID = va.AssessmentID
WHERE FindingAbbr IN ('A_IV1 Type', 'A_IV2 Type', 'A_IV3 Type', 'A_IV4 Type')
	--  AND Value  IN ('Saline Lock', 'Peripheral')  
	--  AND Value  IN ('Saline Lock/Peripheral', 'Peripheral IV') --EVTS :5454437  
	AND Value IN ('Central Line', 'IVAD', 'PICC Line', 'Hemodialysis Catheter') --EVTS 5572767
	AND ha.AssessmentStatusCode IN (1, 3)
	AND ho.EndDT IS NULL
	AND ha.EndDt IS NULL
	AND ha.CollectedDT BETWEEN @dtStartDate
		AND @dtEndDate

----------------------------------------------------------------------------------------  
----------------------------------------------------------------------------------------  
-- We already got a list of lines from the last section  
-- NOw we just need to filter out the findings we don't need.  
INSERT INTO @OtherLinePatients
SELECT DISTINCT va.LocationName,
	va.PatientVisitOID
FROM hobservation ho WITH (NOLOCK)
INNER JOIN hassessment ha WITH (NOLOCK) ON ho.assessmentid = ha.assessmentid
INNER JOIN @CentralLineAssessments va ON ha.PatientVisit_OID = va.PatientVisitOID
	AND ha.AssessmentID = va.AssessmentID
WHERE FindingAbbr IN ('A_IV1 Type', 'A_IV2 Type', 'A_IV3 Type', 'A_IV4 Type')
	--AND Value NOT IN ('Saline Lock', 'Peripheral', 'Not Applicable')  
	AND Value IN ('Peripheral IV', 'Saline Lock/Peripheral') --EVTS 5572767
	AND ha.AssessmentStatusCode IN (1, 3)
	AND ho.EndDT IS NULL
	AND ha.EndDt IS NULL
	AND ha.CollectedDT BETWEEN @dtStartDate
		AND @dtEndDate

----------------------------------------------------------------------------------------  
--SELECT * FROM @DOHTotals  
SELECT t1.LocationName,
	t1.PatientAccountID,
	PatientsInBedCount = MAX(t6.PatientsInBedCount),
	PatientsOnVentCount = CASE 
		WHEN t2.patientvisit_oid IS NOT NULL
			THEN 1
		ELSE 0
		END,
	PatientsWithFoleyCount = CASE 
		WHEN t3.patientvisit_oid IS NOT NULL
			THEN 1
		ELSE 0
		END,
	PatientsWithCentralLine = CASE 
		WHEN t4.patientvisit_oid IS NOT NULL
			THEN 1
		ELSE 0
		END,
	PatientsWithOtherLine = CASE 
		WHEN t5.patientvisit_oid IS NOT NULL
			THEN 1
		ELSE 0
		END
FROM @CensusVisitOIDs t1
INNER JOIN @PatientsInBedCount t6 ON t1.LocationName = t6.Location
LEFT JOIN @VentPatients t2 ON t1.visitoid = t2.patientvisit_oid
	AND t1.locationname = t2.locationname
LEFT JOIN @FoleyPatients t3 ON t1.visitoid = t3.patientvisit_oid
	AND t1.locationname = t3.locationname
LEFT JOIN @CentralLinePatients t4 ON t1.visitoid = t4.patientvisit_oid
	AND t1.locationname = t4.locationname
LEFT JOIN @OtherLinePatients t5 ON t1.visitoid = t5.patientvisit_oid
	AND t1.locationname = t5.locationname
GROUP BY t1.LocationName,
	t1.VisitOID,
	t2.patientvisit_oid,
	t3.patientvisit_oid,
	t4.patientvisit_oid,
	t5.patientvisit_oid,
	t1.PatientAccountID
ORDER BY 1

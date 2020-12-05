USE [Soarian_Clin_Tst_1]
GO
/****** Object:  StoredProcedure [dbo].[ORE_BMH_MEWS_SCORE]    Script Date: 11/20/2020 10:15:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
***********************************************************************
  
File: ORE_BMH_MEWS_SCORE.sql
  
Input Parameters:
	@pvchLocation - As Location used to identify which Nurse Station the report should be run for.  
    @HSF_SESSION_USEROID - Used to get user name of user who printed the report
    @pchReportUsage - Used to indicate how the report is being run
			        1 = Context Senstive (CSP)
                    2 = Operational Reporting (OPR)
                    3 = Job Scheduler (JS)
                    4 = Event Driven Routing (EDR)  
                    5 = Modal Print - From Patient Record 
           
Tables/Views:
	HAssessment ha with(nolock)
	HObservation ho with(nolock)

Creates Table:
	None

Functions:
	dbo.fn_ORE_GetPersonName
	dbo.fn_GetStrParmTable
	dbo.fn_ORE_GetExternalPatientID

Author: Steven P. Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description:
	This procedure returns the most recent assessment that has MEWS Score charted.

Revision History:  
   
Date        Author		        Description  
----        ------				-----------  
2020-11-20	Steve				Initial Creation
***********************************************************************
*/  
   
ALTER PROCEDURE [dbo].[ORE_BMH_MEWS_SCORE] @pvchLocation VARCHAR(2000) = NULL,
	@HSF_SESSION_USEROID AS VARCHAR(20) = NULL,
	@pchReportUsage AS CHAR(1) = '2'
	--declare @pvchlocation varchar(20)
	--set @pvchLocation =  'CSU,'
AS
--*************************************************************************************************  
-- Variables declaration for Vitals Sign Report --  
--*************************************************************************************************  
DECLARE @FormUsageName VARCHAR(255),
	@FindingName VARCHAR(64),
	@iPatientOID INT,
	@iVisitOID INT,
	@FindingAbbrName VARCHAR(16),
	@dStartDate DATETIME,
	@dEndDate DATETIME,
	@dtDschDtFrom DATETIME,
	@dtDschDtTo DATETIME,
	@iRecCount INT,
	@vcFormUsageName CHAR(3),
	@iHours INT,
	@ChapterName VARCHAR(255),
	@iUseroid INT,
	@vchReportUserName VARCHAR(184)

-- Set session user oid
IF IsNumeric(@HSF_SESSION_USEROID) = 1
	SET @iUserOID = cast(@HSF_SESSION_USEROID AS INT)
ELSE
	SET @iUserOID = - 1

IF @pchReportUsage <> 3
	SET @vchReportUserName = isnull(dbo.fn_ORE_GetPersonName((
					SELECT Person_OID
					FROM HSUser WITH (NOLOCK)
					WHERE ObjectID = @iUserOID
					), 6), '')
ELSE
	SET @vchReportUserName = 'Job Scheduler'

--Table to hold parsed visit oids from incoming @ptxOrderTypeNames  parameter
--DECLARE @PVCHLOCATION VARCHAR(10)
--SET @pvchLocation = 'All'
DECLARE @tblLocation TABLE (Location VARCHAR(75))
INSERT INTO @tblLocation (Location)
SELECT *
FROM fn_GetStrParmTable(@pvchLocation)

--Pulling Patient and Visit Oids
DECLARE @PatientTable TABLE (
	PVisit_oid VARCHAR(10),
	Pat_oid VARCHAR(10)
	)

INSERT INTO @PatientTable (
	PVisit_oid,
	Pat_oid
	)
SELECT pv.objectid,
	pv.Patient_oid
FROM HPatientVisit pv WITH (NOLOCK)
WHERE (
		EXISTS (
			SELECT Location
			FROM @tblLocation t1
			WHERE t1.location = pv.PatientLocationName
			)
		OR @pvchLocation = 'All'
		)
	AND pv.VisitStatus IN (0, 4)
	AND pv.isdeleted = 0

--Table to hold Qualified Assessment IDs'  
DECLARE @AssessmentIDs TABLE (
	PatientOID INTEGER,
	PatientVisitOID INTEGER,
	AssessmentID INTEGER,
	CollectedDT SMALLDATETIME,
	RN INT
	)
INSERT INTO @AssessmentIDs
SELECT PatientOID = ha.Patient_OID,
	PatientVisitOID = ha.PatientVisit_OID,
	AssessmentID = ha.AssessmentID,
	CollectedDT = ha.EnteredDT,
	RN = ROW_NUMBER() OVER(PARTITION BY HA.PATIENT_OID ORDER BY HA.ENTEREDDT DESC)
FROM HAssessment ha WITH (NOLOCK)
INNER JOIN @PatientTable pt ON ha.Patient_oid = pt.pat_oid
	AND ha.PatientVisit_OID = pt.pvisit_oid
INNER JOIN HObservation ho WITH (NOLOCK) ON ha.assessmentid = ho.assessmentid
	AND ha.EnteredDT = (
		SELECT TOP 1 ha.EnteredDT
		FROM hassessment ha
		INNER JOIN HObservation ho WITH (NOLOCK) ON ha.assessmentid = ho.assessmentid
		WHERE ha.patient_oid = pt.pat_oid
			AND ha.patientvisit_oid = pt.pvisit_oid
			AND ho.FindingAbbr = 'A_BMH_MEWSScore'
			AND ha.assessmentstatuscode IN ('1', '3')
			AND ha.enddt IS NULL
			AND ho.EndDt IS NULL
		ORDER BY ha.EnteredDT DESC
		)

WHERE ha.EndDt IS NULL
	AND ho.EndDt IS NULL
	AND ho.FindingAbbr = 'A_BMH_MEWSScore'
	AND HA.FormUsageDisplayName = 'Vital Signs'
	AND ha.assessmentstatuscode IN ('1', '3')
ORDER BY ha.patient_oid,
	ha.EnteredDT DESC;

DELETE
FROM @AssessmentIDs
WHERE RN != 1;

--select * from @AssessmentIDs
DECLARE @tmpAssessment TABLE (
	Patientoid INT,
	PatientVisitoid INT,
	FormUsageName VARCHAR(100),
	FindingName VARCHAR(64),
	FindingAbbrName VARCHAR(16),
	CollectedDateTime SMALLDATETIME,
	CreationTime DATETIME,
	EnteredDateTime SMALLDATETIME,
	OBSValue TEXT,
	AssessmentStatus VARCHAR(35)
	)

INSERT INTO @tmpAssessment (
	Patientoid,
	PatientVisitoid,
	FormUsageName,
	FindingName,
	FindingAbbrName,
	CollectedDateTime,
	CreationTime,
	EnteredDateTime,
	OBSValue,
	AssessmentStatus
	)
SELECT ai.PatientOID,
	ai.PatientVisitOID,
	ha.FormUsage,
	ho.FindingName,
	ho.FindingAbbr,
	ha.CollectedDT,
	ha.CreationTime,
	ha.EnteredDT,
	ho.Value,
	ha.AssessmentStatus
FROM @AssessmentIDs AI
INNER JOIN HAssessment ha WITH (NOLOCK) ON ai.AssessmentID = ha.AssessmentID
INNER JOIN HObservation ho WITH (NOLOCK) ON ai.assessmentid = ho.assessmentid
	AND ho.EndDt IS NULL
	AND ha.enddt IS NULL
WHERE ho.Findingabbr = ('A_BMH_MEWSScore')
ORDER BY ai.Patientoid,
	ai.PatientVisitoid

---select * from @tmpAssessment ORDER BY PATIENTOID, EnteredDateTime DESC
DECLARE @PivotTable TABLE (
	patientoid VARCHAR(10),
	patientvisit_oid VARCHAR(10),
	MEWS_Score VARCHAR(255),
	CollectedDate DATETIME
	)

INSERT INTO @PivotTable (
	PatientOID,
	PatientVisit_OID
	)
SELECT DISTINCT PatientOID,
	PatientVisitoid
FROM @tmpAssessment

UPDATE @PivotTable
SET MEWS_Score = isnull(ta.OBSValue, '')
FROM @TmpAssessment ta,
	@PivotTable pt
WHERE FindingAbbrName = 'A_BMH_MEWSScore' --added
	AND ta.PatientOid = pt.Patientoid

-- @Patient TABLE
DECLARE @Patient TABLE (
	PatientName VARCHAR(184),
	PatientNumber VARCHAR(20),
	PatientAcctNum VARCHAR(20),
	MRNumber VARCHAR(20),
	BirthDate DATETIME,
	Sex VARCHAR(6),
	Age VARCHAR(20),
	Location VARCHAR(75),
	RoomBed VARCHAR(75),
	Allergies TEXT,
	AttendDr VARCHAR(184),
	AdmittingDiag VARCHAR(255),
	Height VARCHAR(40),
	Weight VARCHAR(40),
	EntityName VARCHAR(75),
	VisitStartDateTime DATETIME,
	VisitEndDateTime DATETIME,
	VisitTypeCode VARCHAR(30),
	VIP INT,
	AdmittingDr VARCHAR(184),
	ReferringDr VARCHAR(184),
	ReferringInstitution VARCHAR(75),
	VisitID VARCHAR(30),
	UnitContacted VARCHAR(75),
	ChiefComplaint VARCHAR(255),
	PatientOID INTEGER,
	PatientVisitOID INTEGER,
	EntityOID INTEGER
	)
-- First Create Dummy Records 
INSERT INTO @Patient
SELECT [PatientName] = '',
	[PatientNumber] = '',
	[PatientAcctNum] = '',
	[MRNumber] = '',
	[BirthDate] = NULL,
	[Sex] = '',
	[Age] = '',
	[Location] = '',
	[RoomBed] = '',
	[Allergies] = '',
	[AttendDr] = '',
	[AdmittingDiag] = '',
	[Height] = '',
	[Weight] = '',
	[EntityName] = '',
	[VisitStartDateTime] = NULL,
	[VisitEndDateTime] = NULL,
	[VisitTypeCode] = '',
	[VIP] = '',
	[AdmittingDr] = '',
	[ReferringDr] = '',
	[ReferringInstitution] = '',
	[VisitID] = '',
	[UnitContacted] = '',
	[ChiefComplaint] = '',
	[PatientOID] = - 1,
	[PatientVisitOID] = - 1,
	[EntityOID] = 0

INSERT INTO @Patient
SELECT
	--	       PatientName = isnull (pt.LastName + ' , ' + pt.FirstName + ' ' + isnull(substring(pt.MiddleName,1,1), ' '),''),
	PatientName = CASE ISNULL(pt.GenerationQualifier, '')
		WHEN ''
			THEN pt.LastName + ', ' + pt.FirstName + ' ' + ISNULL(SUBSTRING(pt.MiddleName, 1, 1), ' ')
		ELSE pt.LastName + ' ' + pt.GenerationQualifier + ', ' + pt.FirstName + ' ' + ISNULL(SUBSTRING(pt.MiddleName, 1, 1), ' ')
		END,
	PatientNumber = isnull(pt.InternalPatientID, ''),
	PatientAcctNum = isnull(pv.PatientAccountID, ''),
	MRNumber = isnull(.dbo.fn_ORE_GetExternalPatientID(pt.ObjectID, pv.entity_oid), ''),
	BirthDate = convert(VARCHAR(10), per.BirthDate, 101),
	Sex = cast(CASE per.Sex
			WHEN 0
				THEN 'M'
			WHEN 1
				THEN 'F'
			ELSE ' '
			END AS CHAR(6)),
	Age = (.dbo.fn_ORE_GetPatientAge(per.BirthDate, getdate())),
	Location = isnull(pv.PatientLocationName, ''),
	RoomBed = isnull(pv.LatestBedName, ''),
	--       Allergies = substring((.dbo.fn_ORE_GetPatientAllergies(pt.ObjectID)),1,255),
	Allergies = '', --isnull(dbo.Fn_ORE_GetPatientAllergies(pt.ObjectID),isnull(.dbo.fn_ORE_VisitAllergiesCheck(pt.ObjectID,pv.ObjectID),'')),
	AttendDr = '', --isnull(.dbo.fn_ORE_GetPhysicianName (pv.ObjectID,0,6),''),     
	AdmittingDiag = '', ---- isnull(.dbo.fn_ORE_GetPatientAdmitDx(pv.ObjectID),''),
	Height = '', ---isnull(.dbo.fn_ORE_GetPatientHt(pt.ObjectID),''),
	Weight = '', ---isnull(.dbo.fn_ORE_GetPatientWt(pt.ObjectID),''),
	EntityName = isnull(pv.EntityName, ''),
	VisitStartDateTime = pv.VisitStartDateTime,
	VisitEndDateTime = pv.VisitEndDateTime,
	VisitTypeCode = isnull(pv.VisitTypeCode, ''),
	VIP = pt.VIPIndicator,
	AdmittingDr = '', ---isnull(.dbo.fn_ORE_GetPhysicianName (pv.ObjectID,4,6),''), 
	ReferringDr = '', ---isnull(.dbo.fn_ORE_GetPhysicianName (pv.ObjectID,2,6),''),
	ReferringInstitution = isnull(ri.Name, ''),
	VisitID = isnull(pv.VisitID, ''),
	UnitContacted = isnull(pv.UnitContactedName, ''),
	ChiefComplaint = isnull(pv.PatientReasonForSeekingHC, ''),
	PatientOID = pt.ObjectID,
	PatientVisitOID = pv.ObjectID,
	EntityOID = pv.Entity_oid
FROM HPatientVisit pv WITH (NOLOCK)
INNER JOIN HPatient pt WITH (NOLOCK) ON pt.ObjectID = pv.Patient_OID
INNER JOIN HPerson per WITH (NOLOCK) ON pt.ObjectID = per.ObjectID
LEFT OUTER JOIN HReferringInstitution ri WITH (NOLOCK) ON pv.ReferringInstitution_oid = ri.ObjectID
INNER JOIN @AssessmentIDs t1 ON t1.PatientVisitOID = pv.ObjectID
	AND t1.patientoid = pv.patient_oid

-- delete the dummy record if we find a patient 
SET @iRecCount = (
		SELECT count(*)
		FROM @Patient
		)

IF @iRecCount > 1
BEGIN
	DELETE @Patient
	WHERE PatientOID = - 1
END

SELECT pt.patientoid,
	pt.patientvisit_oid,
	pt.MEWS_Score,
	AI.[CollectedDateTime],
	p.PatientName,
	p.PatientNumber,
	p.PatientAcctNum,
	p.MRNumber,
	p.Birthdate,
	p.Sex,
	p.Height,
	p.[Weight],
	p.Age,
	p.Location,
	p.RoomBed,
	p.VisitStartDateTime,
	p.ChiefComplaint,
	UserName = @vchReportUserName
FROM @PivotTable pt
INNER JOIN @Patient p ON pt.patientoid = p.patientoid
	AND pt.patientvisit_oid = p.patientvisitoid
OUTER APPLY (
	SELECT TOP 1 AI.CollectedDT AS CollectedDateTime
	FROM @AssessmentIDs AS AI
	WHERE pt.patientoid = ai.PatientOID
		AND pt.patientvisit_oid = ai.PatientVisitOID
	) AS ai
ORDER BY pt.patientoid

;
USE [Soarian_Clin_Tst_1]
GO
/****** Object:  StoredProcedure [dbo].[ORE_BMH_FallRisk_SPS]    Script Date: 9/4/2020 8:45:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
***********************************************************************
File: ORE_BMH_FallRisk_SPS.sql

Input  Parameters:   
    @pvchLocation - as Location used to identify which Nurse Station the report should be run for.  
    @HSF_SESSION_USEROID - Used to get user name of user who printed the report
    @pchReportUsage - Used to indicate how the report is being run
        1 = Context Senstive (CSP)
        2 = Operational Reporting (OPR)
        3 = Job Scheduler (JS)
        4 = Event Driven Routing (EDR)  
        5 = Modal Print - From Patient Record 

Tables/Views:
	HAssessment
	HObservation
	HPatientVisit
	HPatient
	HPerson
	HReferringInstitution

Creates Table:
	None

Functions:
	fn_GetStrParmTable

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Returns the most recent assessment that has fall risk data charted

Revision History:
Date		Version		Description
----		----		----
2020-01-27	v1			Initial Creation
2020-09-04	v2			Modify BMAT section to have the following:
							A_BMH_FailLev1
							A_BMH_Levl1Equip
							A_BMH_PassLevel1
							A_BMH_FailLev2
							A_BMH_Levl2Equip
							A_BMH_PassLevel2
							A_BMH_FailLev3
							A_BMH_Levl3Equip
							A_BMH_PassLevel3
							A_BMH_FailLev4
							A_BMH_Levl4Equip
							A_BMH_PassLevel4
***********************************************************************
*/

ALTER PROCEDURE [dbo].[ORE_BMH_FallRisk_SPS] @pvchLocation VARCHAR(2000) = NULL,
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

/*
BMAT DATA
*/
DECLARE @BMAT_TBL TABLE (
	Patient_OID INT
	, PatientVisit_OID INT
	, EnteredDT DATETIME
	, Fail_Level1  VARCHAR(500)
	, Equip_Level1 VARCHAR(500)
	, Pass_Level1  VARCHAR(500)
	, Fail_Level2  VARCHAR(500)
	, Equip_Level2 VARCHAR(500)
	, Pass_Level2  VARCHAR(500)
	, Fail_Level3  VARCHAR(500)
	, Equip_Level3 VARCHAR(500)
	, Pass_Level3  VARCHAR(500)
	, Fail_Level4  VARCHAR(500)
	, Equip_Level4 VARCHAR(500)
	, Pass_Level4  VARCHAR(500)
)

INSERT INTO @BMAT_TBL
SELECT PVT.Patient_oid
, PVT.PatientVisit_oid
, PVT.EnteredDT
, PVT.A_BMH_FailLev1
, PVT.A_BMH_Levl1Equip
, PVT.A_BMH_PassLevel1
, PVT.A_BMH_FailLev2
, PVT.A_BMH_Levl2Equip
, PVT.A_BMH_PassLevel2
, PVT.A_BMH_FailLev3
, PVT.A_BMH_Levl3Equip
, PVT.A_BMH_PassLevel3
, PVT.A_BMH_FailLev4
, PVT.A_BMH_Levl4Equip
, PVT.A_BMH_PassLevel4
FROM (
	SELECT ha.Patient_oid
	, HA.PatientVisit_oid
	, HA.EnteredDT
	, HO.FindingAbbr
	, HO.Value
	, HA.FormUsageDisplayName
	FROM HAssessment AS ha WITH (NOLOCK)
	INNER JOIN HObservation AS ho WITH (NOLOCK) ON ha.assessmentid = ho.assessmentid
	WHERE HA.EndDT IS NULL
	AND HO.EndDT IS NULL
	AND HA.AssessmentStatusCode IN ('1', '3')
	AND HO.FindingAbbr IN (
		'A_BMH_FailLev1',
		'A_BMH_Levl1Equip',
		'A_BMH_PassLevel1',
		'A_BMH_FailLev2',
		'A_BMH_Levl2Equip',
		'A_BMH_PassLevel2',
		'A_BMH_FailLev3',
		'A_BMH_Levl3Equip',
		'A_BMH_PassLevel3',
		'A_BMH_FailLev4',
		'A_BMH_Levl4Equip',
		'A_BMH_PassLevel4'
	)
	AND HA.FormUsageDisplayName = 'Admission'
) AS BMAT

PIVOT(
	MAX(Value)
	FOR FindingAbbr IN (
		"A_BMH_FailLev1","A_BMH_Levl1Equip","A_BMH_PassLevel1",
		"A_BMH_FailLev2","A_BMH_Levl2Equip","A_BMH_PassLevel2",
		"A_BMH_FailLev3","A_BMH_Levl3Equip","A_BMH_PassLevel3",
		"A_BMH_FailLev4","A_BMH_Levl4Equip","A_BMH_PassLevel4"
	)
) AS PVT

--*************************************************************************************************  
-- Temp Tables declaration for Assessments Report --  
--*************************************************************************************************  
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
-- temp table to hold vitals info   
--declare @tmpAssessment table   
--Declare @TempDisplayGrp table(FindingName	varchar(20)) 
--Table to hold parsed visit oids from incoming @ptxOrderTypeNames  parameter
DECLARE @tblLocation TABLE (Location VARCHAR(75))
--Table to hold parsed form usage names from incoming @pvcFormUsageName parameter  
DECLARE @tblFormUsageName TABLE (FormUsageName VARCHAR(100))
--Table to hold parsed order status' from incoming @pchAssmtStatus parameter  
DECLARE @tblAssmntStatus TABLE (AssmntStatus INT)
-- Table to hold Chapter Information --   
DECLARE @FindingSort TABLE (
	Assessmentid INT,
	ParentFormusageName VARCHAR(255),
	ChapterName VARCHAR(255),
	ChapterSequence INT,
	FindingAbbrName VARCHAR(64),
	DisplaySequence INT
	)
--Table to hold Qualified Assessment IDs'  
DECLARE @AssessmentIDs TABLE (
	PatientOID INTEGER,
	PatientVisitOID INTEGER,
	AssessmentID INTEGER,
	CollectedDT SMALLDATETIME
	)

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

INSERT INTO @AssessmentIDs
SELECT PatientOID = ha.Patient_OID,
	PatientVisitOID = ha.PatientVisit_OID,
	AssessmentID = ha.AssessmentID,
	CollectedDT = ha.EnteredDT
FROM HAssessment ha WITH (NOLOCK)
INNER JOIN HObservation ho WITH (NOLOCK) ON ha.assessmentid = ho.assessmentid
INNER JOIN @PatientTable pt ON ha.Patient_oid = pt.pat_oid
	AND ha.PatientVisit_OID = pt.pvisit_oid
	AND ha.EnteredDT = (
		SELECT TOP 1 ha.EnteredDT
		FROM hassessment ha
		INNER JOIN HObservation ho WITH (NOLOCK) ON ha.assessmentid = ho.assessmentid
		WHERE ha.patient_oid = pt.pat_oid
			AND ha.patientvisit_oid = pt.pvisit_oid
			AND ho.FindingAbbr = 'A_MorseFallRisk' --added 'A_MorseFallRisk'
			AND ha.assessmentstatuscode IN ('1', '3')
			AND ha.enddt IS NULL
			AND ho.EndDt IS NULL
		ORDER BY ha.EnteredDT DESC
		)
WHERE ha.EndDt IS NULL
	AND ho.EndDt IS NULL
	AND ho.FindingAbbr = 'A_MorseFallRisk' --added 'A_MorseFallRisk'
	AND ha.assessmentstatuscode IN ('1', '3')
ORDER BY ha.patient_oid,
	ha.EnteredDT DESC

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
WHERE --ho.Findingabbr = ('A_Fall Risk')
	ho.Findingabbr = ('A_Fall Risk Cmnt')
	OR ho.Findingabbr = ('A_MorseFallRisk') --added
ORDER BY ai.Patientoid,
	ai.PatientVisitoid

--select * from @tmpAssessment
DECLARE @PivotTable TABLE (
	patientoid VARCHAR(10),
	patientvisit_oid VARCHAR(10),
	FallRisk VARCHAR(255),
	FallRiskComments VARCHAR(255),
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
SET FallRisk = isnull(ta.OBSValue, '')
FROM @TmpAssessment ta,
	@PivotTable pt
WHERE FindingAbbrName = 'A_MorseFallRisk' --added
	AND ta.PatientOid = pt.Patientoid

UPDATE @PivotTable
SET FallRiskComments = isnull(ta.OBSValue, '')
FROM @TmpAssessment ta,
	@PivotTable pt
WHERE FindingAbbrName = 'A_Fall Risk Cmnt'
	AND ta.PatientOid = pt.Patientoid

------------- Collected Date
UPDATE @PivotTable
SET CollectedDate = ta.CollectedDateTime
FROM @TmpAssessment ta,
	@PivotTable pt
WHERE FindingAbbrName = 'A_MorseFallRisk' --added
	AND ta.PatientOid = pt.Patientoid

-- First Create Dummy Records 
INSERT INTO @Patient
SELECT PatientName = '',
	PatientNumber = '',
	PatientAcctNum = '',
	MRNumber = '',
	BirthDate = NULL,
	Sex = '',
	Age = '',
	Location = '',
	RoomBed = '',
	Allergies = '',
	AttendDr = '',
	AdmittingDiag = '',
	Height = '',
	Weight = '',
	EntityName = '',
	VisitStartDateTime = NULL,
	VisitEndDateTime = NULL,
	VisitTypeCode = '',
	VIP = '',
	AdmittingDr = '',
	ReferringDr = '',
	ReferringInstitution = '',
	VisitID = '',
	UnitContacted = '',
	ChiefComplaint = '',
	PatientOID = - 1,
	PatientVisitOID = - 1,
	EntityOID = 0

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
FROM HPatientVisit pv with(nolock)
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
	pt.FallRisk,
	pt.FallRiskComments,
	pt.CollectedDate,
	p.PatientName,
	p.PatientNumber,
	p.PatientAcctNum,
	p.MRNumber,
	p.Birthdate,
	p.Sex,
	p.Height,
	p.Weight,
	p.Age,
	p.Location,
	p.RoomBed,
	p.VisitStartDateTime,
	p.ChiefComplaint,
	UserName = @vchReportUserName,
	BMAT.EnteredDT,
	BMAT.Fail_Level1,
	BMAT.Equip_Level1,
	BMAT.Pass_Level1,
	BMAT.Fail_Level2,
	BMAT.Equip_Level2,
	BMAT.Pass_Level2,
	BMAT.Fail_Level3,
	BMAT.Equip_Level3,
	BMAT.Pass_Level3,
	BMAT.Fail_Level4,
	BMAT.Equip_Level4,
	BMAT.Pass_Level4

FROM @PivotTable pt
INNER JOIN @Patient p ON pt.patientoid = p.patientoid
	AND pt.patientvisit_oid = p.patientvisitoid
LEFT OUTER JOIN @BMAT_TBL AS BMAT ON PT.patientoid = BMAT.Patient_OID
	AND PT.patientvisit_oid = BMAT.PatientVisit_OID
ORDER BY pt.patientoid







USE [Soarian_Clin_Tst_1]
GO
/****** Object:  StoredProcedure [dbo].[ORE_BH_PatientHlthConcernsGoals]    Script Date: 6/29/2018 1:04:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




--------------------------------------------------------------------------------
--
--	 File : ORE_BH_PhysicianDischInstPrc.sql
--
--	 Parameters : 
--	 	 @HSF_CONTEXT_PATIENTID	 - Patient ID  
--	 	 @VisitOID             	 - Visit ID  
--------------------------------------------------------------------------------
--	 Copyright 2014 Siemens
--	 This program is proprietary to Siemens AND may be used only
--	 as authorized in a license agreement controlling such use.
--------------------------------------------------------------------------------
--	 Purpose: 
--
--	 Tables: 
--	 Views: 
--	 Functions: 
--
--	 Revision History: 
--	 Date         Author             Description
--	 ----         ------             -----------
--	 04/29/2014	 Auto CRGen 1.0	 	 New Procedure
--------------------------------------------------------------------------------
ALTER PROCEDURE [dbo].[ORE_BH_PatientHlthConcernsGoals]
	 @HSF_CONTEXT_PATIENTID    VARCHAR(20) = null,
	 @VisitOID                 VARCHAR(20) = null
	 --@AssessmentID				INT = null
AS 
BEGIN
DECLARE @iPatientOID	int,
	    @iVisitOID		int,
	    @AssessmentID   int
	     

DECLARE @tblPatientOID table (
	 	 PatientOID    int, 
	 	 VisitOID      int 
	)

DECLARE @tblFormUsageNames table (
	 	 FormUsageNames  VARCHAR(75)
	)

DECLARE @assessmentObsValueTbl table ( 
	PatientOID int,
	PatientVisitOID int,
	CollectedDate smalldatetime,  
	CollectedTime VARCHAR(MAX),  
	ScheduledDateTime smalldatetime,  
	EnteredBy VARCHAR(MAX),  
	Status VARCHAR(MAX)  ,
	FormUsageDisplayName VARCHAR(MAX),
	AssessmentID int,
	FindingAbbr VARCHAR(MAX),
	FindingName VARCHAR(MAX),
	[Value] VARCHAR(MAX)
	)

	IF isnumeric(@HSF_CONTEXT_PATIENTID) = 1
		SET @iPatientOID = cast(@HSF_CONTEXT_PATIENTID as int)
	ELSE
		SET @iPatientOID = -1
	IF isnumeric(@VisitOID) = 1
		SET @iVisitOID = cast(@VisitOID as int)
	ELSE
		SET @iVisitOID = -1

INSERT INTO @tblFormUsageNames (FormUsageNames)
SELECT DISTINCT * 
FROM fn_GetStrParmTable('Physician Discharge Instructions')
	 	 
SET @AssessmentID = (
	SELECT top 1 a.AssessmentID  
	FROM HAssessment a 
	WHERE a.Patient_oid = @HSF_CONTEXT_PATIENTID 
	AND a.PatientVisit_oid = @VisitOID  
	AND A.FormUsageDisplayName ='Physician Discharge Instructions' 
) 	  	 

Declare @Assessment_oid VARCHAR(100)

SELECT top 1 @Assessment_oid = hac.assessment_oid 
, @AssessmentID = ha.AssessmentID

FROM HAssessment ha
INNER JOIN  HAssessmentCategory hac
ON ha.AssessmentID = hac.AssessmentID
	AND ha.Patient_oid = @HSF_CONTEXT_PATIENTID
	AND ha.PatientVisit_oid = @VisitOID

WHERE ha.FormUsageDisplayName ='Physician Discharge Instructions'
AND hac.FormUsageDisplayName IN ('Physician Discharge Instructions')
AND hac.CategoryStatus NOT IN ( 0, 3 )
AND hac.IsLatest = 1
AND hac.FormVersion IS NOT NULL
AND ha.AssessmentStatus = 'Complete'

ORDER BY hac.FormDateTime DESC
;
   
INSERT INTO @assessmentObsValueTbl 

SELECT PatientOID = ha.Patient_OID
, PatientVisitOID  = ha.PatientVisit_OID
, CollectedDate  = cast(ha.collecteddt as datetime)
, CollectedTime  = cast(ha.collecteddt as datetime)
, ScheduledDateTime  = ha.ScheduledDT
, EnteredBy  = ha.UserAbbrName
, Status  = ha.AssessmentStatus
, FormUsageDisplayName = ha.FormUsageDisplayName
, AssessmentID = ha.AssessmentID
, FindingAbbr = ho.FindingAbbr
, FindingName = ho.FindingName
, Value		= ho.Value

FROM Hassessment ha with (nolock)
INNER JOIN HObservation Ho WITH (nolock)
ON Ho.Patient_oid = ha.Patient_oid
	AND Ho.AssessmentID = ha.AssessmentID
	
WHERE ha.Patient_OID = @iPatientOID
AND ha.PatientVisit_oid = @iVisitOID
AND ha.assessmentid = @AssessmentID
AND ho.EndDt is null
AND ha.EndDT is null
;

DECLARE @pivotObsValues table (
	PatientOID int
	, PatientVisitOID int
	, [Asmt.CollectedDate] smalldatetime
	, [Asmt.CollectedTime] VARCHAR(MAX)
	, [Asmt.ScheduledDateTime] smalldatetime
	, [Asmt.EnteredBy] VARCHAR(MAX)
	, [Asmt.Status] VARCHAR(MAX)
	, [A_Activity] VARCHAR(MAX)
	, [A_Discharge Date] VARCHAR(MAX)
	, [A_Driving] VARCHAR(MAX)
	, [A_OSActInstruct] VARCHAR(MAX)
	, [A_OSBathing] VARCHAR(MAX)
	, [A_OSDfWndCar] VARCHAR(MAX)
	, [A_OSDietInstruc] VARCHAR(MAX)
	, [A_OSIVSI] VARCHAR(MAX)
	, [A_OSLifting] VARCHAR(MAX)
	, [A_OSMedRefDt] VARCHAR(MAX)
	, [A_OSMedRefDt2] VARCHAR(MAX)
	, [A_OSMedRefDt3] VARCHAR(MAX)
	, [A_OSMedRefWho] VARCHAR(MAX)
	, [A_OSMedRefWho3] VARCHAR(MAX)
	, [A_OSMedRefWith2] VARCHAR(MAX)
	, [A_OSSpecDiet] VARCHAR(MAX)
	, [A_OSSpecInst] VARCHAR(MAX)
	, [A_OSWork] VARCHAR(MAX)
	, [A_Stairs] VARCHAR(MAX)
	, [A_ToCReferCmplt] VARCHAR(MAX)
	, [A_Wound Care] VARCHAR(MAX)
	, [J_ChgDress] VARCHAR(MAX)
	, [J_ChgPack] VARCHAR(MAX)
	, [A_OSRefNote] VARCHAR(MAX)
	, [PA_Diagnosis] VARCHAR(MAX)
	, [J_FollowUpAttned] VARCHAR(MAX)
	, [Site1] VARCHAR(MAX)
	, [Instructions1] VARCHAR(MAX)
	, [Site2] VARCHAR(MAX)
	, [Instructions2] VARCHAR(MAX)
	, [Site3] VARCHAR(MAX)
	, [Instructions3] VARCHAR(MAX)
	, [SpecialInstructions] VARCHAR(MAX)
	, [OtherInstructions] VARCHAR(MAX)
	, [Alcohol] VARCHAR(MAX)
	, [Sex] VARCHAR(MAX)
	, [ChangeBandage] VARCHAR(MAX)
	, [A_OSNotifyMD] VARCHAR(MAX)

)

INSERT INTO @pivotObsValues

SELECT t1.PatientOID
, t1.PatientVisitOID
, t1.CollectedDate
, t1.collectedtime
, t1.ScheduledDateTime
, t1.EnteredBy,t1.status
, 'A_Activity' = MAX(CASE 
	WHEN t1.FindingAbbr = 'A_Activity' 
		THEN REPLACE(t1.value,CHAR(30),CHAR(44)) 
		ELSE '' 
	END)
, 'A_Discharge Date' = MAX(CASE 
	WHEN t1.FindingAbbr = 'A_Discharge Date' 
		THEN REPLACE(t1.value,CHAR(30),CHAR(44)) 
		ELSE '' 
	END)
, 'A_Driving' = MAX(CASE 
	WHEN t1.FindingAbbr = 'A_Driving' 
		THEN REPLACE(t1.value,CHAR(30),CHAR(44)) 
		ELSE '' 
	END)
, 'A_OSActInstruct' = MAX(CASE 
	WHEN t1.FindingAbbr = 'A_OSActInstruct' 
		THEN REPLACE(t1.value,CHAR(30),CHAR(44)) 
		ELSE '' 
	END)
, 'A_OSBathing' = MAX(CASE 
	WHEN t1.FindingAbbr = 'A_OSBathing' 
		THEN REPLACE(t1.value,CHAR(30),CHAR(44)) 
		ELSE '' 
	END)
, 'A_OSDfWndCar' = MAX(CASE 
	WHEN t1.FindingAbbr = 'A_OSDfWndCar' 
		THEN Convert(datetime,(REPLACE(t1.value,CHAR(30),CHAR(44))),120) 
		ELSE '' 
	END)
, 'A_OSDietInstruc' = MAX(CASE 
	WHEN t1.FindingAbbr = 'A_OSDietInstruc' 
		THEN REPLACE(t1.value,CHAR(30),CHAR(44)) 
		ELSE '' 
	END)
, 'A_OSIVSI' = MAX(CASE 
	WHEN t1.FindingAbbr = 'A_OSIVSI' 
		THEN REPLACE(t1.value,CHAR(30),CHAR(44)) 
		ELSE '' 
	END)
, 'A_OSLifting' = MAX(CASE 
	WHEN t1.FindingAbbr = 'A_OSLifting' 
		THEN REPLACE(t1.value,CHAR(30),CHAR(44)) 
		ELSE '' 
	END)
, 'A_OSMedRefDt' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSMedRefDt' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'A_OSMedRefDt2' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSMedRefDt2' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'A_OSMedRefDt3' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSMedRefDt3' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'A_OSMedRefWho' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSMedRefWho' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'A_OSMedRefWho3' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSMedRefWho3' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'A_OSMedRefWith2' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSMedRefWith2' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'A_OSSpecDiet' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSSpecDiet' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'A_OSSpecInst' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSSpecInst' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'A_OSWork' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSWork' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'A_Stairs' = MAX(CASE WHEN t1.FindingAbbr = 'A_Stairs' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'A_ToCReferCmplt' = MAX(CASE WHEN t1.FindingAbbr = 'A_ToCReferCmplt' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'A_Wound Care' = MAX(CASE WHEN t1.FindingAbbr = 'A_Wound Care' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'J_ChgDress' = MAX(CASE WHEN t1.FindingAbbr = 'J_ChgDress' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'J_ChgPack' = MAX(CASE WHEN t1.FindingAbbr = 'J_ChgPack' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'A_OSRefNote' = MAX(CASE WHEN t1.FindingAbbr = 'J_OSRefNote1' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'PA_Diagnosis' = MAX(CASE WHEN t1.FindingAbbr = 'PA_Diagnosis' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'J_FollowUpAttned' = MAX(CASE WHEN t1.FindingAbbr = 'J_FollowUpAttned' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'Site1' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSSteCre1' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'Instructions2' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSSteCarIns1' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'Site2' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSSteCre2' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'Instructions2' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSSteCarIns2' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'Site3' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSSteCre3' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'Instructions3' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSSteCarIns3' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'SpecialInstructions' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSIVSI' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'OtherInstructions' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSOSecIns' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'Alcohol' = MAX(CASE WHEN t1.FindingAbbr = 'A_BMH_Alcohol' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'Sex' = MAX(CASE WHEN t1.FindingAbbr = 'A_BMH_SexActivit' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'ChangeBandage' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSChgeBndge' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)
, 'A_OSNotifyMD' = MAX(CASE WHEN t1.FindingAbbr = 'A_OSNotifyMD' THEN REPLACE(t1.value,CHAR(30),CHAR(44)) ELSE '' END)

FROM @assessmentObsValueTbl t1 

GROUP BY t1.PatientOID
, t1.PatientVisitOID
, t1.CollectedDate
, t1.collectedtime
, t1.ScheduledDateTime
, t1.EnteredBy,t1.Status
;

SELECT  tov.*

FROM @pivotObsValues tov

WHERE tov.PatientOID = @iPatientOID 
AND tov.PatientVisitOID = @ivisitoid

END
;
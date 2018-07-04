USE [Soarian_Clin_Tst_1]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
--------------------------------------------------------------------------------

File : ORE_BH_PatientHlthConcernsGoals.sql

Parameters : 
	@HSF_CONTEXT_PATIENTID	 - Patient ID  
	@VisitOID             	 - Visit ID  
--------------------------------------------------------------------------------
Purpose: Get data for Patient Discharge Plan/Instructions form. New Section
	PATIENT HEALTH CONCERNS AND GOALS

Tables: HAssessment, HAssessmentCategory, HObservation
Views: None
Functions: None
	
Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle
	
Purpose:
	Get Helath Concern:
		A_BMH_DCHlthCncn
	Get Other Health Concern
		, 'A_BMH_DCGoal1'
		, 'A_BMH_DCGoal2'
		, 'A_BMH_DCGoal3'
		, 'A_BMH_DCGoal4'
		, 'A_BMH_DCGoal5'
		, 'A_BMH_DCGoal6'
		, 'A_BMH_DCGoal7'
		, 'A_BMH_DCGoal8'
		, 'A_BMH_DCGoal9'
		, 'A_BMH_DCGoal10'
		, 'A_BMH_DCGoal11'
		, 'A_BMH_DCGoal12'
		, 'A_BMH_DCGoal'
	Get Other Goal
		A_BMH_DCOthrGoal
	
Revision History: 
Date		Version		Description
----		----		----
2018-07-02	v1			Initial Creation
--------------------------------------------------------------------------------
*/
ALTER PROCEDURE [dbo].[ORE_BH_PatientHlthConcernsGoals]
	@HSF_CONTEXT_PATIENTID VARCHAR(20) = NULL,
	@VisitOID VARCHAR(20) = NULL
AS

BEGIN

	DECLARE @iPatientOID INT;
	DECLARE @iVisitOID INT;
	DECLARE @AssessmentID INT;

	--SET @iPatientOID = '2131342';
	--SET @iVisitOID = '152496';

	DECLARE @tblPatientOID TABLE (
		PatientOID INT
		, VisitOID INT
	)

	DECLARE @AssessmentObsValueTbl TABLE (
		PatientOID INT
		, PatientVisitOID INT
		, CollectedDate SMALLDATETIME
		, CollectedTime VARCHAR(MAX)
		, ScheduledDateTime SMALLDATETIME
		, EnteredBy VARCHAR(MAX)
		, [Status] VARCHAR(MAX)
		, FormUsageDisplayName VARCHAR(MAX)
		, AssessmentID INT
		, FindingAbbr VARCHAR(MAX)
		, FindingName VARCHAR(MAX)
		, [Value] VARCHAR(MAX)
	)

	IF ISNUMERIC(@HSF_CONTEXT_PATIENTID) = 1
		SET @iPatientOID = CAST(@HSF_CONTEXT_PATIENTID AS INT)
	ELSE
		SET @iPatientOID = -1
	IF ISNUMERIC(@VisitOID) = 1
		SET @iVisitOID = CAST(@VisitOID AS INT)
	ELSE
		SET @iVisitOID = -1

	SET @AssessmentID = (
		SELECT TOP 1 A.AssessmentID
		FROM HAssessment AS A
		WHERE A.Patient_oid = @HSF_CONTEXT_PATIENTID
		AND A.PatientVisit_oid = @VisitOID
		AND A.FormUsageDisplayName = 'Nursing Discharge Assessment'
	)

	-- GETS THAT LATEST COMPLETED ASSESSMENT_OID AND ASSESSMENTID
	DECLARE @Assessment_OID VARCHAR(100)

	SELECT TOP 1 @Assessment_OID = HAC.ASSESSMENT_OID
	, @AssessmentID = HA.AssessmentID

	FROM HAssessment AS HA
	INNER JOIN HAssessmentCategory AS HAC
	ON HA.AssessmentID = HAC.AssessmentID
		AND HA.Patient_oid = @HSF_CONTEXT_PATIENTID
		AND HA.PatientVisit_oid = @VisitOID

	WHERE HA.FormUsageDisplayName = 'Nursing Discharge Assessment'
	AND HAC.FormUsageDisplayName = 'Nursing Discharge Assessment'
	AND HAC.CategoryStatus NOT IN (0, 3)
	AND HAC.IsLatest = 1
	AND HAC.FormVersion IS NOT NULL
	AND HA.AssessmentStatus = 'Complete'

	ORDER BY HAC.FormDateTime DESC
	;

	INSERT INTO @AssessmentObsValueTbl

	SELECT PatientOID = ha.Patient_oid
	, PatientVisitOID = ha.PatientVisit_OID
	, CollectedDate = CAST(ha.collecteddt AS datetime)
	, CollectedTime = CAST(ha.collecteddt AS datetime)
	, ScheduledDateTime = ha.ScheduledDT
	, EnteredBy = ha.UserAbbrName
	, [Status] = ha.AssessmentStatus
	, FormUsageDisplayName = ha.FormUsageDisplayName
	, AssessmentID = ha.AssessmentID
	, FindingAbbr = ho.FindingAbbr
	, FindingName = ho.FindingName
	, [Value] = ho.Value

	FROM HAssessment AS HA WITH (NOLOCK)
	INNER JOIN HObservation AS HO WITH (NOLOCK)
	ON HO.Patient_oid = HA.Patient_oid
		AND HO.AssessmentID = HA.AssessmentID

	WHERE HA.Patient_oid = @iPatientOID
	AND HA.PatientVisit_oid = @iVisitOID
	AND HA.AssessmentID = @AssessmentID
	AND HO.EndDT IS NULL
	AND HA.EndDT IS NULL
	AND HO.FindingAbbr IN (
		'A_BMH_DCHlthCncn'
		, 'A_BMH_DCOtherHC'
		, 'A_BMH_DCGoal1'
		, 'A_BMH_DCGoal2'
		, 'A_BMH_DCGoal3'
		, 'A_BMH_DCGoal4'
		, 'A_BMH_DCGoal5'
		, 'A_BMH_DCGoal6'
		, 'A_BMH_DCGoal7'
		, 'A_BMH_DCGoal8'
		, 'A_BMH_DCGoal9'
		, 'A_BMH_DCGoal10'
		, 'A_BMH_DCGoal11'
		, 'A_BMH_DCGoal12'
		, 'A_BMH_DCGoal'
		, 'A_BMH_DCOthrGoal'
	)
	;

	DECLARE @PivotObsValues TABLE (
		PatientOID int
		, PatientVisitOID int
		, [Asmt.CollectedDate] smalldatetime
		, [Asmt.CollectedTime] VARCHAR(MAX)
		, [Asmt.ScheduledDateTime] smalldatetime
		, [Asmt.EnteredBy] VARCHAR(MAX)
		, [Asmt.Status] VARCHAR(MAX)
		, [A_BMH_DCHlthCncn] VARCHAR(MAX)
		, [A_BMH_DCOtherHC] VARCHAR(MAX)
		, [A_BMH_DCGoal1] VARCHAR(MAX)
		, [A_BMH_DCGoal2] VARCHAR(MAX)
		, [A_BMH_DCGoal3] VARCHAR(MAX)
		, [A_BMH_DCGoal4] VARCHAR(MAX)
		, [A_BMH_DCGoal5] VARCHAR(MAX)
		, [A_BMH_DCGoal6] VARCHAR(MAX)
		, [A_BMH_DCGoal7] VARCHAR(MAX)
		, [A_BMH_DCGoal8] VARCHAR(MAX)
		, [A_BMH_DCGoal9] VARCHAR(MAX)
		, [A_BMH_DCGoal10] VARCHAR(MAX)
		, [A_BMH_DCGoal11] VARCHAR(MAX)
		, [A_BMH_DCGoal12] VARCHAR(MAX)
		, [A_BMH_DCGoal] VARCHAR(MAX)
		, [A_BMH_DCOthrGoal] VARCHAR(MAX)

	)

	INSERT INTO @PivotObsValues
	
	SELECT T1.PatientOID
	, T1.PatientVisitOID
	, T1.CollectedDate
	, T1.CollectedTime
	, T1.ScheduledDateTime
	, T1.EnteredBy
	, T1.[Status]
	, 'A_BMH_DCHlthCncn' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCHlthCncn'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCOtherHC' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCOtherHC'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCGoal1' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCGoal1'
				THEN REPLACE(T1.[VALUE], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCGoal2' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCGoal2'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCGoal3' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCGoal3'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCGoal4' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCGoal4'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCGoal5' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCGoal5'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCGoal6' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCGoal6'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCGoal7' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCGoal7'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCGoal8' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCGoal8'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCGoal9' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCGoal9'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCGoal10' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCGoal10'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCGoal11' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCGoal11'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCGoal12' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCGoal12'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCGoal' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCGoal'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)
	, 'A_BMH_DCOthrGoal' = MAX(
		CASE
			WHEN T1.FindingAbbr = 'A_BMH_DCOthrGoal'
				THEN REPLACE(T1.[Value], CHAR(30), CHAR(44))
				ELSE ''
			END
		)

	FROM @AssessmentObsValueTbl AS T1

	GROUP BY T1.PatientOID
	, T1.PatientVisitOID
	, T1.CollectedDate
	, T1.CollectedTime
	, T1.ScheduledDateTime
	, T1.EnteredBy
	, T1.[Status]
	;

	SELECT TOV.*

	FROM @PivotObsValues AS TOV

	WHERE TOV.PatientOID = @iPatientOID
	AND TOV.PatientVisitOID = @iVisitOID

END
;

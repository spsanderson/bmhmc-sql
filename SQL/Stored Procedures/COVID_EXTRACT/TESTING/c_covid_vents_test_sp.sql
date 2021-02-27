USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_vents_test_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit HPatientVisit
	[SC_server].[Soarian_Clin_Prd_1].DBO.hobservation ho 
	[SC_server].[Soarian_Clin_Prd_1].DBO.hassessment ha

Creates Table:
	smsdss.c_covid_vents_test_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get current vent information from the Ventilator Flowsheet Form
	for last 12 hours

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
2021-02-25  v2          Rewrite for new stream testing
***********************************************************************
*/
 
CREATE PROCEDURE [dbo].[c_covid_vents_test_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Create a new table called 'c_covid_vents_test_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_vents_test_tbl', 'U') IS NOT NULL
	DROP TABLE smsdss.c_covid_vents_test_tbl;

	DECLARE @dtEndDate AS DATETIME;
	DECLARE @dtStartDate AS DATETIME;
	-- Table Variable declaration area  
	--  
	DECLARE @CensusVisitOIDs TABLE (
		VisitOID INT,
		PatientOID INT,
		PatientAccountID VARCHAR(20)
		)
	-- Table to vent assessments  
	DECLARE @VentAssessments TABLE (
		id_num INT IDENTITY(1, 1),
		AssessmentID INTEGER,
		CollectedDT DATETIME,
		PatientVisitOID INTEGER
		)
	DECLARE @VentPatients TABLE (PatientVisit_oid INT)

	SET @dtEndDate = getdate()
	SET @dtStartDate = DATEADD(HOUR, - 12, @dtEndDate)

	INSERT INTO @CensusVisitOIDs
	SELECT DISTINCT HPatientVisit.ObjectID,
		HPatientVisit.Patient_OID,
		HPatientVisit.PatientAccountID
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit HPatientVisit WITH (NOLOCK)
	WHERE HPatientVisit.IsDeleted = 0
		AND HpatientVisit.VisitStatus IN (0, 4)

	----------------------------------------------------------------------------------------  
	-- Get all the assessments within the last 12 hours that contain  
	-- A_BMH_VFMode NO LONGER A_02 Del Method and sort them by Collected Date.    
	INSERT INTO @VentAssessments (
		AssessmentID,
		CollectedDT,
		PatientVisitOID
		)
	SELECT ha.AssessmentID,
		ha.CollectedDT,
		cv.VisitOID
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.hobservation ho WITH (NOLOCK)
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.hassessment ha WITH (NOLOCK) ON ho.assessmentid = ha.assessmentid
	INNER JOIN @CensusVisitOIDs cv ON ha.PatientVisit_OID = cv.VisitOID
		AND ha.Patient_OID = cv.PatientOID -- Performance Improvement
	WHERE HA.FormUsage IN ('Ventilator Flow Sheet')
		AND ha.AssessmentStatusCode IN (1, 3)
		AND ho.EndDT IS NULL
		AND ha.EndDt IS NULL
		AND CollectedDT BETWEEN @dtStartDate
			AND @dtEndDate
	ORDER BY VisitOID,
		CollectedDT DESC

	--Delete everything but the last assessment for each location, patient  
	DELETE
	FROM @VentAssessments
	WHERE id_num NOT IN (
			SELECT MIN(id_num)
			FROM @VentAssessments
			GROUP BY PatientVisitOID
			)

	INSERT INTO @VentPatients
	SELECT DISTINCT va.PatientVisitOID
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.hobservation ho WITH (NOLOCK)
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.hassessment ha WITH (NOLOCK) ON ho.assessmentid = ha.assessmentid
	INNER JOIN @VentAssessments va ON ha.PatientVisit_OID = va.PatientVisitOID
		AND ha.AssessmentID = va.AssessmentID
	WHERE FindingAbbr IN ('A_BMH_VFMode')
		AND value NOT IN ('Non invasive mode (BiPAP/CPAP)', 'CPAP')
		AND HA.FormUsage IN ('Ventilator Flow Sheet')
		AND ha.AssessmentStatusCode IN (1, 3)
		AND ho.EndDT IS NULL
		AND ha.EndDt IS NULL
		AND ha.CollectedDT BETWEEN @dtStartDate
			AND @dtEndDate

	DECLARE @Vented TABLE (
		VisitOID INT,
		PatientOID INT,
		PatientAccountID INT,
		PatientVisit_OID INT,
		id_num INT,
		AssessmentID INT,
		CollectedDT DATETIME2,
		PatientVisitOID INT
		)

	INSERT INTO @Vented
	SELECT VisitOID,
		PatientOID,
		PatientAccountID,
		PatientVisit_oid,
		id_num,
		AssessmentID,
		CAST(CollectedDT AS DATETIME2) AS [CollectedDT],
		PatientVisitOID
	FROM @VentPatients AS PTS
	INNER JOIN @VentAssessments AS VAS ON PTS.PatientVisit_oid = VAS.PatientVisitOID
	INNER JOIN @CensusVisitOIDs AS CEN ON PTS.PatientVisit_oid = CEN.VisitOID;

	SELECT * 
	INTO smsdss.c_covid_vents_test_tbl
	FROM @Vented;

END;
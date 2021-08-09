USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_vax_sts_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HObservation
	[SC_server].[Soarian_Clin_Prd_1].DBO.HAssessment
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit
	[SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]

Creates Table:
	smsdss.c_covid_vax_sts_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get Covid vaccine status from SC and WellSoft

Revision History:
Date		Version		Description
----		----		----
2021-08-05	v1			Initial Creation
***********************************************************************
*/
CREATE PROCEDURE [dbo].[c_covid_vax_sts_sp]
AS
BEGIN
	SET NOCOUNT ON;
	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON

	-- Create a new table called 'c_covid_vax_sts_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_vax_sts_tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_covid_vax_sts_tbl;

	DECLARE @SC_VaxAssessTbl AS TABLE (
		PatientAccountID INT,
		PatientVaccinationStatusAnswer VARCHAR(255),
		AdditionalComments VARCHAR(1000)
		)

	INSERT INTO @SC_VaxAssessTbl
	SELECT PVT.PatientAccountID,
		PVT.[A_BMH_CovVavRec?] AS [Vax_Status],
		PVT.A_BMH_CovVacComm AS [PtComments]
	FROM (
		SELECT PV.PatientAccountID,
			HO.FindingAbbr,
			HO.[Value] AS [patient_answer]
		FROM [SC_server].[Soarian_Clin_Prd_1].[dbo].[HObservation] AS HO
		INNER JOIN [SC_server].[Soarian_Clin_Prd_1].[dbo].[HAssessment] AS HA ON HO.assessmentid = HA.assessmentid
		INNER JOIN [SC_server].[Soarian_Clin_Prd_1].[dbo].[HPatientVisit] AS PV ON HA.PatientVisit_OID = PV.ObjectID
			AND HA.Patient_OID = PV.Patient_OID
		WHERE HO.FindingAbbr IN ('A_BMH_CovVavRec?', 'A_BMH_CovVacComm')
			AND HA.AssessmentStatusCode IN (1, 3)
			AND HO.EndDT IS NULL
			AND HO.EndDT IS NULL
		) AS A
	PIVOT(MAX([patient_answer]) FOR FindingAbbr IN ("A_BMH_CovVavRec?", "A_BMH_CovVacComm")) AS PVT;

	DECLARE @WS_VaxAssessTbl AS TABLE (
		PatientAccountID INT,
		PatientVaccinationStatusAnswer VARCHAR(255),
		AdditionalComments VARCHAR(1000)
		)

	INSERT INTO @WS_VaxAssessTbl
	SELECT WS.Account,
		WS.IncidentAddress AS [PatientVaccinationStatusAnswer],
		'' AS [AdditionalComments]
	FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS WS
	WHERE WS.IncidentAddress IS NOT NULL;

	SELECT A.PatientAccountID,
		A.PatientVaccinationStatusAnswer,
		A.AdditionalComments,
		A.Source_System
	INTO smsdss.c_covid_vax_sts_tbl
	FROM (
		SELECT *,
			'Soarian' AS [Source_System]
		FROM @SC_VaxAssessTbl
		
		UNION ALL
		
		SELECT *,
			'WellSoft' AS [Source_System]
		FROM @WS_VaxAssessTbl
		) AS A
END;

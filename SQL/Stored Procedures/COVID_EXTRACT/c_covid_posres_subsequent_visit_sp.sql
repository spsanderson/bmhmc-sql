USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_posres_subsequent_visit_sp.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_positive_covid_visits_tbl
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit

Creates Table:
	smsdss.c_covid_posres_subsequent_visits_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get subsequent visits for patients who previously tested positive

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
***********************************************************************
*/

ALTER PROCEDURE [dbo].[c_covid_posres_subsequent_visit_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	
	SET NOCOUNT ON;
	-- Create a new table called 'c_covid_posres_subsequent_visits_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_posres_subsequent_visits_tbl', 'U') IS NOT NULL
	DROP TABLE smsdss.c_covid_posres_subsequent_visits_tbl;

	/*
	Positive Results and their subsequent visits
	*/
	DECLARE @POSRES TABLE (
		PatientOID INT,
		PatientVisitOID INT,
		VisitStartDateTime DATETIME2
		)

	INSERT INTO @POSRES
	SELECT A.Patient_OID,
		A.PatientVisit_OID,
		B.VisitStartDateTime AS [Adm_Date]
	FROM smsdss.c_positive_covid_visits_tbl AS A
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS B ON A.PatientVisit_OID = B.OBJECTID;

	DECLARE @Subsequent TABLE (PatientVisitOID INT)

	INSERT INTO @Subsequent
	SELECT PV.OBJECTID
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS PV
	WHERE PV.Patient_OID IN (
			SELECT DISTINCT ZZZ.PatientOID
			FROM @POSRES AS ZZZ
			WHERE PV.VisitStartDatetime > ZZZ.VisitStartDateTime
				AND VisitTypeCode IN ('IP-WARD', 'IP', 'EOP')
			);

	SELECT *
	INTO smsdss.c_covid_posres_subsequent_visits_tbl
	FROM @Subsequent;

END;
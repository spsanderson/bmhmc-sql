USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_cv_indicator_text_test_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit
    [SC_server].[Soarian_Clin_Prd_1].dbo.HExtendedPatientVisit
    smsdss.c_covid_ptvisitoid_tbl

Creates Table:
	smsdss.c_covid_indicator_text_test_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get the covid indicator text

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
2021-02-12  v2          Complete re-write to split data from PRD and DSS
                        Make all data parts into local variable tables
                        makes a large speed up 
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_covid_cv_indicator_text_test_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	-- Create a new table called 'c_covid_indicator_text_test_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_indicator_text_test_tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_covid_indicator_text_test_tbl;

	/*
    Covid Indicator Text
    */
	DECLARE @PtVistitOID TABLE (PatientVisit_OID INT NOT NULL)

	INSERT INTO @PtVistitOID
	SELECT DISTINCT PatientVisitOID
	FROM smsdss.c_covid_ptvisitoid_tbl
	WHERE PatientVisitOID IS NOT NULL

	DECLARE @UserDefinedString TABLE (
		PatientVisit_OID INT,
		PatientAccountID INT,
		Covid_Indicator VARCHAR(1000)
		)

	INSERT INTO @UserDefinedString
	SELECT A.OBJECTID AS PatientVisit_OID,
		A.PATIENTACCOUNTID,
		B.UserDefinedString20
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].dbo.HExtendedPatientVisit AS B ON A.PatientVisitExtension_OID = B.objectid
	WHERE A.PatientVisitExtension_OID IS NOT NULL
		AND B.UserDefinedString20 IS NOT NULL
		AND B.UserDefinedString20 != ''

	SELECT A.PatientVisit_OID,
		B.PatientAccountID,
		B.Covid_Indicator
	INTO smsdss.c_covid_indicator_text_test_tbl
	FROM @PtVistitOID AS A
	INNER JOIN @UserDefinedString AS B ON A.PatientVisit_OID = B.PatientVisit_OID
END;

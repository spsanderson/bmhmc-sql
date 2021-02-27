USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_miscref_test_sp.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_Covid_MiscRefRslt_tbl
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit

Creates Table:
	smsdss.c_covid_miscref_test_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get Covid misc ref clean results

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
2021-02-25  v2          Rewrite for new stream testing
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_covid_miscref_test_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	
	SET NOCOUNT ON;
	-- Create a new table called 'c_covid_miscref_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_miscref_test_tbl', 'U') IS NOT NULL
	DROP TABLE smsdss.c_covid_miscref_test_tbl;

	DECLARE @MiscRef TABLE (
		PatientVisitOID INT,
		PatientAccountID INT,
		Test_Date DATETIME2,
		Result VARCHAR(50)
		)

	INSERT INTO @MiscRef
	SELECT B.ObjectID,
		[Acct No],
		[Test date],
		[Result]
	FROM smsdss.c_Covid_MiscRefRslt_tbl AS A
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS B ON A.[Acct No] = B.PatientAccountID;

	SELECT *
	INTO smsdss.c_covid_miscref_test_tbl
	FROM @MiscRef;

END;
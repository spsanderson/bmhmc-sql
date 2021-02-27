USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_wellsoft_test_sp.sql

Input Parameters:
	None

Tables/Views:
	[SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit

Creates Table:
	smsdss.c_covid_wellsoft_test_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get Covid wellsoft information

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
2021-01-25	v2			Add [COVID_test_within_30_days]
2021-02-01	v3			Add Covid_Order Case statement 
						Fix WHERE CLAUSE
						Push to prod
2021-02-25  v4          Rewrite for new stream testing
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_covid_wellsoft_test_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	-- Create a new table called 'c_covid_wellsoft_test_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_wellsoft_test_tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_covid_wellsoft_test_tbl;

	/*
	ED Table Information
	*/
	DECLARE @WellSoft TABLE (
		PatientVisitOID INT,
		Covid_Test_Outside_Hosp VARCHAR(50),
		Order_Status VARCHAR(250),
		Result VARCHAR(50),
		Account VARCHAR(50),
		MRN VARCHAR(10),
		PT_Name VARCHAR(100),
		PT_Age VARCHAR(3),
		TimeLeftED VARCHAR(100)
		);

	INSERT INTO @WellSoft
	SELECT B.ObjectID,
		--A.COVID_TESTED_OUTSIDE_HOSP AS [COVID_ORDER]
		CASE 
			WHEN A.COVID_TEST_WITHIN_30_DAYS IS NOT NULL
				THEN A.COVID_TEST_WITHIN_30_DAYS
			ELSE a.covid_Tested_Outside_Hosp
			END AS [Covid_Order],
		a.covid_Where_Tested AS [Order_Status],
		a.covid_Test_Results AS [Result],
		--a.covid_test_within_30_days,
		A.Account,
		A.MR#,
		A.Patient,
		ROUND(DATEDIFF(MONTH, A.AgeDOB, GETDATE()) / 12, 0) AS [PT_Age],
		A.TimeLeftED
	FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
	LEFT OUTER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS B ON CAST(A.Account AS VARCHAR) = cast(B.PatientAccountID AS VARCHAR)
	WHERE (
			A.COVID_TESTED_OUTSIDE_HOSP IS NOT NULL -- tested yes
			OR A.COVID_WHERE_TESTED IS NOT NULL
			OR A.COVID_TEST_RESULTS IS NOT NULL
			OR A.[COVID_test_within_30_days] IS NOT NULL
			)
		--AND A.COVID_TESTED_OUTSIDE_HOSP != '(((('
		AND (
			A.Covid_Tested_Outside_Hosp = 'Yes'
			OR A.[COVID_test_within_30_days] LIKE '%Yes%'
			)
		AND LEFT(A.Account, 1) = '1';

	SELECT *
	INTO smsdss.c_covid_wellsoft_test_tbl
	FROM @WellSoft;
END;

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
2021-03-17	v5			Re-write to split data due to March 16 2021 DSS
						Server Upgrade
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

	-- Get data from DSS first
	DECLARE @WellSoftDSS TABLE (
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

	INSERT INTO @WellSoftDSS
	SELECT B.ObjectID,
		CASE 
			WHEN A.COVID_TEST_WITHIN_30_DAYS IS NOT NULL
				THEN A.COVID_TEST_WITHIN_30_DAYS
			ELSE a.covid_Tested_Outside_Hosp
			END AS [Covid_Order],
		a.covid_Where_Tested AS [Order_Status],
		a.covid_Test_Results AS [Result],
		A.Account,
		A.MR#,
		A.Patient,
		ROUND(DATEDIFF(MONTH, A.AgeDOB, GETDATE()) / 12, 0) AS [PT_Age],
		A.TimeLeftED
	FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
	LEFT OUTER JOIN smsmir.sc_PatientVisit AS B ON CAST(A.Account AS VARCHAR) = cast(B.PatientAccountID AS VARCHAR)
	WHERE (
			A.COVID_TESTED_OUTSIDE_HOSP IS NOT NULL -- tested yes
			OR A.COVID_WHERE_TESTED IS NOT NULL
			OR A.COVID_TEST_RESULTS IS NOT NULL
			OR A.[COVID_test_within_30_days] IS NOT NULL
			)
		AND (
			A.Covid_Tested_Outside_Hosp = 'Yes'
			OR A.[COVID_test_within_30_days] LIKE '%Yes%'
			)
		AND LEFT(A.Account, 1) = '1';

	-- Get records with no PatientVisitOID to get from PRD
	DECLARE @Missing TABLE (Account INT)

	INSERT INTO @Missing
	SELECT Account
	FROM @WellSoftDSS
	WHERE PatientVisitOID IS NULL;

	-- Get missing records from PRD
	DECLARE @WellSoftPRD TABLE (
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

	INSERT INTO @WellSoftPRD
	SELECT B.ObjectID,
		CASE 
			WHEN A.COVID_TEST_WITHIN_30_DAYS IS NOT NULL
				THEN A.COVID_TEST_WITHIN_30_DAYS
			ELSE a.covid_Tested_Outside_Hosp
			END AS [Covid_Order],
		a.covid_Where_Tested AS [Order_Status],
		a.covid_Test_Results AS [Result],
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
		AND (
			A.Covid_Tested_Outside_Hosp = 'Yes'
			OR A.[COVID_test_within_30_days] LIKE '%Yes%'
			)
		AND LEFT(A.Account, 1) = '1'
		AND EXISTS (
			SELECT 1
			FROM @Missing AS V
			WHERE V.Account = A.Account
			);

	-- Union results together
	SELECT PatientVisitOID,
		Covid_Test_Outside_Hosp,
		Order_Status,
		Result,
		Account,
		MRN,
		PT_Name,
		PT_Age,
		TimeLeftED
	INTO smsdss.c_covid_wellsoft_test_tbl
	FROM (
		SELECT PatientVisitOID,
			Covid_Test_Outside_Hosp,
			Order_Status,
			Result,
			Account,
			MRN,
			PT_Name,
			PT_Age,
			TimeLeftED
		FROM @WellSoftDSS
		WHERE PatientVisitOID IS NOT NULL
		
		UNION ALL
		
		SELECT PatientVisitOID,
			Covid_Test_Outside_Hosp,
			Order_Status,
			Result,
			Account,
			MRN,
			PT_Name,
			PT_Age,
			TimeLeftED
		FROM @WellSoftPRD
		) AS A
END;

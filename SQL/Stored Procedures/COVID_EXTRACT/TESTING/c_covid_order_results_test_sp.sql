USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_order_results_test_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult

Creates Table:
	smsdss.c_covid_order_results_test_tbl
	smsmir.mir_sc_InvestigationResult

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get Covid order results for findingabbreviation 9782.
	Go back a maximum of 10 days in PRD SC DB and get the
	rest from DSS

Revision History:
Date		Version		Description
----		----		----
2021-02-08	v1			Initial Creation
2021-02-09	v2			Rewrite using date parameters instead
***********************************************************************
*/

ALTER PROCEDURE [dbo].[c_covid_order_results_test_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	-- Create a new table called 'c_covid_orders_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_order_results_test_tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_covid_order_results_test_tbl;

	DECLARE @START DATE;

	SET @START = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()) - 10, 0);

	-- Get results for those that are in the rt census
	DECLARE @CovidResultsRT TABLE (
		id_num INT,
		-- Links to HOccurrence.ObjectID
		OccurrenceOID INT,
		FindingAbbreviation VARCHAR(10),
		ResultDateTime DATETIME2,
		ResultValue VARCHAR(500),
		PatientVisitOID INT
		)

	-- Insert results into the Real Time table where we only go back for results
	-- from no more than 10 days ago to relieve resources on PROD
	INSERT INTO @CovidResultsRT
	SELECT [RN] = ROW_NUMBER() OVER (
			PARTITION BY PatientVisit_OID,
			Occurrence_OID ORDER BY ResultDateTime DESC
			),
		Occurrence_OID,
		FindingAbbreviation,
		ResultDateTime,
		REPLACE(REPLACE(ResultValue, CHAR(13), ' '), CHAR(10), ' ') AS [ResultValue],
		PatientVisit_OID
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult AS A
	WHERE FindingAbbreviation = '9782'
		AND ResultDateTime >= @START
	ORDER BY PatientVisit_OID,
		ResultDateTime DESC;

	DELETE
	FROM @CovidResultsRT
	WHERE id_num != 1;

	-- Get results for orders that are more than 10 days old
	DECLARE @CovidResultsDC TABLE (
		id_num INT,
		-- Links to HOccurrence.ObjectID
		OccurrenceOID INT,
		FindingAbbreviation VARCHAR(10),
		ResultDateTime DATETIME2,
		ResultValue VARCHAR(500),
		PatientVisitOID INT
		)

	INSERT INTO @CovidResultsDC
	SELECT [RN] = ROW_NUMBER() OVER (
			PARTITION BY PatientVisit_OID,
			Occurrence_OID ORDER BY ResultDateTime DESC
			),
		Occurrence_OID,
		FindingAbbreviation,
		ResultDateTime,
		REPLACE(REPLACE(ResultValue, CHAR(13), ' '), CHAR(10), ' ') AS [ResultValue],
		PatientVisit_OID
	FROM smsmir.mir_sc_InvestigationResult
	WHERE FindingAbbreviation = '9782'
		AND ResultDateTime < @START
	ORDER BY PatientVisit_OID,
		ResultDateTime DESC;

	DELETE
	FROM @CovidResultsDC
	WHERE id_num != 1;

	-- UNION results from both tables together
	DECLARE @CovidResults TABLE (
		id_num INT IDENTITY(1,1),
		-- Links to HOccurrence.ObjectID
		OccurrenceOID INT,
		FindingAbbreviation VARCHAR(10),
		ResultDateTime DATETIME2,
		ResultValue VARCHAR(500),
		PatientVisitOID INT
		)

	INSERT INTO @CovidResults
	SELECT OccurrenceOID,
		FindingAbbreviation,
		ResultDateTime,
		ResultValue,
		PatientVisitOID
	FROM @CovidResultsRT
	
	UNION ALL
	
	SELECT OccurrenceOID,
		FindingAbbreviation,
		ResultDateTime,
		ResultValue,
		PatientVisitOID
	FROM @CovidResultsDC

	SELECT id_num,
		OccurrenceOID,
		FindingAbbreviation,
		ResultDateTime,
		ResultValue,
		PatientVisitOID
	INTO smsdss.c_covid_order_results_test_tbl
	FROM @CovidResults;
END;


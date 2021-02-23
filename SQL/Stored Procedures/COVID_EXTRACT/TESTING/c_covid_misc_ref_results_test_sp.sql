USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_misc_ref_results_test_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HORDER
	[SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER
	[SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult
    smsmir.sc_InvestigationResult
    smsmir.sc_Order
    smsmir.sc_OccurrenceOrder

Creates Table:
	smsdss.c_covid_misc_ref_results_test_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get Covid misc ref orders and results

Revision History:
Date		Version		Description
----		----		----
2021-02-10	v1			Initial Creation
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_covid_misc_ref_results_test_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	-- Create a new table called 'c_covid_misc_ref_results_test_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_misc_ref_results_test_tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_covid_misc_ref_results_test_tbl;

	DECLARE @START DATE;

	SET @START = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()) - 10, 0);

	DECLARE @CovidMiscRefResultsPRD TABLE (
		id_num INT IDENTITY(1, 1),
		OccurrenceOID INT -- links to HOccurrence.ObjectID
		,
		FindingAbbreviation VARCHAR(10),
		ResultDateTime DATETIME2,
		ResultValue VARCHAR(500),
		PatientVisitOID INT,
		OrderID INT,
		OrderAbbreviation VARCHAR(50),
		OrderDTime DATETIME2,
		ObjectID INT -- links to HOrderOccurrence.Order_OID
		,
		OrderOccurrenceStatus VARCHAR(100),
		StatusEnteredDateTime DATETIME2
		)

	INSERT INTO @CovidMiscRefResultsPRD
	SELECT F.Occurrence_OID,
		F.FindingAbbreviation,
		F.ResultDateTime,
		REPLACE(REPLACE(F.ResultValue, CHAR(13), ' '), CHAR(10), ' ') AS [ResultValue],
		F.PatientVisit_OID,
		D.Orderid,
		D.OrderAbbreviation,
		D.CreationTime,
		D.ObjectID,
		E.OrderOccurrenceStatus,
		E.StatusEnteredDateTime
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HORDER AS D
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER AS E ON D.OBJECTID = E.ORDER_OID
		AND D.CREATIONTIME = E.CREATIONTIME
		AND E.ORDEROCCURRENCESTATUS NOT IN ('DISCONTINUE', 'Cancel')
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult AS F ON E.OBJECTID = F.OCCURRENCE_OID
	WHERE F.RESULTVALUE LIKE '%COVID%' -- COVID MISC REF VALUE
		AND D.orderabbreviation = '00410001'
		AND F.ResultDateTime >= @START

	-- Get results from DSS before @start
	DECLARE @CovidMiscRefResultsDSS TABLE (
		id_num INT IDENTITY(1, 1),
		OccurrenceOID INT -- links to HOccurrence.ObjectID
		,
		FindingAbbreviation VARCHAR(10),
		ResultDateTime DATETIME2,
		ResultValue VARCHAR(500),
		PatientVisitOID INT,
		OrderID INT,
		OrderAbbreviation VARCHAR(50),
		OrderDTime DATETIME2,
		ObjectID INT -- links to HOrderOccurrence.Order_OID
		,
		OrderOccurrenceStatus VARCHAR(100),
		StatusEnteredDateTime DATETIME2
		)

	INSERT INTO @CovidMiscRefResultsDSS
	SELECT F.Occurrence_OID,
		F.FindingAbbreviation,
		F.ResultDateTime,
		REPLACE(REPLACE(F.ResultValue, CHAR(13), ' '), CHAR(10), ' ') AS [ResultValue],
		F.PatientVisit_OID,
		D.Orderid,
		D.OrderAbbreviation,
		D.CreationTime,
		D.ObjectID,
		E.OrderOccurrenceStatus,
		E.StatusEnteredDateTime
	FROM smsmir.sc_Order AS D
	INNER JOIN smsmir.sc_OccurrenceOrder AS E ON D.OBJECTID = E.ORDER_OID
		AND D.CREATIONTIME = E.CREATIONTIME
		AND E.ORDEROCCURRENCESTATUS NOT IN ('DISCONTINUE', 'Cancel')
	INNER JOIN smsmir.sc_InvestigationResult AS F ON E.OBJECTID = F.OCCURRENCE_OID
	WHERE F.RESULTVALUE LIKE '%COVID%' -- COVID MISC REF VALUE
		AND D.orderabbreviation = '00410001'
		AND F.ResultDateTime < @START

	-- union all results together
	DECLARE @CovidMiscRefResults TABLE (
		id_num INT IDENTITY(1, 1),
		OccurrenceOID INT -- links to HOccurrence.ObjectID
		,
		FindingAbbreviation VARCHAR(10),
		ResultDateTime DATETIME2,
		ResultValue VARCHAR(500),
		PatientVisitOID INT,
		OrderID INT,
		OrderAbbreviation VARCHAR(50),
		OrderDTime DATETIME2,
		ObjectID INT -- links to HOrderOccurrence.Order_OID
		,
		OrderOccurrenceStatus VARCHAR(100),
		StatusEnteredDateTime DATETIME2
		)

	INSERT INTO @CovidMiscRefResults
	SELECT A.OccurrenceOID,
		A.FindingAbbreviation,
		A.ResultDateTime,
		A.ResultValue,
		A.PatientVisitOID,
		A.OrderID,
		A.OrderAbbreviation,
		A.OrderDTime,
		A.ObjectID,
		A.OrderOccurrenceStatus,
		A.StatusEnteredDateTime
	FROM (
		SELECT id_num,
			OccurrenceOID,
			FindingAbbreviation,
			ResultDateTime,
			ResultValue,
			PatientVisitOID,
			OrderID,
			OrderAbbreviation,
			OrderDTime,
			ObjectID,
			OrderOccurrenceStatus,
			StatusEnteredDateTime
		FROM @CovidMiscRefResultsPRD
		
		UNION
		
		SELECT id_num,
			OccurrenceOID,
			FindingAbbreviation,
			ResultDateTime,
			ResultValue,
			PatientVisitOID,
			OrderID,
			OrderAbbreviation,
			OrderDTime,
			ObjectID,
			OrderOccurrenceStatus,
			StatusEnteredDateTime
		FROM @CovidMiscRefResultsDSS
		) AS A

	SELECT *
	INTO smsdss.c_covid_misc_ref_results_test_tbl
	FROM @CovidMiscRefResults;
END;

USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_misc_ref_results_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HORDER
	[SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER
	[SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult

Creates Table:
	smsdss.c_covid_misc_ref_results_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get Covid misc ref orders and results

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_covid_misc_ref_results_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	
	SET NOCOUNT ON;
	-- Create a new table called 'c_covid_misc_ref_results_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_misc_ref_results_tbl', 'U') IS NOT NULL
	DROP TABLE smsdss.c_covid_misc_ref_results_tbl;

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
	ORDER BY F.PatientVisit_OID,
		F.ResultDateTime DESC;

	SELECT *
	INTO smsdss.c_covid_misc_ref_results_tbl
	FROM @CovidMiscRefResults;

END;
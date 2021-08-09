USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [dbo].[c_covid_order_results_sp]    Script Date: 7/27/2021 2:15:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_order_results_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult

Creates Table:
	smsdss.c_covid_order_results_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get Covid orders for OrderAbbreviation 00425421
    results

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
2021-07-27	v2			Add FindingAbbreviation 00414086
***********************************************************************
*/

ALTER PROCEDURE [dbo].[c_covid_order_results_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	
	SET NOCOUNT ON;
	-- Create a new table called 'c_covid_orders_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_order_results_tbl', 'U') IS NOT NULL
	DROP TABLE smsdss.c_covid_order_results_tbl;

	DECLARE @CovidResults TABLE (
	id_num INT,
	-- Links to HOccurrence.ObjectID
	OccurrenceOID INT,
	FindingAbbreviation VARCHAR(10),
	ResultDateTime DATETIME2,
	ResultValue VARCHAR(500),
	PatientVisitOID INT
	)

	INSERT INTO @CovidResults
	SELECT [RN] = ROW_NUMBER() OVER (
			PARTITION BY PatientVisit_OID,
			Occurrence_OID ORDER BY ResultDateTime DESC
			),
		Occurrence_OID,
		FindingAbbreviation,
		ResultDateTime,
		REPLACE(REPLACE(ResultValue, CHAR(13), ' '), CHAR(10), ' ') AS [ResultValue],
		PatientVisit_OID
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult
	WHERE FindingAbbreviation IN ('9782','00414086')
	ORDER BY PatientVisit_OID,
		ResultDateTime DESC;

	DELETE
	FROM @CovidResults
	WHERE id_num != 1;

	SELECT *
	INTO smsdss.c_covid_order_results_tbl
	FROM @CovidResults;

END;
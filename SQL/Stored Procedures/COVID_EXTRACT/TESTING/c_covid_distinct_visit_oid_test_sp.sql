USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_disinct_visit_oid_test_sp.sql

Input Parameters:
	None

Tables/Views:
	[smsdss].[c_covid_wellsoft_test_tbl]
	[smsdss].[c_covid_rt_census_test_tbl]
	[smsdss].[c_covid_order_results_test_tbl]
	[smsdss].[c_covid_orders_test_tbl]
	[smsdss].[c_covid_misc_ref_results_test_tbl]
	[smsdss].[c_covid_miscref_test_tbl]
	[smsdss].[c_covid_ext_pos_tbl] -- no test table this is static
	[smsdss].[c_covid_posres_subsequent_visits_test_tbl]
	[smsdss].[c_covid_flu_results_test_tbl]

Creates Table:
	smsdss.c_covid_ptvisitoid_test_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get distinct visit oids

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
2020-10-30	v2			Add flu results tbl to union list
2021-02-25  v3          Rewrite for new stream testing
***********************************************************************
*/

ALTER PROCEDURE [dbo].[c_covid_distinct_visit_oid_test_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	
	SET NOCOUNT ON;
	-- Create a new table called 'c_covid_ptvisitoid_test_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_ptvisitoid_test_tbl', 'U') IS NOT NULL
	DROP TABLE smsdss.c_covid_ptvisitoid_test_tbl;

	DECLARE @PatientVisit TABLE (PatientVisitOID INT)

	INSERT INTO @PatientVisit
	SELECT DISTINCT A.PatientVisitOID
	FROM (
		SELECT PatientVisitOID
		FROM [smsdss].[c_covid_wellsoft_test_tbl]
	
		UNION
	
		SELECT PatientVisitOID
		FROM [smsdss].[c_covid_rt_census_test_tbl]
	
		UNION
	
		SELECT PatientVisitOID
		FROM [smsdss].[c_covid_order_results_test_tbl]
	
		UNION
	
		SELECT PatientVisitOID
		FROM [smsdss].[c_covid_orders_test_tbl]
	
		UNION
	
		SELECT PatientVisitOID
		FROM [smsdss].[c_covid_misc_ref_results_test_tbl]
	
		UNION
	
		SELECT PatientVisitOID
		FROM [smsdss].[c_covid_miscref_test_tbl]
	
		UNION
	
		SELECT PatientVisitOID
		FROM [smsdss].[c_covid_ext_pos_tbl]
	
		UNION
	
		SELECT PatientVisitOID
		FROM [smsdss].[c_covid_posres_subsequent_visits_test_tbl]

		UNION

		SELECT PatientVisitOID
		FROM smsdss.c_covid_flu_results_test_tbl
		) AS A

	SELECT *
	INTO smsdss.c_covid_ptvisitoid_test_tbl
	FROM @PatientVisit
END;
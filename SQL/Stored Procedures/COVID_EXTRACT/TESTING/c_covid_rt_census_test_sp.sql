USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_rt_census_sp.sql

Input Parameters:
	None

Tables/Views:
	[SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit

Creates Table:
	smsdss.c_covid_rt_census_test_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get real time census from sc
    This is going to be used as the base for the COVID reporting. Those 
    that are in the real time census will have records pulled from SC,
    those that are not will get pulled from DSS in order to relieve resources
    from production.

Revision History:
Date		Version		Description
----		----		----
2021-02-08	v1			Initial Creation
2021-02-11	v2			Add Patient_OID
***********************************************************************
*/

ALTER PROCEDURE [dbo].[c_covid_rt_census_test_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	
	SET NOCOUNT ON;
	-- Create a new table called 'c_covid_rt_census_test_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_rt_census_test_tbl', 'U') IS NOT NULL
	DROP TABLE smsdss.c_covid_rt_census_test_tbl;

	DECLARE @SCRTCensus TABLE (
	PatientVisitOID INT,
	Nurs_Sta VARCHAR(10),
	Bed VARCHAR(10),
	Account VARCHAR(50),
	Patient_OID INT
	);

	INSERT INTO @SCRTCensus
	SELECT A.ObjectID,
		A.PatientLocationName,
		A.LatestBedName,
		A.patientAccountId,
		A.Patient_OID
	--FROM smsdss.c_soarian_real_time_census_CDI_v AS A
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
	WHERE A.VisitEndDateTime IS NULL
		AND A.PatientLocationName <> ''
		AND A.IsDeleted = 0;

	SELECT *
	INTO smsdss.c_covid_rt_census_test_tbl
	FROM @SCRTCensus;

END;
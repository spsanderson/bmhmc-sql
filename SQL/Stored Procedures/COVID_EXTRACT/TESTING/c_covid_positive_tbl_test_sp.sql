USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_positive_tbl_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit
	[SC_server].[Soarian_Clin_Prd_1].DBO.HOrder
	[SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult
	smsdss.bmh_plm_ptacct_v

Creates Table:
	c_positive_covid_visits_test_tbl

Functions:
	Enter Here

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get all unique encounters with a positive covid-19 result
    Depends on the following to finish
        1. dbo.c_covid_orders_test_sp
        2. dbo.c_covid_rt_census_test_sp
        3. dbo.c_covid_order_results_test_sp
        4. dbo.c_covid_misc_ref_results_test_sp

Revision History:
Date		Version		Description
----		----		----
2020-04-13	v1			Initial Creation
2020-05-08	v2			Add MRN column
2021-02-11  v3          Re-write, split by dates for PRD and DSS
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_covid_positive_tbl_test_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	-- COVID ORDER
	SELECT COALESCE(B.Account, C.PatientAccountID) AS [PatientAccountID],
		COALESCE(B.Patient_OID, C.Patient_oid) AS [Patient_OID],
		A.PatientVisitOID,
		'ORDER' AS [VAL]
	INTO #COVIDORDER
	FROM SMSDSS.c_covid_orders_test_tbl AS A
	LEFT OUTER JOIN SMSDSS.c_covid_rt_census_test_tbl AS B ON A.PatientVisitOID = B.PatientVisitOID
	LEFT OUTER JOIN smsmir.mir_sc_PatientVisit AS C ON A.PatientVisitOID = C.ObjectID;

	-- COVID RESULTS
	SELECT COALESCE(B.Account, C.PatientAccountID) AS [PatientAccountID],
		COALESCE(B.Patient_OID, C.Patient_oid) AS [Patient_OID],
		A.PatientVisitOID,
		REPLACE(REPLACE(A.ResultValue, CHAR(13), ' '), CHAR(10), ' ') AS [VAL]
	INTO #COVIDRSLT
	FROM SMSDSS.c_covid_order_results_test_tbl AS A
	LEFT OUTER JOIN SMSDSS.c_covid_rt_census_test_tbl AS B ON A.PatientVisitOID = B.PatientVisitOID
	LEFT OUTER JOIN smsmir.mir_sc_PatientVisit AS C ON A.PatientVisitOID = C.ObjectID

	-- MIS REF COVID-19 RESULT
	SELECT COALESCE(B.Account, C.PatientAccountID) AS [PatientAccountID],
		COALESCE(B.Patient_OID, C.Patient_oid) AS [Patient_OID],
		A.PatientVisitOID,
		'MISC_REF' AS [VAL]
	INTO #MISCREF
	FROM smsdss.c_covid_misc_ref_results_test_tbl AS A
	LEFT OUTER JOIN SMSDSS.c_covid_rt_census_test_tbl AS B ON A.PatientVisitOID = B.PatientVisitOID
	LEFT OUTER JOIN smsmir.mir_sc_PatientVisit AS C ON A.PatientVisitOID = C.ObjectID

	-- UNION ALL TABLES AND GET DISTINCT VALUES
	SELECT DISTINCT A.PatientAccountID,
		A.Patient_OID,
		A.PatientVisitOID,
		A.VAL
	INTO #UNIONEDRESLTS
	FROM (
		SELECT PatientAccountID,
			Patient_OID,
			PatientVisitOID,
			VAL
		FROM #COVIDORDER
		
		UNION
		
		SELECT PatientAccountID,
			Patient_OID,
			PatientVisitOID,
			VAL
		FROM #COVIDRSLT
		
		UNION
		
		SELECT PatientAccountID,
			Patient_OID,
			PatientVisitOID,
			VAL
		FROM #MISCREF
		) AS A

	-- DISTINCT TBL
	SELECT A.PATIENTACCOUNTID,
		A.PATIENT_OID,
		A.PATIENTVISITOID AS [PatientVisit_OID],
		COVIDORDER.VAL AS [CovidOrder],
		COVIDRSLT.VAL AS [CovidResult],
		MISCREF.VAL AS [CovidMiscRef],
		[Positive_Negative] = CASE 
			WHEN COVIDRSLT.VAL LIKE 'DETECTED%'
				THEN 'Positive'
			WHEN COVIDRSLT.VAL LIKE 'DETECE%'
				THEN 'Positive'
			WHEN COVIDRSLT.VAL LIKE 'POSITIV%'
				THEN 'Positive'
			WHEN COVIDRSLT.VAL LIKE 'PRESUMP% POSITIVE%'
				THEN 'Positive'
			WHEN COVIDRSLT.VAL LIKE 'NOT DETECTED%'
				THEN 'Negative'
			WHEN COVIDRSLT.VAL IS NULL
				THEN 'NO-RESULT'
			ELSE COVIDRSLT.VAL
			END
	INTO #FULLTBL
	FROM #UNIONEDRESLTS AS A
	LEFT OUTER JOIN #COVIDORDER AS COVIDORDER ON A.PATIENTACCOUNTID = COVIDORDER.PATIENTACCOUNTID
	LEFT OUTER JOIN #COVIDRSLT AS COVIDRSLT ON A.PATIENTACCOUNTID = COVIDRSLT.PATIENTACCOUNTID
	LEFT OUTER JOIN #MISCREF AS MISCREF ON A.PATIENTACCOUNTID = MISCREF.PATIENTACCOUNTID;

	-- Create a new table called 'c_positive_covid_visits_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_positive_covid_visits_test_tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_positive_covid_visits_test_tbl

	-- Create the table in the specified schema
	CREATE TABLE smsdss.c_positive_covid_visits_test_tbl (
		Prim_Key INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		-- primary key column
		PatientAccountID [NVARCHAR](50) NOT NULL,
		Patient_OID INT NOT NULL,
		PatientVisit_OID INT NOT NULL,
		MRN VARCHAR(10) NOT NULL
		);

	INSERT INTO smsdss.c_positive_covid_visits_test_tbl
	SELECT DISTINCT A.PATIENTACCOUNTID,
		A.Patient_OID,
		A.Patientvisit_OID,
		B.Med_Rec_No
	FROM #FULLTBL AS A
	INNER JOIN SMSDSS.BMH_PLM_PTACCT_V AS B ON A.PatientAccountID = B.PtNo_Num
	WHERE A.Positive_Negative = 'Positive'

	-- DROP TABLES
	DROP TABLE #COVIDORDER

	DROP TABLE #COVIDRSLT

	DROP TABLE #MISCREF
END

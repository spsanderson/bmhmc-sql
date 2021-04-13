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
	c_positive_covid_visits_tbl

Functions:
	Enter Here

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get all unique encounters with a positive covid-19 result

Revision History:
Date		Version		Description
----		----		----
2020-04-13	v1			Initial Creation
2020-05-08	v2			Add MRN column
2021-04-06	v4			swap out smsdss.bmh_plm_ptacct_v for smsmir.hl7_pt
						to obtain the pt mrn
***********************************************************************
*/

ALTER PROCEDURE [dbo].[c_covid_positive_tbl_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	
	SET NOCOUNT ON;


	-- COVID ORDER
	SELECT DISTINCT a.patientaccountid,
		a.patient_oid,
		a.objectid AS [patientvisit_oid],
		'ORDER' AS [VAL]
	INTO #COVIDORDER
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HORDER AS horder ON a.objectid = horder.patientvisit_oid
	WHERE horder.ORDERABBREVIATION = '00425421';

	-- COVID RESULTS
	SELECT DISTINCT A.PATIENT_OID,
		B.PATIENTVISIT_OID,
		A.PATIENTACCOUNTID,
		REPLACE(REPLACE(B.RESULTVALUE, CHAR(13), ' '), CHAR(10), ' ') AS [VAL]
	INTO #COVIDRSLT
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult AS B ON A.OBJECTID = B.PATIENTVISIT_OID
		AND B.FINDINGABBREVIATION = '9782';

	-- MIS REF COVID-19 RESULT
	SELECT DISTINCT A.PATIENT_OID,
		B.PATIENTVISIT_OID,
		A.PATIENTACCOUNTID,
		'MISC_REF' AS [VAL]
	--, HORDER.ORDERABBREVIATION
	--, B.RESULTVALUE
	INTO #MISCREF
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult AS B ON A.OBJECTID = B.PATIENTVISIT_OID
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HORDER AS horder ON a.objectid = horder.patientvisit_oid
	WHERE B.RESULTVALUE LIKE '%COVID%' -- COVID MISC REF VALUE
		AND horder.orderabbreviation = '00410001';

	-- UNION ALL TABLES AND GET DISTINCT VALUES
	SELECT DISTINCT A.PATIENTACCOUNTID,
		A.PATIENT_OID,
		A.patientvisit_oid,
		A.VAL
	INTO #UNIONEDRESLTS
	FROM (
		SELECT PATIENTACCOUNTID,
			PATIENT_OID,
			PATIENTVISIT_OID,
			VAL
		FROM #COVIDORDER
	
		UNION
	
		SELECT PATIENTACCOUNTID,
			PATIENT_OID,
			PATIENTVISIT_OID,
			VAL
		FROM #COVIDRSLT
	
		UNION
	
		SELECT PATIENTACCOUNTID,
			PATIENT_OID,
			PATIENTVISIT_OID,
			VAL
		FROM #MISCREF
		) AS A

	-- DISTINCT TBL
	SELECT A.PATIENTACCOUNTID,
		A.PATIENT_OID,
		A.PATIENTVISIT_OID,
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
	IF OBJECT_ID('smsdss.c_positive_covid_visits_tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_positive_covid_visits_tbl

	-- Create the table in the specified schema
	CREATE TABLE smsdss.c_positive_covid_visits_tbl (
		Prim_Key INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		-- primary key column
		PatientAccountID [NVARCHAR](50) NOT NULL,
		Patient_OID INT NOT NULL,
		PatientVisit_OID INT NOT NULL,
		MRN VARCHAR(10) NOT NULL
		);

	INSERT INTO smsdss.c_positive_covid_visits_tbl
	SELECT DISTINCT A.PATIENTACCOUNTID,
		A.Patient_OID,
		A.Patientvisit_OID,
		B.pt_med_rec_no
	FROM #FULLTBL AS A
	--INNER JOIN SMSDSS.BMH_PLM_PTACCT_V AS B ON A.PatientAccountID = B.PtNo_Num
	INNER JOIN smsmir.hl7_pt AS B ON A.PatientAccountID = B.pt_id
	WHERE A.Positive_Negative = 'Positive'

	-- DROP TABLES
	DROP TABLE #COVIDORDER

	DROP TABLE #COVIDRSLT

	DROP TABLE #MISCREF

	DROP TABLE #UNIONEDRESLTS

	DROP TABLE #FULLTBL

END
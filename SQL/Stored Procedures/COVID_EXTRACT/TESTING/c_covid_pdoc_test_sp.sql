USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [dbo].[c_covid_pdoc_sp]    Script Date: 8/4/2020 1:20:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_pdoc_test_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.DdcAnswer
	[SC_server].[Soarian_Clin_Prd_1].DBO.DdcDoc
	[SC_server].[Soarian_Clin_Prd_1].[dbo].[DdcDocVersion]
    smsmir.sc_DdcAnswer
    smsmir.sc_DdcDoc
    smsmir.sc_DdcDocVersion

Creates Table:
	smsdss.c_covid_pdoc_test_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get PDOC values for LeafConceptID X0S0t2614 and X0S0t2613

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
2020-08-04	v2			Add Clinical_Note_Abbr
						Add Dc_Summary_Abbr
2021-02-10  v3          re-write
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_covid_pdoc_test_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	-- Create a new table called 'c_covid_pdoc_test_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_pdoc_test_tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_covid_pdoc_test_tbl;

	/*

	PDOC

	*/
	DECLARE @START DATE;

	SET @START = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()) - 10, 0);

	-- Get DSS Results
	SELECT A.Patient_OID,
		A.PatientVisit_OID,
		A.TextValue,
		A.CreateDTime,
		A.CollectedDTime,
		C.DocumentStatusCd,
		a.LeafConceptId,
		A.DdcDoc_OID,
		[RN] = ROW_NUMBER() OVER (
			PARTITION BY A.PATIENTVISIT_OID,
			A.LEAFCONCEPTID ORDER BY A.CREATEDTIME DESC
			)
	INTO #CTE_DSS
	FROM smsmir.sc_DdcAnswer AS A
	JOIN smsmir.sc_DdcDoc AS B ON A.DdcDoc_OID = B.DdcDoc_OID
		AND A.Patient_OID = B.Patient_OID
		AND A.PatientVisit_OID = B.PatientVisit_OID
	INNER JOIN smsmir.sc_DdcDocVersion AS C ON A.DdcDoc_OID = C.DdcDoc_OID
	WHERE LeafConceptId IN ('X0S0t2614', 'X0S0t2613')
		AND C.DocumentStatusCd IN ('3', '6')
		AND C.VersionId = (
			SELECT MAX(ZZZ.VERSIONID)
			FROM smsmir.sc_DdcDocVersion AS ZZZ
			WHERE ZZZ.DdcDoc_OID = C.DdcDoc_OID
			)
		AND A.CreateDTime = (
			SELECT MAX(XXX.CreateDTime)
			FROM smsmir.mir_sc_DdcAnswer AS XXX
			WHERE XXX.DdcDoc_OID = A.DdcDoc_OID
				--WHERE XXX.PatientVisit_OID = A.PatientVisit_OID
				AND XXX.LeafConceptId IN ('X0S0t2614', 'X0S0t2613')
			)
		AND A.isvalued = '1'
		AND A.CollectedDTime < @START

	SELECT DISTINCT Patient_OID,
		PatientVisit_OID
	INTO #PDOC_DistinctPV_DSS
	FROM #CTE_DSS

	SELECT A.Patient_OID,
		A.PatientVisit_OID
		--, C1.LeafconceptID
		,
		C1.TextValue AS [DC_Summary_CV19_Dx],
		CASE 
			WHEN C1.TextValue = 'NON-COVID-19 / COVID-19 RULED-OUT'
				THEN 'NCRO'
			WHEN C1.TextValue = 'COVID-19 CLINICALLY CONFIRMED / LAB POSITIVE'
				THEN 'CCCLP'
			END AS [Dc_Summary_Abbr],
		C1.CreateDTime AS [DC_Summary_CV19_Dx_CreatedDTime]
		--, C2.LeafConceptID
		,
		C2.TextValue AS [Clinical_Note_CV19_Dx],
		CASE 
			WHEN C2.TextValue = 'COVID 19 SUSPECTED'
				THEN 'CS'
			WHEN C2.TextValue = 'COVID 19 CLINICALLY DIAGNOSED'
				THEN 'CCD'
			WHEN C2.TextValue = 'NON-COVID 19 / ASYMPTOMATIC'
				THEN 'NCA'
			WHEN C2.TextValue = 'COVID 19 POSITIVE LAB TEST'
				THEN 'CPL'
			END AS [Clinical_Note_Abbr],
		C2.CreateDTime AS [Clinical_Note_CV19_Dx_CreatedDTime]
	INTO #PDOC_DSS
	FROM #PDOC_DistinctPV_DSS AS A
	LEFT OUTER JOIN #CTE_DSS AS C1 ON A.PatientVisit_OID = C1.PatientVisit_OID
		AND C1.RN = 1
		AND C1.LeafConceptId = 'X0S0t2614'
	LEFT OUTER JOIN #CTE_DSS AS C2 ON A.PatientVisit_OID = C2.PatientVisit_OID
		AND C2.RN = 1
		AND C2.LeafConceptId = 'X0S0t2613';

	-- Get PRD Results
	SELECT A.Patient_OID,
		A.PatientVisit_OID,
		A.TextValue,
		A.CreateDTime,
		A.CollectedDTime,
		C.DocumentStatusCd,
		a.LeafConceptId,
		A.DdcDoc_OID,
		[RN] = ROW_NUMBER() OVER (
			PARTITION BY A.PATIENTVISIT_OID,
			A.LEAFCONCEPTID ORDER BY A.CREATEDTIME DESC
			)
	INTO #CTE_PRD
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.DdcAnswer AS A
	JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.DdcDoc AS B ON A.DdcDoc_OID = B.DdcDoc_OID
		AND A.Patient_OID = B.Patient_OID
		AND A.PatientVisit_OID = B.PatientVisit_OID
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].[dbo].[DdcDocVersion] AS C ON A.DdcDoc_OID = C.DdcDoc_OID
	WHERE LeafConceptId IN ('X0S0t2614', 'X0S0t2613')
		AND C.DocumentStatusCd IN ('3', '6')
		AND C.VersionId = (
			SELECT MAX(ZZZ.VERSIONID)
			FROM [SC_server].[Soarian_Clin_Prd_1].[dbo].DdcDocVersion AS ZZZ
			WHERE ZZZ.DdcDoc_OID = C.DdcDoc_OID
			)
		AND A.CreateDTime = (
			SELECT MAX(XXX.CreateDTime)
			FROM [SC_server].[Soarian_Clin_Prd_1].[dbo].DdcAnswer AS XXX
			WHERE XXX.DdcDoc_OID = A.DdcDoc_OID
				--WHERE XXX.PatientVisit_OID = A.PatientVisit_OID
				AND XXX.LeafConceptId IN ('X0S0t2614', 'X0S0t2613')
			)
		AND A.isvalued = '1'
		AND A.CollectedDTime >= @START

	SELECT DISTINCT Patient_OID,
		PatientVisit_OID
	INTO #PDOC_DistinctPV_PRD
	FROM #CTE_PRD

	SELECT B.Patient_OID,
		B.PatientVisit_OID
		--, C1.LeafconceptID
		,
		C1.TextValue AS [DC_Summary_CV19_Dx],
		CASE 
			WHEN C1.TextValue = 'NON-COVID-19 / COVID-19 RULED-OUT'
				THEN 'NCRO'
			WHEN C1.TextValue = 'COVID-19 CLINICALLY CONFIRMED / LAB POSITIVE'
				THEN 'CCCLP'
			END AS [Dc_Summary_Abbr],
		C1.CreateDTime AS [DC_Summary_CV19_Dx_CreatedDTime]
		--, C2.LeafConceptID
		,
		C2.TextValue AS [Clinical_Note_CV19_Dx],
		CASE 
			WHEN C2.TextValue = 'COVID 19 SUSPECTED'
				THEN 'CS'
			WHEN C2.TextValue = 'COVID 19 CLINICALLY DIAGNOSED'
				THEN 'CCD'
			WHEN C2.TextValue = 'NON-COVID 19 / ASYMPTOMATIC'
				THEN 'NCA'
			WHEN C2.TextValue = 'COVID 19 POSITIVE LAB TEST'
				THEN 'CPL'
			END AS [Clinical_Note_Abbr],
		C2.CreateDTime AS [Clinical_Note_CV19_Dx_CreatedDTime]
	INTO #PDOC_PRD
	FROM #PDOC_DistinctPV_PRD AS B
	LEFT OUTER JOIN #CTE_PRD AS C1 ON B.PatientVisit_OID = C1.PatientVisit_OID
		AND C1.RN = 1
		AND C1.LeafConceptId = 'X0S0t2614'
	LEFT OUTER JOIN #CTE_PRD AS C2 ON B.PatientVisit_OID = C2.PatientVisit_OID
		AND C2.RN = 1
		AND C2.LeafConceptId = 'X0S0t2613';

	-- Union results together
	SELECT A.Patient_OID,
		A.PatientVisit_OID,
		A.DC_Summary_CV19_Dx,
		A.Dc_Summary_Abbr,
		A.DC_Summary_CV19_Dx_CreatedDTime,
		A.Clinical_Note_CV19_Dx,
		A.Clinical_Note_Abbr,
		A.Clinical_Note_CV19_Dx_CreatedDTime
	INTO smsdss.c_covid_pdoc_test_tbl
	FROM (
		SELECT Patient_OID,
			PatientVisit_OID,
			DC_Summary_CV19_Dx,
			Dc_Summary_Abbr,
			DC_Summary_CV19_Dx_CreatedDTime,
			Clinical_Note_CV19_Dx,
			Clinical_Note_Abbr,
			Clinical_Note_CV19_Dx_CreatedDTime
		FROM #PDOC_PRD
		
		UNION ALL
		
		SELECT Patient_OID,
			PatientVisit_OID,
			DC_Summary_CV19_Dx,
			Dc_Summary_Abbr,
			DC_Summary_CV19_Dx_CreatedDTime,
			Clinical_Note_CV19_Dx,
			Clinical_Note_Abbr,
			Clinical_Note_CV19_Dx_CreatedDTime
		FROM #PDOC_DSS
		) AS A

	-- DROP TEMP TABLES
	DROP TABLE #CTE_DSS

	DROP TABLE #CTE_PRD

	DROP TABLE #PDOC_DistinctPV_DSS

	DROP TABLE #PDOC_DistinctPV_PRD

	DROP TABLE #PDOC_DSS

	DROP TABLE #PDOC_PRD
END;

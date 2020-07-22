USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_pdoc_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.DdcAnswer
	[SC_server].[Soarian_Clin_Prd_1].DBO.DdcDoc
	[SC_server].[Soarian_Clin_Prd_1].[dbo].[DdcDocVersion]

Creates Table:
	smsdss.c_covid_pdoc_tbl

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
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_covid_pdoc_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	
	SET NOCOUNT ON;
	-- Create a new table called 'c_covid_pdoc_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_pdoc_tbl', 'U') IS NOT NULL
	DROP TABLE smsdss.c_covid_pdoc_tbl;

	/*

	PDOC

	*/
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
		INTO #CTE
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

	SELECT DISTINCT Patient_OID, PatientVisit_OID
	INTO #PDOC_DistinctPV
	FROM #CTE

	SELECT A.Patient_OID
	, A.PatientVisit_OID
	--, C1.LeafconceptID
	, C1.TextValue AS [DC_Summary_CV19_Dx]
	, C1.CreateDTime AS [DC_Summary_CV19_Dx_CreatedDTime]
	--, C2.LeafConceptID
	, C2.TextValue AS [Clinical_Note_CV19_Dx]
	, C2.CreateDTime AS [Clinical_Note_CV19_Dx_CreatedDTime]
	INTO #PDOC
	FROM #PDOC_DistinctPV AS A
	LEFT OUTER JOIN #CTE AS C1
	ON A.PatientVisit_OID = C1.PatientVisit_OID
		AND C1.RN = 1
		AND C1.LeafConceptId = 'X0S0t2614'
	LEFT OUTER JOIN #CTE AS C2
	ON A.PatientVisit_OID = C2.PatientVisit_OID
		AND C2.RN = 1
		AND C2.LeafConceptId = 'X0S0t2613';

	SELECT *
	INTO smsdss.c_covid_pdoc_tbl
	FROM #PDOC;

	DROP TABLE #PDOC, #PDOC_DistinctPV, #CTE;

END;
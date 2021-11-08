USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [dbo].[c_covid_flu_results_sp]    Script Date: 11/3/2020 2:53:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_flu_results_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].[DBO].[HORDER]
	[SC_server].[Soarian_Clin_Prd_1].[DBO].[HOCCURRENCEORDER]
	[SC_server].[Soarian_Clin_Prd_1].[DBO].[HInvestigationResult]

Creates Table:
	smsdss.c_covid_flu_results_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get flu results.

	Order:
	OrderAbbreviation = '00424762'

	Results:
	FindingAbbreviation IN ('00424721','00424739')

Revision History:
Date		Version		Description
----		----		----
2020-10-16	v1			Initial Creation
2020-10-30 	v2			Update query to use update logic
2020-11-03	v3			Overhaul only pull in data from investigation results
						drop lastcngdtime
2021-10-29	v4			Add '9785' (FLU_A) and '9786' (FLU_B)
***********************************************************************
*/
ALTER PROCEDURE [dbo].[c_covid_flu_results_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	DECLARE @START_DATE DATE;

	SET @START_DATE = CAST(GETDATE() - 30 AS DATE)

	-- GET ORER RESULTS
	DECLARE @FluResults TABLE (
		id_num INT,
		-- Links to HOccurrence.ObjectID
		OccurrenceOID INT,
		FindingAbbreviation VARCHAR(10),
		ResultDateTime DATETIME2,
		ResultValue VARCHAR(500),
		PatientVisitOID INT,
		--LastCngDtime SMALLDATETIME,
		NewRecord_Flag INT,
		UpdateOrder_Flag INT
		)

	INSERT INTO @FluResults
	SELECT [RN] = ROW_NUMBER() OVER (
			PARTITION BY A.PatientVisit_OID,
			A.Occurrence_OID,
			A.FindingAbbreviation ORDER BY A.ResultDateTime DESC
			),
		A.Occurrence_oid,
		A.FindingAbbreviation,
		A.ResultDateTime,
		REPLACE(REPLACE(A.ResultValue, CHAR(13), ' '), CHAR(10), ' ') AS [ResultValue],
		A.PatientVisit_OID,
		--A.LastCngDtime,
		[NewRecord_Flag] = CASE 
			WHEN A.PatientVisit_oid NOT IN (
					SELECT DISTINCT zzz.PatientVisitOID
					FROM smsdss.c_covid_flu_results_tbl AS ZZZ
					)
				THEN 1
			ELSE 0
			END,
		[UpdateOrder_Flag] = CASE 
			WHEN A.PatientVisit_oid = (
					SELECT ZZZ.PatientVisitOID
					FROM smsdss.c_covid_flu_results_tbl AS ZZZ
					WHERE CAST(A.ResultDateTime AS SMALLDATETIME) > CAST(ZZZ.ResultDateTime AS SMALLDATETIME)
						AND A.PatientVisit_oid = ZZZ.PatientVisitOID
					)
				THEN 1
			ELSE 0
			END
	FROM [SC_server].[Soarian_Clin_Prd_1].[DBO].[HInvestigationResult] AS A
	WHERE A.FindingAbbreviation IN ('00424721', '00424739','9785','9786')
		AND A.ResultValue IS NOT NULL
		AND A.CreationTime >= @START_DATE
	ORDER BY PatientVisit_oid,
		ResultDateTime DESC;

	-- grab only the newest records
	DELETE
	FROM @FluResults
	WHERE id_num != 1;

	-- Pivot Records to get one row per patientvisit_oid
	SELECT PVT.PatientVisitOID,
		PVT.ResultDateTime,
		--PVT.LastCngDtime,
		PVT.UpdateOrder_Flag,
		PVT.NewRecord_Flag,
		COALESCE(PVT.[00424721], PVT.[9785]) AS [Flu_A],
		COALESCE(PVT.[00424739], PVT.[9786]) AS [Flu_B],
		RN = ROW_NUMBER() OVER (
			PARTITION BY PVT.PatientVisitOID ORDER BY PVT.ResultDateTime
			)
	INTO #TEMPA
	FROM (
		SELECT PatientVisitOID,
			FindingAbbreviation,
			ResultValue,
			ResultDateTime,
			--LastCngDtime,
			UpdateOrder_Flag,
			NewRecord_Flag
		FROM @FluResults
		WHERE (
				NewRecord_Flag = 1
				OR UpdateOrder_Flag = 1
				)
		) AS A
	PIVOT(MAX(ResultValue) FOR FindingAbbreviation IN ("00424721", "00424739","9785","9786")) AS PVT
	ORDER BY PVT.PatientVisitOID,
		PVT.ResultDateTime DESC;
		--PVT.LastCngDtime DESC;

	-- grab only the newest records
	DELETE
	FROM #TEMPA
	WHERE RN != 1;

	-- Insert new records not yet in table
	INSERT INTO smsdss.c_covid_flu_results_tbl
	SELECT PatientVisitOID,
		ResultDateTime,
		--LastCngDtime,
		Flu_A,
		Flu_B
	FROM #TEMPA
	WHERE NewRecord_Flag = 1;

	-- UPDATE EXISTING RECORDS IF APPLICABLE
	-- MAKE UPDATE TABLE
	SELECT A.PatientVisitOID,
		A.ResultDateTime,
		--A.LastCngDtime,
		A.Flu_A,
		A.Flu_B
	INTO #UpdateTable
	FROM #TEMPA AS A
	WHERE A.UpdateOrder_Flag = 1;

	-- DROP OLD RECORDS from table
	DELETE
	FROM SMSDSS.c_covid_flu_results_tbl
	WHERE PatientVisitOID IN (
			SELECT DISTINCT PatientVisitOID
			FROM #UpdateTable
			);

	-- insert the updated records
	INSERT INTO SMSDSS.c_covid_flu_results_tbl
	SELECT UT.PatientVisitOID,
		UT.ResultDateTime,
		--UT.LastCngDtime,
		UT.Flu_A,
		UT.Flu_B
	FROM #UpdateTable AS UT;

	DROP TABLE #TEMPA;

	DROP TABLE #UpdateTable;
END
;

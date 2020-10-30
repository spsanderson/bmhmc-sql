USE [SMSPHDSSS0X0]
GO

/****** Object:  StoredProcedure [dbo].[c_covid_flu_results_sp]    Script Date: 10/16/2020 3:34:01 PM ******/
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

	-- FLU ORDERS
	DECLARE @FluOrders TABLE (
		id_num INT IDENTITY(1, 1),
		PatientVisitOID VARCHAR(50),
		OrderID INT,
		OrderAbbreviation VARCHAR(50),
		CreationTime DATETIME2,
		ObjectID INT, -- links to HOrderOccurrence.Order_OID
		LastCngDtime SMALLDATETIME,
		UpdatedOrder_Flag INT
		);

	INSERT INTO @FluOrders
	SELECT PatientVisit_oid,
		OrderId,
		OrderAbbreviation,
		CreationTime,
		ObjectID,
		LastCngDtime,
		[UpdatedOrder_Flag] = CASE 
			WHEN OrderId IN (
					SELECT OrderID
					FROM smsdss.c_covid_flu_results_tbl
					)
				THEN 1
			ELSE 0
			END
	FROM [SC_server].[Soarian_Clin_Prd_1].[DBO].[HORDER]
	WHERE OrderAbbreviation = '00424762'
		AND CreationTime >= @START_DATE
		AND OrderStatusModifier NOT IN ('Cancelled', 'Discontinue', 'Invalid-DC Order')
		AND (
			OrderID NOT IN (
				SELECT ZZZ.OrderID
				FROM smsdss.c_covid_flu_results_tbl AS ZZZ
				)
			OR OrderID IN (
				SELECT ZZZ.OrderID
				FROM smsdss.c_covid_flu_results_tbl AS ZZZ
				WHERE ZZZ.LastCngDtime > LastCngDtime
				)
			)
	ORDER BY PatientVisit_oid,
		CreationTime DESC;

	-- ORDER OCCURRENCE
	DECLARE @FluOrderOcc TABLE (
		id_num INT,
		-- links to HOrder.ObjectID
		Order_OID INT,
		CreationTime DATETIME2,
		OrderOccurrenceStatus VARCHAR(500),
		StatusEnteredDatetime DATETIME2,
		ObjectID INT, -- Links to HInvestigationResults.Occurence_OID
		LastCngDtime SMALLDATETIME
		)

	INSERT INTO @FluOrderOcc
	SELECT [RN] = ROW_NUMBER() OVER (
			PARTITION BY A.ORDER_OID ORDER BY A.STATUSENTEREDDATETIME DESC
			),
		A.Order_oid,
		A.CreationTime,
		A.OrderOccurrenceStatus,
		A.StatusEnteredDatetime,
		A.ObjectID,
		A.LastCngDtime
	FROM [SC_server].[Soarian_Clin_Prd_1].[DBO].[HOCCURRENCEORDER] AS A
	INNER JOIN @FluOrders AS B ON A.Order_oid = B.ObjectID
		AND A.CreationTime = B.CreationTime
	WHERE A.OrderOccurrenceStatus NOT IN ('DISCONTINUE', 'CANCEL')
	ORDER BY A.Order_oid,
		A.ObjectID;

	-- DE-DUPE
	DELETE
	FROM @FluOrderOcc
	WHERE id_num != 1;

	-- GET ORER RESULTS
	DECLARE @FluResults TABLE (
		id_num INT,
		-- Links to HOccurrence.ObjectID
		OccurrenceOID INT,
		FindingAbbreviation VARCHAR(10),
		ResultDateTime DATETIME2,
		ResultValue VARCHAR(500),
		PatientVisitOID INT,
		LastCngDtime SMALLDATETIME
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
		A.LastCngDtime
	FROM [SC_server].[Soarian_Clin_Prd_1].[DBO].[HInvestigationResult] AS A
	INNER JOIN @FluOrderOcc AS B ON A.Occurrence_oid = B.ObjectID
	WHERE A.FindingAbbreviation IN ('00424721', '00424739')
		AND A.ResultValue IS NOT NULL
	ORDER BY A.PatientVisit_oid,
		A.ResultDateTime DESC;

	DELETE
	FROM @FluResults
	WHERE id_num != 1;

	-- PULL TOGETHER
	SELECT A.PatientVisitOID,
		A.OrderID,
		A.OrderAbbreviation,
		A.CreationTime AS [FluOrders_CreationTime],
		A.ObjectID AS [FluOrders_ObjectID],
		B.Order_OID,
		B.CreationTime AS [FluOrdersOccurrence_CreationTime],
		B.OrderOccurrenceStatus,
		B.StatusEnteredDatetime,
		B.ObjectID AS [FluOrdersOccurrence_ObjectID],
		C.OccurrenceOID,
		C.FindingAbbreviation,
		C.ResultDateTime,
		C.ResultValue,
		A.LastCngDtime,
		A.UpdatedOrder_Flag
	INTO #TEMPA
	FROM @FluOrders AS A
	LEFT OUTER JOIN @FluOrderOcc AS B ON A.ObjectID = B.Order_OID
	LEFT OUTER JOIN @FluResults AS C ON B.ObjectID = C.OccurrenceOID
		AND A.PatientVisitOID = C.PatientVisitOID
	WHERE C.ResultValue IS NOT NULL
	ORDER BY A.PatientVisitOID,
		C.ResultDateTime DESC;

	-- RECORD PIVOT
	SELECT PVT.PatientVisitOID,
		PVT.OrderID,
		PVT.OrderAbbreviation,
		PVT.ResultDateTime,
		PVT.LastCngDtime,
		PVT.UpdatedOrder_Flag,
		PVT.[00424721] AS [Flu_A],
		PVT.[00424739] AS [Flu_B]
	INTO #TEMPB
	FROM (
		SELECT PatientVisitOID,
			OrderID,
			OrderAbbreviation,
			FindingAbbreviation,
			ResultDateTime,
			LastCngDtime,
			ResultValue,
			UpdatedOrder_Flag
		FROM #TEMPA
		) A
	PIVOT(MAX(RESULTVALUE) FOR FINDINGABBREVIATION IN ("00424721", "00424739")) AS PVT;

	-- Insert New Records, those where the UpdatedOrder_Flag = 0
	INSERT INTO smsdss.c_covid_flu_results_tbl
	SELECT A.PatientVisitOID,
		A.OrderID,
		A.OrderAbbreviation,
		A.ResultDateTime,
		A.LastCngDtime,
		A.Flu_A,
		A.Flu_B
	FROM #TEMPB AS A
	WHERE UpdatedOrder_Flag = 0

	-- Update Records where UpdatedOrder_Flag = 1
	SELECT A.PatientVisitOID,
		A.OrderID,
		A.OrderAbbreviation,
		A.ResultDateTime,
		A.LastCngDtime,
		A.Flu_A,
		A.Flu_B
	INTO #UpdateTable
	FROM #TEMPB AS A
	WHERE UpdatedOrder_Flag = 1;

	UPDATE SMSDSS.c_covid_flu_results_tbl
	SET PatientVisitOID = UT.PatientVisitOID,
		OrderID = UT.OrderID,
		OrderAbbreviation = UT.OrderAbbreviation,
		ResultDateTime = UT.ResultDateTime,
		LastCngDtime = UT.LastCngDtime,
		Flu_A = UT.Flu_A,
		Flu_B = UT.Flu_B
	FROM #UpdateTable AS UT
	WHERE UT.PatientVisitOID IS NOT NULL;

	DROP TABLE #TEMPA;

	DROP TABLE #TEMPB;

	DROP TABLE #UpdateTable;
END;

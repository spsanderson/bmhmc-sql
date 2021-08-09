USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [dbo].[c_covid_orders_sp]    Script Date: 7/27/2021 2:21:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_orders_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HORDER
	[SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER
	SMSMIR.mir_sc_OccurrenceOrder
	smsmir.mir_sc_Order

Creates Table:
	smsdss.c_covid_orders_tbl
	smsdss.c_covid_order_occ_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get Covid orders for OrderAbbreviation 00425421
    Gets most recent order occurrence and joins

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
2021-02-09	v2			Rewrite using date parameters instead
2021-07-27	v3			Add IN ('00425421','00414086')
***********************************************************************
*/
ALTER PROCEDURE [dbo].[c_covid_orders_sp]
AS
BEGIN
	SET NOCOUNT ON;
	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON

	-- Create a new table called 'c_covid_orders_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_orders_tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_covid_orders_tbl;

	IF OBJECT_ID('smsdss.c_covid_order_occ_tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_covid_order_occ_tbl

	DECLARE @START DATE;

	SET @START = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()) - 10, 0);

	/*
	Creat tables to get the Latest Covid Order for an encounter

	First Get all Orders
	Second Get latest order by PatientVisitOID, CreationTime DESC

	*/
	-- Get all of the orders from PRD on and after the start date
	DECLARE @CovidOrdersPRD TABLE (
		id_num INT IDENTITY(1, 1),
		PatientVisitOID VARCHAR(50),
		OrderID INT,
		OrderAbbreviation VARCHAR(50),
		CreationTime DATETIME2,
		ObjectID INT -- links to HOrderOccurrence.Order_OID
		);

	INSERT INTO @CovidOrdersPRD
	SELECT PatientVisit_OID,
		Orderid,
		OrderAbbreviation,
		CreationTime,
		ObjectID
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HORDER
	WHERE OrderAbbreviation IN ('00425421','00414086')
		AND OrderStatusModifier NOT IN ('Cancelled', 'Discontinue', 'Invalid-DC Order')
		AND CreationTime >= @START

	-- Get all of the orders from DSS before the Start date
	DECLARE @CovidOrdersDSS TABLE (
		id_num INT IDENTITY(1, 1),
		PatientVisitOID VARCHAR(50),
		OrderID INT,
		OrderAbbreviation VARCHAR(50),
		CreationTime DATETIME2,
		ObjectID INT -- links to HOrderOccurrence.Order_OID
		);

	INSERT INTO @CovidOrdersDSS
	SELECT PatientVisit_OID,
		Orderid,
		OrderAbbreviation,
		CreationTime,
		ObjectID
	FROM smsmir.mir_sc_Order
	WHERE OrderAbbreviation IN ('00425421','00414086')
		AND OrderStatusModifier NOT IN ('Cancelled', 'Discontinue', 'Invalid-DC Order')
		AND CreationTime < @START

	DECLARE @CovidOrders TABLE (
		id_num INT,
		PatientVisitOID VARCHAR(50),
		OrderID INT,
		OrderAbbreviation VARCHAR(50),
		CreationTime DATETIME2,
		ObjectID INT -- links to HOrderOccurrence.Order_OID
		)

	INSERT INTO @CovidOrders
	SELECT A.id_num,
		A.PatientVisitOID,
		A.OrderID,
		A.OrderAbbreviation,
		A.CreationTime,
		A.ObjectID
	FROM (
		SELECT id_num,
			PatientVisitOID,
			OrderID,
			OrderAbbreviation,
			CreationTime,
			ObjectID
		FROM @CovidOrdersPRD
		
		UNION ALL
		
		SELECT id_num,
			PatientVisitOID,
			OrderID,
			OrderAbbreviation,
			CreationTime,
			ObjectID
		FROM @CovidOrdersDSS
		) AS A

	SELECT A.id_num,
		A.PatientVisitOID,
		A.OrderID,
		A.OrderAbbreviation,
		A.CreationTime,
		A.ObjectID
	INTO smsdss.c_covid_orders_tbl
	FROM @CovidOrders AS A

	/*
	Creat tables to get the Latest Covid Order Occurrence for an encounter

	First Get all Order Occurrences
	Second Get latest Result by PatientVisitOID, CreationTime DESC

	*/
	-- Get all of the orders from PRD on and after the start date
	DECLARE @CovidOrderOccPRD TABLE (
		id_num INT,
		-- links to HOrder.ObjectID
		Order_OID INT,
		CreationTime DATETIME2,
		OrderOccurrenceStatus VARCHAR(500),
		StatusEnteredDatetime DATETIME2,
		ObjectID INT -- Links to HInvestigationResults.Occurence_OID
		)

	INSERT INTO @CovidOrderOccPRD
	SELECT [RN] = ROW_NUMBER() OVER (
			PARTITION BY A.Order_OID ORDER BY A.StatusEnteredDateTime DESC
			),
		A.Order_OID,
		A.CreationTime,
		A.OrderOccurrenceStatus,
		A.StatusEnteredDateTime,
		A.ObjectID
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER AS A
	INNER JOIN @CovidOrders AS B ON A.ORDER_OID = B.ObjectID
		AND A.CreationTime = B.CreationTime
	WHERE A.OrderOccurrenceStatus NOT IN ('DISCONTINUE', 'Cancel')
		AND A.CreationTime >= @START
	ORDER BY A.Order_OID,
		A.ObjectID;

	-- de duplicate
	DELETE
	FROM @CovidOrderOccPRD
	WHERE id_num != 1;

	-- Get all of the orders from DSS before the Start date
	DECLARE @CovidOrderOccDSS TABLE (
		id_num INT,
		-- links to HOrder.ObjectID
		Order_OID INT,
		CreationTime DATETIME2,
		OrderOccurrenceStatus VARCHAR(500),
		StatusEnteredDatetime DATETIME2,
		ObjectID INT -- Links to HInvestigationResults.Occurence_OID
		)

	INSERT INTO @CovidOrderOccDSS
	SELECT [RN] = ROW_NUMBER() OVER (
			PARTITION BY A.Order_OID ORDER BY A.StatusEnteredDateTime DESC
			),
		A.Order_OID,
		A.CreationTime,
		A.OrderOccurrenceStatus,
		A.StatusEnteredDateTime,
		A.ObjectID
	FROM SMSMIR.mir_sc_OccurrenceOrder AS A
	INNER JOIN @CovidOrders AS B ON A.ORDER_OID = B.ObjectID
		AND A.CreationTime = B.CreationTime
	WHERE A.OrderOccurrenceStatus NOT IN ('DISCONTINUE', 'Cancel')
		AND A.CreationTime < @START
	ORDER BY A.Order_OID,
		A.ObjectID;

	-- de duplicate
	DELETE
	FROM @CovidOrderOccDSS
	WHERE id_num != 1;

	-- Union results together
	DECLARE @CovidOrderOcc TABLE (
		id_num INT,
		-- links to HOrder.ObjectID
		Order_OID INT,
		CreationTime DATETIME2,
		OrderOccurrenceStatus VARCHAR(500),
		StatusEnteredDatetime DATETIME2,
		ObjectID INT -- Links to HInvestigationResults.Occurence_OID
		)

	INSERT INTO @CovidOrderOcc
	SELECT A.id_num,
		A.Order_OID,
		A.CreationTime,
		A.OrderOccurrenceStatus,
		A.StatusEnteredDatetime,
		A.ObjectID
	FROM (
		SELECT id_num,
			Order_OID,
			CreationTime,
			OrderOccurrenceStatus,
			StatusEnteredDatetime,
			ObjectID
		FROM @CovidOrderOccPRD
		
		UNION ALL
		
		SELECT id_num,
			Order_OID,
			CreationTime,
			OrderOccurrenceStatus,
			StatusEnteredDatetime,
			ObjectID
		FROM @CovidOrderOccDSS
		) AS A

	SELECT A.id_num,
		A.Order_OID,
		A.CreationTime,
		A.OrderOccurrenceStatus,
		A.StatusEnteredDatetime,
		A.ObjectID
	INTO smsdss.c_covid_order_occ_tbl
	FROM @CovidOrderOcc AS A
END;



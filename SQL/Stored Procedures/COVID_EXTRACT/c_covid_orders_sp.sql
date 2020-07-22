USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [dbo].[c_covid_orders_sp]    Script Date: 7/9/2020 3:21:14 PM ******/
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

	/*
	Creat tables to get the Latest Covid Order for an encounter

	First Get all Orders
	Second Get latest order by PatientVisitOID, CreationTime DESC

	*/
	DECLARE @CovidOrders TABLE (
		id_num INT IDENTITY(1, 1),
		PatientVisitOID VARCHAR(50),
		OrderID INT,
		OrderAbbreviation VARCHAR(50),
		CreationTime DATETIME2,
		ObjectID INT -- links to HOrderOccurrence.Order_OID
		);

	INSERT INTO @CovidOrders
	SELECT PatientVisit_OID,
		Orderid,
		OrderAbbreviation,
		CreationTime,
		ObjectID
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HORDER
	WHERE OrderAbbreviation = '00425421'
		AND OrderStatusModifier NOT IN ('Cancelled', 'Discontinue', 'Invalid-DC Order')
	ORDER BY PatientVisit_OID,
		CreationTime DESC;

	SELECT *
	INTO smsdss.c_covid_orders_tbl
	FROM @CovidOrders;

	/*
	Creat tables to get the Latest Covid Order Occurrence for an encounter

	First Get all Order Occurrences
	Second Get latest Result by PatientVisitOID, CreationTime DESC

	*/
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
	ORDER BY A.Order_OID,
		A.ObjectID;

	-- de duplicate
	DELETE
	FROM @CovidOrderOcc
	WHERE id_num != 1;

	SELECT *
	INTO smsdss.c_covid_order_occ_tbl
	FROM @CovidOrderOcc;

END;
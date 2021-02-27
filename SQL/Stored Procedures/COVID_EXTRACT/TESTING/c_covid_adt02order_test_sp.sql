USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_adt02order_test_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HORDER
	[SC_SERVER].[SOARIAN_CLIN_PRD_1].DBO.HExtendedOrder
	[SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER
	smsmir.mir_sc_Order
	smsmir.mir_sc_ExtendedOrder
	smsmir.mir_sc_OccurrenceOrder

Creates Table:
	smsdss.c_covid_adt02order_test_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	get last adt02 order

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
2020-08-04	v2			Add Dx_Order_Abbr column
2021-02-24	v3			Complete re-write
***********************************************************************
*/

CREATE PROCEDURE [dbo].[c_covid_adt02order_test_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	-- Create a new table called 'c_covid_adt02order_test_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_adt02order_test_tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_covid_adt02order_test_tbl;

	/*
	Last ADT02 Order
	*/
	-- Get all of the PatientVisitOID for which we want data
	DECLARE @VisitOID TABLE (PatientVisitOID INT);

	INSERT INTO @VisitOID
	SELECT DISTINCT PatientVisitOID
	FROM SMSDSS.c_covid_ptvisitoid_tbl;

	-- Get all of the PatientVisitOID for which we want data
	DECLARE @ADT02OrdersDSS TABLE (
		id_num INT IDENTITY(1, 1),
		PatientVisitOID VARCHAR(50),
		OrderID INT,
		OrderAbbreviation VARCHAR(50),
		CreationTime DATETIME2,
		ObjectID INT, -- links to HOrderOccurrence.Order_OID
		Dx_Order VARCHAR(1000),
		Dx_Order_Abbr VARCHAR(50)
		);

	INSERT INTO @ADT02OrdersDSS
	SELECT A.PatientVisit_OID,
		A.Orderid,
		A.OrderAbbreviation,
		A.CreationTime,
		A.ObjectID,
		B.UserDefinedString55 AS [dx_order],
		CASE 
			WHEN B.UserDefinedString55 = 'COVID 19 SUSPECTED'
				THEN 'CS'
			WHEN B.UserDefinedString55 = 'COVID 19 CLINICALLY DIAGNOSED'
				THEN 'CCD'
			WHEN B.UserDefinedString55 = 'NON-COVID 19 / ASYMPTOMATIC'
				THEN 'NCA'
			WHEN B.UserDefinedString55 = 'COVID 19 POSITIVE LAB TEST'
				THEN 'CPL'
			END AS [dx_order_abbr]
	FROM SMSMIR.mir_sc_Order AS A
	INNER JOIN SMSMIR.mir_sc_ExtendedOrder AS B ON A.ExtendedOrder_OID = B.ObjectID
	WHERE A.OrderAbbreviation = 'ADT02'
		AND A.OrderStatusModifier NOT IN ('Cancelled', 'Discontinue', 'Invalid-DC Order')
		AND A.PatientVisit_oid IN (
			SELECT PatientVisitOID
			FROM @VisitOID
			);

	DECLARE @ADT02OrderOccDSS TABLE (
		id_num INT,
		-- links to HOrder.ObjectID
		Order_OID INT,
		CreationTime DATETIME2,
		OrderOccurrenceStatus VARCHAR(500),
		StatusEnteredDatetime DATETIME2,
		ObjectID INT -- Links to HInvestigationResults.Occurence_OID
		)

	INSERT INTO @ADT02OrderOccDSS
	SELECT [RN] = ROW_NUMBER() OVER (
			PARTITION BY A.Order_OID ORDER BY A.StatusEnteredDateTime DESC
			),
		A.Order_OID,
		A.CreationTime,
		A.OrderOccurrenceStatus,
		A.StatusEnteredDateTime,
		A.ObjectID
	FROM SMSMIR.mir_sc_OccurrenceOrder AS A
	INNER JOIN @ADT02OrdersDSS AS B ON A.Order_oid = B.ObjectID
		AND A.CreationTime = B.CreationTime
	WHERE A.OrderOccurrenceStatus NOT IN ('DISCONTINUE', 'CANCEL');

	DELETE
	FROM @ADT02OrderOccDSS
	WHERE id_num != 1;

	DECLARE @ADT02Final_Tbl_DSS TABLE (
		PatientVisit_OID INT,
		OrderID VARCHAR(100),
		OrderAbbreviation VARCHAR(100),
		Order_DTime DATETIME2,
		Dx_Order VARCHAR(1000),
		Dx_Order_Abbr VARCHAR(50),
		OrderOccurrenceStatus VARCHAR(100),
		StatusEnteredDateTime DATETIME2
		)

	INSERT INTO @ADT02Final_Tbl_DSS
	SELECT A.PatientVisitOID,
		A.OrderID,
		A.OrderAbbreviation,
		A.CreationTime,
		A.Dx_Order,
		A.Dx_Order_Abbr,
		B.OrderOccurrenceStatus,
		B.StatusEnteredDatetime
	FROM @ADT02OrdersDSS AS A
	INNER JOIN @ADT02OrderOccDSS AS B ON A.ObjectID = B.Order_OID
		AND A.CreationTime = B.CreationTime;

	-- Get accounts that are not yet in DSS
	DECLARE @MissingVisitOID TABLE (PatientVisitOID INT)

	INSERT INTO @MissingVisitOID
	SELECT PatientVisitOID
	FROM @VisitOID
	
	EXCEPT
	
	SELECT PatientVisit_OID
	FROM @ADT02Final_Tbl_DSS

	--SELECT * FROM @MissingVisitOID
	-- FROM PRD
	/*
	Last ADT02 Order
	*/
	DECLARE @ADT02OrdersPRD TABLE (
		id_num INT IDENTITY(1, 1),
		PatientVisitOID VARCHAR(50),
		OrderID INT,
		OrderAbbreviation VARCHAR(50),
		CreationTime DATETIME2,
		ObjectID INT, -- links to HOrderOccurrence.Order_OID
		Dx_Order VARCHAR(1000),
		Dx_Order_Abbr VARCHAR(50)
		);

	INSERT INTO @ADT02OrdersPRD
	SELECT A.PatientVisit_OID,
		A.Orderid,
		A.OrderAbbreviation,
		A.CreationTime,
		A.ObjectID,
		B.UserDefinedString55 AS [dx_order],
		CASE 
			WHEN B.UserDefinedString55 = 'COVID 19 SUSPECTED'
				THEN 'CS'
			WHEN B.UserDefinedString55 = 'COVID 19 CLINICALLY DIAGNOSED'
				THEN 'CCD'
			WHEN B.UserDefinedString55 = 'NON-COVID 19 / ASYMPTOMATIC'
				THEN 'NCA'
			WHEN B.UserDefinedString55 = 'COVID 19 POSITIVE LAB TEST'
				THEN 'CPL'
			END AS [dx_order_abbr]
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HORDER AS A
	INNER JOIN [SC_SERVER].[SOARIAN_CLIN_PRD_1].DBO.HExtendedOrder AS B ON A.ExtendedOrder_OID = B.Objectid
	WHERE A.OrderAbbreviation = 'ADT02'
		AND A.OrderStatusModifier NOT IN ('Cancelled', 'Discontinue', 'Invalid-DC Order')
		AND A.PatientVisit_OID IN (
			SELECT PatientVisitOID
			FROM @MissingVisitOID
			)

	DECLARE @ADT02OrderOccPRD TABLE (
		id_num INT,
		-- links to HOrder.ObjectID
		Order_OID INT,
		CreationTime DATETIME2,
		OrderOccurrenceStatus VARCHAR(500),
		StatusEnteredDatetime DATETIME2,
		ObjectID INT -- Links to HInvestigationResults.Occurence_OID
		)

	INSERT INTO @ADT02OrderOccPRD
	SELECT [RN] = ROW_NUMBER() OVER (
			PARTITION BY A.Order_OID ORDER BY A.StatusEnteredDateTime DESC
			),
		A.Order_OID,
		A.CreationTime,
		A.OrderOccurrenceStatus,
		A.StatusEnteredDateTime,
		A.ObjectID
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER AS A
	INNER JOIN @ADT02OrdersPRD AS B ON A.ORDER_OID = B.ObjectID
		AND A.CreationTime = B.CreationTime
	WHERE A.OrderOccurrenceStatus NOT IN ('DISCONTINUE', 'Cancel')

	-- de duplicate
	DELETE
	FROM @ADT02OrderOccPRD
	WHERE id_num != 1;

	DECLARE @ADT02Final_Tbl_PRD TABLE (
		PatientVisit_OID INT,
		OrderID VARCHAR(100),
		OrderAbbreviation VARCHAR(100),
		Order_DTime DATETIME2,
		Dx_Order VARCHAR(1000),
		Dx_Order_Abbr VARCHAR(50),
		OrderOccurrenceStatus VARCHAR(100),
		StatusEnteredDateTime DATETIME2
		)

	INSERT INTO @ADT02Final_Tbl_PRD
	SELECT A.PatientVisitOID,
		A.OrderID,
		A.OrderAbbreviation,
		A.CreationTime,
		A.Dx_Order,
		A.Dx_Order_Abbr,
		B.OrderOccurrenceStatus,
		B.StatusEnteredDatetime
	FROM @ADT02OrdersPRD AS A
	INNER JOIN @ADT02OrderOccPRD AS B ON A.ObjectID = B.Order_OID
		AND A.CreationTime = B.CreationTime;

	-- UNION RESULTS
	SELECT A.PatientVisit_OID,
		A.OrderID,
		A.OrderAbbreviation,
		A.Order_DTime,
		A.Dx_Order,
		A.Dx_Order_Abbr,
		A.OrderOccurrenceStatus,
		A.StatusEnteredDateTime
	INTO smsdss.c_covid_adt02order_test_tbl
	FROM (
		SELECT PatientVisit_OID,
			OrderID,
			OrderAbbreviation,
			Order_DTime,
			Dx_Order,
			Dx_Order_Abbr,
			OrderOccurrenceStatus,
			StatusEnteredDateTime
		FROM @ADT02Final_Tbl_DSS
		
		UNION
		
		SELECT PatientVisit_OID,
			OrderID,
			OrderAbbreviation,
			Order_DTime,
			Dx_Order,
			Dx_Order_Abbr,
			OrderOccurrenceStatus,
			StatusEnteredDateTime
		FROM @ADT02Final_Tbl_PRD
		) AS A;
END;

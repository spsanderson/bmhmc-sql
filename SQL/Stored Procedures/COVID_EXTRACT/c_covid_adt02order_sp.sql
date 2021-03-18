USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [dbo].[c_covid_adt02order_sp]    Script Date: 8/4/2020 1:14:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_adt02order_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HORDER
	[SC_SERVER].[SOARIAN_CLIN_PRD_1].DBO.HExtendedOrder
	[SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER

Creates Table:
	smsdss.c_covid_adt02order_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	get ht wt admit and comorbidities

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
2020-08-04	v2			Add Dx_Order_Abbr column
2021-03-09	v3			Drop looking up order occurrence since it is a 
						one to one with the actual order.
***********************************************************************
*/

ALTER PROCEDURE [dbo].[c_covid_adt02order_sp]
AS

	SET ANSI_NULLS ON
	SET ANSI_WARNINGS ON
	SET QUOTED_IDENTIFIER ON

BEGIN
	
	SET NOCOUNT ON;
	-- Create a new table called 'c_covid_adt02order_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_adt02order_tbl', 'U') IS NOT NULL
	DROP TABLE smsdss.c_covid_adt02order_tbl;

	/*
	Last ADT02 Order
	*/
	DECLARE @ADT02Orders TABLE (
		id_num INT IDENTITY(1, 1),
		PatientVisitOID VARCHAR(50),
		OrderID INT,
		OrderAbbreviation VARCHAR(50),
		CreationTime DATETIME2,
		ObjectID INT, -- links to HOrderOccurrence.Order_OID
		Dx_Order VARCHAR(1000),
		Dx_Order_Abbr VARCHAR(50)
		);

	INSERT INTO @ADT02Orders
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
			SELECT DISTINCT PatientVisitOID
			FROM smsdss.c_covid_patient_visit_data_tbl
			)
	ORDER BY PatientVisit_OID,
		CreationTime DESC;

	--DECLARE @ADT02OrderOcc TABLE (
	--	id_num INT,
	--	-- links to HOrder.ObjectID
	--	Order_OID INT,
	--	CreationTime DATETIME2,
	--	OrderOccurrenceStatus VARCHAR(500),
	--	StatusEnteredDatetime DATETIME2,
	--	ObjectID INT -- Links to HInvestigationResults.Occurence_OID
	--	)

	--INSERT INTO @ADT02OrderOcc
	--SELECT [RN] = ROW_NUMBER() OVER (
	--		PARTITION BY A.Order_OID ORDER BY A.StatusEnteredDateTime DESC
	--		),
	--	A.Order_OID,
	--	A.CreationTime,
	--	A.OrderOccurrenceStatus,
	--	A.StatusEnteredDateTime,
	--	A.ObjectID
	--FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER AS A
	--INNER JOIN @ADT02Orders AS B ON A.ORDER_OID = B.ObjectID
	--	AND A.CreationTime = B.CreationTime
	--WHERE A.OrderOccurrenceStatus NOT IN ('DISCONTINUE', 'Cancel')
	--ORDER BY A.Order_OID,
	--	A.ObjectID;

	---- de duplicate
	--DELETE
	--FROM @ADT02OrderOcc
	--WHERE id_num != 1;

	DECLARE @ADT02Final_Tbl TABLE (
		PatientVisit_OID INT,
		OrderID VARCHAR(100),
		OrderAbbreviation VARCHAR(100),
		Order_DTime DATETIME2,
		Dx_Order VARCHAR(1000),
		Dx_Order_Abbr VARCHAR(50)--,
		--OrderOccurrenceStatus VARCHAR(100),
		--StatusEnteredDateTime DATETIME2
		)

	INSERT INTO @ADT02Final_Tbl
	SELECT A.PatientVisitOID,
		A.OrderID,
		A.OrderAbbreviation,
		A.CreationTime,
		A.Dx_Order,
		A.Dx_Order_Abbr--,
	--	B.OrderOccurrenceStatus,
	--	B.StatusEnteredDatetime
	FROM @ADT02Orders AS A
	--INNER JOIN @ADT02OrderOcc AS B ON A.ObjectID = B.Order_OID
	--	AND A.CreationTime = B.CreationTime;

	SELECT *
	INTO smsdss.c_covid_adt02order_tbl
	FROM @ADT02Final_Tbl

END;
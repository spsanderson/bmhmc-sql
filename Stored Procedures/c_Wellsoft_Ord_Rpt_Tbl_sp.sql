USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[c_Wellsoft_Ord_Rpt_Tbl_sp]    Script Date: 2/9/2016 9:00:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ====================================================================
-- Author:		Steven Sanderson
-- Create date: 02-08-2016
-- Description:	Create a reportable Wellsoft orders table bound to the
-- smsdss schema None of the orders in this procedure will be of 
-- canceled status
-- ====================================================================

ALTER PROCEDURE [smsdss].[c_Wellsoft_Ord_Rpt_Tbl_sp]
AS

BEGIN

	SET NOCOUNT ON;

	IF OBJECT_ID('smsdss.c_Wellsoft_Ord_Rpt_Tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_Wellsoft_Ord_Rpt_Tbl;

	SELECT A.[Patient]
	, CAST(dbo.c_udf_NumericChars(A.[Account]) AS INT) AS [Account] 
	, CAST(dbo.c_udf_NumericChars(A.[MR#]) AS INT)     AS [MR#]
	, B.[OrderName]
	, B.[Placer#]
	, B.[Filler#]
	, CONVERT(VARCHAR,
	  SUBSTRING(dbo.c_udf_AlphaNumericChars(B.[SchedDT]), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(B.[SchedDT]), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(B.[SchedDT]), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(B.[SchedDT]), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(B.[SchedDT]), 11, 2) + ':00',
	  120)                                             AS SchedDT
	, CONVERT(VARCHAR,
	  SUBSTRING(dbo.c_udf_AlphaNumericChars(B.[InProgDT]), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(B.[InProgDT]), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(B.[InProgDT]), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(B.[InProgDT]), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(B.[InProgDT]), 11, 2) + ':00',
	  120)                                             AS InProgDT
	, CONVERT(VARCHAR,
	  SUBSTRING(dbo.c_udf_AlphaNumericChars(B.[CompDT]), 1, 4) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(B.[CompDT]), 5, 2) + '-' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(B.[CompDT]), 7, 2) + ' ' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(B.[CompDT]), 9, 2) + ':' +
	  SUBSTRING(DBO.c_udf_AlphaNumericChars(B.[CompDT]), 11, 2) + ':00',
	  120)                                             AS CompDT
	, RIGHT(B.[MDSigntr], 14)                          AS MD_Signature
	, ROW_NUMBER() OVER(
		PARTITION BY A.[Account], B.[UnivCode]
		ORDER BY B.[SchedDT]
	)                                                  AS [RN]

	INTO smsdss.c_Wellsoft_Ord_Rpt_Tbl

	FROM [BMH-EDIS-CL]..[WELLUSER].[Patient_Chart]             A
	LEFT OUTER JOIN [BMH-EDIS-CL]..[WELLUSER].[Patient_Orders] B
	ON A.MASTER_REC_ID = B.MASTER_REC_ID

	WHERE B.SentTo != 'Canceled'
	AND A.[Account] != '1234567890'
	AND A.[Account] != '1356718513566856'
	AND LEN(A.[Account]) = 8
	AND LEN(A.[MR#]) = 6
	
END


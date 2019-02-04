USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[c_lihn_svc_dept_desc_bench_sp]    Script Date: 1/17/2019 8:13:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
*****************************************************************************  
File: c_lihn_svc_dept_desc_bench_sp.sql      

Input  Parameters:
	None

Tables:   
	smsdss.c_elos_bench-data
	smsdss.c_Lab_Rad_Order_Utilization
  
Functions:
	None

Author: Steve P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose:
	This creates a benchmarking table for the short order utilization report
	for Dr. Wehbeh and Nona
      
Revision History: 
Date		Version		Description
----		----		----
2018-10-11	v1			Initial Creation
2018-11-01	v2			Take out glucometer readings per discussion with CQMO
						Change Order_Year to Benchmark_Year
						Add Report Year (Benchmark_Year + 1)
2019-01-17	v3			Fix Order_Year > in ELSE statement to use MAX(ZZZ.Benchmark_Year)		
						NOT MAX(ZZZ.Order_Year)
-------------------------------------------------------------------------------- 
*/

ALTER PROCEDURE [smsdss].[c_lihn_svc_dept_desc_bench_sp]
AS

IF NOT EXISTS(
	SELECT TOP 1 * FROM SYSOBJECTS WHERE name = 'c_order_utilization_lihn_svc_w_order_dept_desc_bench' AND xtype = 'U'
)

BEGIN

	CREATE TABLE smsdss.c_order_utilization_lihn_svc_w_order_dept_desc_bench (
		LIHN_Svc_Dept_Desc NVARCHAR(276)
		, LIHN_Service_line NVARCHAR(255)
		, Svc_Sub_Dept_Desc VARCHAR(18)
		, ELOS FLOAT
		, [Order Count] INT
		, PT_Count INT
		, Avg_Ord_Per_Pt_ELOS FLOAT
		, Avg_Ord_Per_Pt FLOAT
		, Rundate DATE
		, RunDTime DATETIME
		, Benchmark_Year INT
		, Report_Year INT
	)

	DECLARE @TODAY DATE;
	DECLARE @END   DATE;

	SET @TODAY = GETDATE();
	SET @END   = DATEADD(YEAR, DATEDIFF(YEAR, 0, @TODAY), 0);

	SELECT A.LIHN_Service_Line
	, B.Svc_Sub_Dept_Desc
	, YEAR(B.Ord_Entry_DTime)      AS [Order_Year]
	, ROUND(AVG(A.Performance), 2) AS [elos]
	, COUNT(b.Order_No)            AS [order count]
	, COUNT(distinct(a.Encounter)) AS pt_count

	INTO #TEMP_A

	FROM smsdss.c_elos_bench_data                AS A
	LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization AS B
	ON a.Encounter = b.Encounter

	WHERE B.Ord_Entry_DTime >= '2015-01-01'
	AND B.Ord_Entry_DTime < @END
	AND B.Svc_Sub_Dept_Desc IS NOT NULL
	AND A.Encounter IS NOT NULL
	AND B.Ord_Pty_Number IS NOT NULL
	AND B.Ord_Pty_Number != '000000'
	AND B.Ord_Pty_Number != '000059'
	-- Get rid of Glucose Testing
	AND B.svc_cd NOT IN (
		'00401760'
		, '00425157'
		, '00409748'
	)

	GROUP BY  A.LIHN_Service_Line, B.Svc_Sub_Dept_Desc, YEAR(B.Ord_Entry_DTime)

	ORDER BY A.LIHN_Service_Line, B.Svc_Sub_Dept_Desc, YEAR(B.Ord_Entry_DTime)
	;

	-----
	INSERT INTO smsdss.c_order_utilization_lihn_svc_w_order_dept_desc_bench
	
	SELECT CONCAT(A.LIHN_SERVICE_LINE, ' - ', A.SVC_SUB_DEPT_DESC)
	, A.LIHN_Service_Line
	, A.Svc_Sub_Dept_Desc
	, A.elos
	, A.[order count]
	, A.pt_count
	, ROUND((A.[order count] / A.elos) / A.pt_count, 2)
	, ROUND(A.[ORDER COUNT] / CAST(A.PT_COUNT AS float), 2)
	, Rundate = CAST(GETDATE() AS date)
	, RunDTime = GETDATE()
	, a.Order_Year
	, (a.Order_Year + 1)

	FROM #TEMP_A AS A

	DROP TABLE #TEMP_A

END

ELSE BEGIN

	DECLARE @TODAY_B DATE;
	DECLARE @START_B DATE;
	DECLARE @END_B   DATE;

	SET @TODAY_B = GETDATE();
	SET @START_B = DATEADD(YEAR, DATEDIFF(YEAR, 0, @TODAY_B) -1, 0);
	SET @END_B   = DATEADD(YEAR, DATEDIFF(YEAR, 0, @TODAY_B), 0);

	SELECT A.LIHN_Service_Line
	, B.Svc_Sub_Dept_Desc
	, YEAR(B.Ord_Entry_DTime)      AS [Order_Year]
	, ROUND(AVG(A.Performance), 2) AS [elos]
	, COUNT(b.Order_No)            AS [order count]
	, COUNT(distinct(a.Encounter)) AS pt_count

	INTO #TEMP_B

	FROM smsdss.c_elos_bench_data                AS A
	LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization AS B
	ON a.Encounter = b.Encounter

	WHERE B.Ord_Entry_DTime >= @START_B
	AND B.Ord_Entry_DTime < @END_B
	AND B.Svc_Sub_Dept_Desc IS NOT NULL
	AND A.Encounter IS NOT NULL
	AND B.Ord_Pty_Number IS NOT NULL
	AND B.Ord_Pty_Number != '000000'
	AND B.Ord_Pty_Number != '000059'
	-- Get rid of Glucose Testing
	AND B.svc_cd NOT IN (
		'00401760'
		, '00425157'
		, '00409748'
	)

	GROUP BY  A.LIHN_Service_Line, B.Svc_Sub_Dept_Desc, YEAR(B.Ord_Entry_DTime)

	ORDER BY A.LIHN_Service_Line, B.Svc_Sub_Dept_Desc, YEAR(B.Ord_Entry_DTime)
	;

	-----
	INSERT INTO smsdss.c_order_utilization_lihn_svc_w_order_dept_desc_bench

	SELECT CONCAT(A.LIHN_SERVICE_LINE, ' - ', A.SVC_SUB_DEPT_DESC)
	, A.LIHN_Service_Line
	, A.Svc_Sub_Dept_Desc
	, A.elos
	, A.[order count]
	, A.pt_count
	, ROUND((A.[order count] / A.elos) / A.pt_count, 2)
	, ROUND(A.[ORDER COUNT] / CAST(A.PT_COUNT AS float), 2)
	, Rundate = CAST(GETDATE() AS date)
	, RunDTime = GETDATE()
	, Order_Year
	, (Order_Year + 1)

	FROM #TEMP_B AS A

	WHERE Order_Year > (
		SELECT MAX(ZZZ.Benchmark_Year)
		FROM smsdss.c_order_utilization_lihn_svc_w_order_dept_desc_bench AS ZZZ
	)

	DROP TABLE #TEMP_B

END
;
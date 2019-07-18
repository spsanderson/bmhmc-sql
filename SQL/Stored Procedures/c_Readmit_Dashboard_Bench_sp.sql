USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[c_Readmit_Dashboard_Bench_sp]    Script Date: 7/18/2018 11:01:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_Readmit_Dashboard_Bench_sp.sql

Input Parameters: None

Tables/Views:
	smsdss.BMH_PLM_PtAcct_V
	Customer.Custom_DRG
	smsdss.vReadmits
	smsdss.c_LIHN_Svc_Line_Tbl

Creates Table:
	smsdss.c_Readmit_Dashboard_Bench

Functions: None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

This sp creates a table to get all readmit benchmark rates by LIHN
Service Line and SOI. For example:

SvcLine	SOI	Rate
----	---	----
COPD	1	0.12

Revision History:
Date		Version		Description
----		----		----
2018-07-13	v1			Initial Creation
2018-07-18	v2			Change ROUND function from 2 decimals places to 4
***********************************************************************
*/

ALTER PROCEDURE [smsdss].[c_Readmit_Dashboard_Bench_sp]
AS

IF NOT EXISTS(
	SELECT TOP 1 * FROM SYSOBJECTS WHERE name = 'c_Readmit_Dashboard_Bench_Tbl'
)

BEGIN

	DECLARE @TODAY DATE;
	DECLARE @START DATE;
	DECLARE @END   DATE;

	SET @TODAY = GETDATE();
	SET @START = DATEADD(YEAR, DATEDIFF(YEAR, 0, @TODAY) - 3, 0);
	SET @END   = DATEADD(YEAR, DATEDIFF(YEAR, 0, @TODAY), 0);

	CREATE TABLE smsdss.c_Readmit_Dashboard_Bench_Tbl (
		BENCH_YR CHAR(4)
		, LIHN_SVC_LINE VARCHAR(100)
		, SOI TINYINT
		, VISIT_COUNT INT
		, READMIT_COUNT INT
		, READMIT_RATE FLOAT
	)

	SELECT D.LIHN_Svc_Line
	, B.SEVERITY_OF_ILLNESS
	, 1 AS [Encounter_Flag]
	, CASE
		WHEN C.READMIT IS NOT NULL
			THEN 1
			ELSE 0
	  END AS [RA_Flag]
	, DATEPART(YEAR, A.Dsch_Date) AS [Bench_Yr]

	INTO #TEMPA

	FROM smsdss.BMH_PLM_PtAcct_V AS A
	LEFT OUTER JOIN Customer.Custom_DRG AS B
	ON A.PtNo_Num = B.PATIENT#
	LEFT OUTER JOIN smsdss.vReadmits AS C
	ON A.PtNo_Num = C.[INDEX]
		AND C.[INTERIM] < 31
		AND C.[READMIT SOURCE DESC] != 'Scheduled Admission'
	LEFT OUTER JOIN smsdss.c_LIHN_Svc_Line_Tbl AS D
	ON A.PtNo_Num = D.Encounter
		AND A.prin_dx_cd_schm = D.prin_dx_cd_schme

	WHERE A.Dsch_Date >= @START
	AND A.Dsch_Date < @END
	AND A.drg_no IS NOT NULL
	AND A.tot_chg_amt > 0
	AND A.dsch_disp IN ('AHR', 'ATW')
	AND B.APRDRGNO NOT IN (
		SELECT ZZZ.[APR-DRG]
		FROM smsdss.c_ppr_apr_drg_global_exclusions AS ZZZ
	)
	AND B.SEVERITY_OF_ILLNESS != 0
	AND D.LIHN_Svc_Line IS NOT NULL
	;

	INSERT INTO smsdss.c_Readmit_Dashboard_Bench_Tbl

	SELECT A.[Bench_Yr]
	, A.LIHN_Svc_Line
	, A.SEVERITY_OF_ILLNESS
	, SUM(A.Encounter_Flag) AS [Visit_Count]
	, SUM(A.RA_Flag) AS [Readmit_Count]
	, ROUND(SUM(CAST(A.RA_Flag AS float)) / SUM(CAST(A.Encounter_Flag AS float)), 4) AS [Readmit_Rate]

	FROM #TEMPA AS A

	GROUP BY A.Bench_Yr
	, A.LIHN_Svc_Line
	, A.SEVERITY_OF_ILLNESS

	ORDER BY A.Bench_Yr
	, A.LIHN_Svc_Line
	, A.SEVERITY_OF_ILLNESS
	;

	DROP TABLE #TEMPA
	;

END

ELSE BEGIN

	DECLARE @TODAY2 DATE;
	DECLARE @START2 DATE;
	DECLARE @END2   DATE;

	SET @TODAY2 = GETDATE();
	SET @START2 = DATEADD(YEAR, DATEDIFF(YEAR, 0, @TODAY2) - 1, 0);
	SET @END2   = DATEADD(YEAR, DATEDIFF(YEAR, 0, @TODAY2), 0);

	SELECT D.LIHN_Svc_Line
	, B.SEVERITY_OF_ILLNESS
	, 1 AS [Encounter_Flag]
	, CASE
		WHEN C.READMIT IS NOT NULL
			THEN 1
			ELSE 0
	  END AS [RA_Flag]
	, DATEPART(YEAR, A.Dsch_Date) AS [Bench_Yr]

	INTO #TEMPA2

	FROM smsdss.BMH_PLM_PtAcct_V AS A
	LEFT OUTER JOIN Customer.Custom_DRG AS B
	ON A.PtNo_Num = B.PATIENT#
	LEFT OUTER JOIN smsdss.vReadmits AS C
	ON A.PtNo_Num = C.[INDEX]
		AND C.[INTERIM] < 31
		AND C.[READMIT SOURCE DESC] != 'Scheduled Admission'
	LEFT OUTER JOIN smsdss.c_LIHN_Svc_Line_Tbl AS D
	ON A.PtNo_Num = D.Encounter
		AND A.prin_dx_cd_schm = D.prin_dx_cd_schme

	WHERE A.Dsch_Date >= @START2
	AND A.Dsch_Date < @END2
	AND DATEPART(YEAR, A.DSCH_DATE) NOT IN (
		SELECT DISTINCT(ZZZ.BENCH_YR)
		FROM smsdss.c_Readmit_Dashboard_Bench_Tbl AS ZZZ
	)
	AND A.drg_no IS NOT NULL
	AND A.tot_chg_amt > 0
	AND A.dsch_disp IN ('AHR', 'ATW')
	AND B.APRDRGNO NOT IN (
		SELECT ZZZ.[APR-DRG]
		FROM smsdss.c_ppr_apr_drg_global_exclusions AS ZZZ
	)
	AND B.SEVERITY_OF_ILLNESS != 0
	AND D.LIHN_Svc_Line IS NOT NULL
	;

	INSERT INTO smsdss.c_Readmit_Dashboard_Bench_Tbl

	SELECT A.[Bench_Yr]
	, A.LIHN_Svc_Line
	, A.SEVERITY_OF_ILLNESS
	, SUM(A.Encounter_Flag) AS [Visit_Count]
	, SUM(A.RA_Flag) AS [Readmit_Count]
	, ROUND(SUM(CAST(A.RA_Flag AS float)) / SUM(CAST(A.Encounter_Flag AS float)), 4) AS [Readmit_Rate]

	FROM #TEMPA2 AS A

	GROUP BY A.Bench_Yr
	, A.LIHN_Svc_Line
	, A.SEVERITY_OF_ILLNESS

	ORDER BY A.Bench_Yr
	, A.LIHN_Svc_Line
	, A.SEVERITY_OF_ILLNESS
	;

	DROP TABLE #TEMPA2
	;

END
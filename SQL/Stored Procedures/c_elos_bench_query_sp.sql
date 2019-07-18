USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
***********************************************************************
File: c_elos_bench_query_sp.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_LIHN_Svc_Line_tbl
	smsdss.BMH_PLM_PtAcct_V
	Customer.Custom_DRG
	smsdss.c_LIHN_SPARCS_BenchmarkRates
	smsdss.pract_dim_v
    smsdss.c_LIHN_APR_DRG_OutlierThresholds AS f
	smsdss.pyr_dim_v AS G

Creates Table:
	smsdss.c_elos_bench_data

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Update the smsdss.c_elos_bench_data report table monthly

Revision History:
Date		Version		Description
----		----		----
2018-11-16	v1			Initial Creation
********************************************************************
*/
CREATE PROCEDURE smsdss.c_elos_bench_sp
AS

IF NOT EXISTS (
	SELECT TOP 1 * FROM SYSOBJECTS WHERE name = 'c_elos_bench_data' AND xtype = 'U'
)

BEGIN

	CREATE TABLE smsdss.c_elos_bench_data (
		Encounter VARCHAR(12) NOT NULL
		, Dsch_Date DATE
		, LOS INT
		, LIHN_Service_Line VARCHAR(150)
		, [AP-DRG] VARCHAR(5)
		, SOI CHAR(1)
		, LIHN_Svc_Line_APR_SOI VARCHAR(200)
		, Performance FLOAT
		, Threshold INT
		, [In or Outside Threshold] VARCHAR(50)
	)
	;

	SELECT b.PtNo_Num
	, b.Dsch_Date
	, CASE
		WHEN b.Days_Stay = '0'
			THEN '1'
			ELSE b.Days_Stay
	  END                   AS [LOS]
	, a.LIHN_Svc_Line
	, c.APRDRGNO
	, c.SEVERITY_OF_ILLNESS
	, CASE 
		WHEN d.Performance = '0'
			THEN '1'
		WHEN d.Performance IS null 
		AND b.Days_Stay = 0
			THEN '1'
		WHEN d.Performance IS null
		AND b.days_stay != 0
			THEN b.Days_Stay
			ELSE d.Performance
	  END                   AS [Performance]
	, f.[Outlier Threshold] AS [Threshold]

	INTO #TEMPA

	FROM smsdss.c_LIHN_Svc_Line_tbl                   AS a
	LEFT JOIN smsdss.BMH_PLM_PtAcct_V                 AS b
	ON a.Encounter = b.Pt_No
	LEFT JOIN Customer.Custom_DRG                     AS c
	ON b.PtNo_Num = c.PATIENT#
	LEFT JOIN smsdss.c_LIHN_SPARCS_BenchmarkRates     AS d
	ON c.APRDRGNO = d.[APRDRG Code]
		AND c.SEVERITY_OF_ILLNESS = d.SOI
		AND d.[Measure ID] = 4
		AND d.[Benchmark ID] = 3
		AND a.LIHN_Svc_Line = d.[LIHN Service Line]
	LEFT JOIN smsdss.pract_dim_v                      AS e
	ON b.Atn_Dr_No = e.src_pract_no
		AND e.orgz_cd = 's0x0'
	LEFT JOIN smsdss.c_LIHN_APR_DRG_OutlierThresholds AS f
	ON c.APRDRGNO = f.[apr-drgcode]
	LEFT JOIN smsdss.pyr_dim_v AS G
	ON B.Pyr1_Co_Plan_Cd = G.pyr_cd
		AND b.Regn_Hosp = G.orgz_cd

	WHERE b.drg_no NOT IN (
		'0','981','982','983','984','985',
		'986','987','988','989','998','999'
	)
	AND b.Plm_Pt_Acct_Type = 'I'
	AND LEFT(B.PTNO_NUM, 1) != '2'
	AND LEFT(b.PtNo_Num, 4) != '1999'
	AND b.tot_chg_amt > 0
	AND e.med_staff_dept NOT IN ('?', 'Anesthesiology', 'Emergency Department')

	OPTION(FORCE ORDER)
	;

	INSERT INTO smsdss.c_elos_bench_data

	SELECT A.PtNo_Num       AS [Encounter]
	, A.Dsch_Date
	, CAST(A.LOS as int)    AS [LOS]
	, A.LIHN_Svc_Line       AS [LIHN_Service_Line]
	, A.APRDRGNO            AS [AP-DRG]
	, A.SEVERITY_OF_ILLNESS AS [SOI]
	, (
		CAST(A.LIHN_SVC_LINE AS varchar) +
		'' +
		CAST(A.APRDRGNO AS varchar) +
		'' +
		CAST(A.SEVERITY_OF_ILLNESS AS varchar)
	) AS LIHN_Svc_Line_APR_SOI
	, A.Performance
	, A.Threshold
	, CASE
		WHEN a.LOS > A.[Threshold]
			THEN 'Outside Threshold'
			ELSE 'Inside Threshold'
	  END                   AS [In or Outside Threshold]

	FROM #TEMPA AS A

	WHERE A.APRDRGNO IS NOT NULL
	AND A.SEVERITY_OF_ILLNESS IS NOT NULL
	;

	DROP TABLE #TEMPA
	;

END

ELSE BEGIN

	SELECT b.PtNo_Num
	, b.Dsch_Date
	, CASE
		WHEN b.Days_Stay = '0'
			THEN '1'
			ELSE b.Days_Stay
	  END                   AS [LOS]
	, a.LIHN_Svc_Line
	, c.APRDRGNO
	, c.SEVERITY_OF_ILLNESS
	, CASE 
		WHEN d.Performance = '0'
			THEN '1'
		WHEN d.Performance IS null 
		AND b.Days_Stay = 0
			THEN '1'
		WHEN d.Performance IS null
		AND b.days_stay != 0
			THEN b.Days_Stay
			ELSE d.Performance
	  END                   AS [Performance]
	, f.[Outlier Threshold] AS [Threshold]

	INTO #TEMPAA

	FROM smsdss.c_LIHN_Svc_Line_tbl                   AS a
	LEFT JOIN smsdss.BMH_PLM_PtAcct_V                 AS b
	ON a.Encounter = b.Pt_No
	LEFT JOIN Customer.Custom_DRG                     AS c
	ON b.PtNo_Num = c.PATIENT#
	LEFT JOIN smsdss.c_LIHN_SPARCS_BenchmarkRates     AS d
	ON c.APRDRGNO = d.[APRDRG Code]
		AND c.SEVERITY_OF_ILLNESS = d.SOI
		AND d.[Measure ID] = 4
		AND d.[Benchmark ID] = 3
		AND a.LIHN_Svc_Line = d.[LIHN Service Line]
	LEFT JOIN smsdss.pract_dim_v                      AS e
	ON b.Atn_Dr_No = e.src_pract_no
		AND e.orgz_cd = 's0x0'
	LEFT JOIN smsdss.c_LIHN_APR_DRG_OutlierThresholds AS f
	ON c.APRDRGNO = f.[apr-drgcode]
	LEFT JOIN smsdss.pyr_dim_v AS G
	ON B.Pyr1_Co_Plan_Cd = G.pyr_cd
		AND b.Regn_Hosp = G.orgz_cd

	WHERE b.drg_no NOT IN (
		'0','981','982','983','984','985',
		'986','987','988','989','998','999'
	)
	AND b.Plm_Pt_Acct_Type = 'I'
	AND LEFT(B.PTNO_NUM, 1) != '2'
	AND LEFT(b.PtNo_Num, 4) != '1999'
	AND b.tot_chg_amt > 0
	AND e.med_staff_dept NOT IN ('?', 'Anesthesiology', 'Emergency Department')
	AND B.PtNo_Num NOT IN (
		SELECT ZZZ.Encounter
		FROM smsdss.c_elos_bench_data AS ZZZ
	)

	OPTION(FORCE ORDER)
	;

	INSERT INTO smsdss.c_elos_bench_data

	SELECT A.PtNo_Num       AS [Encounter]
	, A.Dsch_Date
	, CAST(A.LOS as int)    AS [LOS]
	, A.LIHN_Svc_Line       AS [LIHN_Service_Line]
	, A.APRDRGNO            AS [AP-DRG]
	, A.SEVERITY_OF_ILLNESS AS [SOI]
	, (
		CAST(A.LIHN_SVC_LINE AS varchar) +
		'' +
		CAST(A.APRDRGNO AS varchar) +
		'' +
		CAST(A.SEVERITY_OF_ILLNESS AS varchar)
	) AS LIHN_Svc_Line_APR_SOI
	, A.Performance
	, A.Threshold
	, CASE
		WHEN a.LOS > A.[Threshold]
			THEN 'Outside Threshold'
			ELSE 'Inside Threshold'
	  END                   AS [In or Outside Threshold]

	FROM #TEMPAA AS A

	WHERE A.APRDRGNO IS NOT NULL
	AND A.SEVERITY_OF_ILLNESS IS NOT NULL
	;

	DROP TABLE #TEMPAA
	;

END
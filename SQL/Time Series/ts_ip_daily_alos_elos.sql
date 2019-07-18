/*
***********************************************************************
File: ts_ip_daily_alos_elos.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_LIHN_Svc_Line_tbl
	smsdss.BMH_PLM_PtAcct_V
	Customer.Custom_DRG
	smsdss.c_LIHN_SPARCS_BenchmarkRates
	smsdss.pract_dim_v
	smsdss.c_LIHN_APR_DRG_OutlierThresholds

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Time Series query for daily pt_count, sum of days and sum expectation

Revision History:
Date		Version		Description
----		----		----
2018-07-13	v1			Initial Creation
***********************************************************************
*/

DECLARE @TODAY DATE;
DECLARE @END   DATE;

SET @TODAY = CAST(GETDATE() AS date);
SET @END   = DATEADD(MM, DATEDIFF(MM, 0, @TODAY), 0);

SELECT b.Pt_No
, b.Dsch_Date
, CASE
	WHEN b.Days_Stay = '0'
		THEN '1'
		ELSE b.Days_Stay
  END AS [LOS]
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
  END AS [Performance]

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

WHERE b.Dsch_Date >= '2014-04-01'
AND b.Dsch_Date < @end
AND b.drg_no NOT IN (
	'0','981','982','983','984','985',
	'986','987','988','989','998','999'
)
AND b.Plm_Pt_Acct_Type = 'I'
AND LEFT(B.PTNO_NUM, 1) != '2'
AND LEFT(b.PtNo_Num, 4) != '1999'
AND b.tot_chg_amt > 0
AND e.med_staff_dept NOT IN ('?', 'Anesthesiology', 'Emergency Department')
AND c.PATIENT# IS NOT NULL

OPTION(FORCE ORDER)
;

SELECT A.Dsch_Date   AS [Time]
, COUNT(A.Pt_No)     AS [DSCH_COUNT]
, SUM(A.LOS)         AS [SUM_DAYS]
, SUM(A.Performance) AS [SUM_EXP_DAYS]
--, [Case_Var] = SUM(ROUND((a.los - A.Performance), 4)) -- a positive number is worse
--, [Case_Index] = SUM(ROUND(A.LOS / A.Performance, 4))
--, ROUND((A.LOS - A.Performance) / STDEV(a.los) over(), 4) as [z-score]

FROM #TEMPA AS A

GROUP BY A.Dsch_Date

ORDER BY A.Dsch_Date
;

DROP TABLE #TEMPA
;

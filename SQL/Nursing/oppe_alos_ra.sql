/*
***********************************************************************
File: oppe_alos_ra.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_LIHN_Svc_Line_tbl
    smsdss.BMH_PLM_PtAcct_V
	Customer.Custom_DRG
	smsdss.c_LIHN_SPARCS_BenchmarkRates
	smsdss.pract_dim_v
	smsdss.c_LIHN_APR_DRG_OutlierThresholds
	smsdss.pyr_dim_v
	SMSDSS.C_READMIT_DASHBOARD_DETAIL_TBL
	smsdss.c_Readmit_Dashboard_Bench_Tbl

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get ALOS and Readmit Rate for OPPE

Revision History:
Date		Version		Description
----		----		----
2018-11-08	v1			Initial Creation
***********************************************************************
*/
DECLARE @MD_LIST TABLE (
	MD_ID VARCHAR(6)
)

INSERT @MD_LIST (MD_ID)
VALUES ('')

-- Get ALOS
SELECT b.Pt_No
, b.Dsch_Date
, [Dsch_Month] = DATEPART(month, b.dsch_date)
, [Dsch_Yr] = DATEPART(year, b.dsch_date)
, CASE
	WHEN b.Days_Stay = '0'
		THEN '1'
		ELSE b.Days_Stay
  END AS [LOS]
, b.Atn_Dr_No
, e.pract_rpt_name
, b.drg_no
, a.LIHN_Svc_Line
, CASE
	WHEN e.src_spclty_cd = 'hosim'
		THEN 'Hospitalist'
		ELSE 'Private'
  END AS [hosim]
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
  END AS [Performance]
, f.[Outlier Threshold] AS [Threshold]
, CASE
	WHEN b.Days_Stay > f.[Outlier Threshold]
		THEN 1
		ELSE 0
  END AS [outlier_flag]
, b.drg_cost_weight
, G.pyr_group2
, e.med_staff_dept

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
LEFT JOIN smsdss.pyr_dim_v                        AS G
ON B.Pyr1_Co_Plan_Cd = G.pyr_cd
	AND b.Regn_Hosp = G.orgz_cd

WHERE b.Dsch_Date between '2018-05-01' and '2018-10-31'
AND b.drg_no NOT IN (
	'0','981','982','983','984','985',
	'986','987','988','989','998','999'
)
AND b.Plm_Pt_Acct_Type = 'I'
AND LEFT(B.PTNO_NUM, 1) != '2'
AND LEFT(b.PtNo_Num, 4) != '1999'
AND b.tot_chg_amt > 0
AND e.med_staff_dept NOT IN ('?', 'Anesthesiology', 'Emergency Department')
and b.Atn_Dr_No IN (
	SELECT * FROM @MD_LIST
)

OPTION(FORCE ORDER)
;

SELECT A.Atn_Dr_No
, A.pract_rpt_name AS [Atn_Dr_Name]
, COUNT(DISTINCT(A.Pt_No)) AS [PT_COUNT]
, ROUND(AVG(A.LOS), 2) AS [ALOS]

FROM #TEMPA AS A

GROUP BY A.Atn_Dr_No
, A.pract_rpt_name
;

DROP TABLE #TEMPA
;

-- Get Readmit Rate
SELECT A.Atn_Dr_No
, A.pract_rpt_name
, COUNT(DISTINCT(A.PTNO_NUM)) AS [PT_COUNT]
, SUM(A.RA_Flag)              AS [READMIT_COUNT]

FROM SMSDSS.C_READMIT_DASHBOARD_DETAIL_TBL           AS A
LEFT OUTER JOIN smsdss.c_Readmit_Dashboard_Bench_Tbl AS B
ON A.LIHN_Svc_Line = B.LIHN_SVC_LINE
	AND (A.Dsch_YR - 1) = B.BENCH_YR
	AND A.SEVERITY_OF_ILLNESS = B.SOI

WHERE B.SOI IS NOT NULL
AND A.Atn_Dr_No IN (
	SELECT * FROM @MD_LIST
)
AND A.Dsch_Date >= '2018-04-01' 
AND A.Dsch_Date < '2018-10-01'

GROUP BY A.Atn_Dr_No
, A.pract_rpt_name

GO
;

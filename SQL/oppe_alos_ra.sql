/*
***********************************************************************
File: oppe_alos_ra.sql

Input Parameters:
	None

Tables/Views:
	Start Here

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get the ALOS and Readmit Rate for a provider for OPPE

Revision History:
Date		Version		Description
----		----		----
2019-01-07	v1			Initial Creation
***********************************************************************
*/

-- VARIABLE DECLARATION
DECLARE @TODAY      DATE;
DECLARE @ALOS_START DATE;
DECLARE @ALOS_END   DATE;
DECLARE @RA_START   DATE;
DECLARE @RA_END     DATE;
DECLARE @PROVIDER   CHAR(6);

SET @TODAY      = CAST(GETDATE() AS date);
SET @ALOS_START = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) - 13, 0);
SET @ALOS_END   = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) - 1, 0);
SET @RA_START   = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) - 14, 0);
SET @RA_END     = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) - 2, 0);
SET @PROVIDER   = '';

-- ALOS QUERY ---------------------------------------------------------
SELECT E.src_pract_no                             AS [PROVIDER_ID]
, E.pract_rpt_name                                AS [PROVIDER_NAME]
, COUNT(A.Encounter)                              AS [PT_COUNT]
, ROUND(AVG(CAST(B.Days_Stay AS float)), 2)       AS [ALOS]
, ROUND(AVG(D.Performance), 2)                    AS [ELOS]

FROM smsdss.c_LIHN_Svc_Line_tbl                   AS A
LEFT JOIN smsdss.BMH_PLM_PtAcct_V                 AS B
ON a.Encounter = b.Pt_No
LEFT JOIN Customer.Custom_DRG                     AS C
ON b.PtNo_Num = c.PATIENT#
LEFT JOIN smsdss.c_LIHN_SPARCS_BenchmarkRates     AS D
ON c.APRDRGNO = d.[APRDRG Code]
	AND c.SEVERITY_OF_ILLNESS = d.SOI
	AND d.[Measure ID] = 4
	AND d.[Benchmark ID] = 3
	AND a.LIHN_Svc_Line = d.[LIHN Service Line]
LEFT JOIN smsdss.pract_dim_v                      AS E
ON b.Atn_Dr_No = e.src_pract_no
	AND e.orgz_cd = 's0x0'
LEFT JOIN smsdss.c_LIHN_APR_DRG_OutlierThresholds AS F
ON c.APRDRGNO = f.[apr-drgcode]
LEFT JOIN smsdss.pyr_dim_v AS G
ON B.Pyr1_Co_Plan_Cd = G.pyr_cd
	AND b.Regn_Hosp = G.orgz_cd

WHERE b.Dsch_Date >= @ALOS_START
AND b.Dsch_Date < @ALOS_END
AND E.src_pract_no = @PROVIDER
AND b.drg_no NOT IN (
	'0','981','982','983','984','985',
	'986','987','988','989','998','999'
)
AND b.Plm_Pt_Acct_Type = 'I'
AND LEFT(B.PTNO_NUM, 1) != '2'
AND LEFT(b.PtNo_Num, 4) != '1999'
AND b.tot_chg_amt > 0
AND e.med_staff_dept NOT IN ('?', 'Anesthesiology', 'Emergency Department')

GROUP BY E.src_pract_no
, E.pract_rpt_name

OPTION(FORCE ORDER)
;

-- READMIT QUERY ------------------------------------------------------
SELECT A.Atn_Dr_No AS [PROVIDER_ID]
, A.pract_rpt_name AS [PROVIDER_NAME]
, COUNT(A.PtNo_Num) AS [PT_COUNT]
, ROUND(SUM(A.RA_FLAG) / CAST(COUNT(A.PTNO_NUM) AS float), 2) AS [READMIT_RATE]
, ROUND(AVG(B.READMIT_RATE), 2) AS [Readmit_Rate_Bench]

FROM SMSDSS.C_READMIT_DASHBOARD_DETAIL_TBL AS A
LEFT OUTER JOIN smsdss.c_Readmit_Dashboard_Bench_Tbl AS B
ON A.LIHN_Svc_Line = B.LIHN_SVC_LINE
	AND (A.Dsch_YR - 1) = B.BENCH_YR
	AND A.SEVERITY_OF_ILLNESS = B.SOI

WHERE B.SOI IS NOT NULL
AND A.Dsch_Date >= @RA_START
AND A.Dsch_Date < @RA_END
AND A.Atn_Dr_No = @PROVIDER

GROUP BY A.Atn_Dr_No
, A.pract_rpt_name
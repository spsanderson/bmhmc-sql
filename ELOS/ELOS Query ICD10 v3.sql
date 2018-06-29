DECLARE @TODAY DATE;
DECLARE @START DATE;
DECLARE @END   DATE;

SET @TODAY = CAST(GETDATE() AS date);
SET @TODAY = DATEADD(MM, DATEDIFF(MM, 0, @TODAY), 0);
SET @START = DATEADD(MM, DATEDIFF(MM, 0, @TODAY) - 18, 0);
SET @END   = dateadd(mm, datediff(mm, 0, @TODAY), 0);

SELECT a.pt_id
, a.Dsch_Date
, [Dsch_Month] = DATEPART(month, a.dsch_date)
, [Dsch_Yr] = DATEPART(year, a.dsch_date)
, CASE
	WHEN a.LOS = '0'
		THEN '1'
		ELSE a.LOS
  END AS [LOS]
, a.Atn_Dr_No
, a.Atn_Dr_Name
, a.drg_no
, a.drg_name
, a.Diag01
, a.Diagnosis
, a.Proc01
, a.[Procedure]
, a.LIHN_Service_Line
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
	AND a.LOS = 0
		THEN '1'
	WHEN d.Performance IS null
	AND a.los != 0
		THEN a.LOS
		ELSE d.Performance
  END AS [Performance]
, f.[Outlier Threshold] AS [Threshold]
, CASE
	WHEN a.LOS > f.[Outlier Threshold]
		THEN 1
		ELSE 0
  END AS [outlier_flag]
, b.drg_cost_weight
, G.pyr_group2

INTO #TEMPA

FROM smsdss.c_LIHN_Svc_Lines_Rpt2_ICD10_v     AS a
LEFT JOIN smsdss.BMH_PLM_PtAcct_V             AS b
ON a.pt_id = b.Pt_No
LEFT JOIN Customer.Custom_DRG                 AS c
ON b.PtNo_Num = c.PATIENT#
LEFT JOIN smsdss.c_LIHN_SPARCS_BenchmarkRates AS d
ON c.APRDRGNO = d.[APRDRG Code]
	AND c.SEVERITY_OF_ILLNESS = d.SOI
	AND d.[Measure ID] = 4
	AND d.[Benchmark ID] = 3
	AND a.LIHN_Service_Line = d.[LIHN Service Line]
LEFT JOIN smsdss.pract_dim_v                  AS e
ON a.Atn_Dr_No = e.src_pract_no
	AND e.orgz_cd = 's0x0'
LEFT JOIN smsdss.c_LIHN_APR_DRG_OutlierThresholds AS f
ON c.APRDRGNO = f.[apr-drgcode]
LEFT JOIN smsdss.pyr_dim_v AS G
ON B.Pyr1_Co_Plan_Cd = G.pyr_cd
	AND b.Regn_Hosp = G.orgz_cd

WHERE a.Dsch_Date >= @start
AND a.Dsch_Date < @end
AND a.drg_no NOT IN (
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

SELECT A.pt_id
, A.Dsch_Date
, [Last_Rpt_Month] = CASE
	WHEN DATEPART(MONTH, A.DSCH_DATE) < 10
		THEN CAST(DATEPART(YEAR, A.DSCH_DATE) AS VARCHAR) + '0' + CAST(DATEPART(MONTH, A.Dsch_Date) AS varchar)
		ELSE CAST(DATEPART(YEAR, A.DSCH_DATE) AS varchar) + CAST(DATEPART(MONTH, A.Dsch_Date) AS varchar)
	END
, A.Dsch_Yr
, A.Dsch_Month
, A.Atn_Dr_No
, A.Atn_Dr_Name
, A.drg_no
, A.drg_name
, A.Diag01
, A.Diagnosis
, A.Proc01
, A.[Procedure]
, A.LIHN_Service_Line
, A.hosim
, A.APRDRGNO
, A.SEVERITY_OF_ILLNESS
, A.LOS
, A.Performance
, A.Threshold
, A.outlier_flag
, A.drg_cost_weight
, A.pyr_group2
, [Case_Var] = ROUND((a.los - A.Performance), 4) -- a positive number is worse
, [Case_Index] = ROUND(A.LOS / A.Performance, 4)
, [Index_Threshold] = 1
, ROUND((A.LOS - A.Performance) / STDEV(a.los) over(), 4) as [z-score]
, [zScore_UL] = 1.96
, [zScore_LL] = -1.96

FROM #TEMPA AS A

ORDER BY A.Dsch_Date
;

DROP TABLE #TEMPA
;




SELECT a.pt_id
, a.Dsch_Date
, CASE
	WHEN a.LOS = '0'
	THEN '1'
	ELSE a.LOS
  END AS [LOS]
, a.Atn_Dr_No
, a.Atn_Dr_Name
, a.drg_no
, a.drg_schm
, a.drg_name
, a.Diag01
, a.Diagnosis
, a.Proc01
, a.[Procedure]
, a.Shock_Ind
, a.Intermed_Coronary_Synd_Ind
, a.LIHN_Service_Line
, CASE
	WHEN e.src_spclty_cd = 'hosim'
	THEN 'Hospitalist'
	ELSE 'Private'
  END AS [hosim]
, c.APRDRGNO
, c.SEVERITY_OF_ILLNESS
, CAST(a.LIHN_Service_Line AS varchar) + ' ' 
	+ CAST(c.APRDRGNO AS varchar) + ' ' 
	+ CAST(c.SEVERITY_OF_ILLNESS AS varchar)
	AS [Sparc Line of Service + APR DRGT + SOI]
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
, f.[outlier threshold] as [Threshold]
, Case
	when a.LOS > f.[Outlier Threshold]
		THEN 'Outside Threshold'
		ELSE 'Inside Threshold'
  end as [In or Outside Threshold]
, Case
	when a.LOS > f.[Outlier Threshold]
		then 1
		else 0
  end as [outlier_flag]

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

WHERE a.Dsch_Date >= '2017-01-01'
AND a.Dsch_Date < '2017-02-01'
AND a.drg_no NOT IN (
	'0','981','982','983','984','985',
	'986','987','988','989','998','999'
)

ORDER BY pt_id
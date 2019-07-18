SELECT [pt_id]
,a.[Dsch_Date]
,CASE
	WHEN [LOS] = '0'
	THEN 1
	ELSE [LOS]
 END AS [LOS]
,a.[Atn_Dr_No]
,[Atn_Dr_Name]
,a.[drg_no]
,[drg_schm]
,[drg_name]
,[Diag01]
--,[ICD_CD_SCHM]
,[Diagnosis]
,[Proc01]
--,[proc_cd_schm]
,[Procedure]
,[Shock_Ind]
,[Intermed_Coronary_Synd_Ind]
,[LIHN_Service_Line]
, CASE
	WHEN B.SRC_SPCLTY_CD = 'HOSIM'
	THEN 'Hospitalist'
	ELSE 'Private'
  END AS [HOSIM]

into #elos_1

FROM [smsdss].[c_LIHN_Svc_Lines_Rpt2_ICD10_v] as a
LEFT OUTER JOIN [SMSDSS].[PRACT_DIM_V] AS B
ON a.[ATN_DR_NO] = B.SRC_PRACT_NO
	AND b.orgz_cd = 's0x0'

WHERE a.Dsch_Date >= '2016-05-01'
AND a.Dsch_Date < '2016-06-01'
AND a.drg_no NOT IN (
	'0','981','982','983','984','985','986','987','988','989','998','999'
)

ORDER BY pt_id
-----------------------------------------------------------------------
SELECT a.*

FROM #elos_1 AS A
LEFT OUTER MERGE JOIN [smsdss].[BMH_PLM_PtAcct_V] AS C 
ON a.pt_id = c.Pt_No

WHERE c.hosp_svc != 'psy'

-----------------------------------------------------------------------
DROP TABLE #elos_1
SELECT [pt_id]
,[Dsch_Date]
,CASE
	WHEN [LOS] = '0'
	THEN 1
	ELSE [LOS]
 END AS [LOS]
,[Atn_Dr_No]
,[Atn_Dr_Name]
,[drg_no]
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

FROM [SMSPHDSSS0X0].[smsdss].[c_LIHN_Svc_Lines_Rpt2_ICD10_v] 
LEFT OUTER JOIN [SMSDSS].[PRACT_DIM_V] AS B
ON [SMSDSS].[C_LIHN_SVC_LINES_RPT2_ICD10_V].[ATN_DR_NO] = B.SRC_PRACT_NO
	AND b.orgz_cd = 's0x0'

WHERE dsch_date >= '2016-01-01'
AND dsch_date < '2016-02-01'
AND drg_no NOT IN ('0','981','982','983','984','985','986','987','988','989','998','999')

ORDER BY pt_id
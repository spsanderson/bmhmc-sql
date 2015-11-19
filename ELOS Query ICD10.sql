SELECT [pt_id]
,[Dsch_Date]
,[LOS]
,[Atn_Dr_No]
,[Atn_Dr_Name]
,[drg_no]
,[drg_schm]
,[drg_name]
,[Diag01]
,[ICD_CD_SCHM]
,[Diagnosis]
,[Proc01]
,[proc_cd_schm]
,[Procedure]
,[Shock_Ind]
,[Intermed_Coronary_Synd_Ind]
,[LIHN_Service_Line]

FROM [SMSPHDSSS0X0].[smsdss].[c_LIHN_Svc_Lines_Rpt2_ICD10_v]

WHERE dsch_date >= '2015-09-01'
AND dsch_date < '2015-10-01'
AND drg_no NOT IN ('0','981','982','983','984','985','986','987','988','989','998','999')

ORDER BY pt_id
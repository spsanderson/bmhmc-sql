DECLARE @ICD_CD_SCHM VARCHAR(2);

SET @ICD_CD_SCHM = '9';

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

FROM [SMSPHDSSS0X0].[smsdss].[c_LIHN_Svc_Lines_Rpt2_v]
  
--WHERE DSCH_Date BETWEEN '2015-09-01 00:00:00.000' AND '2015-09-30 23:59:59.000'
WHERE dsch_date >= '2015-09-01'
AND dsch_date < '2015-10-01'
AND drg_no NOT IN ('0','981','982','983','984','985','986','987','988','989','998','999')
--WHERE pt_id IN ('000014127450')--('000014118764', '000014118954','000014119267')
--Dsch_Date BETWEEN '04/01/2014 00:00:00.000' AND '06/30/2014 23:59:59.000'
AND [ICD_CD_SCHM] = @ICD_CD_SCHM
AND (
      [proc_cd_schm] = '9'
      or
      [proc_cd_schm] is null
      )

ORDER BY pt_id

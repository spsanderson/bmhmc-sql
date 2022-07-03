/*
***********************************************************************
File: op_gastro_peds.sql

Input Parameters:
	None

Tables/Views:
	SMSDSS.BMH_PLM_PtAcct_V
	SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New
	SMSDSS.BMH_UserTwoFact_V
	SMSDSS.BMH_UserTwoField_Dim_V

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Pull adult/peds cases for gastro procedures 2019 op lf

Revision History:
Date		Version		Description
----		----		----
2019-06-04	v1			Initial Creation
2019-06-26	v2			Add Parent CCS Description
2021-06-17	v3			2021 surver of 2020 data
2022-06-20	v4			2022 survey of 2021 data
***********************************************************************
*/

SELECT PAV.Med_Rec_No
, PAV.PtNo_Num
, E.UserDataCd
, D.UserDataText AS 'ORSOS_CASE_NO'
, CAST(PAV.Adm_Date as date) AS [Adm_Date]
, pvn.ClasfCd
--, 'Gastroenterology_Adult' AS 'LeapFrog_Procedure_Group'
, 'Gastroenterology_Peds' AS 'LeapFrog_Procedure_Group'
, CCS.[Description] AS 'CCS_Description'

FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN
ON PAV.Pt_No = PVN.Pt_No
	AND (
		-- Upper GI Endoscopy
		PVN.ClasfCd IN (
			'43210','43233','43235','43236','43237','43238',
			'43239','43240','43241','43242','43243','43244',
			'43245','43246','43247','43248','43249','43250',
			'43251','43252','43253','43254','43255','43257',
			'43259','43266','43270'
		)
		OR
		-- Other Upper GI Procedure
		PVN.ClasfCd IN ('43450','43453','43460')
		-- Lower GI Endoscopy
		OR
		PVN.ClasfCd IN (
			'44388','44389','44390','44391','44392','44394',
			'44401','44402','44403','44404','44405','44406',
			'44407','44408','45305','45307','45308','45309',
			'45315','45317','45320','45321','45327','45330',
			'45331','45332','45333','45334','45335','45337',
			'45338','45340','45341','45342','45346','45347',
			'45349','45350','45378','45379','45380','45381',
			'45382','45384','45385','45386','45388','45389',
			'45390','45391','45392','45393','45398'
		)
	)
INNER JOIN SMSDSS.BMH_UserTwoFact_V AS D
ON PAV.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '571'
LEFT OUTER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS E
ON D.UserDataKey = E.UserTwoKey

CROSS APPLY (
	SELECT
		CASE
			WHEN PVN.CLASFCD IN (
			'43210','43233','43235','43236','43237','43238',
			'43239','43240','43241','43242','43243','43244',
			'43245','43246','43247','43248','43249','43250',
			'43251','43252','43253','43254','43255','43257',
			'43259','43266','43270'
		) THEN 'Upper_GI_Endoscopy'
			WHEN PVN.CLASFCD IN ('43450','43453','43460') THEN 'Other_Upper_GI_Procedure'
			WHEN PVN.CLASFCD IN (
			'44388','44389','44390','44391','44392','44394',
			'44401','44402','44403','44404','44405','44406',
			'44407','44408','45305','45307','45308','45309',
			'45315','45317','45320','45321','45327','45330',
			'45331','45332','45333','45334','45335','45337',
			'45338','45340','45341','45342','45346','45347',
			'45349','45350','45378','45379','45380','45381',
			'45382','45384','45385','45386','45388','45389',
			'45390','45391','45392','45393','45398'
		) THEN 'Lower_GI_Endoscopy'
		END AS 'Description'
) AS CCS
WHERE PAV.Pt_Age < 18
AND PAV.tot_chg_amt > 0
AND LEFT(PAV.PTNO_NUM, 1) NOT IN ('2', '8')
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
AND PAV.Adm_Date >= '2020-01-01'
AND PAV.Adm_Date < '2021-01-01'
AND PAV.Plm_Pt_Acct_Type != 'I'
ORDER BY PAV.PtNo_Num
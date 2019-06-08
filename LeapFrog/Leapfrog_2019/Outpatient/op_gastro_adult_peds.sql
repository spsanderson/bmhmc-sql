/*
***********************************************************************
File: op_gastro_adult_peds.sql

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
***********************************************************************
*/

SELECT PAV.Med_Rec_No
, PAV.PtNo_Num
, E.UserDataCd
, D.UserDataText AS 'ORSOS_CASE_NO'
, PAV.Adm_Date
, pvn.ClasfCd
--, 'Gastroenterology_Adult' AS 'LeapFrog_Procedure_Group'
, 'Gastroenterology_Peds' AS 'LeapFrog_Procedure_Group'
, CCS.[Description] AS 'CCS_Description'

FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN
ON PAV.Pt_No = PVN.Pt_No
	AND (
		PVN.ClasfCd BETWEEN '43248' AND '43249'
		OR
		PVN.ClasfCd BETWEEN '43234' AND '43242'
		OR
		PVN.ClasfCd BETWEEN '43250' AND '43259'
		OR
		PVN.ClasfCd BETWEEN '43450' AND '43460'
		OR
		PVN.ClasfCd BETWEEN '44360' AND '44361'
		OR
		PVN.ClasfCd BETWEEN '45355' AND '45378'
		OR
		PVN.ClasfCd BETWEEN '45380' AND '45393'
		OR
		PVN.ClasfCd BETWEEN '45308' AND '45331'
	)
INNER JOIN SMSDSS.BMH_UserTwoFact_V AS D
ON PAV.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '571'
LEFT OUTER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS E
ON D.UserDataKey = E.UserTwoKey

CROSS APPLY (
	SELECT
		CASE
			WHEN PVN.CLASFCD BETWEEN '43248' AND '43249' THEN 'Esophageal dilatation'
			WHEN PVN.CLASFCD BETWEEN '43234' AND '43242' THEN 'Upper gastrointestinal endoscopy, biopsy'
			WHEN PVN.CLASFCD BETWEEN '43250' AND '43259' THEN 'Upper gastrointestinal endoscopy, biopsy'
			WHEN PVN.CLASFCD BETWEEN '43450' AND '43460' THEN 'Esophageal dilatation'
			WHEN PVN.CLASFCD BETWEEN '44360' AND '44361' THEN 'Upper gastrointestinal endoscopy, biopsy'
			WHEN PVN.CLASFCD BETWEEN '45355' AND '45378' THEN 'Colonoscopy and biopsy'
			WHEN PVN.CLASFCD BETWEEN '45380' AND '45393' THEN 'Colonoscopy and biopsy'
			WHEN PVN.CLASFCD BETWEEN '45308' AND '45331' THEN 'Proctoscopy and anorectal biopsy'
		END AS 'Description'
) AS CCS

WHERE PAV.Pt_Age < 18
AND PAV.tot_chg_amt > 0
AND LEFT(PAV.PTNO_NUM, 1) NOT IN ('2', '8')
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
AND PAV.Adm_Date >= '2018-01-01'
AND PAV.Adm_Date < '2019-01-01'
AND PAV.Plm_Pt_Acct_Type != 'I'

ORDER BY PAV.PtNo_Num
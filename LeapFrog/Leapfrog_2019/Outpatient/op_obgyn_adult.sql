/*
***********************************************************************
File: op_obgyn_adult.sql

Input Parameters:
	None

Tables/Views:
	SMSDSS.BMH_PLM_PtAcct_V
	SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New
	SMSDSS.BMH_UserTwoFact_V AS D
	SMSDSS.BMH_UserTwoField_Dim_V

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Pull adult/peds cases for adult OBGYN procedures 2019 op lf

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
, 'OBGYN_Adult' AS 'LeapFrog_Procedure_Group'
, CCS.[Description] AS 'CCS_Description'

FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN
ON PAV.Pt_No = PVN.Pt_No
	AND (
		PVN.ClasfCd BETWEEN '57510' AND '57550' OR 
		PVN.ClasfCd BETWEEN '58559' AND '58561' OR 
		PVN.ClasfCd BETWEEN '58563' AND '58563' OR 
		PVN.ClasfCd BETWEEN '58555' AND '58558' OR 
		PVN.ClasfCd BETWEEN '58661' AND '58661' OR 
		PVN.ClasfCd BETWEEN '58670' AND '58671' OR 
		PVN.ClasfCd BETWEEN '58662' AND '58662'
	)
INNER JOIN SMSDSS.BMH_UserTwoFact_V AS D
ON PAV.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '571'
LEFT OUTER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS E
ON D.UserDataKey = E.UserTwoKey

CROSS APPLY (
	SELECT
		CASE
			WHEN PVN.CLASFCD BETWEEN '57510' AND '57550' THEN 'Other excision of cervix and uterus'
			WHEN PVN.CLASFCD BETWEEN '58559' AND '58561' THEN 'Other excision of cervix and uterus'
			WHEN PVN.CLASFCD BETWEEN '58563' AND '58563' THEN 'Other excision of cervix and uterus'
			WHEN PVN.CLASFCD BETWEEN '58555' AND '58558' THEN 'Other diagnostic procedures, female organs'
			WHEN PVN.CLASFCD BETWEEN '58661' AND '58661' THEN 'Oophorectomy, unilateral and bilateral'
			WHEN PVN.CLASFCD BETWEEN '58670' AND '58671' THEN 'Ligation of fallopian tubes'
			WHEN PVN.CLASFCD BETWEEN '58662' AND '58662' THEN 'Other OR therapeutic procedures, female organs'
		END AS 'Description'
) AS CCS

WHERE PAV.Pt_Age >= 18
AND PAV.tot_chg_amt > 0
AND LEFT(PAV.PTNO_NUM, 1) NOT IN ('2', '8')
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
AND PAV.Adm_Date >= '2018-01-01'
AND PAV.Adm_Date < '2019-01-01'
AND PAV.Plm_Pt_Acct_Type != 'I'

ORDER BY PAV.PtNo_Num
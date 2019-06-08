/*
***********************************************************************
File: op_general_surgery_adult.sql

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
	Pull adult/peds cases for adult general surgery procedures 2019 op lf

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
, 'General_Surgery_Adult' AS 'LeapFrog_Procedure_Group'
, CCS.[Description] AS 'CCS_Description'

FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN
ON PAV.Pt_No = PVN.Pt_No
	AND (
		PVN.ClasfCd BETWEEN '47562' AND '47564' OR 
		PVN.ClasfCd BETWEEN '11200' AND '11646' OR 
		PVN.ClasfCd BETWEEN '17000' AND '17380' OR 
		PVN.ClasfCd BETWEEN '24071' AND '24071' OR 
		PVN.ClasfCd BETWEEN '26111' AND '26111' OR 
		PVN.ClasfCd BETWEEN '26115' AND '26115' OR 
		PVN.ClasfCd BETWEEN '28039' AND '28039' OR 
		PVN.ClasfCd BETWEEN '28043' AND '28043' OR 
		PVN.ClasfCd BETWEEN '29893' AND '29893' OR 
		PVN.ClasfCd BETWEEN '46221' AND '46262' OR 
		PVN.ClasfCd BETWEEN '49491' AND '49535' OR 
		PVN.ClasfCd BETWEEN '49650' AND '49651' OR 
		PVN.ClasfCd BETWEEN '43281' AND '43282' OR 
		PVN.ClasfCd BETWEEN '49560' AND '49611' OR 
		PVN.ClasfCd BETWEEN '49320' AND '49322' OR 
		PVN.ClasfCd BETWEEN '19120' AND '19126' OR 
		PVN.ClasfCd BETWEEN '19301' AND '19302' OR 
		PVN.ClasfCd BETWEEN '19303' AND '19307' OR 
		PVN.ClasfCd BETWEEN '14000' AND '15738'
	)
INNER JOIN SMSDSS.BMH_UserTwoFact_V AS D
ON PAV.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '571'
LEFT OUTER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS E
ON D.UserDataKey = E.UserTwoKey

CROSS APPLY (
	SELECT
		CASE
			WHEN PVN.CLASFCD BETWEEN '47562' AND '47564' THEN 'Cholecystectomy and common duct exploration'
			WHEN PVN.CLASFCD BETWEEN '11200' AND '11646' THEN 'Excision of skin lesion'
			WHEN PVN.CLASFCD BETWEEN '17000' AND '17380' THEN 'Excision of skin lesion'
			WHEN PVN.CLASFCD BETWEEN '24071' AND '24071' THEN 'Excision of skin lesion'
			WHEN PVN.CLASFCD BETWEEN '26111' AND '26111' THEN 'Excision of skin lesion'
			WHEN PVN.CLASFCD BETWEEN '26115' AND '26115' THEN 'Excision of skin lesion'
			WHEN PVN.CLASFCD BETWEEN '28039' AND '28039' THEN 'Excision of skin lesion'
			WHEN PVN.CLASFCD BETWEEN '28043' AND '28043' THEN 'Excision of skin lesion'
			WHEN PVN.CLASFCD BETWEEN '29893' AND '29893' THEN 'Excision of skin lesion'
			WHEN PVN.CLASFCD BETWEEN '46221' AND '46262' THEN 'Hemorrhoid procedures'
			WHEN PVN.CLASFCD BETWEEN '49491' AND '49535' THEN 'Inguinal and femoral hernia repair'
			WHEN PVN.CLASFCD BETWEEN '49650' AND '49651' THEN 'Inguinal and femoral hernia repair'
			WHEN PVN.CLASFCD BETWEEN '43281' AND '43282' THEN 'Other hernia repair'
			WHEN PVN.CLASFCD BETWEEN '49560' AND '49611' THEN 'Other hernia repair'
			WHEN PVN.CLASFCD BETWEEN '49320' AND '49322' THEN 'Laparoscopy'
			WHEN PVN.CLASFCD BETWEEN '19120' AND '19126' THEN 'Lumpectomy, quadrantectomy of breast'
			WHEN PVN.CLASFCD BETWEEN '19301' AND '19302' THEN 'Lumpectomy, quadrantectomy of breast'
			WHEN PVN.CLASFCD BETWEEN '19303' AND '19307' THEN 'Mastectomy'
			WHEN PVN.CLASFCD BETWEEN '14000' AND '15738' THEN 'Skin graft'
		END AS 'Description'
) AS CCS

WHERE PAV.Pt_Age >= 18
AND PAV.tot_chg_amt > 0
AND LEFT(PAV.PTNO_NUM, 1) NOT IN ( '2', '8')
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
AND PAV.Adm_Date >= '2018-01-01'
AND PAV.Adm_Date < '2019-01-01'
AND PAV.Plm_Pt_Acct_Type != 'I'

ORDER BY PAV.PtNo_Num
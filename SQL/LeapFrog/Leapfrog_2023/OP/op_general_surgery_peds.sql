/*
***********************************************************************
File: op_general_surgery_peds.sql

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
	Pull adult/peds cases for peds general surgery procedures 2019 op lf

Revision History:
Date		Version		Description
----		----		----
2019-06-04	v1			Initial Creation
2019-06-25	v2			Add CCS Parent Description
2021-06-17	v3			2021 survey 2020 data
2022-06-20	v4			2022 survey of 2021 data
***********************************************************************
*/

SELECT PAV.Med_Rec_No,
	PAV.PtNo_Num,
	E.UserDataCd,
	D.UserDataText AS 'ORSOS_CASE_NO',
	PAV.Adm_Date,
	pvn.ClasfCd,
	'General_Surgery_Peds' AS 'LeapFrog_Procedure_Group',
	CCS.[Description] AS 'CCS_Description'
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN ON PAV.Pt_No = PVN.Pt_No
	AND (
		PVN.CLASFCD IN ('49491', '49492', '49495', '49496', '49500', '49501', '49505', '49507', '49520', '49521', '49525', '49550', '49553', '49555', '49557', '49650', '49651')
		OR PVN.ClasfCd IN ('43281', '43282', '49560', '49561', '49565', '49566', '49568', '49570', '49572', '49580', '49582', '49585', '49587', '49590', '49600', '49605', '49606', '49610', '49611', '49652', '49653', '49654', '49655', '49656', '49657', '49659')
		)
INNER JOIN SMSDSS.BMH_UserTwoFact_V AS D ON PAV.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '571'
LEFT OUTER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS E ON D.UserDataKey = E.UserTwoKey
CROSS APPLY (
	SELECT CASE 
			WHEN PVN.CLASFCD IN ('49491', '49492', '49495', '49496', '49500', '49501', '49505', '49507', '49520', '49521', '49525', '49550', '49553', '49555', '49557', '49650', '49651')
				THEN 'Inguinal and femoral hernia repair'
			WHEN PVN.ClasfCd IN ('43281', '43282', '49560', '49561', '49565', '49566', '49568', '49570', '49572', '49580', '49582', '49585', '49587', '49590', '49600', '49605', '49606', '49610', '49611', '49652', '49653', '49654', '49655', '49656', '49657', '49659')
				THEN 'Other hernia repair'
			END AS 'Description'
	) AS CCS
WHERE PAV.Pt_Age < 18
	AND PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) NOT IN ('2', '8', '9')
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.Adm_Date >= '2021-01-01'
	AND PAV.Adm_Date < '2022-01-01'
	AND PAV.Plm_Pt_Acct_Type != 'I'
ORDER BY PAV.PtNo_Num

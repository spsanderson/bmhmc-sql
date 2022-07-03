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
2019-06-27	v2			Add CCSParent_Description
2021-06-18	v3			2021 survey 2020 data
2022-06-21	v4			2022 survey 2021 data
***********************************************************************
*/

SELECT PAV.Med_Rec_No,
	PAV.PtNo_Num,
	E.UserDataCd,
	D.UserDataText AS 'ORSOS_CASE_NO',
	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
	pvn.ClasfCd,
	'OBGYN_Adult' AS 'LeapFrog_Procedure_Group',
	CCS.[Description] AS 'CCS_Description'
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN ON PAV.Pt_No = PVN.Pt_No
	AND PVN.ClasfCd IN (
		-- CERVIX PROCEDURE
		'57510', '57511', '57513', '57520', '57522', '57530', '57531', '57540', '57545', '57550',
		-- HYSTEROSCOPY
		'58555', '58558', '58559', '58560', '58561', '58563',
		-- UTERUS AND ADNEXA LAPAROSCOPY
		'58661', '58662', '58670', '58671'
		)
INNER JOIN SMSDSS.BMH_UserTwoFact_V AS D ON PAV.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '571'
LEFT OUTER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS E ON D.UserDataKey = E.UserTwoKey
CROSS APPLY (
	SELECT CASE 
			WHEN PVN.CLASFCD IN ('57510', '57511', '57513', '57520', '57522', '57530', '57531', '57540', '57545', '57550')
				THEN 'Cervix_Procedure'
			WHEN PVN.CLASFCD IN ('58555', '58558', '58559', '58560', '58561', '58563')
				THEN 'Hysteroscopy'
			WHEN PVN.CLASFCD IN ('58661', '58662', '58670', '58671')
				THEN 'Uterus_and_Adnexa_Laparoscopy'
			END AS 'Description'
	) AS CCS
WHERE PAV.Pt_Age >= 18
	AND PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) NOT IN ('2', '8', '9')
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.Adm_Date >= '2021-01-01'
	AND PAV.Adm_Date < '2022-01-01'
	AND PAV.Plm_Pt_Acct_Type != 'I'
ORDER BY PAV.PtNo_Num

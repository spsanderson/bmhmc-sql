/*
***********************************************************************
File: op_urology_adult.sql

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
	Pull adult urology procedures 2019 op lf

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
	'Urology_Adult' AS 'LeapFrog_Procedure_Group',
	CCS.[Description] AS 'CCS_Description'
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN ON PAV.Pt_No = PVN.Pt_No
	AND PVN.ClasfCd IN (
		--	Circumcision
		'54150', '54161', '54162', '54163',
		-- Cystourethroscopy
		'52007', '52010', '52204', '52214', '52224', '52234', '52235', '52240', '52277', '52281', '52282', '52283', '52285', '52287', '52290', '52300', '52301', '52305', '52310', '52315', '52332', '52351', '52352', '52353', '52354', '52355', '52356',
		-- Male Genital Procedures
		'54300', '54304', '54308', '54312', '54316', '54318', '54322', '54324', '54326', '54328', '54332', '54336', '54340', '54344', '54512', '54520', '54522', '54530', '54535', '54550', '54560', '54600', '54620', '54640', '54650', '54660', '54670', '54680', '54690', '54692', '55040', '55041', '55060', '55150', '55175', '55180', '55530', '55535', '55540',
		-- Urethra Procedures
		'52001', '52005', '52441', '52442', '53000', '53010', '53020', '53025', '53040', '53060', '53230', '53235', '53450', '53460', '53500', '53502', '53505', '53510', '53515', '53520', '53600', '53601', '53605', '53620', '53621', '53660', '53661', '53665', '53852',
		-- Vaginal Repair Procedures
		'57287', '57288'
		)
INNER JOIN SMSDSS.BMH_UserTwoFact_V AS D ON PAV.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '571'
LEFT OUTER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS E ON D.UserDataKey = E.UserTwoKey
CROSS APPLY (
	SELECT CASE 
			WHEN PVN.CLASFCD IN ('54150', '54161', '54162', '54163')
				THEN 'Circumcision'
			WHEN PVN.CLASFCD IN ('52007', '52010', '52204', '52214', '52224', '52234', '52235', '52240', '52277', '52281', '52282', '52283', '52285', '52287', '52290', '52300', '52301', '52305', '52310', '52315', '52332', '52351', '52352', '52353', '52354', '52355', '52356')
				THEN 'Cystourethroscopy'
			WHEN PVN.CLASFCD IN ('54300', '54304', '54308', '54312', '54316', '54318', '54322', '54324', '54326', '54328', '54332', '54336', '54340', '54344', '54512', '54520', '54522', '54530', '54535', '54550', '54560', '54600', '54620', '54640', '54650', '54660', '54670', '54680', '54690', '54692', '55040', '55041', '55060', '55150', '55175', '55180', '55530', '55535', '55540')
				THEN 'Male_Genital_Procedures'
			WHEN PVN.CLASFCD IN ('52001', '52005', '52441', '52442', '53000', '53010', '53020', '53025', '53040', '53060', '53230', '53235', '53450', '53460', '53500', '53502', '53505', '53510', '53515', '53520', '53600', '53601', '53605', '53620', '53621', '53660', '53661', '53665', '53852')
				THEN 'Urethra_Procedures'
			WHEN PVN.CLASFCD IN ('57287', '57288')
				THEN 'Vaginal_Repair_Procedures'
			END AS 'Description'
	) AS CCS
WHERE PAV.Pt_Age >= 18
	AND PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) NOT IN ('2', '8', '9')
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.Adm_Date >= '2020-01-01'
	AND PAV.Adm_Date < '2021-01-01'
	AND PAV.Plm_Pt_Acct_Type != 'I'
ORDER BY PAV.PtNo_Num



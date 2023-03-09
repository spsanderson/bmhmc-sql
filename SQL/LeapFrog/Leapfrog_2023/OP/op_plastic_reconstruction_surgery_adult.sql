/*
***********************************************************************
File: op_plastic_reconstruction_srugery_adult.sql

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
	Pull adult/peds cases for adult plastic reconstruction surgery procedures 2019 op lf

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
	'Plastic_Reconstruction_Surgery_Adult' AS 'LeapFrog_Procedure_Group',
	CCS.[Description] AS 'CCS_Description'
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN ON PAV.Pt_No = PVN.Pt_No
	AND PVN.ClasfCd IN (
		-- BREAST REPAIR OR RECONSTRUCTION
		'19316', '19318', '19325', '19328', '19330', '19340', '19342', '19350', '19355', '19357', '19361', '19364', '19367', '19368', '19369', '19370', '19371', '19380',
		-- SKIN GRAFT RECONSTRUCTION PROCEDURES
		'14000', '14001', '14020', '14021', '14040', '14041', '14060', '14061', '14301', '14302', '14350', '15002', '15003', '15004', '15005', '15040', '15050', '15100', '15101', '15110', '15111', '15115', '15116', '15120', '15121', '15130', '15131', '15135', '15136', '15150', '15151', '15152', '15155', '15156', '15157', '15200', '15201', '15220', '15221', '15240', '15241', '15260', '15261', '15271', '15272', '15273', '15274', '15275', '15276', '15277', '15278', '15570', '15572', '15574', '15576', '15600', '15610', '15620', '15630', '15650', '15730', '15731', '15733', '15734', '15736', '15738', '15820', '15821', '15822', '15823'
		)
INNER JOIN SMSDSS.BMH_UserTwoFact_V AS D ON PAV.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '571'
LEFT OUTER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS E ON D.UserDataKey = E.UserTwoKey
CROSS APPLY (
	SELECT CASE 
			WHEN PVN.CLASFCD IN ('19316', '19318', '19325', '19328', '19330', '19340', '19342', '19350', '19355', '19357', '19361', '19364', '19367', '19368', '19369', '19370', '19371', '19380')
				THEN 'Breast_Repair_or_Reconstruction'
			WHEN PVN.CLASFCD IN ('14000', '14001', '14020', '14021', '14040', '14041', '14060', '14061', '14301', '14302', '14350', '15002', '15003', '15004', '15005', '15040', '15050', '15100', '15101', '15110', '15111', '15115', '15116', '15120', '15121', '15130', '15131', '15135', '15136', '15150', '15151', '15152', '15155', '15156', '15157', '15200', '15201', '15220', '15221', '15240', '15241', '15260', '15261', '15271', '15272', '15273', '15274', '15275', '15276', '15277', '15278', '15570', '15572', '15574', '15576', '15600', '15610', '15620', '15630', '15650', '15730', '15731', '15733', '15734', '15736', '15738', '15820', '15821', '15822', '15823')
				THEN 'Skin_Graft_or_Reconstruction_Procedures'
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


/*
***********************************************************************
File: op_opthalmology_peds.sql

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
	Pull adult/peds cases for peds opthalmology procedures 2019 op lf

Revision History:
Date		Version		Description
----		----		----
2019-06-04	v1			Initial Creation
2019-06-25	v2			Add CCSParent_Description
2021-06-17	v3			2021 Survey 2020 data
2020-06-20	v4			2022 survey of 2021 data
***********************************************************************
*/

SELECT PAV.Med_Rec_No,
	PAV.PtNo_Num,
	E.UserDataCd,
	D.UserDataText AS 'ORSOS_CASE_NO',
	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
	pvn.ClasfCd,
	'Opthalmology_Peds' AS 'LeapFrog_Procedure_Group',
	CCS.[Description] AS 'CCS_Description'
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN ON PAV.Pt_No = PVN.Pt_No
	AND PVN.ClasfCd IN (
		-- Anterior Segment Eye Procedures
		'15820', '15821', '15822', '15823', '65270', '65272', '65273', '65275', '65280', '65285', '65286', '65400', '65420', '65426', '65450', '65710', '65730', '65750', '65755', '65756', '65820', '65850', '65855', '66150', '66155', '66160', '66170', '66172', '66174', '66175', '66179', '66180', '66183', '66184', '66185', '66225', '66250', '66605', '66700', '66710', '66711', '66720', '66740', '66761', '66820', '66821', '66825', '66830', '66840', '66850', '66852', '66920', '66930', '66940', '66982', '66983', '66984', '66985', '66986', '66987', '66988', '66990', 
		-- Posterior Segment Eye Procedures
		'67218', '67220', '67221', '67225', '67227', '67228',
		-- Ocular Adnexa and Other Eye Procedures
		'67311', '67312', '67314', '67316', '67318', '67320', '67331', '67332', '67334', '67335', '67340', '67343', '67345', '67346', '67400', '67405', '67412', '67413', '67414', '67415', '67420', '67430', '67440', '67445', '67450', '67500', '67505', '67515', '67550', '67560', '67570', '67700', '67710', '67715', '67800', '67801', '67805', '67808', '67810', '67820', '67825', '67830', '67835', '67840', '67850', '67875', '67880', '67882', '67900', '67901', '67902', '67903', '67904', '67906', '67908', '67909', '67911', '67912', '67914', '67915', '67916', '67917', '67921', '67922', '67923', '67924', '67930', '67935', '67938', '67950', '67961', '67966', '67971', '67973', '67974', '67975', '67999', '68020', '68040', '68100', '68110', '68115', '68130', '68135', '68200', '68320', '68325', '68326', '68328', '68330', '68335', '68340', '68360', '68362', '68371', '68399', '68400', '68420', '68440', '68500', '68505', '68520', '68530', '68540', '68550', '68700', '68705', '68720', '68745', '68750', '68760', '68761', '68770', '68801', '68810', '68811', '68815', '68816', '68840'
		)
INNER JOIN SMSDSS.BMH_UserTwoFact_V AS D ON PAV.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '571'
LEFT OUTER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS E ON D.UserDataKey = E.UserTwoKey
CROSS APPLY (
	SELECT CASE 
			WHEN PVN.CLASFCD IN ('15820', '15821', '15822', '15823', '65270', '65272', '65273', '65275', '65280', '65285', '65286', '65400', '65420', '65426', '65450', '65710', '65730', '65750', '65755', '65756', '65820', '65850', '65855', '66150', '66155', '66160', '66170', '66172', '66174', '66175', '66179', '66180', '66183', '66184', '66185', '66225', '66250', '66605', '66700', '66710', '66711', '66720', '66740', '66761', '66820', '66821', '66825', '66830', '66840', '66850', '66852', '66920', '66930', '66940', '66982', '66983', '66984', '66985', '66986', '66987', '66988', '66990')
				THEN 'Anterior_Segment_Eye_Procedures'
			WHEN PVN.ClasfCd IN ('67218', '67220', '67221', '67225', '67227', '67228')
				THEN 'Posterior_Segment_Eye_Procedures'
			WHEN PVN.CLASFCD IN ('67311', '67312', '67314', '67316', '67318', '67320', '67331', '67332', '67334', '67335', '67340', '67343', '67345', '67346', '67400', '67405', '67412', '67413', '67414', '67415', '67420', '67430', '67440', '67445', '67450', '67500', '67505', '67515', '67550', '67560', '67570', '67700', '67710', '67715', '67800', '67801', '67805', '67808', '67810', '67820', '67825', '67830', '67835', '67840', '67850', '67875', '67880', '67882', '67900', '67901', '67902', '67903', '67904', '67906', '67908', '67909', '67911', '67912', '67914', '67915', '67916', '67917', '67921', '67922', '67923', '67924', '67930', '67935', '67938', '67950', '67961', '67966', '67971', '67973', '67974', '67975', '67999', '68020', '68040', '68100', '68110', '68115', '68130', '68135', '68200', '68320', '68325', '68326', '68328', '68330', '68335', '68340', '68360', '68362', '68371', '68399', '68400', '68420', '68440', '68500', '68505', '68520', '68530', '68540', '68550', '68700', '68705', '68720', '68745', '68750', '68760', '68761', '68770', '68801', '68810', '68811', '68815', '68816', '68840'
					)
				THEN 'Ocular_Adnexa_and_Other_Eye_Procedures'
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

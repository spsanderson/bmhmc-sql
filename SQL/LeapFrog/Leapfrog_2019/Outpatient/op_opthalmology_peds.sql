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
***********************************************************************
*/

SELECT PAV.Med_Rec_No
, PAV.PtNo_Num
, E.UserDataCd
, D.UserDataText AS 'ORSOS_CASE_NO'
, PAV.Adm_Date
, pvn.ClasfCd
, 'Opthalmology_Peds' AS 'LeapFrog_Procedure_Group'
, CCS.[Description] AS 'CCS_Description'
,CCSParent.[Description] AS 'CCSParent_Description'

FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN
ON PAV.Pt_No = PVN.Pt_No
	AND (
		PVN.ClasfCd BETWEEN '65710' AND '65757' OR 
		PVN.ClasfCd BETWEEN '65820' AND '65855' OR 
		PVN.ClasfCd BETWEEN '66150' AND '66185' OR 
		PVN.ClasfCd BETWEEN '66700' AND '66761' OR 
		PVN.ClasfCd BETWEEN '66820' AND '66986' OR 
		PVN.ClasfCd BETWEEN '15820' AND '15823' OR 
		PVN.ClasfCd BETWEEN '65270' AND '65286' OR 
		PVN.ClasfCd BETWEEN '65400' AND '65400' OR 
		PVN.ClasfCd BETWEEN '65420' AND '65426' OR 
		PVN.ClasfCd BETWEEN '66250' AND '66250' OR 
		PVN.ClasfCd BETWEEN '67700' AND '67808' OR 
		PVN.ClasfCd BETWEEN '67820' AND '68040' OR 
		PVN.ClasfCd BETWEEN '68110' AND '68505' OR 
		PVN.ClasfCd BETWEEN '68530' AND '68840' OR 
		PVN.ClasfCd BETWEEN '67311' AND '67345' OR 
		PVN.ClasfCd BETWEEN '67405' AND '67414' OR 
		PVN.ClasfCd BETWEEN '67420' AND '67445' OR 
		PVN.ClasfCd BETWEEN '67500' AND '67560'
	)
INNER JOIN SMSDSS.BMH_UserTwoFact_V AS D
ON PAV.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '571'
LEFT OUTER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS E
ON D.UserDataKey = E.UserTwoKey

CROSS APPLY (
	SELECT
		CASE
			WHEN PVN.CLASFCD BETWEEN '65710' AND '65757' THEN 'Corneal transplant'
			WHEN PVN.CLASFCD BETWEEN '65820' AND '65855' THEN 'Glaucoma procedures'
			WHEN PVN.CLASFCD BETWEEN '66150' AND '66185' THEN 'Glaucoma procedures'
			WHEN PVN.CLASFCD BETWEEN '66700' AND '66761' THEN 'Glaucoma procedures'
			WHEN PVN.CLASFCD BETWEEN '66820' AND '66986' THEN 'Lens and cataract procedures'
			WHEN PVN.CLASFCD BETWEEN '15820' AND '15823' THEN 'Other therapeutic procedures on eyelids, conjunctiva, cornea'
			WHEN PVN.CLASFCD BETWEEN '65270' AND '65286' THEN 'Other therapeutic procedures on eyelids, conjunctiva, cornea'
			WHEN PVN.CLASFCD BETWEEN '65400' AND '65400' THEN 'Other therapeutic procedures on eyelids, conjunctiva, cornea'
			WHEN PVN.CLASFCD BETWEEN '65420' AND '65426' THEN 'Other therapeutic procedures on eyelids, conjunctiva, cornea'
			WHEN PVN.CLASFCD BETWEEN '66250' AND '66250' THEN 'Other therapeutic procedures on eyelids, conjunctiva, cornea'
			WHEN PVN.CLASFCD BETWEEN '67700' AND '67808' THEN 'Other therapeutic procedures on eyelids, conjunctiva, cornea'
			WHEN PVN.CLASFCD BETWEEN '67820' AND '68040' THEN 'Other therapeutic procedures on eyelids, conjunctiva, cornea'
			WHEN PVN.CLASFCD BETWEEN '68110' AND '68505' THEN 'Other therapeutic procedures on eyelids, conjunctiva, cornea'
			WHEN PVN.CLASFCD BETWEEN '68530' AND '68840' THEN 'Other therapeutic procedures on eyelids, conjunctiva, cornea'
			WHEN PVN.CLASFCD BETWEEN '67311' AND '67345' THEN 'Other extraocular muscle and orbit therapeutic procedures'
			WHEN PVN.CLASFCD BETWEEN '67405' AND '67414' THEN 'Other extraocular muscle and orbit therapeutic procedures'
			WHEN PVN.CLASFCD BETWEEN '67420' AND '67445' THEN 'Other extraocular muscle and orbit therapeutic procedures'
			WHEN PVN.CLASFCD BETWEEN '67500' AND '67560' THEN 'Other extraocular muscle and orbit therapeutic procedures'
		END AS 'Description'
) AS CCS

CROSS APPLY (
	SELECT
		CASE
			WHEN PVN.CLASFCD BETWEEN '65710' AND '65757' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '65820' AND '65855' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '66150' AND '66185' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '66700' AND '66761' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '66820' AND '66986' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '15820' AND '15823' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '65270' AND '65286' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '65400' AND '65400' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '65420' AND '65426' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '66250' AND '66250' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '67700' AND '67808' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '67820' AND '68040' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '68110' AND '68505' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '68530' AND '68840' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '67311' AND '67345' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '67405' AND '67414' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '67420' AND '67445' THEN 'Anterior Segment Eye Procedures'
			WHEN PVN.CLASFCD BETWEEN '67500' AND '67560' THEN 'Anterior Segment Eye Procedures'
		END AS 'Description'
) AS CCSParent

WHERE PAV.Pt_Age < 18
AND PAV.tot_chg_amt > 0
AND LEFT(PAV.PTNO_NUM, 1) NOT IN ('2', '8')
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
AND PAV.Adm_Date >= '2018-01-01'
AND PAV.Adm_Date < '2019-01-01'
AND PAV.Plm_Pt_Acct_Type != 'I'

ORDER BY PAV.PtNo_Num
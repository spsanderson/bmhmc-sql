/*
***********************************************************************
File: op_otolaryngology_peds.sql

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
	Pull adult/peds cases for peds otolaryngology procedures 2019 op lf

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
, 'Otolaryngology_Peds' AS 'LeapFrog_Procedure_Group'
, CCS.[Description] AS 'CCS_Description'

FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN
ON PAV.Pt_No = PVN.Pt_No
	AND (
		PVN.ClasfCd BETWEEN '69610' AND '69637' OR 
		PVN.ClasfCd BETWEEN '69420' AND '69421' OR 
		PVN.ClasfCd BETWEEN '69433' AND '69440' OR 
		PVN.ClasfCd BETWEEN '69110' AND '69155' OR 
		PVN.ClasfCd BETWEEN '69205' AND '69210' OR 
		PVN.ClasfCd BETWEEN '69424' AND '69424' OR 
		PVN.ClasfCd BETWEEN '21230' AND '21235' OR 
		PVN.ClasfCd BETWEEN '40810' AND '40816' OR 
		PVN.ClasfCd BETWEEN '41500' AND '41599' OR 
		PVN.ClasfCd BETWEEN '42104' AND '42340' OR 
		PVN.ClasfCd BETWEEN '42408' AND '42510' OR 
		PVN.ClasfCd BETWEEN '42810' AND '42815' OR 
		PVN.ClasfCd BETWEEN '30400' AND '30545' OR 
		PVN.ClasfCd BETWEEN '30110' AND '30117' OR 
		PVN.ClasfCd BETWEEN '30130' AND '30160' OR 
		PVN.ClasfCd BETWEEN '30310' AND '30310' OR 
		PVN.ClasfCd BETWEEN '30801' AND '30802' OR 
		PVN.ClasfCd BETWEEN '31239' AND '31240' OR 
		PVN.ClasfCd BETWEEN '31251' AND '31259' OR 
		PVN.ClasfCd BETWEEN '31261' AND '31269' OR 
		PVN.ClasfCd BETWEEN '31271' AND '31299' OR 
		PVN.ClasfCd BETWEEN '21300' AND '21495' OR 
		PVN.ClasfCd BETWEEN '30930' AND '30930' OR 
		PVN.ClasfCd BETWEEN '42820' AND '42836'
	)
INNER JOIN SMSDSS.BMH_UserTwoFact_V AS D
ON PAV.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '571'
LEFT OUTER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS E
ON D.UserDataKey = E.UserTwoKey

CROSS APPLY (
	SELECT
		CASE
			WHEN PVN.CLASFCD BETWEEN '69610' AND '69637' THEN 'Tympanoplasty'
			WHEN PVN.CLASFCD BETWEEN '69420' AND '69421' THEN 'Myringotomy'
			WHEN PVN.CLASFCD BETWEEN '69433' AND '69440' THEN 'Myringotomy'
			WHEN PVN.CLASFCD BETWEEN '69110' AND '69155' THEN 'Other therapeutic ear procedures'
			WHEN PVN.CLASFCD BETWEEN '69205' AND '69210' THEN 'Other therapeutic ear procedures'
			WHEN PVN.CLASFCD BETWEEN '69424' AND '69424' THEN 'Other therapeutic ear procedures'
			WHEN PVN.CLASFCD BETWEEN '21230' AND '21235' THEN 'Other OR therapeutic procedures on musculoskeletal system'
			WHEN PVN.CLASFCD BETWEEN '40810' AND '40816' THEN 'Other OR therapeutic procedures on nose, mouth and pharynx'
			WHEN PVN.CLASFCD BETWEEN '41500' AND '41599' THEN 'Other OR therapeutic procedures on nose, mouth and pharynx'
			WHEN PVN.CLASFCD BETWEEN '42104' AND '42340' THEN 'Other OR therapeutic procedures on nose, mouth and pharynx'
			WHEN PVN.CLASFCD BETWEEN '42408' AND '42510' THEN 'Other OR therapeutic procedures on nose, mouth and pharynx'
			WHEN PVN.CLASFCD BETWEEN '42810' AND '42815' THEN 'Other OR therapeutic procedures on nose, mouth and pharynx'
			WHEN PVN.CLASFCD BETWEEN '30400' AND '30545' THEN 'Plastic procedures on nose'
			WHEN PVN.CLASFCD BETWEEN '30110' AND '30117' THEN 'Other OR therapeutic procedures on nose, mouth and pharynx'
			WHEN PVN.CLASFCD BETWEEN '30130' AND '30160' THEN 'Other OR therapeutic procedures on nose, mouth and pharynx'
			WHEN PVN.CLASFCD BETWEEN '30310' AND '30310' THEN 'Other OR therapeutic procedures on nose, mouth and pharynx'
			WHEN PVN.CLASFCD BETWEEN '30801' AND '30802' THEN 'Other OR therapeutic procedures on nose, mouth and pharynx'
			WHEN PVN.CLASFCD BETWEEN '31239' AND '31240' THEN 'Other OR therapeutic procedures on nose, mouth and pharynx'
			WHEN PVN.CLASFCD BETWEEN '31251' AND '31259' THEN 'Other OR therapeutic procedures on nose, mouth and pharynx'
			WHEN PVN.CLASFCD BETWEEN '31261' AND '31269' THEN 'Other OR therapeutic procedures on nose, mouth and pharynx'
			WHEN PVN.CLASFCD BETWEEN '31271' AND '31299' THEN 'Other OR therapeutic procedures on nose, mouth and pharynx'
			WHEN PVN.CLASFCD BETWEEN '21300' AND '21495' THEN 'Treatment, facial fracture or dislocation'
			WHEN PVN.CLASFCD BETWEEN '30930' AND '30930' THEN 'Treatment, facial fracture or dislocation'
			WHEN PVN.CLASFCD BETWEEN '42820' AND '42836' THEN 'Tonsillectomy and/or adenoidectomy'
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
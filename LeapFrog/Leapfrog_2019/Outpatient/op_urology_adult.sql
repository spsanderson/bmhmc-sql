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
	Pull adult/peds cases for adult urology procedures 2019 op lf

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
, 'Urology_Adult' AS 'LeapFrog_Procedure_Group'
, CCS.[Description] AS 'CCS_Description'

FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN
ON PAV.Pt_No = PVN.Pt_No
	AND (
		PVN.ClasfCd BETWEEN '54150' AND '54161' OR 
		PVN.ClasfCd BETWEEN '54162' AND '54162' OR 
		PVN.ClasfCd BETWEEN '54163' AND '54163' OR 
		PVN.ClasfCd BETWEEN '52000' AND '52000' OR 
		PVN.ClasfCd BETWEEN '52007' AND '52204' OR 
		PVN.ClasfCd BETWEEN '52351' AND '52351' OR 
		PVN.ClasfCd BETWEEN '52214' AND '52240' OR 
		PVN.ClasfCd BETWEEN '52300' AND '52315' OR 
		PVN.ClasfCd BETWEEN '52352' AND '52352' OR 
		PVN.ClasfCd BETWEEN '52353' AND '52353' OR 
		PVN.ClasfCd BETWEEN '52356' AND '52356' OR 
		PVN.ClasfCd BETWEEN '52277' AND '52285' OR 
		PVN.ClasfCd BETWEEN '52287' AND '52287' OR 
		PVN.ClasfCd BETWEEN '52355' AND '52355' OR 
		PVN.ClasfCd BETWEEN '54300' AND '54304' OR 
		PVN.ClasfCd BETWEEN '54322' AND '54440' OR 
		PVN.ClasfCd BETWEEN '54510' AND '54692' OR 
		PVN.ClasfCd BETWEEN '55040' AND '55060' OR 
		PVN.ClasfCd BETWEEN '55150' AND '55180' OR 
		PVN.ClasfCd BETWEEN '55200' AND '55250' OR 
		PVN.ClasfCd BETWEEN '53000' AND '53060' OR 
		PVN.ClasfCd BETWEEN '53450' AND '53665' OR
		PVN.ClasfCd BETWEEN '57287' AND '57288'
	)
INNER JOIN SMSDSS.BMH_UserTwoFact_V AS D
ON PAV.PtNo_Num = D.PtNo_Num
	AND D.UserDataKey = '571'
LEFT OUTER JOIN SMSDSS.BMH_UserTwoField_Dim_V AS E
ON D.UserDataKey = E.UserTwoKey

CROSS APPLY (
	SELECT
		CASE
			WHEN PVN.CLASFCD BETWEEN '54150' AND '54161' THEN 'Circumcision'
			WHEN PVN.CLASFCD BETWEEN '54162' AND '54162' THEN 'Circumcision'
			WHEN PVN.CLASFCD BETWEEN '54163' AND '54163' THEN 'Circumcision'
			WHEN PVN.CLASFCD BETWEEN '52000' AND '52000' THEN 'Endoscopy and endoscopic biopsy of the urinary tract'
			WHEN PVN.CLASFCD BETWEEN '52007' AND '52204' THEN 'Endoscopy and endoscopic biopsy of the urinary tract'
			WHEN PVN.CLASFCD BETWEEN '52351' AND '52351' THEN 'Endoscopy and endoscopic biopsy of the urinary tract'
			WHEN PVN.CLASFCD BETWEEN '52214' AND '52240' THEN 'Transurethral excision, drainage, or removal urinary obstruction'
			WHEN PVN.CLASFCD BETWEEN '52300' AND '52315' THEN 'Transurethral excision, drainage, or removal urinary obstruction'
			WHEN PVN.CLASFCD BETWEEN '52352' AND '52352' THEN 'Transurethral excision, drainage, or removal urinary obstruction'
			WHEN PVN.CLASFCD BETWEEN '52353' AND '52353' THEN 'Extracorporeal lithotripsy, urinary'
			WHEN PVN.CLASFCD BETWEEN '52356' AND '52356' THEN 'Extracorporeal lithotripsy, urinary'
			WHEN PVN.CLASFCD BETWEEN '52277' AND '52285' THEN 'Procedures on the urethra'
			WHEN PVN.CLASFCD BETWEEN '52287' AND '52287' THEN 'Other OR therapeutic procedures of urinary tract'
			WHEN PVN.CLASFCD BETWEEN '52355' AND '52355' THEN 'Other OR therapeutic procedures of urinary tract'
			WHEN PVN.CLASFCD BETWEEN '54300' AND '54304' THEN 'Other OR therapeutic procedures, male genital'
			WHEN PVN.CLASFCD BETWEEN '54322' AND '54440' THEN 'Other OR therapeutic procedures, male genital'
			WHEN PVN.CLASFCD BETWEEN '54510' AND '54692' THEN 'Other OR therapeutic procedures, male genital'
			WHEN PVN.CLASFCD BETWEEN '55040' AND '55060' THEN 'Other OR therapeutic procedures, male genital'
			WHEN PVN.CLASFCD BETWEEN '55150' AND '55180' THEN 'Other OR therapeutic procedures, male genital'
			WHEN PVN.CLASFCD BETWEEN '55200' AND '55250' THEN 'Other non-OR therapeutic procedures, male genital'
			WHEN PVN.CLASFCD BETWEEN '53000' AND '53060' THEN 'Procedures on the urethra'
			WHEN PVN.CLASFCD BETWEEN '53450' AND '53665' THEN 'Procedures on the urethra'
			WHEN PVN.CLASFCD BETWEEN '57287' AND '57288' THEN 'Genitourinary incontinence procedures'
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
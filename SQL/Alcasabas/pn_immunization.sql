/*
***********************************************************************
File: pn_immunization.sql

Input Parameters:
	None

Tables/Views:
	smsmir.sr_obsv AS SROBV
	smsdss.BMH_PLM_PtAcct_V AS PAV
	smsdss.QOC_obsv_v OBV

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get the Pneumonia Immunization information from the Admission Form
	and the last value from the shift assessment

Revision History:
Date		Version		Description
----		----		----
2019-03-08	v1			Initial Creation
***********************************************************************
*/



SELECT TOP 10 PAV.Med_Rec_No
, SROBV.episode_no
, SROBV.form_usage
, SROBV.obsv_cd
, SROBV.obsv_cd_name
, SROBV.obsv_cre_dtime
, SROBV.dsply_val
, LAST_VAL.sort_dtime AS [Last_Value_DTime]
, LAST_VAL.dsply_val AS [Last_Value]
, CAST(PAV.Adm_Date AS date) AS [Adm_Date]
, CAST(PAV.Dsch_Date AS date) AS [Dsch_Date]

FROM smsmir.sr_obsv AS SROBV
INNER JOIN smsdss.BMH_PLM_PtAcct_V AS PAV
ON SROBV.episode_no = PAV.PtNo_Num
	AND PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) != '2'
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
-- LAST VALUE
LEFT OUTER JOIN (
	SELECT OBV.episode_no
	, OBV.obsv_cd
	, OBV.sort_dtime
	, OBV.dsply_val
	FROM smsdss.QOC_obsv_v OBV
	WHERE OBV.obsv_cd = 'A_Pneumo Immun'
	AND OBV.sort_dtime = (
		SELECT MAX(ZZZ.SORT_DTIME) 
		FROM smsdss.QOC_obsv_v AS ZZZ 
		WHERE ZZZ.episode_no = OBV.episode_no 
		AND ZZZ.obsv_cd = OBV.obsv_cd
	)
) AS LAST_VAL
ON SROBV.episode_no = LAST_VAL.episode_no
	AND SROBV.obsv_cd = LAST_VAL.obsv_cd

WHERE SROBV.form_usage = 'ADMISSION'
AND SROBV.obsv_cd = 'A_Pneumo Immun'
AND PAV.Dsch_Date >= '2019-01-01'
AND PAV.Dsch_Date < '2019-03-01'

OPTION(FORCE ORDER)
;
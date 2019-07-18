/*
***********************************************************************
File: cigna_rate_sheet_Lithotripsy_query.sql

Input Parameters:
	None

Tables/Views:
	SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New
	SMSDSS.BMH_PLM_PtAcct_V
	SMSMIR.actv
	SMSMIR.mir_actv_proc_seg_xref

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get Cigna Lithotripsy Volume

Revision History:
Date		Version		Description
----		----		----
2019-06-20	v1			Initial Creation
***********************************************************************
*/
DECLARE @STARTDATE DATETIME;
DECLARE @ENDDATE DATETIME;

SET @STARTDATE = '2018-01-01';
SET @ENDDATE = '2019-01-01';

SELECT PAV.med_rec_no,
	PAV.PtNo_Num,
	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
	CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date],
	YEAR(PAV.DSCH_DATE) AS [Dsch_YR],
	MONTH(PAV.DSCH_DATE) AS [Dsch_MO],
	pav.hosp_svc,
	pav.tot_chg_amt,
	pav.tot_pay_amt,
	pav.tot_amt_due
FROM smsdss.BMH_PLM_PtAcct_V AS PAV
WHERE PAV.Dsch_Date >= @STARTDATE
	AND PAV.Dsch_Date < @ENDDATE
	AND PAV.tot_chg_amt > 0
	AND PAV.Pyr1_Co_Plan_Cd IN ('K11', 'X01', 'E01', 'K55')
	AND PAV.PT_NO IN (
		SELECT DISTINCT PT_NO
		FROM SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New
		WHERE (
			ClasfCd IN (
				'50590','43265','52353','28890','0019T','S0400'
			)
			OR ClasfCd BETWEEN '50592' AND '50593'
			OR ClasfCd BETWEEN '0101T' AND '0102T'
			OR ClasfCd BETWEEN '50080' AND '50081'
			OR ClasfCd = 'S9034'
		)
		AND PT_NO IN (
			SELECT DISTINCT ZZZ.pt_id
			FROM SMSMIR.actv AS ZZZ
			WHERE ZZZ.actv_cd IN (
				SELECT actv_cd
				FROM SMSMIR.mir_actv_proc_seg_xref
				WHERE REV_CD IN (
					'360','361','369','481','490','499','750','790'
				)
			)
		)
	)

/*
***********************************************************************
File: cigna_rate_sheet_drugs_259_query.sql

Input Parameters:
	None

Tables/Views:
	SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New
	SMSDSS.BMH_PLM_PtAcct_V
	SMSMIR.mir_actv_proc_seg_xref
	SMSMIR.actv

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get Volume Other Pharmacy - RC 259

Revision History:
Date		Version		Description
----		----		----
2019-07-01	v1			Initial Creation
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
	pav.tot_amt_due,
	(
		SELECT ISNULL(SUM(ZZZ.actv_tot_qty), 0)
		FROM smsmir.actv AS ZZZ
		WHERE PAV.Pt_No = ZZZ.pt_id
			AND PAV.unit_seq_no = ZZZ.unit_seq_no
			AND PAV.from_file_ind = ZZZ.from_file_ind
			AND actv_cd IN (
				SELECT DISTINCT ACTV_CD
				FROM SMSMIR.mir_actv_proc_seg_xref
				WHERE rev_cd IN ('259')
				)
		) AS [Drugs_Other_Qty],
	(
		SELECT ISNULL(SUM(ZZZ.chg_tot_amt), 0)
		FROM smsmir.actv AS ZZZ
		WHERE PAV.Pt_No = ZZZ.pt_id
			AND PAV.unit_seq_no = ZZZ.unit_seq_no
			AND PAV.from_file_ind = ZZZ.from_file_ind
			AND actv_cd IN (
				SELECT DISTINCT ACTV_CD
				FROM SMSMIR.mir_actv_proc_seg_xref
				WHERE rev_cd IN ('259')
				)
		) AS [Drugs_Other_Chgs]
FROM smsdss.BMH_PLM_PtAcct_V AS PAV
WHERE PAV.Dsch_Date >= @STARTDATE
	AND PAV.Dsch_Date < @ENDDATE
	AND PAV.tot_chg_amt > 0
	AND PAV.Pyr1_Co_Plan_Cd IN ('K11', 'X01', 'E01', 'K55')
	AND PAV.Plm_Pt_Acct_Type != 'I'
	AND PAV.PT_NO IN (
		SELECT DISTINCT ZZZ.pt_id
		FROM SMSMIR.actv AS ZZZ
		WHERE ZZZ.actv_cd IN (
			SELECT actv_cd
			FROM SMSMIR.mir_actv_proc_seg_xref
			WHERE rev_cd IN ('259')
		)
	)
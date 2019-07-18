/*
***********************************************************************
File: cigna_rate_sheet_er_ct_query.sql

Input Parameters:
	None

Tables/Views:
	SMSMIR.mir_actv_proc_seg_xref
	SMSDSS.BMH_PLM_PtAcct_V
	smsmir.actv

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Entere Here

Revision History:
Date		Version		Description
----		----		----
2019-06-19	v1			Initial Creation
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
	(
		SELECT COUNT(DISTINCT (PT_ID))
		FROM smsmir.actv AS ZZZ
		WHERE PAV.Pt_No = ZZZ.pt_id
			AND PAV.unit_seq_no = ZZZ.unit_seq_no
			AND PAV.from_file_ind = ZZZ.from_file_ind
			AND actv_cd IN (
				SELECT DISTINCT ACTV_CD
				FROM SMSMIR.mir_actv_proc_seg_xref
				WHERE rev_cd IN ('350', '351', '352', '353', '354', '355', '356', '357', '358', '359')
				)
		) AS [ED_CT_Pts],
	(
		SELECT ISNULL(SUM(ZZZ.actv_tot_qty), 0)
		FROM smsmir.actv AS ZZZ
		WHERE PAV.Pt_No = ZZZ.pt_id
			AND PAV.unit_seq_no = ZZZ.unit_seq_no
			AND PAV.from_file_ind = ZZZ.from_file_ind
			AND actv_cd IN (
				SELECT DISTINCT ACTV_CD
				FROM SMSMIR.mir_actv_proc_seg_xref
				WHERE rev_cd IN ('350', '351', '352', '353', '354', '355', '356', '357', '358', '359')
				)
		) AS [ED_CT_Qty],
	(
		SELECT ISNULL(SUM(ZZZ.chg_tot_amt), 0)
		FROM smsmir.actv AS ZZZ
		WHERE PAV.Pt_No = ZZZ.pt_id
			AND PAV.unit_seq_no = ZZZ.unit_seq_no
			AND PAV.from_file_ind = ZZZ.from_file_ind
			AND actv_cd IN (
				SELECT DISTINCT ACTV_CD
				FROM SMSMIR.mir_actv_proc_seg_xref
				WHERE rev_cd IN ('350', '351', '352', '353', '354', '355', '356', '357', '358', '359')
				)
		) AS [ED_CT_Chgs]
FROM smsdss.BMH_PLM_PtAcct_V AS PAV
WHERE PAV.Dsch_Date >= @STARTDATE
	AND PAV.Dsch_Date < @ENDDATE
	AND PAV.tot_chg_amt > 0
	AND PAV.Pyr1_Co_Plan_Cd IN ('K11', 'X01', 'E01', 'K55')
	AND LEFT(PAV.PtNo_Num, 1) = '8'

/**********************************************************************
File: cigna_rate_sheet_ip_query.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
	SMSDSS.pyr_dim_v
	SMSDSS.drg_dim_v
	smsmir.mir_actv_proc_seg_xref
	smsmir.actv

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get inpatient data for Cigna patients to fill out rate sheet

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

SELECT PAV.Med_Rec_No,
	PAV.PtNo_Num,
	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
	CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date],
	YEAR(PAV.DSCH_DATE) AS [Dsch_YR],
	MONTH(PAV.DSCH_DATE) AS [Dsch_MO],
	PAV.drg_no,
	DRG.drg_name,
	DRG.MDCDescText,
	DRG.MDCVal,
	DRG.drg_med_surg_group,
	DRG.drg_complic_group,
	PAV.drg_cost_weight,
	PAV.drg_outl_ind,
	PAV.tot_chg_amt,
	PAV.tot_adj_amt,
	PAV.tot_pay_amt,
	PAV.Tot_Amt_Due,
	PAV.Pyr1_Co_Plan_Cd,
	PDV.pyr_name,
	PDV.pyr_group2
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.pyr_dim_v AS PDV ON PAV.Pyr1_Co_Plan_Cd = PDV.pyr_cd
	AND PAV.Regn_Hosp = PDV.orgz_cd
LEFT OUTER JOIN SMSDSS.drg_dim_v AS DRG ON PAV.drg_no = DRG.drg_no
	AND DRG.drg_vers = 'MS-V25'
WHERE PAV.Dsch_Date >= @STARTDATE
	AND PAV.Dsch_Date < @ENDDATE
	AND PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_nUM, 1) != '2'
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.Pyr1_Co_Plan_Cd IN ('K11', 'X01', 'E01', 'K55')
	AND PAV.Plm_Pt_Acct_Type = 'I'
	AND PAV.PT_NO IN (
		SELECT DISTINCT ZZZ.PT_ID
		FROM SMSMIR.actv AS ZZZ
		WHERE ZZZ.actv_cd IN (
				SELECT actv_cd
				FROM smsmir.mir_actv_proc_seg_xref
				WHERE rev_cd IN ('')
				)
		)

/*
***********************************************************************
File: hbcs_act_records.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
	smsmir.mir_acct
	smsdss.pract_dim_v
	smsdss.c_pt_payments_v
	smsmir.vst_rpt
	Customer.Custom_DRG

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Gather the ACT records for HBCS on the self pay accounts

Revision History:
Date		Version		Description
----		----		----
2022-05-24	v1			Initial Creation
***********************************************************************
*/

DROP TABLE IF EXISTS #visits_tbl
CREATE TABLE #visits_tbl (
	med_rec_no VARCHAR(12),
	pt_id VARCHAR(12),
	unit_seq_no VARCHAR(12),
	pt_id_start_dtime DATE
)

INSERT INTO #visits_tbl
SELECT DISTINCT PAV.Med_Rec_No,
	PAV.Pt_No,
	PAV.unit_seq_no,
	PAV.pt_id_start_dtime
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
WHERE PAV.Tot_Amt_Due > 0
AND PAV.FC IN ('G','P','R')
AND PAV.tot_chg_amt > 0
AND PAV.Tot_Amt_Due > 0
AND PAV.prin_dx_cd IS NOT NULL
AND PAV.unit_seq_no != '99999999';

SELECT [RECORD_IDENTIFIER] = 'ACT',
	[MEDICAL_RECORD_NUMBER] = UV.med_rec_no,
	[PATIENT_ACCOUNT_NUMBER] = UV.pt_id,
	[PATIENT_ACCOUNT_UNIT_NO] = UV.unit_seq_no,
	[PATIENT_ID_START_DTIME] = UV.pt_id_start_dtime,
	[TOTAL_CHARGES] = PAV.tot_chg_amt,
	[CURRENT_BALANCE] = PAV.Tot_Amt_Due,
	[ADMIT_DATE] = REPLACE(CAST(PAV.Adm_Date AS DATE), '-',''), -- strip out hyphens YYYYMMDD
	[DISCHARGE_DATE] = CAST(PAV.Dsch_Date AS DATE),
	[BILL_DROP_DATE] = CAST(CASE 
			WHEN PAV.Plm_Pt_Acct_Type = 'I'
				THEN COALESCE(ACCT.fnl_bl_dtime, ACCT.LAST_ACTL_PT_BL_DTIME)
			ELSE COALESCE(ACCT.op_first_bl_dtime, ACCT.LAST_ACTL_PT_BL_DTIME)
			END AS DATE),
	[PATIENT_TYPE] = PAV.pt_type,
	[ACCIDENT_TYPE] = '',
	[CLIENT_FINANCIAL_CLASS] = PAV.fc,
	[VIP_ACCOUNT] = '',
	[CLIENT_SERVICE_CODE] = PAV.hosp_svc,
	[RECURRING_INDICATOR] = PAV.unit_seq_no,
	[FACILITY] = CASE 
		WHEN PAV.hosp_svc = 'DMS'
			THEN 'END STAGE RENAL CENTER'
		WHEN PAV.hosp_svc = 'DIA'
			THEN 'HOSPITAL DIALYSIS CENTER'
		ELSE 'HOSPITAL'
		END,
	[ACCOUNT_TYPE] = PAV.Plm_Pt_Acct_Type,
	[TOTAL_PATIENT_PAYMENT] = ISNULL((
			SELECT SUM(ZZZ.Tot_Pt_Pymts)
			FROM smsdss.c_pt_payments_v AS ZZZ
			WHERE UV.pt_id = ZZZ.pt_id
				AND UV.unit_seq_no = ZZZ.unit_seq_no
			), 0),
	[TOTAL_INSURANCE_PAYMENT] = VST_RPT.ins_pay_amt,
	[TOTAL_ADJUSTMENTS] = PAV.tot_adj_amt,
	[ATTENDING_PHYSICIAN] = UPPER(PDV.pract_rpt_name),
	[ATTENDING_PHYSICIAN_NPI] = PDV.npi_no,
	[REFERRING_PHYSICIAN] = '',
	[PRINCIPAL_DIAGNOSIS] = PAV.prin_dx_cd,
	[STATE_DRG] = APR.APRDRGNO,
	[FEDERAL_DRG] = PAV.drg_no,
	[FACILITY_NPI] = CASE 
		WHEN PAV.hosp_svc = 'DMS'
			THEN '1487743480'
		WHEN PAV.hosp_svc = 'DIA'
			THEN '1235210931'
		ELSE '1053354100'
		END
FROM #visits_tbl AS UV
INNER JOIN smsdss.BMH_PLM_PTACCT_V AS PAV ON UV.med_rec_no = PAV.Med_Rec_No
	AND UV.pt_id = PAV.Pt_No
	AND UV.unit_seq_no = PAV.unit_seq_no
INNER JOIN smsmir.mir_acct AS ACCT ON UV.pt_id = ACCT.pt_id
	AND UV.unit_seq_no = ACCT.unit_seq_no
LEFT JOIN smsmir.vst_rpt AS VST_RPT ON UV.pt_id = VST_RPT.pt_id
	AND UV.unit_seq_no = VST_RPT.unit_seq_no
LEFT JOIN smsdss.pract_dim_v AS PDV ON PAV.Atn_Dr_No = PDV.src_pract_no
	AND PAV.Regn_Hosp = PDV.orgz_cd
LEFT JOIN Customer.Custom_DRG AS APR ON PAV.PtNo_Num = APR.PATIENT#


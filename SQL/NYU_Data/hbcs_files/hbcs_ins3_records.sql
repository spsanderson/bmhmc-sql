/*
***********************************************************************
File: hbcs_ins3_records.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
	smsdss.pyr_dim_v
	smsmir.vst_rpt
	smsdss.c_ins_user_fields_v
    smsdss.c_guarantor_demos_v
    smsmir.pyr_plan
    smsmir.pay

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Gather the INS3 records for HBCS on the self pay accounts

Revision History:
Date		Version		Description
----		----		----
2022-05-25	v1			Initial Creation
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

SELECT [RECORD_IDENTIFIER] = 'INS3',
	[MEDICAL_RECORD_NUMBER] = UV.med_rec_no,
	[PATIENT_ACCOUNT_NUMBER] = UV.pt_id,
	[PATIENT_ACCUNT_UNIT_NO] = UV.unit_seq_no,
	[PATIENT_ID_START_DTIME] = UV.pt_id_start_dtime,
	[PLAN_CODE] = PAV.Pyr3_Co_Plan_Cd,
	[PAYER_NAME] = PDV.pyr_name,
	[PAYER_ADDRESS_LINE_1] = INS.Ins_Addr1,
	[PAYER_ADDRESS_LINE_2] = '',
	[PAYER_CITY] = INS.Ins_City,
	[PAYER_STATE] = INS.Ins_State,
	[PAYER_ZIP] = INS.Ins_Zip,
	[PAYER_PHONE] = INS.Ins_Tel_No,
	[SUBSCRIBER_DATE_OF_BIRTH] = CAST(PAV.Pt_Birthdate AS DATE),
	[CONTACT_EXTENSION_NUMBER] = '',
	[GROUP_NUMBER] = VST.subscr_ins1_grp_id,
	[GROUP_NAME] = '',
	[PLAN_NUMBER] = '',
	[POLICY_NUMBER] = INS.Ins_Pol_No,
	[PRECERTIFICATION_NUMBER] = VST.ins1_treat_authz_no,
	[POLICY_EFFECTIVE_DATE] = '',
	[INSURANCE_COVERAGE_START] = '',
	[INSURANCE_CONTACT_PERSON] = '',
	[SUBSCRIBER_NAME] = GUA.GuarantorLast + ', ' + GUA.GuarantorFirst,
	[SUBSCRIBER_RELATIONSHIP_TO_PATIENT] = '',
	[SUBSCRIBER_SSN] = GUA.GuarantorSocial,
	[CASE_RATE] = 'WHAT DOES THIS MEAN?',
	[PRIOR_APPROVAL_NUMBER] = '',
	[REFERRAL_NUMBER] = '',
	[PROVIDER_NUMBER] = 'WHAT DOES THIS MEAN?',
	[BILL_TYPE] = '',
	[CLAIM_ID] = CLAIM.pay_desc,
	[OUTSTANDING_PAYER_BALANCE] = PYRPLAN.tot_amt_due,
	[SUBSCRIBER_SEX] = ''
FROM #visits_tbl AS UV
INNER JOIN smsdss.BMH_PLM_PTACCT_V AS PAV ON UV.med_rec_no = PAV.Med_Rec_No
	AND UV.pt_id = PAV.Pt_No
	AND UV.unit_seq_no = PAV.unit_seq_no
INNER JOIN smsdss.pyr_dim_v AS PDV ON PAV.Pyr3_Co_Plan_Cd = PDV.src_pyr_cd
	AND PAV.Regn_Hosp = PDV.orgz_cd
LEFT JOIN smsdss.c_ins_user_fields_v AS INS ON PAV.PT_NO = INS.pt_id
	AND PAV.pt_id_start_dtime = INS.pt_id_start_dtime
	AND PAV.Pyr3_Co_Plan_Cd = INS.pyr_cd
LEFT JOIN smsmir.vst_rpt AS VST ON PAV.Pt_NO = VST.pt_id
	AND PAV.unit_seq_no = VST.unit_seq_no
LEFT JOIN smsdss.c_guarantor_demos_v AS GUA ON PAV.PT_NO = GUA.pt_id
	AND PAV.pt_id_start_dtime = GUA.pt_id_start_dtime
LEFT JOIN smsmir.PAY AS CLAIM ON PAV.PT_NO = CLAIM.pt_id
	AND PAV.unit_seq_no = CLAIM.unit_seq_no
	AND CLAIM.pay_cd = '10501435'
LEFT JOIN smsmir.pyr_plan AS PYRPLAN ON PAV.PT_NO = PYRPLAN.PT_ID
	AND PAV.unit_seq_no = PYRPLAN.PT_ID
	AND PAV.Pyr3_Co_Plan_Cd = PYRPLAN.pyr_cd
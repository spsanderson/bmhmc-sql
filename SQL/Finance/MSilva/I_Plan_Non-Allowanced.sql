/*
*****************************************************************************  
File: I_Plan_Non-Allowanced.sql      

Input  Parameters:
	None

Tables:   
	smsmir.pyr_plan
	smsmir.vst_rpt
	smsdss.c_guarantor_demos_v
	smsmir.mir_pyr_plan_user 
  
Functions:   
	None

Author: Steve P Sanderson II, MPH

Department: Finance, Revenue Cycle
      
Revision History: 
Date		Version	Description
----		----		----
2018-09-25	v1		Initial Creation
2018-09-26	v2		Add filters to ensure pt_bal_amt >= 0
2018-10-30	v3		Add VST.prin_dx_cd IS NOT NULL
2018-06-28    v4            Add I08 insurance plan for July 1st 2019 start date
2021-06-02    v5            Add the following logic:
                            AND DATEDIFF(DAY, VST.vst_end_date ,CAST(GETDATE() AS DATE)) >= 90
2021-06-10    v6            Drop DATEDIFF logic and add E26 back in
-------------------------------------------------------------------------------- 
*/

SELECT PYRPLAN.pt_id
, VST.vst_start_date as [Admit_Date]
, VST.vst_end_date as [Discharge_Date]
, VST.fc
, VST.hosp_svc
, CASE
	WHEN LEFT(VST.hosp_svc, 1) = 'E'
		THEN 1
		ELSE 0
  END AS [EME_Flag]
, DATEDIFF(DD, VST.VST_END_DATE, GETDATE()) AS 'AGE IN DAYS'
, PYRPLAN.pyr_cd
, PYRPLAN.pyr_seq_no
, VST.tot_chg_amt
, VST.tot_bal_amt
, VST.ins_pay_amt
, VST.pt_bal_amt
, PYRPLAN.tot_amt_due AS INS_BAL_AMT
, VST.tot_pay_amt
, (VST.tot_pay_amt - VST.ins_pay_amt) AS PT_PAY_AMT
, guar.GuarantorDOB
, guar.GuarantorFirst
, guar.GuarantorLast
, vst.pt_first_name
, VST.pt_last_name
, COALESCE(vst.ins1_pol_no, INS1.user_text, VST.subscr_ins1_grp_id) AS [Ins1]
, INS_NAME.user_text AS [Ins1_Name]
, COALESCE(vst.ins2_pol_no, INS2.USER_TEXT, VST.SUBSCR_INS2_GRP_ID) AS [Ins2]
, COALESCE(vst.ins3_pol_no, INS3.USER_TEXT, VST.SUBSCR_INS3_GRP_ID) AS [Ins3]
, COALESCE(vst.ins4_pol_no, INS4.USER_TEXT, VST.SUBSCR_INS4_GRP_ID) AS [Ins4]
, vst.drg_no
, PYR_USER.user_text AS [Auth]

FROM SMSMIR.PYR_PLAN AS PYRPLAN
LEFT JOIN smsmir.vst_rpt VST
ON PYRPLAN.pt_id = VST.pt_id
	--AND PYRPLAN.unit_seq_no = VST.unit_seq_no
LEFT JOIN smsdss.c_guarantor_demos_v AS GUAR
ON VST.pt_id = GUAR.pt_id
-- ADD AUTHORIZATION NUMBER '5C49AUTH'
LEFT JOIN SMSMIR.MIR_PYR_PLAN_USER AS PYR_USER
ON PYRPLAN.PT_ID = PYR_USER.PT_ID
       AND PYRPLAN.pyr_cd = PYR_USER.pyr_cd
       AND PYRPLAN.from_file_ind = PYR_USER.from_file_ind
       AND PYR_USER.user_comp_id = '5C49AUTH'
-- ADD INS1 FROM MIR_PYR_PLAN_USER '5C49IDNO'
LEFT JOIN smsmir.mir_pyr_plan_user AS INS1
ON PYRPLAN.pt_id = INS1.pt_id
       AND PYRPLAN.pyr_cd = INS1.pyr_cd
       AND PYRPLAN.from_file_ind = INS1.from_file_ind
       AND INS1.user_comp_id = '5C49IDNO'
       AND PYRPLAN.pyr_seq_no = '1'
-- ADD INS2 FROM MIR_PYR_PLAN_USER '5C49IDNO'
LEFT JOIN smsmir.mir_pyr_plan_user AS INS2
ON PYRPLAN.pt_id = INS2.pt_id
       AND PYRPLAN.pyr_cd = INS2.pyr_cd
       AND PYRPLAN.from_file_ind = INS2.from_file_ind
       AND INS2.user_comp_id = '5C49IDNO'
       AND PYRPLAN.pyr_seq_no = '2'
-- ADD INS3 FROM MIR_PYR_PLAN_USER '5C49IDNO'
LEFT JOIN smsmir.mir_pyr_plan_user AS INS3
ON PYRPLAN.pt_id = INS3.pt_id
       AND PYRPLAN.pyr_cd = INS3.pyr_cd
       AND PYRPLAN.from_file_ind = INS3.from_file_ind
       AND INS3.user_comp_id = '5C49IDNO'
       AND PYRPLAN.pyr_seq_no = '3'
-- ADD INS4 FROM MIR_PYR_PLAN_USER '5C49IDNO'
LEFT JOIN smsmir.mir_pyr_plan_user AS INS4
ON PYRPLAN.pt_id = INS4.pt_id
       AND PYRPLAN.pyr_cd = INS4.pyr_cd
       AND PYRPLAN.from_file_ind = INS4.from_file_ind
       AND INS4.user_comp_id = '5C49IDNO'
       AND PYRPLAN.pyr_seq_no = '4'
-- Add INS1 Name
LEFT JOIN SMSMIR.mir_pyr_plan_user AS INS_NAME
ON PYRPLAN.PT_ID = INS_NAME.PT_ID
       AND PYRPLAN.pyr_cd = INS_NAME.pyr_cd
       AND PYRPLAN.from_file_ind = INS_NAME.from_file_ind
       AND INS_NAME.user_comp_id = '5C49NAME'
       AND PYRPLAN.pyr_seq_no = '1'
       AND INS_NAME.pyr_seq_no = '1'

WHERE VST.vst_end_date IS NOT NULL
AND PYRPLAN.PYR_CD IN (
	'I01','I04','I06','I07','I08','I10'
)
AND LEFT(PYRPLAN.pt_id, 5) != '00007'
AND PYRPLAN.pyr_seq_no = 1
AND VST.tot_bal_amt > 0
AND PYRPLAN.tot_amt_due > 0
AND VST.ins_pay_amt = 0
AND PYRPLAN.pt_id NOT IN (
	SELECT DISTINCT(pt_id)
	FROM smsmir.pay
	WHERE pay_cd IN (
		'09701509',
		'09701558',
		'09701608',
		'09730078',
		'09735077',
		'09731084',
              '09770116'
	)
)
AND SUBSTRING(PYRPLAN.PT_ID, 5, 1) != '1'
AND PYRPLAN.last_bl_dtime IS NOT NULL
AND PYRPLAN.pyr_seq_no = 1
AND VST.pt_bal_amt >= 0
AND VST.prin_dx_cd IS NOT NULL

ORDER BY PYRPLAN.pt_id

GO
;
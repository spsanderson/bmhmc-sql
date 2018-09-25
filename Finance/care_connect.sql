SELECT PYRPLAN.pt_id
, VST.vst_start_date as [Admit_Date]
, VST.vst_end_date as [Discharge_Date]
, VST.fc
, VST.hosp_svc
, DATEDIFF(DD, VST.VST_END_DATE, GETDATE()) AS 'AGE IN DAYS'
, PYRPLAN.pyr_cd
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
, CLAIM.PAY_DESC AS [CLAIM#]
, CLAIM.pay_entry_dtime
, (
       select SUM(net_pay_amt)
       from smsmir.mir_vst_apc as apc
       where PYRPLAN.pt_id = apc.pt_id
       and PYRPLAN.unit_seq_no = apc.unit_seq_no
) AS [APC_Est_Net_Pay_Amt]

INTO #TEMPA

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
-- Add Claim Number comment code 10501435
LEFT JOIN SMSMIR.PAY AS CLAIM
ON PYRPLAN.PT_ID = CLAIM.PT_ID
       AND PYRPLAN.FROM_FILE_IND = CLAIM.FROM_FILE_IND
       AND PYRPLAN.PYR_CD = CLAIM.PYR_CD
       AND CLAIM.PAY_CD = '10501435'

--WHERE VST.vst_end_date IS NOT NULL
WHERE PYRPLAN.PYR_CD IN ('E39')
--and PYRPLAN.PYR_CD IN ('K21','K72','K22')
AND VST.tot_bal_amt > 0
AND PYRPLAN.tot_amt_due > 0

ORDER BY PYRPLAN.pt_id
;

SELECT A.pt_id
, A.Admit_Date
, A.Discharge_Date
, A.fc
, A.hosp_svc
, A.[AGE IN DAYS]
, A.pyr_cd
, A.tot_chg_amt
, A.tot_bal_amt
, A.ins_pay_amt
, A.pt_bal_amt
, A.INS_BAL_AMT
, A.tot_pay_amt
, A.PT_PAY_AMT
, A.GuarantorDOB
, A.GuarantorFirst
, A.GuarantorLast
, A.pt_first_name
, A.pt_last_name
, A.Ins1
, A.Ins1_Name
, A.Ins2
, A.Ins3
, A.Ins4
, A.drg_no
, A.Auth
, A.CLAIM#
, A.APC_Est_Net_Pay_Amt
, [RN] = ROW_NUMBER() OVER(
	PARTITION BY A.PT_ID
	ORDER BY A.pay_entry_dtime DESC
)

INTO #TEMPB

FROM #TEMPA AS A
;

SELECT A.pt_id
, A.Admit_Date
, A.Discharge_Date
, A.fc
, A.hosp_svc
, A.[AGE IN DAYS]
, A.pyr_cd
, A.tot_chg_amt
, A.tot_bal_amt
, A.ins_pay_amt
, A.pt_bal_amt
, A.INS_BAL_AMT
, A.tot_pay_amt
, A.PT_PAY_AMT
, A.GuarantorDOB
, A.GuarantorFirst
, A.GuarantorLast
, A.pt_first_name
, A.pt_last_name
, A.Ins1
, A.Ins1_Name
, A.Ins2
, A.Ins3
, A.Ins4
, A.drg_no
, A.Auth
, A.CLAIM#
, A.APC_Est_Net_Pay_Amt

FROM #TEMPB AS A

WHERE A.RN = 1
;

DROP TABLE #TEMPA
DROP TABLE #TEMPB
;
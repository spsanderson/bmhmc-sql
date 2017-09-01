SELECT PYRPLAN.pt_id
, VST.vst_end_date
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
, vst.ins1_pol_no
, vst.ins2_pol_no
, vst.ins3_pol_no
, vst.ins4_pol_no

FROM SMSMIR.PYR_PLAN AS PYRPLAN
LEFT JOIN smsmir.vst_rpt VST
ON PYRPLAN.pt_id = VST.pt_id
	AND PYRPLAN.unit_seq_no = VST.unit_seq_no
LEFT JOIN smsdss.c_guarantor_demos_v AS GUAR
ON VST.pt_id = GUAR.pt_id

WHERE VST.prim_pyr_cd = 'J18'
AND VST.vst_end_date IS NOT NULL
AND PYRPLAN.PYR_CD = 'J18'
AND VST.tot_bal_amt > 0
;
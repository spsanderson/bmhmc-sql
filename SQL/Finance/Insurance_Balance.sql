SELECT PYRPLAN.pt_id
, VST.unit_seq_no
, VST.cr_rating
, CAST(VST.vst_end_date AS date)                     AS [vst_end_date]
, VST.fc
, VST.hosp_svc
, CAST(DATEDIFF(DD, VST.VST_END_DATE, GETDATE()) AS int) AS [Age_In_Days]
, PYRPLAN.pyr_cd
, CAST(VST.tot_chg_amt AS money)                     AS [tot_chg_amt]
, CAST(VST.tot_bal_amt AS money)                     AS [tot_enc_bal_amt]
, CAST(VST.ins_pay_amt AS money)                     AS [ins_pay_amt]
, CAST(VST.pt_bal_amt AS money)                      AS [pt_bal_amt]
, CASE
	WHEN PYRPLAN.PYR_CD = '*' THEN 0
	ELSE CAST(PYRPLAN.tot_amt_due AS money)
  END                                                AS [Ins_Bal_Amt]
, CAST(VST.tot_pay_amt AS money) AS [tot_pay_amt]
, CAST((VST.tot_pay_amt - VST.ins_pay_amt) AS money) AS [pt_pay_amt]
, CAST(guar.GuarantorDOB as date)                    AS [GuarantorDOB]
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

WHERE VST.tot_bal_amt > 0
AND VST.vst_end_date IS NOT NULL
AND VST.fc not in (
	'1','2','3','4','5','6','7','8','9'
)

ORDER BY PYRPLAN.pt_id
, PYRPLAN.pyr_cd
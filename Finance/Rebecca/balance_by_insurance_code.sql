SELECT PYRPLAN.pt_id
, VST.unit_seq_no
, VST.cr_rating
, CAST(VST.vst_end_date AS date)                     AS [vst_end_date]
, VST.fc
, VST.hosp_svc
, CAST(DATEDIFF(DD, VST.VST_END_DATE, GETDATE()) AS int) AS [Age_In_Days]
, PYRPLAN.pyr_cd
, PYRPLAN.pyr_seq_no
, CAST(VST.tot_chg_amt AS money)                     AS [tot_chg_amt]
, CAST(VST.tot_bal_amt AS money)                     AS [tot_enc_bal_amt]
, CAST(VST.ins_pay_amt AS money)                     AS [ins_pay_amt]
, CAST(VST.pt_bal_amt AS money)                      AS [pt_bal_amt]
, PYRPLAN.tot_amt_due                                AS [Ins_Cd_Bal]
--, CASE
--	WHEN PYRPLAN.PYR_CD = '*' THEN 0
--	ELSE CAST(PYRPLAN.tot_amt_due AS money)
--	END                                              AS [Ins_Bal_Amt]
, CAST(VST.tot_pay_amt AS money)                     AS [tot_pay_amt]
, CAST((VST.tot_pay_amt - VST.ins_pay_amt) AS money) AS [pt_pay_amt]
, CAST(guar.GuarantorDOB as date)                    AS [GuarantorDOB]
, guar.GuarantorFirst
, guar.GuarantorLast
, vst.ins1_pol_no
, vst.ins2_pol_no
, vst.ins3_pol_no
, vst.ins4_pol_no
, [RunDate] = CAST(GETDATE() AS date)
, [RunDateTime] = GETDATE()
, [RN] = ROW_NUMBER() OVER(
	PARTITION BY PYRPLAN.PT_ID
	ORDER BY PYRPLAN.PYR_SEQ_NO
)

INTO #TEMPA

FROM SMSMIR.PYR_PLAN AS PYRPLAN
LEFT JOIN smsmir.vst_rpt VST
ON PYRPLAN.pt_id = VST.pt_id
LEFT JOIN smsdss.c_guarantor_demos_v AS GUAR
ON VST.pt_id = GUAR.pt_id
	AND VST.from_file_ind = GUAR.from_file_ind

WHERE VST.vst_end_date IS NOT NULL
AND VST.tot_bal_amt != 0
AND VST.fc not in (
	'1','2','3','4','5','6','7','8','9'
)
AND LEFT(VST.pt_id, 5) NOT IN ('00007', '00009')
AND LEFT(VST.PT_ID, 6) != '000009'

ORDER BY PYRPLAN.pt_id
, PYRPLAN.pyr_cd
;

SELECT a.pt_id
, a.RunDate
, a.pyr_cd
, pdv.pyr_cd_desc
, pdv.pyr_group2
, a.pyr_seq_no
, a.Ins_Cd_Bal
--, a.RN
--, case when a.rn = 1 then a.tot_enc_bal_amt else '' end as tot_enc_bal_amt

FROM #TEMPA as a
left outer join smsdss.pyr_dim_v as pdv
on a.pyr_cd = pdv.pyr_cd
	and pdv.orgz_cd = 's0x0'
ORDER BY a.pt_id, a.pyr_seq_no

--DROP TABLE #TEMPA
;

-- unitized
SELECT PYRPLAN.pt_id
, VST.unit_seq_no
, VST.cr_rating
, CAST(VST.vst_end_date AS date)                     AS [vst_end_date]
, VST.fc
, VST.hosp_svc
, CAST(DATEDIFF(DD, VST.VST_END_DATE, GETDATE()) AS int) AS [Age_In_Days]
, PYRPLAN.pyr_cd
, PYRPLAN.pyr_seq_no
, CAST(VST.tot_chg_amt AS money)                     AS [tot_chg_amt]
, CAST(VST.tot_bal_amt AS money)                     AS [tot_enc_bal_amt]
, CAST(VST.ins_pay_amt AS money)                     AS [ins_pay_amt]
, CAST(VST.pt_bal_amt AS money)                      AS [pt_bal_amt]
, PYRPLAN.tot_amt_due                                AS [Ins_Cd_Bal]
, CAST(VST.tot_pay_amt AS money)                     AS [tot_pay_amt]
, CAST((VST.tot_pay_amt - VST.ins_pay_amt) AS money) AS [pt_pay_amt]
, CAST(guar.GuarantorDOB as date)                    AS [GuarantorDOB]
, guar.GuarantorFirst
, guar.GuarantorLast
, vst.ins1_pol_no
, vst.ins2_pol_no
, vst.ins3_pol_no
, vst.ins4_pol_no
, [RunDate] = CAST(GETDATE() AS date)
, [RunDateTime] = GETDATE()
, [RN] = ROW_NUMBER() OVER(
	PARTITION BY PYRPLAN.PT_ID
	ORDER BY PYRPLAN.PYR_SEQ_NO
)

--INTO #TEMPA
--DROP TABLE #TEMPA

FROM SMSMIR.PYR_PLAN AS PYRPLAN
LEFT JOIN smsmir.vst_rpt VST
ON PYRPLAN.pt_id = VST.pt_id
LEFT JOIN smsdss.c_guarantor_demos_v AS GUAR
ON VST.pt_id = GUAR.pt_id
	AND VST.from_file_ind = GUAR.from_file_ind

WHERE VST.unit_seq_no = '99999999'
AND LEFT(VST.PT_ID, 5) = '00007'
--AND VST.vst_end_date IS NOT NULL
--AND VST.tot_bal_amt != 0

ORDER BY PYRPLAN.pt_id
, PYRPLAN.pyr_cd
;

SELECT a.pt_id
, A.unit_seq_no
, a.RunDate
, a.pyr_cd
, pdv.pyr_cd_desc
, pdv.pyr_group2
, a.pyr_seq_no
, a.Ins_Cd_Bal
--, a.RN
--, case when a.rn = 1 then a.tot_enc_bal_amt else '' end as tot_enc_bal_amt

FROM #TEMPA as a
left outer join smsdss.pyr_dim_v as pdv
on a.pyr_cd = pdv.pyr_cd
	and pdv.orgz_cd = 's0x0'

ORDER BY a.pt_id, a.pyr_seq_no


select pt_id
, sum(tot_bal_amt)

from smsmir.vst_rpt

where pt_id = '000070041157'
and vst_end_date IS NOT NULL
and tot_bal_amt != 0
or (
	unit_seq_no = '99999999'
	and pt_id = '000070041157'
	--and tot_bal_amt != 0
	--and vst_end_date null
)
group by pt_id
;

SELECT pt_id
, unit_seq_no
, pt_id_start_dtime
, *
FROM SMSMIR.pyr_plan
WHERE PT_ID = '000070041157'
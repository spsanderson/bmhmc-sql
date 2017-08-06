SELECT DISTINCT(acct.pt_id)
, isnull(acct.dsch_dtime,acct.adm_dtime) as 'Vst_End_Dtime'
, acct.fc
, acct.hosp_svc
, DATEDIFF(dd,isnull(acct.dsch_dtime,acct.adm_Dtime),getdate()) as 'Age'
, acct.prim_pyr_cd
, acct.tot_chg_amt
, acct.tot_bal_amt
, acct.ins_pay_amt
, acct.pt_bal_amt
, (acct.tot_bal_amt - acct.pt_bal_amt) as 'Ins_Bal_Amt'
, acct.tot_pay_amt
, (acct.tot_pay_amt - acct.ins_pay_amt) as 'Pt_Pay_Amt'
, guar.GuarantorDOB
, guar.GuarantorFirst
, guar.GuarantorLast
, vst.ins1_pol_no
, vst.ins2_pol_no
, vst.ins3_pol_no
, vst.ins4_pol_no

FROM smsmir.mir_Acct as acct
left join smsdss.c_guarantor_demos_v as guar
on acct.pt_id = guar.pt_id
left join smsmir.vst_rpt as vst
on acct.pt_id = vst.pt_id
	and acct.prim_pyr_cd = vst.prim_pyr_cd

WHERE acct.tot_Bal_amt > '0'
AND acct.prim_pyr_cd = 'J18'
AND acct.dsch_dtime >= '2014-01-01 00:00:00.000'
AND acct.dsch_dtime < '2017-06-04 00:00:00.000'
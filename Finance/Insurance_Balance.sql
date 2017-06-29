SELECT DISTINCT(pt_id)
, isnull(dsch_dtime,adm_dtime) as 'Vst_End_Dtime'
, fc
, hosp_svc
, DATEDIFF(dd,isnull(dsch_dtime,adm_Dtime),getdate()) as 'Age'
, prim_pyr_cd
, tot_chg_amt
, tot_bal_amt
, ins_pay_amt
, pt_bal_amt
, (tot_bal_amt - pt_bal_amt) as 'Ins_Bal_Amt'
, tot_pay_amt
, (tot_pay_amt - ins_pay_amt) as 'Pt_Pay_Amt'

FROM smsmir.mir_Acct

WHERE tot_Bal_amt > '0'
AND prim_pyr_Cd in (
	''
)
AND dsch_dtime >= '2015-01-01 00:00:00.000'
AND dsch_Dtime < '2017-06-04 00:00:00.000'
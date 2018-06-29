select a.pt_id,
a.proc_cd,
a.proc_eff_Dtime,
b.tot_chg_amt,
b.tot_pay_amt,
b.tot_amt_Due




from smsmir.mir_sproc a left outer join smsdss.BMH_PLM_PtAcct_V b
ON a.pt_id=b.pt_no


where resp_pty_cd IN ('015487','017152')
and proc_eff_dtime BETWEEN '01/01/2018' AND '04/30/2018'
--and pt_id IN ('000030468383','000030466775','000061646022','000030468185')
and (((a.proc_cd BETWEEN '33200' AND '33284') OR (a.proc_cd BETWEEN '93600' AND '93662') OR (a.proc_cd IN ('95924')))
AND proc_cd_prio='01')

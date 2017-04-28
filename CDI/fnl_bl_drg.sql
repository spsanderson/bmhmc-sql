select DATEPART(month, c.fnl_bl_dtime) as [Discharge Month Number]
, COUNT(DISTINCT(a.pt_id)) as [Patient Count]

from smsmir.pyr_plan as a
left join smsdss.BMH_PLM_PtAcct_V as b
on a.pt_id = b.Pt_No
	and a.unit_seq_no = b.unit_seq_no
left join smsmir.acct as c
on a.pt_id = c.pt_id
	and a.unit_seq_no = c.unit_seq_no

where a.bl_drg_schm like 'mc%'
and b.tot_chg_amt > 0
and b.plm_pt_acct_type = 'i'
--and left(b.ptno_num, 4) != '1999'
and b.ptno_num < '20000000'
and a.pyr_seq_no = 1
and b.hosp_svc != 'psy'
and c.fnl_bl_dtime >= '2017-01-01'
and c.fnl_bl_dtime < '2017-04-01'
and b.User_Pyr1_Cat in (
	'aaa'
)
and b.Days_Stay > 2
and b.drg_no is not null

group by DATEPART(month, c.fnl_bl_dtime);
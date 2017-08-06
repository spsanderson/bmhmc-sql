/*
Get the balance of an account per insurance plan loaded on the account
*/
select a.pt_id
, a.unit_seq_no
, a.from_file_ind
, a.pyr_cd
, a.pyr_seq_no
, a.tot_amt_due
, a.tot_pay_amt
, a.last_bl_amt
, cast(a.last_bl_date as date) as last_bl_date
, a.last_pay_amt
, cast(a.last_pay_date as date) as last_pay_date
, a.pol_no
, a.subscr_id
, a.subscr_ins_grp_id
, a.subscr_ins_grp_name
, b.ins_pay_amt
, b.pt_bal_amt
, c.ins1_pol_no
, d.ins2_pol_no
, e.ins3_pol_no
, f.ins4_pol_no

from smsmir.pyr_plan as a
left join smsmir.acct as b
on a.pt_id = b.pt_id
	and a.unit_seq_no = b.unit_seq_no
-- get prim ins data
left join smsmir.vst_rpt as c
on a.pt_id = c.pt_id
	and a.unit_seq_no = c.unit_seq_no
	and a.pyr_cd = c.prim_pyr_cd
-- get second ins data
left join smsmir.vst_rpt as d
on a.pt_id = d.pt_id
	and a.unit_seq_no = d.unit_seq_no
	and a.pyr_cd = d.pyr2_cd
-- get third ins data
left join smsmir.vst_rpt as e
on a.pt_id = e.pt_id
	and a.unit_seq_no = e.unit_seq_no
	and a.pyr_cd = e.pyr3_cd
-- get fourth ins data
left join smsmir.vst_rpt as f
on a.pt_id = f.pt_id
	and a.unit_seq_no = f.unit_seq_no
	and a.pyr_cd = f.pyr4_cd

where a.pt_id in (
'000014478671',
'000014483721', 
'000014484679',
'000014492524',
'000014495238',
'000014495881',
'000014498018',
'000014498190',
'000014499115',
'000014499495'
)
and a.pyr_seq_no != 0
;
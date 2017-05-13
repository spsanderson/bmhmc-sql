SELECT a.pt_no
, a.Plm_Pt_Acct_Type
, a.pt_name
, a.Adm_Date
, a.Dsch_Date
, a.User_Pyr1_Cat
, a.Pyr1_Co_Plan_Cd
, a.atn_dr_no
, b.pract_rpt_name
, b.src_sys_id
, c.tot_pymts_w_pip
, d.proc_cd
, e.clasf_desc
, d.proc_cd_prio
, d.proc_cd_Schm
, d.proc_cd_type

FROM smsdss.BMH_PLM_PtAcct_V  as a 
left outer join smsmir.mir_pract_mstr as b
ON a.Atn_Dr_No = b.pract_no 
	and b.src_sys_id = '#PASS0X0'
left outer join smsdss.c_tot_pymts_w_pip_v as c
ON a.Pt_No = c.pt_id 
	and a.unit_seq_no = c.unit_seq_no
left outer join smsmir.mir_sproc as d
ON a.Pt_No = d.pt_id 
	and d.proc_cd_prio = '01'
left outer join smsmir.mir_clasf_mstr as e
ON d.proc_cd = e.clasf_cd 
	and d.proc_cd_schm = e.clasf_schm 
	and proc_cd_schm <> '!'

WHERE d.proc_cd_schm <> '!'
AND a.Pt_No IN (
	SELECT DISTINCT(pt_id)
	--pract_no,
	--pract_rpt_name,
	--spclty_cd1
	
	from smsmir.mir_sproc as a 
	left outer join smsmir.mir_pract_mstr as b 
	ON a.resp_pty_cd = b.pract_no

	where a.proc_eff_dtime BETWEEN '2016-01-01 00:00:00.000' AND '2016-12-31 23:59:59.000'
	and b.spclty_cd1 = 'ORTSG'
	and a.proc_cd_schm <> '!'
)

order by a.pt_no
;
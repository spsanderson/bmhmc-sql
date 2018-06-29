
SELECT a.user_pyr1_cat,
a.pt_no,
a.days_stay,
a.pyr1_co_plan_cd,
b.bl_drg_schm,
c.lihn_service_line,
e.dx_cd as 'Admit_Dx',
f.clasf_desc as 'Dx_Desc',
g.proc_cd as 'Prin_Proc',
h.clasf_desc as 'Prin_Proc_Desc',
SUM(tot_chg_amt) as 'Tot_Chgs',
SUM(d.tot_pymts_w_pip) as 'Tot_Pymts',
SUM(a.tot_amt_due) as 'Tot_Balance',
COUNT(DISTINCT(a.pt_no)),
SUM(b.bl_drg_cost_weight)





FROM smsdss.bmh_plm_ptacct_v as a LEFT OUTER JOIN smsmir.mir_pyr_plan as b
ON a.pt_no=b.pt_id AND a.pt_id_Start_Dtime=b.pt_id_start_dtime AND a.Pyr1_Co_Plan_Cd=b.pyr_cd
LEFT OUTER JOIN smsdss.c_LIHN_Svc_Lines_Rpt2_v as c
ON a.Pt_No=c.pt_id
LEFT OUTER JOIN smsdss.c_tot_pymts_w_pip_v as d
On a.Pt_No=d.pt_id AND a.unit_seq_no=d.unit_seq_no 
LEFT OUTER JOIN smsmir.mir_dx_grp as e
ON a.Pt_No=e.pt_id AND e.dx_cd_type='DA'
LEFT OUTER JOIN smsmir.mir_clasf_mstr as f
ON e.dx_cd=LTRIM(RTRIM(f.clasf_cd))
LEFT OUTER JOIN smsmir.mir_sproc as g
On a.Pt_No=g.pt_id AND g.proc_cd_prio='01' AND g.proc_cd_type='PC'
LEFT OUTER JOIN smsmir.mir_clasf_mstr as h
ON g.proc_cd=h.clasf_cd


WHERE a.plm_pt_acct_type = 'I'
AND a.tot_chg_amt > '0'
AND a.pt_no IN

(
SELECT DISTINCT(pt_id)
FROM smsmir.mir_actv
WHERE LEFT(actv_cd,3)='070'
AND actv_dtime BETWEEN '01/01/2018' AND '04/30/2018'
)

GROUP BY a.user_pyr1_cat,
a.pt_no,
a.days_stay,
a.pyr1_co_plan_cd,
b.bl_drg_Schm,
c.lihn_service_line,
e.dx_cd,
f.clasf_Desc,
g.proc_cd,
h.clasf_desc

ORDER BY pt_no

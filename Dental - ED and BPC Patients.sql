select a.pt_id
, c.adm_date
, c.hosp_Svc
, c.user_pyr1_cat
, a.dx_cd_prio
, a.dx_cd_type
, a.dx_cd
, b.clasf_desc
, c.prin_hcpc_proc_cd
, d.clasf_desc
, c.prin_dx_icd10_cd
, e.clasf_Desc

from smsmir.mir_dx_grp as a 
left outer join smsmir.mir_clasf_mstr as b
ON a.dx_cd = b.clasf_cd
left outer join smsdss.bmh_plm_ptacct_v as c
ON a.pt_id = c.pt_no 
left outer join smsmir.mir_clasf_mstr as d
ON c.prin_hcpc_proc_cd = d.clasf_cd
left outer join smsmir.mir_clasf_mstr as e
ON c.prin_dx_icd10_cd = e.clasf_cd

where (dx_cd BETWEEN 'K00.0' AND 'K08.9'
OR LEFT(dx_cd,5)='S02.5')
AND vst_type_cd = 'O'
and dx_cd_type = 'DF'
AND dx_eff_Dtime BETWEEN '2016-01-01 00:00:00.000' AND '2016-12-31 23:59:59.000'
AND hosp_svc IN ('EME','EPC','BPC')

order by pt_id, dx_cd_prio,dx_cd

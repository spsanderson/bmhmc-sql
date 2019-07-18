SELECT a.pt_id,
b.rpt_name,
b.vst_med_rec_no,
a.vst_type_cd,
a.actv_full_date as 'Svc_Date',
d.adm_full_date as 'Admit_Date',
d.dsch_full_date as 'Dsch_Date',
a.actv_cd,
a.actv_name,
a.actv_group,
a.actv_tot_qty,
a.chg_tot_amt,
b.pyr_cd,
b.pyr_name,
b.pyr_group,
b.tot_chg_amt,
(
SELECT d.clasf_cd
FROM smsmir.actv_proc_seg_xref as d
WHERE d.proc_pyr_ind='H'
AND a.actv_cd=d.actv_cd
) as 'Proc_Cd',
(
SELECT d.rev_Cd
FROM smsmir.mir_actv_proc_seg_xref as d
WHERE d.proc_pyr_ind='A'
AND a.actv_cd=d.actv_cd
) as 'Rev_Cd',
(
SELECT e.clasf_Cd
FROM smsmir.mir_actv_proc_seg_xref as e
WHERE e.proc_pyr_ind='1'
AND a.actv_cd=e.actv_cd
) as 'Dose_Conv1',
(
SELECT f.clasf_Cd
FROM smsmir.mir_actv_proc_seg_xref as f
WHERE f.proc_pyr_ind='2'
AND a.actv_cd=f.actv_cd
) as 'Dose_Conv2'


FROM smsdss.actv_v as a LEFT JOIN smsdss.vst_v as b
ON a.vst_key = b.vst_key and a.src_sys_id=b.src_sys_id
LEFT JOIN smsdss.acct_v as d
ON a.pt_id=d.pt_id AND a.pt_key=d.pt_key

--WHERE ((b.vst_type_cd ='I' AND d.dsch_full_date >= (DATEADD(month,-month(sysdatetime())-60,(DATEADD(month,DATEDIFF(month,0,sysdatetime()),0) )) )--start of prior yr
--OR (b.vst_type_cd='O' AND d.adm_full_date >= (DATEADD(month,-month(sysdatetime())-60,(DATEADD(month,DATEDIFF(month,0,sysdatetime()),0) )) )))--start of prior yr
--AND a.chg_tot_amt <> 0)


where b.pt_id = ''

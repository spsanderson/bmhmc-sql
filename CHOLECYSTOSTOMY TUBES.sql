SELECT A.pt_id,
C.rpt_name,
C.med_rec_no,
C.birth_dtime,
A.proc_cd,
B.clasf_desc,
A.proc_eff_dtime,
A.resp_pty_cd,
D.pract_rpt_name,
E.prim_pyr_cd,
F.pyr_name

FROM smsmir.mir_sproc                 A 
LEFT OUTER JOIN smsmir.mir_clasf_mstr B
ON A.proc_cd = B.clasf_cd
LEFT OUTER JOIN smsmir.mir_pt         C
ON A.pt_id = C.pt_id 
LEFT OUTER JOIN smsmir.mir_pract_mstr D
ON A.resp_pty_cd = D.pract_no 
	AND A.src_sys_id = D.src_Sys_id
LEFT OUTER JOIN smsmir.mir_acct       E
ON A.pt_id = E.pt_id 
	AND A.unit_seq_no = E.unit_Seq_no
LEFT OUTER JOIN smsmir.mir_pyr_mstr   F
ON E.prim_pyr_cd = F.pyr_cd

WHERE A.proc_cd='51.01'
AND A.pt_id BETWEEN '000010000000' AND '000099999999'

ORDER BY A.proc_eff_dtime ASC
SELECT A.pt_id
, B.vst_end_dtime
, A.drg_no
, B.dsch_disp

FROM smsmir.mir_drg            A
LEFT OUTER JOIN smsmir.mir_vst B
ON a.pt_id=b.pt_id 

WHERE drg_type='3'

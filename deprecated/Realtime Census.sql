DECLARE @sd DATE;
DECLARE @ed DATE;

SET @sd = CAST(GETDATE() AS DATE);
SET @ed = CAST(GETDATE() + 1 AS DATE);

SELECT a.id_col
, a.pt_id
, a.msg_dtime
, a.evnt_dtime
, a.msg_type
, a.appl_from
, a.msg_cntrl_id
, c.last_msg_cntrl_id
, a.evnt_type_cd
, b.[Description]
, c.pt_class
, c.asgn_pt_loc
, c.nurse_sta
, c.bed
, c.adm_type
, c.atn_pract_no
, c.hosp_svc
, c.adm_pract_no
, c.pt_type
, c.fc
, c.pt_sts_cd
, c.pt_wt
, c.pt_ht

FROM smsmir.mir_hl7_msg_hdr                        AS a
LEFT OUTER JOIN smsdss.c_hl7_adt_translation_table AS b
ON a.evnt_type_cd = b.[HL7_Event]
LEFT OUTER JOIN smsmir.mir_hl7_vst                 AS c
ON a.msg_cntrl_id = c.last_msg_cntrl_id

WHERE a.evnt_dtime >= @SD
AND A.evnt_dtime < @ED
AND c.last_msg_cntrl_id IS NOT NULL
AND c.pt_class = 'I'

ORDER BY a.pt_id
, a.id_col

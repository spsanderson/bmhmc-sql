SELECT mir_vst.vst_end_dtime
, mir_pyr_plan.pyr_cd
, mir_pyr_plan.bl_drg_cost_weight
, mir_pyr_plan.pt_id
, mir_vst.len_of_stay
, mir_pyr_plan.bl_drg_no
, mir_vst.pt_type
, mir_pract_mstr.pract_rpt_name
, mir_vst.hosp_svc
, pyr_dim_v.pyr_group2
, mir_vst.prim_pract_no
, mir_pyr_plan.pyr_seq_no
, mir_vst.vst_end_date
, mir_pyr_plan.bl_drg_schm
, mir_vst.vst_type_cd
, mir_vst.tot_chg_amt

FROM (
	(
		SMSPHDSSS0X0.smsmir.mir_pyr_plan mir_pyr_plan
		LEFT OUTER JOIN SMSPHDSSS0X0.smsmir.mir_vst_rpt mir_vst 
		ON mir_pyr_plan.pt_id = mir_vst.pt_id
			AND mir_pyr_plan.pt_id_start_dtime = mir_vst.pt_id_start_dtime
	)
	LEFT OUTER JOIN SMSPHDSSS0X0.smsdss.pyr_dim_v pyr_dim_v 
	ON mir_pyr_plan.pyr_cd = pyr_dim_v.pyr_cd
	AND mir_pyr_plan.src_sys_id = pyr_dim_v.src_sys_id
) 
LEFT OUTER JOIN SMSPHDSSS0X0.smsmir.mir_pract_mstr mir_pract_mstr 
ON mir_vst.src_sys_id = mir_pract_mstr.src_sys_id
	AND mir_vst.prim_pract_no = mir_pract_mstr.pract_no
	
WHERE mir_pyr_plan.pyr_seq_no=1 
AND mir_vst.hosp_svc not in ('epy', 'psy')
AND mir_vst.vst_end_dtime >= '2017-06-01 00:00:00' 
AND mir_vst.vst_end_dtime < '2017-11-01 00:00:00' 
AND mir_vst.vst_type_cd = 'I'
AND mir_vst.tot_chg_amt <> 0

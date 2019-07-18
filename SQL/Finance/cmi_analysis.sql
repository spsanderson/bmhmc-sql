SELECT mir_pyr_plan.pt_id
, mir_vst.vst_end_dtime
, datepart(year, mir_vst.vst_end_dtime) as [Dsch_Yr]
, datepart(month, mir_vst.vst_end_dtime) as [Dsch_Mo]
, DATEPART(HOUR, MIR_VST.VST_END_DTIME) AS [Dsch_Hr]
, mir_pyr_plan.pyr_cd
, CASE
	WHEN mir_pyr_plan.pyr_cd IS NULL
		THEN 'MIS'
		ELSE LEFT(MIR_PYR_PLAN.PYR_CD, 1) +
			 LEFT(MIR_PYR_PLAN.PYR_CD, 1) +
			 LEFT(MIR_PYR_PLAN.PYR_CD, 1)
  END AS [User_Pyr_Cat]				
, pyr_dim_v.pyr_group2
, mir_pyr_plan.bl_drg_cost_weight
, mir_vst.len_of_stay
, mir_pyr_plan.bl_drg_no
, mir_pyr_plan.bl_drg_schm
, CASE
	WHEN DRG.drg_complic_group = '?'
		THEN 0
		ELSE 1
  END AS [DRG_w_Comp]
, DRG.MDCDescText
, DRG.std_drg_name_modf
, DRG.drg_med_surg_group
, mir_pyr_plan.bl_drg_outl_ind
, CASE
	WHEN mir_pyr_plan.bl_drg_outl_ind = 'E'
		THEN 'Expense (Cost) Outlier'
	WHEN mir_pyr_plan.bl_drg_outl_ind = 'H'
		THEN 'Length of Stay Greater Than High-trim Outlier'
	WHEN mir_pyr_plan.bl_drg_outl_ind = 'L'
		THEN 'Length of Stay Less Than Low-trim Outlier'
	WHEN mir_pyr_plan.bl_drg_outl_ind = 'T'
		THEN 'Transfer to or from Acute Care Facility Outlier'
  END AS [DRG_outl_ind_desc]
, mir_vst.pt_type
, mir_pract_mstr.pract_no
, mir_pract_mstr.pract_rpt_name
, case
	when mir_pract_mstr.spclty_cd1 = 'HOSIM'
		then 1
		else 0
  end as [Hosp_Flag]
, mir_vst.hosp_svc
, mir_vst.prim_pract_no
, mir_pyr_plan.pyr_seq_no
, mir_vst.vst_type_cd
, mir_vst.tot_chg_amt
, 1 as [Enc_Flag]

FROM SMSPHDSSS0X0.smsmir.mir_pyr_plan as mir_pyr_plan
LEFT OUTER JOIN SMSPHDSSS0X0.smsmir.mir_vst_rpt as mir_vst 
ON mir_pyr_plan.pt_id = mir_vst.pt_id
	AND mir_pyr_plan.pt_id_start_dtime = mir_vst.pt_id_start_dtime
LEFT OUTER JOIN SMSPHDSSS0X0.smsdss.pyr_dim_v as pyr_dim_v 
ON mir_pyr_plan.pyr_cd = pyr_dim_v.pyr_cd
	AND mir_pyr_plan.src_sys_id = pyr_dim_v.src_sys_id
LEFT OUTER JOIN SMSPHDSSS0X0.smsmir.mir_pract_mstr as mir_pract_mstr 
ON mir_vst.src_sys_id = mir_pract_mstr.src_sys_id
	AND mir_vst.prim_pract_no = mir_pract_mstr.pract_no
LEFT OUTER JOIN SMSPHDSSS0X0.SMSDSS.DRG_DIM_V AS DRG
ON MIR_PYR_PLAN.BL_DRG_NO = DRG.DRG_NO
	AND DRG.DRG_VERS = 'MS-V25'
	
WHERE mir_pyr_plan.pyr_seq_no = 1 
AND mir_vst.hosp_svc not in ('epy', 'psy')
AND (
	(
		mir_vst.vst_end_dtime >= '2017-01-01'
		AND 
		mir_vst.vst_end_dtime < '2017-11-01'
	)
	OR
	(
		mir_vst.vst_end_dtime >= '2016-01-01'
		AND
		mir_vst.vst_end_dtime < '2016-11-01'
	)
)
AND mir_vst.vst_type_cd = 'I'
AND mir_vst.tot_chg_amt <> 0
AND mir_pyr_plan.bl_drg_no <> 0
AND mir_pyr_plan.pyr_cd <> '*'
AND LEFT(mir_vst.pt_id, 8) != '00001999'
AND mir_pyr_plan.bl_drg_no NOT IN ( -- remove trachs as the cmi is very high and volume is low
	'3', '4', '11'
)
USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_soarian_real_time_census_CDI_v]    Script Date: 09/28/2016 12:38:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Script for SelectTopNRows command from SSMS  ******/
ALTER VIEW [smsdss].[c_soarian_real_time_census_CDI_v]

AS


SELECT a.pt_id AS pt_no_num
, CAST(('0000' + a.pt_id) AS varchar) AS 'pt_id'
, [pt_class]
, [asgn_pt_loc]
, [nurse_sta]
, [bed]
, [adm_type]
, a.[atn_pract_no]
, b.pract_rpt_name AS 'atn_dr_name'
, a.hosp_svc
, [adm_pract_no]
, [pt_type]
, a.[fc]
, [adm_dtime]
, DATEDIFF(dd,adm_dtime,getdate()) AS 'LOS' 
, [pt_sts_cd]
, d.ins_plan_no
, CASE
	WHEN g.bl_drg_schm LIKE '%MC%' THEN 'MS-DRG'
	WHEN g.bl_drg_schm LIKE '%ANY%' THEN 'APR-DRG'
	WHEN g.bl_drg_Schm LIKE 'NY%' THEN 'AP-DRG'
	ELSE ''
  END AS 'Case_Mix_Scheme'
-- ,g.bl_drg_schm
, f.pyr_name
-- ,d.ins_plan_prio_no
, e.pt_med_rec_no
, e.pt_last_name
, e.pt_first_name
, e.pt_gender
, xx.order_str_dtime
, xx.desc_as_written

FROM [SMSPHDSSS0X0].[smsmir].[mir_hl7_vst] AS a 
LEFT OUTER JOIN smsmir.mir_pract_mstr AS b
ON a.atn_pract_no = b.pract_no 
	AND b.src_sys_id='#PMSNTX0'
LEFT OUTER JOIN smsmir.mir_pract_mstr AS c
ON a.adm_pract_no = c.pract_no 
	AND c.src_sys_id='#PMSNTX0'
LEFT OUTER JOIN smsmir.mir_hl7_ins AS d
ON a.pt_id = d.pt_id 
	and ins_plan_prio_no='1' 
	and a.last_msg_cntrl_id = d.last_msg_cntrl_id
LEFT OUTER JOIN smsmir.mir_hl7_pt AS e
ON a.pt_id = e.pt_id 
LEFT OUTER JOIN smsmir.mir_pyr_mstr AS f
ON d.ins_plan_no = f.pyr_cd
LEFT OUTER JOIN smsdss.c_bl_drg_schm_by_pyr_cd_v AS g
ON d.ins_plan_no = g.pyr_cd 
	and g.d_rank='1'
LEFT OUTER JOIN smsdss.c_sr_orders_finance_rpt_v AS xx
ON a.pt_id = xx.episode_no 
	AND xx.svc_desc = 'Diagnosis' 
	AND xx.Order_Status <> 'Discontinue' 
	AND xx.ovrd_dup_ind <> '1'
	-- AND a.atn_pract_no = xx.pty_cd

WHERE asgn_pt_loc is not null
AND a.dsch_dtime IS NULL
AND pt_class = 'I' 
--AND nurse_sta <> 'PSY'
AND pt_sts_cd <> 'IP'
AND LEFT(a.pt_id, 1) IN ('1','2')

GROUP BY a.pt_id
, [pt_class]
, [asgn_pt_loc]
, [nurse_sta]
, [bed]
, [adm_type]
, a.[atn_pract_no]
, b.pract_rpt_name 
, a.hosp_svc
, [adm_pract_no]
, [pt_type]
, a.[fc]
, [adm_dtime]
, DATEDIFF(dd,adm_dtime,getdate()) 
, [pt_sts_cd]
, d.ins_plan_no
, g.bl_drg_schm
, f.pyr_name
--,d.ins_plan_prio_no
, e.pt_med_rec_no
, e.pt_last_name
, e.pt_first_name
, e.pt_gender
, xx.order_str_dtime
, xx.desc_as_written

--order by nurse_sta, bed

GO
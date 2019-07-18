USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_ins_user_fields_v]    Script Date: 2/1/2018 9:07:40 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [smsdss].[c_ins_user_fields_v]
AS

SELECT a.pt_id
, a.acct_no
, a.pt_id_start_dtime
, a.pyr_cd
, f.user_text as 'Ins_Name'
, b.user_text as 'Ins_Addr1'
, c.user_text as 'Ins_City'
, d.user_text as 'Ins_State'
, e.user_text as 'Ins_Zip'
, g.user_text as 'Ins_Tel_No'
, a.from_file_ind

FROM smsmir.mir_pyr_plan_user as a LEFT OUTER JOIN
smsmir.mir_pyr_plan_user as b 
ON a.pt_id = b.pt_id 
	and a.pt_id_start_dtime = b.pt_id_start_dtime 
	AND a.pyr_cd = b.pyr_cd 
	AND b.user_comp_id = '5C49ADD1'
LEFT OUTER JOIN smsmir.mir_pyr_plan_user as c 
ON a.pt_id = c.pt_id 
	and a.pt_id_start_dtime = c.pt_id_start_dtime 
	AND a.pyr_cd = c.pyr_cd 
	AND c.user_comp_id = '5C49ADD2'
LEFT OUTER JOIN smsmir.mir_pyr_plan_user as d 
ON a.pt_id = d.pt_id 
	and a.pt_id_start_dtime = d.pt_id_start_dtime 
	AND a.pyr_cd = d.pyr_cd 
	and d.user_comp_id = '5C49ADD3'
LEFT OUTER JOIN smsmir.mir_pyr_plan_user as e 
ON a.pt_id = e.pt_id 
	and a.pt_id_start_dtime = e.pt_id_start_dtime 
	AND a.pyr_cd = e.pyr_cd 
	and e.user_comp_id = '5C49ADD4'
LEFT OUTER JOIN smsmir.mir_pyr_plan_user as f 
ON a.pt_id = f.pt_id 
	and a.pt_id_start_dtime = f.pt_id_start_dtime 
	AND a.pyr_cd = f.pyr_cd 
	and f.user_comp_id = '5C49NAME'
LEFT OUTER JOIN smsmir.mir_pyr_plan_user as g 
ON a.pt_id = g.pt_id 
	and a.pt_id_start_dtime = g.pt_id_start_dtime 
	AND a.pyr_cd = g.pyr_cd 
	and g.user_comp_id = '5IS1ICTE'

GROUP BY a.pt_id
, a.acct_no
, a.pt_id_start_dtime
, a.pyr_cd
, b.user_text
, c.user_text
, d.user_text
, e.user_text
, f.user_text
, g.user_text
, a.from_file_ind

GO
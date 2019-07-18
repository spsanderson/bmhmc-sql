USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_hac_11_fy17_v]    Script Date: 11/23/2016 2:57:45 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER VIEW [smsdss].[c_hac_11_fy17_v]
AS

select a.pt_id
, a.ptno_num
, a.med_rec_no
, a.admit_date
, a.dsch_date
, a.proc_cd
, a.proc_cd_prio
, a.proc_cd_type
, a.proc_cd_schm
, a.hac
, a.hac_desc
, a.proc_short_desc
, b.dx_cd as [prin_dx]
, b.dx_cd_prio as [prin_dx_prio]
, b.dx_cd_type as [prin_dx_type]
, b.dx_cd_schm as [prin_dx_schm]
, b.dx_short_desc as [prin_dx_desc]
, c.dx_cd as [secondary_dx]
, c.dx_cd_prio as [secondary_dx_prio]
, c.dx_cd_type as [secondary_dx_type]
, c.dx_cd_schm as [secondary_dx_schm]
, c.dx_short_desc as [secondary_dx_desc]

from smsdss.c_hac_11_proc_fy17_v as a
inner join smsdss.c_hac_11_dx_prin_fy17_v as b
on a.pt_id = b.pt_id
inner join smsdss.c_hac_11_dx_secondary_fy17_v as c
on a.pt_id = c.pt_id



GO



USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_hac_13_fy17_v]    Script Date: 11/23/2016 2:37:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [smsdss].[c_hac_13_fy17_v]
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
, b.dx_cd
, b.dx_cd_prio
, b.dx_cd_type
, b.dx_cd_schm
, b.dx_short_desc

from smsdss.c_hac_13_proc_fy17_v as a
inner join smsdss.c_hac_13_dx_fy17_v as b
on a.pt_id = b.pt_id

GO



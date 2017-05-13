USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_Hemodialysis_v]    Script Date: 1/28/2016 1:23:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [smsdss].[c_Hemodialysis_v]
AS

SELECT a.pt_id
, CASE
	WHEN LEN(a.unit_seq_no) <> '1' 
		THEN a.unit_seq_no
  END AS [Unit No]
, a.actv_dtime
, a.actv_cd
, b.actv_name
, a.hosp_svc
, CASE
	WHEN hosp_svc NOT IN ('DMS','CAP','CCP','DIA')
		THEN 'Inpatient'
	WHEN hosp_svc = 'DMS' 
		THEN 'Dialysis Main St.'
	WHEN hosp_svc = 'DIA' 
		THEN 'OP Dialysis Hospital'
	WHEN hosp_svc IN ('CAP','CCP') 
		THEN 'CAPD-CCPD'
	ELSE ''
  END AS [Case Type]
, a.pt_type
, a.actv_tot_qty
, a.chg_tot_amt

FROM smsmir.mir_actv           AS A 
LEFT JOIN smsmir.mir_actv_mstr AS B
ON a.actv_cd=b.actv_cd

WHERE a.actv_cd = '05400023'
AND ACTV_DTIME >= '12/17/2011'
AND actv_dtime <= GETDATE()

GO
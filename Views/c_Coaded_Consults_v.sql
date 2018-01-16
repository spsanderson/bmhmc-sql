USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_Coaded_Consults_v]    Script Date: 1/12/2018 2:05:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [smsdss].[c_Coaded_Consults_v]
AS

SELECT B.Med_Rec_No
, A.Pt_No
, CAST(B.Adm_Date AS date) AS [Adm_Date]
, CAST(B.Dsch_Date AS date) AS [Dsch_Date]
, B.Days_Stay
, B.Atn_Dr_No
, ATN.PRACT_RPT_NAME AS [Attending_MD]
, CASE
	WHEN ATN.src_spclty_cd = 'HOSIM'
		THEN 'Hospitalist'
		ELSE 'Private'
  END AS [Attending_Flag]
, A.RespParty
, CONSULTANT.pract_rpt_name AS [CONSULTANT]
, CASE
	WHEN CONSULTANT.src_spclty_cd = 'HOSIM'
		THEN 'Hospitalist'
		ELSE CONSULTANT.spclty_desc
  END AS [Consultant_Spec]
, A.ClasfCd
, CAST(A.Clasf_Eff_Date AS date) AS [Consult_Date]

FROM smsdss.BMH_PLM_PtAcct_Clasf_Proc_V_New AS A
LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS B
ON A.Pt_No = B.Pt_No
	AND A.Pt_Key = B.Pt_Key
	AND A.Bl_Unit_Key = B.Bl_Unit_Key
LEFT OUTER JOIN smsdss.pract_dim_V AS ATN
ON B.Atn_Dr_No = ATN.src_pract_no
	AND B.Regn_Hosp = ATN.orgz_cd
LEFT OUTER JOIN smsdss.pract_dim_v AS CONSULTANT
ON A.RespParty = CONSULTANT.src_pract_no
	AND CONSULTANT.orgz_cd = B.Regn_Hosp

WHERE ClasfType = 'C'


GO



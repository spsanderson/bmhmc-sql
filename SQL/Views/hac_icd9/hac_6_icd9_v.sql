USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [smsdss].[c_hac_6_ICD9_v]
AS

SELECT A.pt_id
, C.PtNo_Num
, C.Med_Rec_No
, CAST(C.ADM_DATE AS DATE) as admit_date
, CAST(C.DSCH_DATE AS DATE) AS dsch_date
, A.dx_cd
, A.dx_cd_prio
, A.dx_cd_type
, A.dx_cd_schm
, 4 as hac_cd
, 'Catheter-Associated Urinary Tract Infection (UTI)' as hac_desc
, '' AS hac_sub_desc

FROM SMSMIR.dx_grp AS A
INNER MERGE JOIN SMSDSS.BMH_PLM_PTACCT_V AS C
ON A.PT_ID = C.Pt_No

WHERE A.dx_cd_type = 'DFN'
AND A.dx_cd_prio NOT IN ('1', '01')
AND C.Dsch_Date >= '2012-01-01'
AND C.Dsch_Date < '2016-01-01'
AND c.prin_dx_cd_schm = '9'
AND C.Plm_Pt_Acct_Type = 'I'
AND LEFT(C.PTNO_NUM, 4) != '1999'
AND C.tot_chg_amt > 0
AND A.dx_cd IN ('996.64')
AND A.dx_cd NOT IN (
	'112.2', '590.10', '590.11', '590.2', '590.3', '590.80', '590.81',
	'595.0', '597.0', '599.0'
)

GO
;
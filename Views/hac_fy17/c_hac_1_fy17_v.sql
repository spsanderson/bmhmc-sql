USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_hac_1_fy17_v]    Script Date: 11/23/2016 2:06:51 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




ALTER VIEW [smsdss].[c_hac_1_fy17_v]
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
, B.hac
, B.hac_desc
, B.dx_short_desc

FROM SMSMIR.dx_grp AS A
INNER MERGE JOIN SMSDSS.c_hac_1_secondary_dx_fy17 AS B
ON REPLACE(A.dx_cd, '.','') = B.dx_cd
INNER MERGE JOIN SMSDSS.BMH_PLM_PTACCT_V AS C
ON A.PT_ID = C.Pt_No

WHERE A.dx_cd_type = 'DFN'
AND A.dx_cd_prio NOT IN ('1', '01')
AND C.Dsch_Date >= '2016-01-01'
AND C.Plm_Pt_Acct_Type = 'I'
AND LEFT(C.PTNO_NUM, 4) != '1999'
AND C.tot_chg_amt > 0;


GO



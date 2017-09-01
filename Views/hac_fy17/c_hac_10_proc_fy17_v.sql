USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_hac_10_proc_fy17_v]    Script Date: 11/23/2016 3:27:10 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER VIEW [smsdss].[c_hac_10_proc_fy17_v]
AS

SELECT A.pt_id
, C.PtNo_Num
, C.Med_Rec_No
, CAST(C.ADM_DATE AS DATE) AS admit_date
, CAST(C.DSCH_DATE AS DATE) AS dsch_date
, A.proc_cd
, A.proc_cd_prio
, A.proc_cd_type
, A.proc_cd_schm
, B.hac
, B.hac_desc
, B.proc_short_desc

FROM SMSMIR.sproc AS A
INNER MERGE JOIN SMSDSS.c_hac_10_procedures_fy17 AS B
ON REPLACE(A.proc_cd, '.','') = B.[procedure]
INNER MERGE JOIN SMSDSS.BMH_PLM_PTACCT_V AS C
ON A.PT_ID = C.Pt_No

WHERE A.proc_cd_type = 'PC'
AND C.Dsch_Date >= '2016-01-01'
AND C.Plm_Pt_Acct_Type = 'I'
AND LEFT(C.PTNO_NUM, 4) != '1999'
AND C.tot_chg_amt > 0



GO



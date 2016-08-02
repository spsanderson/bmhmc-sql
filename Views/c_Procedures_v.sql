USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_Procedures_v]    Script Date: 06/24/2016 09:37:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




ALTER VIEW [smsdss].[c_Procedures_v]
AS

-----------------------------------------------------------------------
-- G E T - P R O C E D U R E S
-----------------------------------------------------------------------
WITH Procedure_Surgery AS (
	SELECT a.pt_id      AS Encounter
	, D.vst_start_dtime AS Admit_DateTime
	, D.vst_end_dtime   AS Discharge_DateTime
	, A.proc_cd_prio    AS Procedure_Priority
	, A.proc_cd_schm    AS Code_Scheme
	, A.proc_cd_type    AS Procedure_Code_Type
	, A.proc_cd         AS Procedure_Code
	, A.proc_eff_dtime  AS Procedure_DateTime
	, A.resp_pty_cd     AS Resp_Party_Cd
	, B.pract_rpt_name  AS Resp_Party
	, B.spclty_desc     AS Resp_Party_Spclty
	, C.alt_clasf_desc  AS Procedure_Cd_Desc
	, C.proc_summ_cat   AS Procedure_CD_Cat

	FROM SMSMIR.mir_sproc                   AS A
	LEFT OUTER JOIN SMSDSS.pract_dim_v      AS B
	ON A.resp_pty_cd = B.src_pract_no
		AND B.orgz_cd = 'S0X0'
	LEFT OUTER JOIN SMSDSS.proc_dim_v       AS C
	ON A.proc_cd = C.proc_cd
	LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS D
	ON A.pt_id = D.Pt_No

	WHERE D.dsch_date >= '2010-01-01'
	AND A.proc_cd_schm IN ('9', '0', 'H')
)

SELECT A.Encounter
, A.Admit_DateTime
, CASE
	WHEN LEFT(A.Encounter, 5) != '00001'
	AND A.Discharge_DateTime IS NULL
		THEN A.Admit_DateTime
		ELSE A.Discharge_DateTime
  END AS Discharge_DateTime
, A.Procedure_Code
, A.Procedure_Priority
, A.Code_Scheme
, A.Procedure_Code_Type
, A.Procedure_DateTime
, A.Resp_Party_Cd
, A.Resp_Party
, A.Resp_Party_Spclty
, A.Procedure_CD_Desc
, A.Procedure_CD_Cat

FROM Procedure_Surgery AS A

WHERE A.Discharge_DateTime < '2015-10-01 00:00:00.000'
AND A.Code_Scheme IN ('9', 'H')
AND LEN(A.Encounter) = 12
AND LEFT(A.Encounter, 5) != '00007'

UNION ALL

SELECT B.Encounter
, B.Admit_DateTime
, CASE
	WHEN LEFT(B.Encounter, 5) != '00001'
	AND B.Discharge_DateTime IS NULL
		THEN B.Admit_DateTime
		ELSE B.Discharge_DateTime
  END AS Discharge_DateTime
, B.Procedure_Code
, B.Procedure_Priority
, B.Code_Scheme
, B.Procedure_Code_Type
, B.Procedure_DateTime
, B.Resp_Party_Cd
, B.Resp_Party
, B.Resp_Party_Spclty
, B.Procedure_CD_Desc
, B.Procedure_CD_Cat

FROM Procedure_Surgery AS B

WHERE B.Discharge_DateTime >= '2015-10-01 00:00:00.000'
AND B.Code_Scheme IN ('0', 'H')
AND LEN(B.Encounter) = 12
AND LEFT(B.Encounter, 5) != '00007'


GO



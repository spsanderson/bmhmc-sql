USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[c_ARxChange_Rpt_Tbl_2_v]    Script Date: 11/23/2015 2:15:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [smsdss].[c_ARxChange_Rpt_Tbl_2_v]

AS

-- insurance information ------------------------------------------
	SELECT b.pt_id
, q.pyr_name									AS [INS1_Name]
, ''											AS [INS1_ProgramName] -- NOT needed
, CASE
	WHEN LEFT(r.pyr_Cd,1) NOT IN ('A','Z') 
	THEN r.grp_no
	ELSE ''
	END											AS [INS1_GROUPID] -- NOT needed
, r.pyr_cd										AS [INS1_PayerID] -- NOT needed
, ''                                            AS [INS1_SubscriberID] -- NOT needed
, ''                                            AS [INS1_Relation_Code] -- NOT needed
, CASE 
	WHEN LEFT(r.pyr_cd,1) IN ('A','Z') 
	THEN r.pol_no + ISNULL(LTRIM(RTRIM(r.grp_no)),'')
	WHEN r.pol_no IS NULL
	THEN r.subscr_ins_grp_id
	ELSE r.pol_no
	END											AS [INS1_PolicyNumber]
, ''                                            AS [INS1_StartDate] -- NOT needed
, ''                                            AS [INS1_EndDate] -- NOT needed
, s.Ins_tel_no									AS [INS1_PhoneNumber] -- NOT needed
, r.pyr_cd										AS [INS1_Plan_Code] -- NOT needed
, ''											AS [INS1_Plan_Type] -- NOT needed
, v.pyr_name									AS [INS2_Name]
, ''											AS [INS2_ProgramName] -- NOT needed
, CASE
	WHEN LEFT(w.pyr_cd,1) IN ('A','Z') 
	THEN ''
	ELSE w.grp_no
	END											AS [INS2_GroupID] -- NOT needed
, CASE 
	WHEN LEFT(w.pyr_cd,1) IN ('A','Z') 
	THEN w.pol_no + ISNULL(LTRIM(RTRIM(w.grp_no)),'')
	WHEN w.pol_no IS NULL
	THEN w.subscr_ins_grp_id
	ELSE w.pol_no
	END											AS [INS2_PolicyNumber]
, w.pyr_cd										AS [INS2_PayerID] -- NOT needed
, ''											AS [INS2_SubscriberID] -- NOT needed
, ''											AS [INS2_Relation_Code] -- NOT needed
, ''											AS [INS2_StartDate] -- NOT needed
, ''											AS [INS2_EndDate] -- NOT needed
, t.Ins_tel_no									AS [INS2_PhoneNumber] -- NOT needed
, w.pyr_cd										AS [INS2_Plan_Code] -- NOT needed
, ''											AS [INS2_Plan_Type] -- NOT needed
, CASE
	WHEN C.VST_TYPE_CD = 'I'
		AND BB.PT_KEY IS NULL
	THEN 'ED'
	WHEN C.VST_TYPE_CD = 'O'
		AND C.PT_TYPE = 'E'
		AND BB.PT_KEY IS NULL
	THEN 'ED'
	WHEN BB.PT_KEY IS NOT NULL
	THEN 'TR'
	ELSE 'EA'
	END                                           AS [Elective_or_ED_Admissions_or_Trauma_Indicator]
, aa.pract_rpt_name                             AS [PhysicianName]
, dd.clasf_desc                                 AS [Primary_Diagnostic_Description]

FROM smsmir.mir_acct							AS b 
LEFT JOIN smsmir.mir_vst						AS c
ON b.pt_id = c.pt_id 
	AND b.pt_id_start_dtime = c.pt_id_start_dtime 
	AND b.unit_seq_no = c.unit_Seq_no
LEFT JOIN smsmir.mir_pyr_mstr					AS q
ON b.prim_pyr_cd = q.pyr_cd
LEFT JOIN smsmir.mir_pyr_plan					AS r
ON b.prim_pyr_cd = r.pyr_cd 
	AND b.pt_id = r.pt_id 
	AND b.pt_id_start_dtime = r.pt_id_start_dtime
LEFT JOIN smsdss.c_ins_user_fields_v			AS s
ON b.pt_id = s.pt_id
	AND b.prim_pyr_cd = s.pyr_cd
LEFT JOIN smsdss.c_ins_user_fields_v			AS t
ON b.pt_iD = t.pt_id
	AND b.pyr2_cd = t.pyr_cd
LEFT JOIN smsmir.mir_pyr_mstr					AS v
ON b.pyr2_cd = v.pyr_cd
LEFT JOIN smsmir.mir_pyr_plan					AS w
ON b.pyr2_cd = w.pyr_cd 
	AND b.pt_id = w.pt_id 
	AND b.pt_id_start_dtime = w.pt_id_start_dtime
	AND w.pyr_seq_no = 2
LEFT JOIN smsmir.mir_pract_mstr					AS aa
ON c.prim_pract_no = aa.pract_no 
	AND aa.iss_orgz_cd = 'S0X0'
	
-- add trauma indicator
LEFT JOIN smsdss.bmh_plm_ptacct_v			    AS cc
ON cc.Pt_No = b.pt_id
LEFT JOIN smsdss.BMH_ER_TraumaCase_Evaluator_V  AS bb
ON cc.Pt_Key = bb.Pt_Key
LEFT JOIN SMSDSS.dx_cd_dim_v                    AS dd
ON c.prin_dx_cd = dd.dx_cd
	AND c.prin_dx_cd_schm = dd.dx_cd_schm

WHERE b.from_file_ind IN ('4a','4h','6a','6h')
AND b.bd_wo_dtime > '12/31/2014'
AND b.tot_bal_amt > 0
AND b.resp_cd IS NULL
AND b.unit_seq_no IN (0, -1)
AND b.pt_type NOT IN ('R', 'K')
GO



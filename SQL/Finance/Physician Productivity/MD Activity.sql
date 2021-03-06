DECLARE @ACTV_CD_START  VARCHAR(10);
DECLARE @ACTV_CD_END    VARCHAR(10);
DECLARE @PROC_EFF_START DATETIME;
DECLARE @PROC_EFF_END   DATETIME;
--DECLARE @PROC_CD_TYPE   VARCHAR(3); -- for icd-9 2 for icd-10 3
DECLARE @ADMIT_START    DATETIME;
DECLARE @ADMIT_END      DATETIME;
DECLARE @PROC_SUMM_CAT  VARCHAR(15);
DECLARE @HCPCS_PROC_CAT VARCHAR(15);

SET @ACTV_CD_START  = '07200000';
SET @ACTV_CD_END    = '07299999';
SET @PROC_EFF_START = '2018-01-01';
SET @PROC_EFF_END   = '2019-01-01';
--SET @PROC_CD_TYPE   = 'PC'; -- for inpatient pc for outpatient pch
SET @ADMIT_START    = @PROC_EFF_START;
SET @ADMIT_END      = @PROC_EFF_END;

-- DECLARE MD LIST ----------------------------------------------------
DECLARE @MD_LIST TABLE (
	MD_ID VARCHAR(6)
)

INSERT @MD_LIST (MD_ID)
VALUES (''),(''),(''),(''),(''),(''),('')
-----------------------------------------------------------------------

--Pull Surgeon Information
SELECT d.user_pyr1_cat
, d.fc
, d.Pyr1_Co_Plan_Cd
, a.pt_id
, d.Pt_Name
, d.Med_Rec_No
, d.Adm_Date
, d.Dsch_Date
, d.Days_Stay                                          AS [LOS]
, a.proc_eff_dtime                                     AS [Proc_Date]
, d.plm_pt_acct_type                                   AS [IP/OP]
, d.pt_type
, d.tot_chg_amt
, (
	SELECT SUM(p.chg_tot_amt)
	FROM smsmir.mir_actv AS p
	WHERE p.actv_cd BETWEEN @ACTV_CD_START AND @ACTV_CD_END
	AND a.pt_id = p.pt_id 
	AND a.pt_id_start_dtime = p.pt_id_start_dtime 
	AND a.unit_seq_no = p.unit_seq_no
	HAVING SUM(p.chg_tot_amt)>0
)                                                      AS [Implant_Chgs]
, ISNULL(e.tot_pymts_w_pip,0)                          AS [Pymts_W_PIP]
, d.tot_amt_due
, a.proc_cd
, CASE
	WHEN a.proc_cd IS Null THEN 'NON-SURGICAL'
	Else 'Surgical' 
  END                                                  AS [Case_Type]
, c.clasf_desc
, a.resp_pty_cd
, b.pract_rpt_name
-- Principal Outpatient Responsibility Code
, CASE
	WHEN a.proc_cd IS NOT NULL
		AND LEFT(a.pt_id, 5) != '00001'
	THEN 1
	ELSE 0
  END                                                  AS [Pincipal_OutPt_Sug_Resp_Flag]
-- Surgical Case that was a direct Admit
, CASE
	WHEN a.proc_cd IS NOT NULL
		AND d.Adm_Source IN ('RA','RP','TH','TV')
	THEN 1
	ELSE 0
  END                                                  AS [Surgical_Direct_Admit]
, YEAR(a.proc_eff_dtime)                               AS [Procedure_Year]
, ATN_DR.pract_rpt_name                                AS [Attending_Dr]
, ADM_DR.pract_rpt_name                                AS [Admitting_Dr]

FROM smsmir.mir_sproc                                  AS a 
LEFT JOIN smsmir.mir_pract_mstr                        AS b
ON a.resp_pty_cd = b.pract_no 
	AND a.src_sys_id = b.src_sys_id
LEFT JOIN smsmir.mir_clasf_mstr                        AS c
ON a.proc_cd = c.clasf_cd 
LEFT JOIN smsdss.BMH_PLM_PtAcct_V                      AS d
ON a.pt_id = d.Pt_No 
	AND a.pt_id_start_dtime = d.pt_id_start_dtime 
	AND a.unit_seq_no=d.unit_seq_no
LEFT JOIN smsdss.c_tot_pymts_w_pip_v                   AS e
ON a.pt_id = e.pt_id 
	AND a.unit_seq_no = e.unit_seq_no 
	AND a.pt_id_start_dtime = e.pt_id_start_dtime
LEFT OUTER JOIN SMSDSS.pract_dim_v                     AS ATN_DR
ON D.Atn_Dr_No = ATN_DR.src_pract_no
	AND ATN_DR.orgz_cd = 'S0X0'
LEFT OUTER JOIN SMSDSS.pract_dim_v                     AS ADM_DR
ON D.Adm_Dr_No = ADM_DR.src_pract_no
	AND ADM_DR.orgz_cd = 'S0X0'

WHERE a.resp_pty_cd IN (
	SELECT * FROM @MD_LIST
)
AND a.proc_cd_prio IN ('01','1')
AND a.proc_eff_dtime >= @PROC_EFF_START
AND a.proc_eff_dtime < @PROC_EFF_END
AND a.proc_cd_schm NOT IN ('!')
--AND a.proc_cd_type = @PROC_CD_TYPE
AND a.pt_id BETWEEN '000010000000' AND '000099999999'
AND d.tot_chg_amt > 0
----- change to not equal to for pch
--AND d.plm_pt_acct_type = 'I'
-----

UNION
/*Pull Outpatient PST & Ref Amb Data and IP Non-Surgical Cases*/
SELECT f.user_pyr1_cat
, f.fc
, f.pyr1_co_plan_cd
, f.pt_no
, f.pt_name
, f.med_rec_no
, f.adm_date
, f.dsch_date
, CASE
	WHEN f.Plm_Pt_Acct_Type = 'O' then '0'
	ELSE f.Days_Stay
  END        AS 'LOS'
, f.Adm_Date AS 'Proc_Date'
, f.plm_pt_acct_type
, f.pt_type
, f.tot_chg_amt
, 0
, ISNULL(g.tot_pymts_w_pip,0)
, f.tot_amt_due
, ''
, 'NON-SURGICAL'
, ''
, f.adm_dr_no
, --Gives CREDIT For Case to Attending Dr
  CASE
	WHEN f.atn_dr_no IN (
		SELECT * FROM @MD_LIST
	)
    THEN i.pract_rpt_name -- Attending
    ELSE h.pract_rpt_name -- Admitting
  END AS 'pract_rpt_name' /*Pulls Dr Name*/
, ''
, ''
, YEAR(f.Adm_Date)                                     AS [Procedure_Year]
, ATN_DR_NON.pract_rpt_name                            AS [Attending Doctor]
, ADM_DR_NON.pract_rpt_name                            AS [Admitting Doctor]

FROM smsdss.BMH_PLM_PtAcct_V                           AS f 
LEFT JOIN smsdss.c_tot_pymts_w_pip_v                   AS g
ON f.pt_no = g.pt_id 
	AND f.pt_id_start_dtime = g.pt_id_start_dtime 
	AND f.unit_seq_no=g.unit_seq_no
LEFT JOIN smsmir.mir_pract_mstr                        AS h
ON f.Adm_Dr_No = h.pract_no 
LEFT JOIN smsmir.mir_pract_mstr                        AS i
ON f.atn_dr_no = i.pract_no
LEFT OUTER JOIN smsdss.pract_dim_v                     AS ATN_DR_NON
ON F.Atn_Dr_No = ATN_DR_NON.src_pract_no
	AND ATN_DR_NON.orgz_cd = 'S0X0'
LEFT OUTER JOIN smsdss.pract_dim_v                     AS ADM_DR_NON
ON F.Adm_Dr_No = ADM_DR_NON.src_pract_no
	AND ADM_DR_NON.orgz_cd = 'S0X0'

WHERE f.pt_type IN ('T','U','O','B','I','J','M','P','Q','S','W','X','Y','Z')
AND f.adm_date >= @ADMIT_START 
AND f.adm_date < @ADMIT_END
AND f.tot_chg_amt > 0
AND h.src_sys_id='#PASS0X0'
AND i.src_sys_id='#PASS0X0'
AND f.hosp_svc <> 'bpc'
----- change to not equal to for pch
--AND f.plm_pt_acct_type = 'I'
-----
AND (
	f.adm_dr_no IN (
		SELECT * FROM @MD_LIST
		)
	OR f.atn_dr_no IN (
		SELECT * FROM @MD_LIST
		)
)
AND f.Pt_No NOT IN (
	SELECT a.pt_id

	FROM smsmir.mir_sproc             AS a 
	LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS d
	ON a.pt_id = d.Pt_No 
		AND a.pt_id_start_dtime = d.pt_id_start_dtime 
		AND a.unit_seq_no = d.unit_seq_no

	WHERE a.resp_pty_cd IN (
		SELECT * FROM @MD_LIST
	)
	AND a.proc_cd_prio IN ('01','1')
	AND a.proc_eff_dtime >= @PROC_EFF_START 
	AND a.proc_eff_dtime < @PROC_EFF_END
	--AND a.proc_cd_type = @PROC_CD_TYPE
	AND a.proc_cd_schm NOT IN ('!')
	AND a.pt_id BETWEEN '000010000000' AND '000099999999'
	AND d.tot_chg_amt > 0
)
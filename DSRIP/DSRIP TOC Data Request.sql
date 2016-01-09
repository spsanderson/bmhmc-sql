SELECT --a.med_Rec_no                AS [MRN #]
  CASE
	WHEN LEFT(pyr1_co_plan_cd,1) = 'W'
		THEN RTRIM(ISNULL(c.pol_no,'')) + LTRIM(RTRIM(ISNULL(c.grp_no,'')))
	ELSE ''
  END                              AS [CIN #]
, n.pt_last                        AS [Patient Last Name]
, N.pt_first                       AS [Patient First Name]
, a.pt_no
, CONVERT(date,a.Pt_Birthdate,101) AS [DOB]
, b.postal_cd                      AS [Zip Code]
--, b.nhs_id_no
, CAST(h.vst_start_dtime AS date)  AS [Arrival date]
, CAST(a.Dsch_DTime AS date)       AS [Discharge date]
, i.pyr_name                       AS [Primary Payor Name]
, CASE
	WHEN LEFT(a.pyr1_co_plan_cd,1) = 'B'
		THEN c.subscr_ins_grp_id
	WHEN a.pyr1_co_plan_Cd IN ('E18','E28')
		THEN c.subscr_ins_grp_id
	ELSE RTRIM(ISNULL(c.pol_no,'')) + LTRIM(RTRIM(ISNULL(c.grp_no,''))) 
  END                              AS [Primary Payor Patient ID Number]
, j.pyr_name                       AS [Secondary Payor Name]
, CASE
	WHEN LEFT(a.pyr2_co_plan_cd,1) = 'B'
		THEN d.subscr_ins_grp_id
	WHEN a.pyr2_co_plan_Cd IN ('E18','E28')
		THEN d.subscr_ins_grp_id
	ELSE RTRIM(ISNULL(d.pol_no,'')) + LTRIM(RTRIM(ISNULL(d.grp_no,''))) 
  END                              AS [Secondary Payor Patient ID Number]
, k.pyr_name                       AS [Tertiary Payor Name]
--, a.pyr3_co_plan_Cd                AS [Tertiary Payor Name]
, CASE
	WHEN LEFT(a.pyr3_co_plan_cd,1) = 'B'
		THEN e.subscr_ins_grp_id
	WHEN a.pyr3_co_plan_Cd IN ('E18','E28')
		THEN e.subscr_ins_grp_id
	ELSE RTRIM(ISNULL(e.pol_no,'')) + LTRIM(RTRIM(ISNULL(e.grp_no,''))) 
  END                              AS [Tertiary Payor Patient ID Number]
--, a.Atn_Dr_No
--, f.pract_rpt_name
--, f.npi_no
--, g.spclty_cd_Desc
--, a.hosp_svc
--, m.ward_cd
, a.plm_pt_acct_type               AS [Encounter Type]

FROM smsdss.BMH_PLM_PtAcct_V             AS a 
LEFT OUTER JOIN smsmir.mir_pt            AS b
ON a.Pt_No = b.pt_id
LEFT OUTER JOIN smsmir.mir_pyr_plan      AS c
ON a.Pt_No = c.pt_id
	AND a.Pyr1_Co_Plan_Cd = c.pyr_cd
LEFT OUTER JOIN smsmir.mir_pyr_plan      AS d
ON a.Pt_No = d.pt_id 
	AND a.Pyr2_Co_Plan_Cd = d.pyr_cd
LEFT OUTER JOIN smsmir.mir_pyr_plan      AS e
ON a.Pt_No = e.pt_id 
	AND a.Pyr3_Co_Plan_Cd = e.pyr_Cd
LEFT OUTER JOIN smsmir.mir_pract_mstr    AS f
ON a.Atn_Dr_No = f.pract_no 
	AND f.src_sys_id='#PASS0X0'
LEFT OUTER JOIN smsdss.pract_spclty_mstr AS g
ON f.spclty_cd1 = g.spclty_cd 
	AND g.src_sys_id = '#PASS0X0'
LEFT OUTER JOIN smsmir.mir_vst           AS h
ON a.Pt_No = h.pt_id
LEFT OUTER JOIN smsmir.mir_pyr_mstr      AS i
ON a.pyr1_co_plan_cd = i.pyr_cd
LEFT OUTER JOIN smsmir.mir_pyr_mstr      AS j
ON a.Pyr2_Co_Plan_Cd = j.pyr_cd
LEFT OUTER JOIN smsmir.mir_pyr_mstr      AS k
ON a.Pyr3_Co_Plan_Cd = k.pyr_cd
LEFT OUTER JOIN smsmir.mir_vst_rpt       AS m
ON a.Pt_No = m.pt_id
LEFT OUTER JOIN smsdss.c_patient_demos_v AS n
ON A.Pt_No = N.pt_id

WHERE a.user_pyr1_Cat IN ('WWW','III')
AND a.Plm_Pt_Acct_Type = 'I'-- or a.pt_type = 'E')
AND a.Dsch_DTime BETWEEN '2015-04-01 00:00:00.000' AND '2015-09-30 23:59:59.000'
AND a.tot_chg_amt > '0'

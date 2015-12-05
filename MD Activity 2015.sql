--Pull Surgeon Information
SELECT d.user_pyr1_cat
, d.fc
, d.Pyr1_Co_Plan_Cd
, a.pt_id
, d.Pt_Name
, d.Med_Rec_No
, d.Adm_Date
, d.Dsch_Date
, d.Days_Stay AS 'LOS'
, a.proc_eff_dtime AS 'Proc_Date'
, d.plm_pt_acct_type AS 'IP/OP'
, d.pt_type
, d.tot_chg_amt
, (
	SELECT SUM(p.chg_tot_amt)
	FROM smsmir.mir_actv AS p
	WHERE p.actv_cd BETWEEN '07200000' AND '07299999'
	AND a.pt_id=p.pt_id AND a.pt_id_start_dtime=p.pt_id_start_dtime AND a.unit_seq_no=p.unit_seq_no
	--GROUP BY p.chg_tot_amt
	HAVING SUM(p.chg_tot_amt)>0
) AS 'Implant_Chgs'
, ISNULL(e.tot_pymts_w_pip,0) AS 'Pymts_W_PIP'
, d.tot_amt_due
, a.proc_cd
, CASE
	WHEN a.proc_cd IS Null THEN 'NON-SURGICAL'
	Else 'Surgical' 
  END  AS 'Case_Type'
, c.clasf_desc
, a.resp_pty_cd
, b.pract_rpt_name

FROM smsmir.mir_sproc AS a 
LEFT JOIN smsmir.mir_pract_mstr AS b
ON a.resp_pty_cd = b.pract_no 
	AND a.src_sys_id = b.src_sys_id
LEFT JOIN smsmir.mir_clasf_mstr AS c
ON a.proc_cd = c.clasf_cd 
LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS d
ON a.pt_id = d.Pt_No 
	AND a.pt_id_start_dtime = d.pt_id_start_dtime 
	AND a.unit_seq_no=d.unit_seq_no
LEFT JOIN smsdss.c_tot_pymts_w_pip_v AS e
ON a.pt_id = e.pt_id 
	AND a.unit_seq_no = e.unit_seq_no 
	AND a.pt_id_start_dtime = e.pt_id_start_dtime

WHERE a.resp_pty_cd IN (
	
)
AND a.proc_cd_prio IN ('01','1')
AND a.proc_eff_dtime >= '01/01/2013' 
AND a.proc_eff_dtime < '01/01/2015'
AND a.proc_cd_type ='PC'
AND a.pt_id BETWEEN '000010000000' AND '000099999999'
AND d.tot_chg_amt >0

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
  END AS 'LOS'
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

	)
    THEN i.pract_rpt_name
    ELSE h.pract_rpt_name
  END AS 'pract_rpt_name' /*Pulls Dr Name*/

FROM smsdss.BMH_PLM_PtAcct_V AS f 
LEFT JOIN smsdss.c_tot_pymts_w_pip_v AS g
ON f.pt_no = g.pt_id 
	AND f.pt_id_start_dtime = g.pt_id_start_dtime 
	AND f.unit_seq_no=g.unit_seq_no
LEFT JOIN smsmir.mir_pract_mstr AS h
ON f.Adm_Dr_No = h.pract_no 
LEFT JOIN smsmir.mir_pract_mstr AS i
ON f.atn_dr_no = i.pract_no

WHERE f.pt_type IN ('T','U','O','B','I','J','M','P','Q','S','W','z','x','Y')
AND f.adm_date >= '01/01/2013' 
AND f.adm_date < '01/01/2015'
AND f.tot_chg_amt > 0
AND h.src_sys_id='#PASS0X0'
AND i.src_sys_id='#PASS0X0'
AND f.hosp_svc <> 'bpc'
AND (
	f.adm_dr_no IN (

	)
	OR f.atn_dr_no IN (

	)
)
AND f.Pt_No NOT IN (
	SELECT a.pt_id

	FROM smsmir.mir_sproc AS a 
	LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS d
	ON a.pt_id = d.Pt_No 
		AND a.pt_id_start_dtime = d.pt_id_start_dtime 
		AND a.unit_seq_no = d.unit_seq_no

	WHERE a.resp_pty_cd IN (

	)
	AND a.proc_cd_prio IN ('01','1')
	AND a.proc_eff_dtime BETWEEN '01/01/2013' and '12/31/2014'
	AND a.proc_cd_type ='PC'
	AND a.pt_id BETWEEN '000010000000' AND '000099999999'
	AND d.tot_chg_amt >0
)
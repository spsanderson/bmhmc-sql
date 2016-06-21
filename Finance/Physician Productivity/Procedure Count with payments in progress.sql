SELECT DISTINCT(a.pt_id)
, t.tot_chg_amt
, a.proc_eff_dtime
, a.resp_pty_cd
, d.pract_rpt_name
, a.proc_cd_prio
, a.proc_Cd
, b.clasf_desc
, a.proc_cd_type
, a.proc_cd_schm
, (
	SELECT SUM(cc.chg_tot_amt)
	FROM smsmir.mir_actv AS cc
	WHERE a.pt_id = cc.pt_id 
		AND cc.actv_cd BETWEEN '07200000' AND '07999999'
) AS [Implant & Supply Charges]
, --(
--SELECT SUM(cc.chg_tot_amt)
--FROM smsmir.mir_actv AS cc
--WHERE a.pt_id=cc.pt_id AND cc.actv_cd BETWEEN '07300000' AND '07999999'
--) AS 'Supply Charges'


FROM smsmir.mir_sproc                 AS a 
LEFT OUTER JOIN smsmir.mir_clasf_mstr AS b
ON a.proc_cd = b.clasf_Cd
LEFT OUTER JOIN smsmir.mir_pract_mstr AS d
ON a.resp_pty_cd = d.pract_no 
	AND a.src_sys_id = d.src_sys_id
LEFT OUTER JOIN smsmir.mir_acct       AS t
ON a.pt_id = t.pt_id 
	AND a.unit_seq_no=t.unit_seq_no

WHERE resp_pty_cd IN ()
AND proc_eff_dtime >= '01/01/2013' 
AND proc_eff_dtime < '11/31/2013'
AND a.pt_id BETWEEN '000010000000' AND '000099999999'
AND a.proc_cd_prio IN ('1','01')
AND a.proc_cd_schm ='9'
AND t.tot_chg_amt > 0
AND a.proc_cd IN
	(
	SELECT DISTINCT(proc_cd)
	FROM smsmir.mir_sproc
	WHERE resp_pty_cd IN ()
	AND proc_eff_dtime >= '01/01/2013' 
	AND proc_eff_dtime < '11/01/2013'
	AND pt_id BETWEEN '000010000000' AND '000099999999'
	AND proc_cd_prio IN ('1','01')
	AND proc_cd NOT IN ('99.04','86.04','77.69','93.54','86.22','03.31','79.02','93.59','93.53')
	AND proc_cd_schm = '9'
	)

ORDER BY proc_cd



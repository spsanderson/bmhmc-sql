SELECT a.user_pyr1_cat,
COUNT(DISTINCT(a.pt_no)) as 'Cases',
SUM(a.tot_Chg_amt) as 'Tot_Chgs'


FROm smsdss.bmh_plm_ptacct_v as a

WHERE a.adm_date BETWEEN '01/01/15' and '12/31/15'
AND a.plm_pt_acct_type = 'O'
AND a.pt_type IN ('X')
--AND a.hosp_svc = 'BPC'
AND a.tot_chg_Amt > 0


GROUP BY a.user_pyr1_Cat

ORDER BY a.user_pyr1_Cat ASC


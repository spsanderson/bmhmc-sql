SELECT a.user_pyr1_cat
, COUNT(DISTINCT(a.pt_no)) AS [Cases]
, SUM(a.tot_Chg_amt) AS [Charges]


FROM smsdss.bmh_plm_ptacct_v AS A

WHERE a.adm_date BETWEEN '01/01/16' and '12/31/16'
AND a.plm_pt_acct_type = 'O'
--AND a.pt_type in ('d','G')
--AND a.pt_type IN ('O','U')
--AND a.pt_type not in ('LAD')
and a.pt_type in ('k')
AND a.hosp_svc IN ('pul')
AND a.tot_chg_Amt > 0


GROUP BY a.user_pyr1_Cat

ORDER BY a.user_pyr1_Cat ASC
SELECT a.user_pyr1_cat
, Pt_No
, unit_seq_no
, Pyr1_Co_Plan_Cd
, Adm_Date
, pt_type
, hosp_svc
, 1 as [Cases] -- just sum this column in your excel pivot table
, tot_chg_amt
, tot_pay_amt
, tot_adj_amt
, Tot_Amt_Due 

FROM smsdss.bmh_plm_ptacct_v as a

WHERE a.adm_date BETWEEN '01/01/15' and '12/31/15'
AND a.plm_pt_acct_type = 'O'
AND a.pt_type IN ('X')
--AND a.hosp_svc = 'BPC'
AND a.tot_chg_Amt > 0

ORDER BY a.user_pyr1_Cat ASC

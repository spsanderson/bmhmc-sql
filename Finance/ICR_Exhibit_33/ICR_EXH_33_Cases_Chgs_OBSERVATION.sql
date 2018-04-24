SELECT a.user_pyr1_cat
, COUNT(DISTINCT(a.pt_no)) as 'Cases'
, SUM(a.tot_chg_amt) as 'Charges'

FROM smsdss.BMH_PLM_PtAcct_V as a 
LEFT OUTER JOIN smsmir.mir_actv as b
ON a.Pt_No = b.pt_id
	AND a.unit_seq_no = b.unit_seq_no

WHERE b.actv_cd = '04700035'
AND b.actv_dtime BETWEEN '01/01/2017' AND '12/31/2017'
AND a.Plm_Pt_Acct_Type <> 'I'

GROUP BY a.User_Pyr1_Cat

ORDER BY a.user_pyr1_Cat
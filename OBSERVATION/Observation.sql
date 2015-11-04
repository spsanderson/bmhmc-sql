SELECT A.Pt_No
, A.Med_Rec_No
, A.Adm_Date
, A.User_Pyr1_Cat
, A.Pyr1_Co_Plan_Cd
, A.tot_chg_amt                     AS [Total Charges]
, A.reimb_amt
, A.tot_adj_amt
, A.tot_adj_amt

FROM smsdss.bmh_plm_ptacct_v        AS A
LEFT OUTER JOIN smsmir.mir_actv     AS B
ON a.Pt_No = b.pt_id 
	AND A.unit_seq_no = b.unit_seq_no

WHERE B.actv_cd = '04700035'
AND B.actv_dtime >= '01/01/2015' 
AND A.Plm_Pt_Acct_Type <> 'I'

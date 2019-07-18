SELECT A.User_Pyr1_Cat
, A.PtNo_Num
, A.unit_seq_no
, A.Pyr1_Co_Plan_Cd
, A.Adm_Date
, A.pt_type
, A.hosp_svc
, 1 AS [Cases]
, a.tot_chg_amt
, A.tot_pay_amt
, A.tot_adj_amt
, A.Tot_Amt_Due

FROM smsdss.BMH_PLM_PtAcct_V as a 
LEFT OUTER JOIN smsmir.mir_actv as b
ON a.Pt_No = b.pt_id
	AND a.unit_seq_no = b.unit_seq_no

WHERE b.actv_cd = '04700035'
AND b.actv_dtime BETWEEN '01/01/2017' AND '12/31/2017'
AND a.Plm_Pt_Acct_Type <> 'I'

OPTION(FORCE ORDER)

GO
;
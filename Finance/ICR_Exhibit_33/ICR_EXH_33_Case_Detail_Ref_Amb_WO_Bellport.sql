SELECT A.User_Pyr1_Cat
, A.PtNo_Num
, A.unit_seq_no
, A.Pyr1_Co_Plan_Cd
, A.Adm_Date
, A.pt_type
, A.hosp_svc
, (
	SELECT COUNT(ZZZ.unit_seq_no) AS [Cases]
	FROM smsdss.BMH_PLM_PtAcct_V AS ZZZ
	WHERE ZZZ.Pt_No = A.Pt_No
	AND ZZZ.unit_seq_no = A.unit_seq_no
) AS [Cases]
, A.tot_chg_amt
, A.tot_pay_amt
, A.tot_adj_amt
, A.Tot_Amt_Due

FROM smsdss.bmh_plm_ptacct_v AS A

WHERE a.adm_date BETWEEN '01/01/16' and '12/31/16'
AND a.plm_pt_acct_type = 'O'
--AND a.pt_type in ('d','G')
--AND a.pt_type IN ('O','U')
--AND a.pt_type not in ('LAD')
and a.pt_type in ('k')
AND a.hosp_svc IN ('pul')
AND a.tot_chg_Amt > 0


OPTION(FORCE ORDER)

GO
;
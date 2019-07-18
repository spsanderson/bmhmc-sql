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

FROM smsdss.BMH_PLM_PtAcct_V AS A

WHERE hosp_Svc IN('WCC','WCH')
AND Adm_Date BETWEEN '01/01/2017' AND '12/31/2017'
AND tot_chg_amt > '0'
AND Pt_No IN (
	SELECT DISTINCT(a.Pt_id)
	
	FROM smsmir.mir_actv AS a 
	LEFT OUTER JOIN smsmir.acct AS b
	ON a.pt_id = b.pt_id

	WHERE a.actv_cd IN (
		'02501005','02501013','02501021','02501039','02501047',
		'02501054','02501062','02501070','02501088','02501096'
		)
	AND b.adm_Date BETWEEN '01/01/2017' AND '12/31/2017'
	AND b.hosp_svc IN ('WCC','WCH')
)


OPTION(FORCE ORDER)

GO
;
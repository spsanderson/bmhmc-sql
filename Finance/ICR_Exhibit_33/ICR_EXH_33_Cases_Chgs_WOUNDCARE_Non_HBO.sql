select user_pyr1_Cat
, COUNT(DISTINCT(pt_no)) as [Cases]
, SUM(tot_chg_Amt) as [Charges]

FROM smsdss.BMH_PLM_PtAcct_V

WHERE hosp_Svc IN('WCC','WCH')
AND Adm_Date BETWEEN '01/01/2017' AND '12/31/2017'
AND tot_chg_amt > '0'
AND Pt_No NOT IN (
	SELECT DISTINCT(a.Pt_id)

	FROM smsmir.mir_actv as a 
	left outer join smsmir.acct as b
	ON a.pt_id = b.pt_id

	WHERE a.actv_cd IN (
		'02501005','02501013','02501021','02501039','02501047',
		'02501054','02501062','02501070','02501088','02501096'
	)
	AND b.adm_Date BETWEEN '01/01/2017' AND '12/31/2017'
	AND b.hosp_svc in ('WCC','WCH')
)

GROUP BY User_Pyr1_Cat

ORDER BY user_pyr1_cat
;
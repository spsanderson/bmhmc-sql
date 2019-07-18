SELECT CASE
	WHEN a.User_Pyr1_Cat IN (
		'AAA', 'EEE', 'ZZZ'
	)
		THEN 'MEDICARE'
	WHEN a.User_Pyr1_Cat IN (
		'BBB', 'JJJ', 'KKK'
	)
		THEN 'HMO/PPO'
	WHEN a.User_Pyr1_Cat IN (
		'CCC', 'NNN'
	)
		THEN 'OTHER'
	WHEN a.User_Pyr1_Cat IN (
		'III', 'WWW'
	)
		THEN 'MEDICAID'
	WHEN a.User_Pyr1_Cat IN (
		'MIS'
	)
		THEN 'INDIGENT/UNCOMPENSATED'
	WHEN a.User_Pyr1_Cat = 'XXX'
		THEN 'COMMERCIAL'
  END AS [PAYER_GROUPING]
, a.PtNo_Num    

FROM smsdss.BMH_PLM_PtAcct_V AS a

WHERE a.Plm_Pt_Acct_Type NOT IN ('I')
            
AND a.Dsch_Date BETWEEN '4/1/17' AND '3/31/18'
AND tot_chg_amt > 0
AND LEFT(A.PTNO_NUM, 1) = '8'

ORDER BY a.Pt_No ASC, a.Dsch_Date ASC

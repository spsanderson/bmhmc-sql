/*
***********************************************************************
File: OneHundred_Pct_Presumptive_WD.sql

Input Parameters:
	None

Tables/Views:
	smsdss.acct
	smsdss.pay

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Find accounts that have a credit rating NOT IN (E, L)
	Presumptive Write Down = Total Charges
	Balance = 0

Revision History:
Date		Version		Description
----		----		----
2019-01-07	v1			Initial Creation
***********************************************************************
*/

SELECT a.pt_id
, a.tot_chg_amt
, SUM(b.tot_pay_adj_amt) AS [total_presumptive_charity]

INTO #TEMPA

FROM smsmir.acct AS A
LEFT OUTER JOIN smsmir.pay AS B
ON a.pt_id = b.pt_id
	AND a.unit_seq_no = b.unit_seq_no

WHERE b.pay_cd IN (
	'09735317'
	,'09735325'
	,'09735333'
	,'09735341'
)
AND a.cr_rating NOT IN ('E', 'L')
AND A.cr_rating IS NOT NULL
AND a.tot_bal_amt = 0
AND B.pt_id IN (
	SELECT XXX.pt_id
	FROM smsmir.pay AS XXX
	WHERE XXX.pay_cd IN (
		'09735317'
		,'09735325'
		,'09735333'
		,'09735341'
	)
	AND XXX.pay_entry_date >= DATEADD(DAY, DATEDIFF(DAY, 0, CAST(GETDATE() AS date)), -7)
)

GROUP BY a.pt_id
, a.tot_chg_amt
;

SELECT A.*
FROM #TEMPA AS A
WHERE A.tot_chg_amt = (total_presumptive_charity * -1)
;

DROP TABLE #TEMPA
;
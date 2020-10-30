/*
***********************************************************************
File: HBOT_PIF.sql

Input Parameters:
	None

Tables/Views:
	smsdss.BMH_PLM_PtAcct_V
    smsmir.actv

Creates Table:
	Enter Here

Functions:
	Enter Here

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Gets counts by FC and total payments for HBOT accounts that are Paid
    in full.

Revision History:
Date		Version		Description
----		----		----
2020-10-06	v1			Initial Creation
***********************************************************************
*/

DECLARE @START DATE
DECLARE @END DATE

SET @START = DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST(GETDATE() AS DATE)) - 9, 0)
SET @END = DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST(GETDATE() AS DATE)), 0)

DECLARE @PYR_GROUP TABLE (
	PYR_GROUP_DESC VARCHAR(255),
	PYR_GROUP VARCHAR(255)
	)

INSERT INTO @PYR_GROUP
SELECT DISTINCT pyr_group2,
	pyr_group
FROM SMSDSS.pyr_dim_v
WHERE orgz_cd = 'S0X0'
	AND pyr_group2 NOT IN ('?', 'No Description');

SELECT b.user_pyr1_cat,
	COUNT(b.pt_no) AS 'VISITS',
	SUM(b.tot_chg_amt) AS 'Total_Charges',
	SUM(b.tot_pay_amt) AS 'Total_Payment_Amt',
	SUM(b.tot_amt_due) AS 'Total_Amount_Due',
	SUM(b.tot_adj_amt) AS 'Total_Allowance'
	INTO #RECORDS
FROM smsdss.BMH_PLM_PtAcct_V AS b
WHERE b.pt_no IN (
		SELECT DISTINCT (a.pt_id)
		FROM smsmir.actv AS a
		WHERE a.actv_cd IN ('02501005', '02501013', '02501021', '02501039', '02501047', '02501054', '02501062', '02501070', '02501088', '02501096')
			AND a.actv_date >= @START
			AND A.actv_date < @END
			AND a.hosp_svc = 'WCC'
			AND a.chg_tot_amt <> 0
		)
AND B.Tot_Amt_Due <= 50
AND B.Tot_Amt_Due >= -50
AND B.Pyr1_Co_Plan_Cd NOT IN ('B75','B76')
GROUP BY b.user_pyr1_cat
HAVING SUM(b.tot_chg_amt) > 0
ORDER BY user_pyr1_cat;

SELECT PG.PYR_GROUP,
ISNULL(REC.VISITS, 0) AS [VISITS],
ISNULL(REC.TOTAL_CHARGES, 0) AS [TOTAL_CHARGES],
ISNULL(REC.TOTAL_PAYMENT_AMT, 0) * -1 AS [TOTAL_PAYMENT_AMT],
ISNULL(REC.TOTAL_AMOUNT_DUE, 0) AS [TOTAL_AMOUNT_DUE],
ISNULL(REC.TOTAL_ALLOWANCE, 0) AS [TOTAL_ALLOWANCE]
FROM @PYR_GROUP AS PG
LEFT OUTER JOIN #RECORDS AS REC
ON PG.PYR_GROUP = REC.user_pyr1_cat

DROP TABLE #RECORDS



/*
***********************************************************************
File: figliozzi_s10_audit_template.sql

Input Parameters:
	None

Tables/Views:
	smsmir.pay

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get payment and ajustment data for the Figliozzi S10 Audit

Revision History:
Date		Version		Description
----		----		----
2020-12-24	v1			Initial Creation
***********************************************************************
*/

SELECT a.pt_id,
	a.pay_cd,
	b.pay_cd_name,
	sum(a.tot_pay_adj_amt) AS [tot_pay_adj_amt]
INTO #tempa
FROM smsmir.pay AS a
LEFT OUTER JOIN smsdss.pay_cd_dim_v AS b ON a.pay_cd = b.pay_cd
	AND a.src_sys_id = b.src_sys_id
	AND a.orgz_cd = b.orgz_cd
WHERE substring(a.pt_id, 5, 8) IN (
		SELECT ptno_num
        -- must create a new table with the new account numbers just change the year
		FROM smsdss.c_figliozzi_audit_2020_tbl
		)
	AND a.pay_dtime < '2019-01-01' -- just change the year to ensure you are getting payments before a certain date
	AND a.pay_cd NOT IN ('09600230', '09600339', '09600537', '09600834')
GROUP BY a.pt_id,
	a.pay_cd,
	b.pay_cd_name
HAVING sum(a.tot_pay_adj_amt) != 0;

SELECT *,
	CASE 
		WHEN pay_cd IN ('09730235', '09731241', '09735234', '09735267', '09735341', '09735317', '09735333', '09735309', '09730243', '09735242', '09731258')
			THEN 'charity_care'
		WHEN left(pay_cd, 3) = '097'
			AND pay_cd NOT IN ('09730235', '09731241', '09735234', '09735267', '09735341', '09735317', '09735333', '09735309', '09730243', '09735242', '09731258')
			THEN 'adjustment'
		WHEN left(pay_cd, 4) = '0097'
			AND pay_cd NOT IN ('09730235', '09731241', '09735234', '09735267', '09735341', '09735317', '09735333', '09735309', '09730243', '09735242', '09731258')
			THEN 'adjustment'
		WHEN left(pay_cd, 3) = '098'
			AND pay_cd NOT IN ('09730235', '09731241', '09735234', '09735267', '09735341', '09735317', '09735333', '09735309', '09730243', '09735242', '09731258')
			THEN 'adjustment'
		WHEN left(pay_cd, 4) = '0098'
			AND pay_cd NOT IN ('09730235', '09731241', '09735234', '09735267', '09735341', '09735317', '09735333', '09735309', '09730243', '09735242', '09731258')
			THEN 'adjustment'
		WHEN pay_cd IN ('09904525', '09904566')
			THEN 'patient_payment'
		WHEN left(pay_cd, 3) = '099'
			AND pay_cd NOT IN ('09904525', '09904566')
			THEN 'third_party_payment'
		WHEN left(pay_cd, 4) = '0099'
			AND pay_cd NOT IN ('09904525', '09904566')
			THEN 'third_party_payment'
		ELSE 'unknown'
		END AS [pmt_adj_flag]
FROM #tempa;

DROP TABLE #tempa;

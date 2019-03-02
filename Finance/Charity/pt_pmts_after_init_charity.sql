/*
***********************************************************************
File: pt_pmts_after_init_charity.sql

Input Parameters:
	None

Tables/Views:
	smsmir.vst_rpt AS VST
	smsdss.c_charity_care_v AS CHARITY
	smsmir.pay AS PAY

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Find all Patient made Payments that occurred on or after the initial
	charity care date.

Revision History:
Date		Version		Description
----		----		----
2019-03-01	v1			Initial Creation
***********************************************************************
*/

SELECT VST.pt_id
, VST.tot_pay_amt
, VST.ins_pay_amt
, (VST.tot_pay_amt - VST.ins_pay_amt) AS PT_PAY_AMT
, CHARITY.pay_entry_date AS [Charity_Cd_Date]
, ISNULL(SUM(PAY.tot_pay_adj_amt), 0) AS [PT_PMTS_AFTER_CHARITY]

FROM smsmir.vst_rpt AS VST
LEFT OUTER JOIN smsdss.c_charity_care_v AS CHARITY
ON VST.pt_id = CHARITY.pt_id
	AND VST.unit_seq_no = CHARITY.unit_seq_no
	AND VST.from_file_ind = CHARITY.from_file_ind
	AND CHARITY.pay_entry_date = (
		SELECT MIN(ZZZ.PAY_ENTRY_DATE) 
		FROM smsdss.c_charity_care_v AS ZZZ 
		WHERE VST.pt_id = ZZZ.pt_id 
		AND VST.from_file_ind = ZZZ.from_file_ind
		AND VST.UNIT_SEQ_NO = ZZZ.UNIT_SEQ_NO
		--AND YEAR(ZZZ.PAY_ENTRY_DATE) = 2018
	)
LEFT OUTER JOIN smsmir.pay AS PAY
ON VST.pt_id = PAY.pt_id
	AND VST.unit_seq_no = PAY.unit_seq_no
	AND VST.from_file_ind = PAY.from_file_ind
	AND PAY.pay_entry_date >= (
		SELECT MIN(XXX.PAY_ENTRY_DATE) 
		FROM smsdss.c_charity_care_v AS XXX
		WHERE PAY.pt_id =XXX .pt_id 
		AND PAY.from_file_ind = XXX.from_file_ind
		AND PAY.unit_seq_no = XXX.unit_seq_no
		--AND YEAR(XXX.PAY_ENTRY_DATE) = 2018
		AND PAY.pay_cd IN (
			'09600438', -- Collections - Bad Debt
			'09600834', -- Collections - Bad Debt
			'09600339', -- Collections - Bad Debt
			'09600537', -- Collections - Bad Debt
			'09600230', -- Collections - Bad Debt
			'09905209', -- Patient Payment
			'09905258', -- Patient Payment
			'09905191', -- Patient Payment
			'09905241', -- Patient Payment
			'09905167', -- Patient Payment
			'09905175', -- Patient Payment
			'09905217', -- Patient Payment
			'09905183', -- Patient Payment
			'09905225', -- Patient Payment
			'09904525', -- Patient Payment
			'09904566', -- Patient Payment
			'09900184', -- Patient Payment
			'09900192'  -- Patient Payment
		)
	)

WHERE VST.pt_id = ''

GROUP BY VST.pt_id
, VST.tot_pay_amt
, VST.ins_pay_amt
, (VST.tot_pay_amt - VST.ins_pay_amt) 
, CHARITY.pay_entry_date

ORDER BY VST.PT_ID
;
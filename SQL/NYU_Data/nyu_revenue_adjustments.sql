SELECT PAV.Pt_No,
	PAV.unit_seq_no,
	PAV.Pyr1_Co_Plan_Cd,
	PDV.pyr_cd_desc,
	PDV.pyr_group2,
	PAY.pay_cd,
	PAYCD.pay_cd_name,
	[posting_date] = CAST(PAY.PAY_ENTRY_DTIME AS DATE),
	[toal_adj_amount] = SUM(PAY.tot_pay_adj_amt)
FROM smsmir.pay AS PAY
INNER JOIN smsdss.BMH_PLM_PtAcct_V AS PAV ON PAY.PT_ID = PAV.PT_NO
	AND PAY.unit_seq_no = PAV.unit_seq_no
INNER JOIN SMSDSS.pyr_dim_v AS PDV ON PAV.Pyr1_Co_Plan_Cd = PDV.src_pyr_cd
	AND PAV.Regn_Hosp = PDV.orgz_cd
INNER JOIN smsdss.pay_cd_dim_v AS PAYCD ON PAY.pay_cd = PAYCD.pay_cd
	AND PAY.orgz_cd = PAYCD.orgz_cd
WHERE LEFT(PAV.PTNO_NUM, 1) != '2'
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
AND PAV.prin_dx_cd IS NOT NULL
AND PAV.tot_chg_amt > 0
--AND PAV.Adm_Date >= '2022-06-01'
AND PAV.PtNo_Num IN ('89982839')
AND PAV.unit_seq_no = '0'
AND (
	LEFT(PAY.PAY_CD, 3) IN ('097')
	OR LEFT(PAY.PAY_CD, 4) IN ('0097')
)
AND PAY.tot_pay_adj_amt != 0
AND EXISTS (
	SELECT 1
	FROM smsmir.actv AS ZZZ
	WHERE ZZZ.PT_ID = PAV.PT_NO
		AND ZZZ.unit_seq_no = PAV.unit_seq_no
		AND ZZZ.actv_cd = '04700019'
)
GROUP BY PAV.Pt_No,
	PAV.unit_seq_no,
	PAV.Pyr1_Co_Plan_Cd,
	PDV.pyr_cd_desc,
	PDV.pyr_group2,
	PAY.pay_cd,
	PAYCD.pay_cd_name,
	PAY.PAY_ENTRY_DTIME
HAVING SUM(PAY.tot_pay_adj_amt) != 0
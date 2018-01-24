SELECT A.pt_id
, VST.fc
, A.pyr_cd AS [Ins1]
, ISNULL(CAST(A.tot_amt_due AS money),0) AS [Ins1_Bal]
, B.pyr_cd AS [Ins2]
, ISNULL(CAST(B.tot_amt_due AS money),0) AS [Ins2_Bal]
, C.pyr_cd  AS [Ins3]
, ISNULL(CAST(C.tot_amt_due AS money),0) AS [Ins3_Bal]
, D.pyr_cd AS [Ins4]
, ISNULL(CAST(D.tot_amt_due AS money),0) AS [Ins4_Bal]
, ISNULL(CAST(VST.pt_bal_amt AS money),0) AS [Pt_Bal_Amt]
, E.pay_cd
, F.pay_cd_name
, E.pay_date
, E.pay_entry_date
, [Referral_Number] = ROW_NUMBER() OVER(
		PARTITION BY E.PT_ID
		ORDER BY E.PAY_DATE
	)

FROM smsmir.pyr_plan AS A
LEFT OUTER JOIN smsmir.pyr_plan AS B
ON A.pt_id = B.pt_id
	AND A.unit_seq_no = B.unit_seq_no
	AND B.pyr_seq_no = 2
LEFT OUTER JOIN smsmir.pyr_plan AS C
ON A.pt_id = C.pt_id
	AND A.unit_seq_no = C.unit_seq_no
	AND C.pyr_seq_no = 3
LEFT OUTER JOIN smsmir.pyr_plan AS D
ON A.pt_id = D.pt_id
	AND A.unit_seq_no = D.unit_seq_no
	AND D.pyr_seq_no = 4
LEFT OUTER JOIN smsmir.pay AS E
ON A.pt_id = E.pt_id
	AND A.unit_seq_no = E.unit_seq_no
	AND E.pay_cd = '10501104'
LEFT OUTER JOIN smsdss.pay_cd_dim_v AS F
ON E.pay_cd = F.pay_cd
	AND E.orgz_cd = F.orgz_cd
LEFT OUTER JOIN smsmir.vst_rpt AS VST
ON A.PT_ID = VST.PT_ID
	AND A.UNIT_SEQ_NO = VST.UNIT_SEQ_NO

WHERE A.pyr_seq_no = 1
AND E.pay_date BETWEEN '2017-08-01' AND '2018-01-19'

ORDER BY A.pt_id
CREATE TABLE smsdss.c_HCRA_coins_flag_unitized (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, pt_id CHAR(12)
	, PtNo_Num CHAR(8)
	, unit_seq_no VARCHAR(10)
	, Pt_Acct_Type INT
	, Pay_Cd VARCHAR(12)
	, Pay_Desc VARCHAR(100)
	, Coinsurance_Flag CHAR(1)
	, Pay_Entry_Date DATE
	, positive_pay MONEY
	, negative_pay MONEY
	, check_digit MONEY
)

INSERT INTO SMSDSS.c_HCRA_coins_flag_unitized

SELECT A.*
FROM (
	SELECT a.pt_id
	, SUBSTRING(A.PT_ID, 5, 8) AS PTNO_NUM
	, b.UNIT_SEQ_NO 
	, a.pt_acct_type
	, a.pay_cd
	, a.pay_desc
	, CASE
		WHEN a.pay_desc like '%co%in%' THEN '1'
		ELSE a.pay_desc
	  END AS coinsurance_flag
	, a.pay_entry_date
	, a.tot_pay_adj_amt AS [positive pay]
	, c.tot_pay_adj_amt AS [negative pay]
	, A.tot_pay_adj_amt + C.tot_pay_adj_amt AS [Checksum]

	FROM smsmir.pay                            AS a
	INNER JOIN smsdss.c_HCRA_unique_pt_id_unitized_2016 AS b
	ON a.pt_id = b.PT_ID
		and a.unit_seq_no = b.UNIT_SEQ_NO
		AND a.tot_pay_adj_amt > 0
		AND a.pay_cd IN (
			'03300704', '03300605'
		)
		AND (
			a.pay_desc LIKE '%co%in%'
		)
	LEFT JOIN smsmir.pay                       AS c
	ON a.pt_id = c.pt_id
		and a.unit_seq_no = c.UNIT_SEQ_NO
		AND c.tot_pay_adj_amt < 0
		AND c.pay_cd IN (
			'03300704', '03300605'
		)
		AND (
			c.pay_desc LIKE '%co%in%'
		)
) A;
CREATE TABLE smsdss.c_HCRA_coins_flag (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, pt_id CHAR(12)
	, PtNo_Num CHAR(8)
	, Pt_Acct_Type INT
	, Pay_Cd VARCHAR(12)
	, Pay_Desc VARCHAR(100)
	, Coinsurance_Flag CHAR(1)
	, Pay_Entry_Date DATE
	, positive_pay MONEY
	, negative_pay MONEY
	, check_digit MONEY
	, rn tinyint
)

INSERT INTO SMSDSS.c_HCRA_coins_flag

SELECT A.*
FROM (
	SELECT a.pt_id
	, SUBSTRING(A.PT_ID, 5, 8) AS PTNO_NUM
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
	, rn = ROW_NUMBER() over(
		partition by a.pt_id
		order by a.pay_entry_date desc
		)

	FROM smsmir.pay                            AS a
	INNER JOIN smsdss.c_HCRA_unique_pt_id_2016 AS b
	ON a.pt_id = b.PT_ID
		AND a.tot_pay_adj_amt > 0
		AND a.pay_cd IN (
			'03300704', '03300605'
		)
		AND (
			a.pay_desc LIKE '%co%in%'
		)
	LEFT JOIN smsmir.pay                       AS c
	ON a.pt_id = c.pt_id
		AND c.tot_pay_adj_amt < 0
		AND c.pay_cd IN (
			'03300704', '03300605'
		)
		AND (
			c.pay_desc LIKE '%co%in%'
		)
) A

where a.rn = 1
;
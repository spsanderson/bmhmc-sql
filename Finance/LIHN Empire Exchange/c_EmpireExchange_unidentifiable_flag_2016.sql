CREATE TABLE smsdss.c_EmpireExchange_unidentifiable_flag (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, pt_id CHAR(12)
	, PtNo_Num CHAR(8)
	, Pt_Acct_Type INT
	, Pay_Cd VARCHAR(12)
	, Pay_Desc VARCHAR(100)
	, Unidentifiable_Flag CHAR(1)
	, Pay_Date DATE
	, positive_pay MONEY
	, negative_pay MONEY
	, check_digit MONEY
)

INSERT INTO smsdss.c_EmpireExchange_unidentifiable_flag

SELECT A.*
FROM (
	SELECT a.pt_id
	, SUBSTRING(A.PT_ID, 5, 8) AS PTNO_NUM
	, a.pt_acct_type
	, a.pay_cd
	, a.pay_desc
	, CASE
		WHEN (
			a.pay_desc like '%copa%/%co%'
			or
			a.pay_desc like '%copa%/%de%'
		)	THEN '1'
		ELSE a.pay_desc
	  END AS unidentifiable_flag
	, a.pay_date
	, a.tot_pay_adj_amt AS [positive pay]
	, c.tot_pay_adj_amt AS [negative pay]
	, A.tot_pay_adj_amt + C.tot_pay_adj_amt AS [Checksum]

	FROM smsmir.pay                            AS a
	INNER JOIN smsdss.c_EmpireExchange_unique_pt_id_2016 AS b
	ON a.pt_id = b.PT_ID
		AND a.tot_pay_adj_amt > 0
		AND a.pay_cd IN (
			'03300704', '03300605'
		)
		AND (
			a.pay_desc LIKE '%copa%/%co%'
			or
			a.pay_desc LIKE '%copa%/%de%'
		)
	LEFT JOIN smsmir.pay                       AS c
	ON a.pt_id = c.pt_id
		AND c.tot_pay_adj_amt < 0
		AND c.pay_cd IN (
			'03300704', '03300605'
		)
		AND (
			c.pay_desc LIKE '%copa%/%co%'
			OR
			c.pay_desc LIKE '%copa%/%de%'
		)
) A;
CREATE TABLE smsdss.c_HCRA_unidentifiable_flag_unitized (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, pt_id CHAR(12)
	, PtNo_Num CHAR(8)
	, UNIT_SEQ_NO VARCHAR(10)
	, Pt_Acct_Type INT
	, Pay_Cd VARCHAR(12)
	, Pay_Desc VARCHAR(100)
	, Unidentifiable_Flag CHAR(1)
	, Pay_Entry_Date DATE
	, positive_pay MONEY
	, negative_pay MONEY
	, check_digit MONEY
)

INSERT INTO SMSDSS.c_HCRA_unidentifiable_flag_unitized

SELECT A.*
FROM (
	SELECT a.pt_id
	, SUBSTRING(A.PT_ID, 5, 8) AS PTNO_NUM
	, a.unit_seq_no
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
	, a.pay_entry_date
	, a.tot_pay_adj_amt AS [positive pay]
	, c.tot_pay_adj_amt AS [negative pay]
	, A.tot_pay_adj_amt + C.tot_pay_adj_amt AS [Checksum]

	FROM smsmir.pay                            AS a
	INNER JOIN smsdss.c_HCRA_unique_pt_id_unitized_2016 AS b
	ON a.pt_id = b.PT_ID
		AND a.unit_seq_no = b.UNIT_SEQ_NO
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
		and a.unit_seq_no = c.unit_seq_no
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
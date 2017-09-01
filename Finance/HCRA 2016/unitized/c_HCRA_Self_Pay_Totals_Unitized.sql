DECLARE @Total_Self_Pay TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, PT_ID       VARCHAR(12)
	, [Total Self Pay Amount] MONEY
)

INSERT INTO @Total_Self_Pay
SELECT A.*
FROM (
	SELECT a.PT_ID
	, SUM(a.tot_pay_adj_amt) AS [Total Self Pay Amount]

	FROM smsdss.c_HCRA_mir_pay_unitized_2016 as a

	WHERE a.pyr_cd = '*'

	GROUP BY a.PT_ID
) A

--SELECT * FROM @Total_Self_Pay
-------------------------------

DECLARE @Total_Self_Pay_Unit TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, PT_ID VARCHAR(12)
	, UNIT_SEQ_NO VARCHAR(12)
	, [Total Self Pay by UNIT] MONEY
)

INSERT INTO @Total_Self_Pay_Unit
SELECT B.*
FROM (
	SELECT PT_ID
	, UNIT_SEQ_NO
	, SUM(TOT_PAY_ADJ_AMT) AS [Total Self Pay Amt by Unit]

	FROM smsdss.c_HCRA_mir_pay_unitized_2016

	WHERE pyr_cd = '*'

	group by pt_id, unit_seq_no
) B

--select * from @Total_Self_Pay_Unit order by pt_id, UNIT_SEQ_NO
-----------------------------------------------------------------

CREATE TABLE smsdss.c_HCRA_Self_Pay_Totals_Unitized_2016 (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, PT_ID VARCHAR(12)
	, UNIT_SEQ_NO VARCHAR(12)
	, Unit_Self_Pay_Amt MONEY
	, Total_Self_Pay_Amt MONEY
);

INSERT INTO smsdss.c_HCRA_Self_Pay_Totals_Unitized_2016

SELECT A.*
FROM (
	SELECT A.PT_ID
	, A.UNIT_SEQ_NO
	, A.[Total Self Pay by UNIT]
	, B.[Total Self Pay Amount]

	FROM @Total_Self_Pay_Unit AS A
	LEFT JOIN @Total_Self_Pay AS B
	ON A.PT_ID = B.PT_ID
) A;
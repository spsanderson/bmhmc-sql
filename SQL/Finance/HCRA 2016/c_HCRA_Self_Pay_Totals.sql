CREATE TABLE smsdss.c_HCRA_Self_Pay_Totals_2016 (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, PT_ID                VARCHAR(12)
	, [Total Self Pay Amt] MONEY
);

INSERT INTO smsdss.c_HCRA_Self_Pay_Totals_2016

SELECT A.*
FROM (
	SELECT PT_ID
	, SUM(TOT_PAY_ADJ_AMT) AS [Total Self Pay Amount]

	FROM smsdss.C_HCRA_MIR_PAY_2016

	WHERE pyr_cd = '*'

	GROUP BY PT_ID
) A;
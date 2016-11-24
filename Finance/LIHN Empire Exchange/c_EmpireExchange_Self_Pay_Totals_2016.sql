CREATE TABLE smsdss.c_EmpireExchange_Self_Pay_Totals_2016 (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, PT_ID                VARCHAR(12)
	, [Total Self Pay Amt] MONEY
);

INSERT INTO smsdss.c_EmpireExchange_Self_Pay_Totals_2016

SELECT A.*
FROM (
	SELECT PT_ID
	, SUM(TOT_PAY_ADJ_AMT) AS [Total Self Pay Amount]

	FROM smsdss.c_EmpireExchange_mir_pay_2016

	WHERE pyr_cd = '*'

	GROUP BY PT_ID
) A;
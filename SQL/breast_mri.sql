DECLARE @Brst_Bi_MRI TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter VARCHAR(12)
);

WITH CTE AS (
	SELECT DISTINCT(pt_id)

	FROM smsmir.actv

	WHERE actv_cd = '02301141'
	AND actv_dtime >= '2015-01-01'
)

INSERT INTO @Brst_Bi_MRI
SELECT * FROM CTE

SELECT * FROM @Brst_Bi_MRI;

---------------------------------------------------------------------------------------------------
DECLARE @Payments TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, Encounter VARCHAR(12)
	, Payment   MONEY
);

WITH CTE AS (
	SELECT PT_ID
	, SUM(tot_pay_adj_amt) AS [PAYMENT]
	
	FROM smsmir.pay
	
	WHERE pyr_cd = 'I01'
	AND pt_id IN (
		SELECT A.Encounter
		FROM @Brst_Bi_MRI AS A
	)
	GROUP BY pt_id
)

INSERT INTO @Payments
SELECT * FROM CTE

SELECT * FROM @Payments
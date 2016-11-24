DECLARE @PYR_SEQ_TBL TABLE (
	PT_ID CHAR(12)
	, PYR_CD CHAR(3)
	, PYR_SEQ INT
);

WITH CTE AS (
	SELECT pt_id
	, prim_pyr_cd
	,'1' AS PYR_SEQ_NO
	FROM SMSMIR.acct
	WHERE pt_id IN (
		SELECT PT_ID
		FROM SMSDSS.c_HCRA_unique_pt_id_2016
	)

	UNION

	SELECT PT_ID
	, pyr2_cd
	, '2' AS PYR_SEQ_NO
	FROM SMSMIR.acct
	WHERE pt_id IN (
		SELECT PT_ID
		FROM SMSDSS.c_HCRA_unique_pt_id_2016
	)

	UNION

	SELECT PT_ID
	, pyr3_cd
	, '3'
	FROM SMSMIR.acct
	WHERE pt_id IN (
		SELECT PT_ID
		FROM SMSDSS.c_HCRA_unique_pt_id_2016
	)

	UNION

	SELECT PT_ID
	, PYR4_CD
	, '4'
	FROM SMSMIR.ACCT
	WHERE pt_id IN (
		SELECT PT_ID
		FROM SMSDSS.c_HCRA_unique_pt_id_2016
	)
)

INSERT INTO @PYR_SEQ_TBL
SELECT * FROM CTE AS A;

-----

CREATE TABLE smsdss.c_HCRA_Pyr_Seq_No_2016 (
	PT_ID VARCHAR(12)
	, PYR_CD CHAR(3)
	, PYR_SEQ_NO INT
);

INSERT INTO smsdss.c_HCRA_Pyr_Seq_No_2016

SELECT * 
FROM @PYR_SEQ_TBL AS A
WHERE PYR_cd IS NOT NULL
ORDER BY PT_ID, PYR_SEQ;
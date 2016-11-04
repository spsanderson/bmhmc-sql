CREATE TABLE smsdss.c_HCRA_ins_addr1 (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, PT_ID VARCHAR(12)
	, PtNo_Num VARCHAR(8)
	, pt_id_start_dtime DATETIME
	, pyr_cd VARCHAR(4)
	, pyr_seq_no VARCHAR(1)
	, ins_addr1 varchar(100)
)

INSERT INTO smsdss.c_HCRA_ins_addr1

SELECT A.*
FROM (
	SELECT A.pt_id
	, SUBSTRING(A.ACCT_NO, 5, 8) AS PtNo_Num
	, A.pt_id_start_dtime
	, A.pyr_cd
	, A.pyr_seq_no
	, A.user_text AS [Ins_Addr1]

	FROM SMSMIR.PYR_PLAN_USER AS A
	INNER MERGE JOIN SMSDSS.c_HCRA_unique_pt_id_2016 AS B
	ON A.pt_id = B.PT_ID
		AND A.user_comp_id = '5C49ADD1'
) A;
CREATE TABLE smsdss.c_HCRA_ins_state (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, PT_ID VARCHAR(12)
	, PtNo_Num VARCHAR(8)
	, pt_id_start_dtime DATETIME
	, pyr_cd VARCHAR(4)
	, [State] varchar(30)
)

INSERT INTO smsdss.c_HCRA_ins_state

SELECT A.pt_id
, A.PtNo_Num
, A.pt_id_start_dtime
, A.pyr_cd
, A.[State]
FROM (
	SELECT A.pt_id
	, SUBSTRING(A.ACCT_NO, 5, 8) AS PtNo_Num
	, A.pt_id_start_dtime
	, A.pyr_cd
	, A.user_text AS [State]
	, rn = row_number() over(
							partition by a.pt_id
								, a.acct_no
								, a.pt_id_start_dtime
								, a.pyr_cd
								, a.user_text
							order by a.pt_id
								, a.acct_no
								, a.pt_id_start_dtime
								, a.pyr_cd
								, a.user_text
						)

	FROM SMSMIR.PYR_PLAN_USER AS A
	
	WHERE A.user_comp_id = '5C49ADD3'
	AND A.pt_id IN (
		SELECT A.PT_ID
		FROM SMSDSS.c_HCRA_unique_pt_id_2016 AS A
	)
) A
WHERE A.rn = 1;
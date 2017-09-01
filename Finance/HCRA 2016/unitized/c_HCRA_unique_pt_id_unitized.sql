CREATE TABLE smsdss.c_HCRA_unique_pt_id_unitized_2016 (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, PT_ID VARCHAR(12)
	, PtNo_Num VARCHAR(8)
	, UNIT_SEQ_NO VARCHAR(10)
	, MRN CHAR(6)
);

INSERT INTO smsdss.c_HCRA_unique_pt_id_unitized_2016

SELECT A.*
FROM (
	SELECT DISTINCT(A.PT_ID)
	, SUBSTRING(A.PT_ID, 5, 8) AS PtNo_Num
	, a.unit_seq_no
	, B.Med_Rec_No
	
	FROM smsdss.c_HCRA_mir_pay_unitized_2016   AS A
	LEFT JOIN smsdss.bmh_plm_ptacct_v AS B
	ON a.pt_id = b.Pt_No
) A;
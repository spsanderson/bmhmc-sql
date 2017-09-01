IF OBJECT_ID('SMSDSS.C_HCRA_UNIQUE_PT_ID_2020', 'U') IS NOT NULL
	DROP TABLE smsdss.c_HCRA_unique_pt_id_2020;

CREATE TABLE smsdss.c_HCRA_unique_pt_id_2020 (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, PT_ID VARCHAR(12)
	, PtNo_Num VARCHAR(8)
	, MRN CHAR(6)
);

INSERT INTO smsdss.c_HCRA_unique_pt_id_2020

SELECT A.*
FROM (
	SELECT DISTINCT(A.PT_ID)
	, SUBSTRING(A.PT_ID, 5, 8) AS PtNo_Num
	, B.Med_Rec_No
	
	FROM smsdss.C_HCRA_MIR_PAY_2020   AS A
	LEFT JOIN smsdss.bmh_plm_ptacct_v AS B
	ON a.pt_id = b.Pt_No
) A;
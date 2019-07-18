CREATE TABLE smsdss.c_HCRA_Payor_Data_2016 (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, [Payor Code] VARCHAR(250)
	, [Payor Code Long] VARCHAR(250)
	, [Payor Code Description] VARCHAR(250)
	, [Payor Sub-Code] VARCHAR(500)
	, [Payor Type] VARCHAR(250)
)

INSERT INTO smsdss.c_HCRA_Payor_Data_2016

SELECT A.*
FROM (
	SELECT CASE
		WHEN A.PYR_CD = '*' THEN 'MIS'
		ELSE A.PYR_CD
	   END AS [Payor Code]
	,  CASE
			WHEN a.pyr_cd = '*' 
				THEN 'Self Pay' + ',' + COALESCE(ISNULL(B.INS_NAME, ''), I.PYR_NAME)
			ELSE A.pyr_cd + ',' + COALESCE(B.INS_NAME, I.PYR_NAME) 
		END AS [Payor Code Long]
	, CASE
		WHEN a.pyr_cd = '*' THEN 'Self Pay'
		WHEN A.pyr_cd IN (
			'E36','X36','I09','K20'
			,'J36','X21','M35'
		)
			THEN COALESCE(B.ins_name, I.PYR_NAME)
		WHEN A.PYR_CD = 'C05'
			AND (
				XXX.Pyr2_Co_Plan_Cd = 'C30'
				OR
				XXX.Pyr3_Co_Plan_Cd = 'C30'
				OR
				XXX.Pyr4_Co_Plan_Cd = 'C30'
			)
			THEN 'See TRI-Tech File'
		WHEN A.PYR_CD = 'C05'
			AND (
				XXX.Pyr2_Co_Plan_Cd != 'C30'
				OR
				XXX.Pyr3_Co_Plan_Cd != 'C30'
				OR
				XXX.Pyr4_Co_Plan_Cd != 'C30'
			)
			THEN COALESCE(B.ins_name, I.PYR_NAME)
		WHEN A.PYR_CD IN ('N09', 'N10')
			AND (
				XXX.Pyr2_Co_Plan_Cd = 'N30'
				OR
				XXX.Pyr3_Co_Plan_Cd = 'N30'
				OR
				XXX.Pyr4_Co_Plan_Cd = 'N30'
			)
			THEN 'See TRI-Tech File'
		WHEN A.PYR_CD IN ('N09', 'N10')
			AND (
				XXX.Pyr2_Co_Plan_Cd != 'N30'
				OR
				XXX.Pyr3_Co_Plan_Cd != 'N30'
				OR
				XXX.Pyr4_Co_Plan_Cd != 'N30'
			)
			THEN COALESCE(B.ins_name, I.PYR_NAME)
		ELSE I.PYR_NAME
	  END AS [Payor Code Description]
	, CASE
			WHEN a.pyr_cd = '*'
			THEN 'Self Pay' + ',' + ISNULL(B.INS_NAME, '') + ',' +
				ISNULL(I.pyr_name, '') + ',' + ISNULL(H.subscr_ins_grp_name, '')
			ELSE A.pyr_cd + ',' + ISNULL(B.INS_NAME, '') + ',' +
				ISNULL(I.pyr_name,'') + ',' + ISNULL(H.subscr_ins_grp_name, '') 
		END AS [PAYOR SUB-CODE]
	, PYR_DIM.pyr_group2

	FROM SMSDSS.c_HCRA_mir_pay_2016            AS A
	LEFT JOIN SMSDSS.c_HCRA_ins_name           AS B
	ON A.PT_ID = B.PT_ID
			AND A.pyr_cd = B.pyr_cd
	LEFT JOIN SMSMIR.pyr_plan                  AS H
	ON A.PT_ID = H.PT_ID
			AND A.pyr_cd = H.pyr_cd
	LEFT JOIN SMSMIR.pyr_mstr                  AS I
	ON A.pyr_cd = I.pyr_cd
			AND I.iss_orgz_cd = 'S0X0'
	LEFT JOIN SMSDSS.c_HCRA_unique_pt_id_2016  AS ZZZ
	ON A.PT_ID = ZZZ.PT_ID
	LEFT JOIN SMSDSS.BMH_PLM_PTACCT_V          AS XXX
	ON A.PT_ID = XXX.Pt_No
	LEFT JOIN SMSDSS.pyr_dim_v AS PYR_DIM
	ON A.pyr_cd = PYR_DIM.src_pyr_cd
		AND PYR_DIM.orgz_cd = 'S0X0'

	GROUP BY A.pyr_cd
	, CASE
			WHEN a.pyr_cd = '*' 
				THEN 'Self Pay' + ',' + COALESCE(ISNULL(B.INS_NAME, ''), I.PYR_NAME)
			ELSE A.pyr_cd + ',' + COALESCE(B.INS_NAME, I.PYR_NAME) 
		END 
	, CASE
		WHEN a.pyr_cd = '*' THEN 'Self Pay'
		WHEN A.pyr_cd IN (
			'E36','X36','I09','K20'
			,'J36','X21','M35'
		)
			THEN COALESCE(B.ins_name, I.PYR_NAME)
		WHEN A.PYR_CD = 'C05'
			AND (
				XXX.Pyr2_Co_Plan_Cd = 'C30'
				OR
				XXX.Pyr3_Co_Plan_Cd = 'C30'
				OR
				XXX.Pyr4_Co_Plan_Cd = 'C30'
			)
			THEN 'See TRI-Tech File'
		WHEN A.PYR_CD = 'C05'
			AND (
				XXX.Pyr2_Co_Plan_Cd != 'C30'
				OR
				XXX.Pyr3_Co_Plan_Cd != 'C30'
				OR
				XXX.Pyr4_Co_Plan_Cd != 'C30'
			)
			THEN COALESCE(B.ins_name, I.PYR_NAME)
		WHEN A.PYR_CD IN ('N09', 'N10')
			AND (
				XXX.Pyr2_Co_Plan_Cd = 'N30'
				OR
				XXX.Pyr3_Co_Plan_Cd = 'N30'
				OR
				XXX.Pyr4_Co_Plan_Cd = 'N30'
			)
			THEN 'See TRI-Tech File'
		WHEN A.PYR_CD IN ('N09', 'N10')
			AND (
				XXX.Pyr2_Co_Plan_Cd != 'N30'
				OR
				XXX.Pyr3_Co_Plan_Cd != 'N30'
				OR
				XXX.Pyr4_Co_Plan_Cd != 'N30'
			)
			THEN COALESCE(B.ins_name, I.PYR_NAME)
		ELSE I.PYR_NAME
	  END 
	, CASE
			WHEN a.pyr_cd = '*'
			THEN 'Self Pay' + ',' + ISNULL(B.INS_NAME, '') + ',' +
				ISNULL(I.pyr_name, '') + ',' + ISNULL(H.subscr_ins_grp_name, '')
			ELSE A.pyr_cd + ',' + ISNULL(B.INS_NAME, '') + ',' +
				ISNULL(I.pyr_name,'') + ',' + ISNULL(H.subscr_ins_grp_name, '') 
		END
	, PYR_DIM.pyr_group2
) A;
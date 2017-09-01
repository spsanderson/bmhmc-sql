CREATE TABLE smsdss.c_EmpireExchange_Static_Data_2016 (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, [Reference Number] VARCHAR(15)
	, [System] VARCHAR(10)
	, [MRN] VARCHAR(8)
	, [Admit Date] DATE
	, [Discharge Date] DATE
	--, [Payor Code] VARCHAR(50)
	, [Payor Code Description] VARCHAR(50)
	--, [Payor Sub-Code] VARCHAR(200)
	, [Payor ID Number] VARCHAR(5)
	--, [Payor City] VARCHAR(40)
	--, [Payor State] VARCHAR(5)
	, [Payor TIN] VARCHAR(10)
	, [Primary Payor] CHAR(3)
	, [Secondary Payor] CHAR(3)
	, [Tertiary Payor] CHAR(3)
	, [Quaternary Payor] CHAR(3)
	, [Primary v Secondary Indicator] INT
	, [Risk Sharing Payor] CHAR(2)
	, [Direct/Non Direct Payor] CHAR(6)
	, [Medical Service Code] VARCHAR(4)
	, [Service Code Description] VARCHAR(40)
	, [Payment Amount] MONEY
	, [Payment Type] VARCHAR(10)
	, [Payment Type Description] VARCHAR(20)
	, [Receivable Type] VARCHAR(15)
	, [HCRA Line] VARCHAR(10)
	, [HCRA Line Description] VARCHAR(10)
	, [Payment Received Date] DATE
	, COPAY_FLAG CHAR(1)
	, COPAY_POSITIVE_PAY MONEY
	, COPAY_NEGATIVE_PAY MONEY
	, DEDUCTIBLE_FLAG CHAR(1)
	, DEDUC_POSITIVE_PAY MONEY
	, DEDUC_NEGATIVE_PAY MONEY
	, COINSURANCE_FLAG CHAR(1)
	, COINS_POSITIVE_PAY MONEY
	, COINS_NEGATIVE_PAY MONEY
	, UN_ID_FLAG CHAR(1)
	, UN_ID_POS_PAY MONEY
	, UN_ID_NEG_PAY MONEY
)

INSERT INTO smsdss.c_EmpireExchange_Static_Data_2016

SELECT A.*
FROM (
	SELECT ZZZ.PtNo_Num AS [Reference Number]
	, 'FMS' AS [System]
	, ZZZ.MRN
	, CAST(XXX.Adm_Date AS DATE) AS [Admit Date]
	, CAST(XXX.Dsch_Date AS DATE) AS [Discharge Date]
	--, CASE
	--	  WHEN a.pyr_cd = '*' 
	--			THEN 'Self Pay' + ',' + COALESCE(ISNULL(B.INS_NAME, ''), I.PYR_NAME)
	--	  ELSE A.pyr_cd + ',' + COALESCE(B.INS_NAME, I.PYR_NAME) 
	--  END AS [Payor Code]
	, CASE
		  WHEN a.pyr_cd = '*' THEN 'Self Pay'
		  ELSE I.pyr_name 
	  END AS [Payor Code Description]
	--, CASE
	--	  WHEN a.pyr_cd = '*'
	--	  THEN 'Self Pay' + ',' + ISNULL(B.INS_NAME, '') + ',' +
	--			ISNULL(I.pyr_name, '') + ',' + ISNULL(H.subscr_ins_grp_name, '')
	--	  ELSE A.pyr_cd + ',' + ISNULL(B.INS_NAME, '') + ',' +
	--			ISNULL(I.pyr_name,'') + ',' + ISNULL(H.subscr_ins_grp_name, '') 
	--  END AS [PAYOR SUB-CODE]
	, '' as [Payor ID Number]
	--, CASE
	--	WHEN D.CITY IS NULL
	--	THEN SUBSTRING(E.[State],1,CHARINDEX(',',E.[STATE],1)-1)
	--	ELSE D.CITY
	--  END AS [Payor City]
	--, ISNULL(SUBSTRING(E.[State], CHARINDEX(',', E.[State],1)+1, 2), '') AS [Payor State]
	, '' as [Payor TIN]
	, ISNULL(XXX.Pyr1_Co_Plan_Cd, '') AS [Primay Payor]
	, ISNULL(XXX.Pyr2_Co_Plan_Cd, '') AS [Secondary Payor]
	, ISNULL(XXX.Pyr3_Co_Plan_Cd, '') AS [Tertiary Payor]
	, ISNULL(XXX.Pyr4_Co_Plan_Cd, '') AS [Quaternary Payor]
	, H.pyr_seq_no AS [Primarv v Secondary Indicator]
	, 'NO' AS [Risk Sharing Payor] -- WE DON'T DO
	, 'Direct' AS [Direct/Non Direct Payor]
	, A.hosp_svc AS [Medical Service Code]
	, HSVC.hosp_svc_name AS [Service Code Description]
	, A.tot_pay_adj_amt AS [Payment Amount]
	, PMT_TYPE.PMT_TYPE AS [Payment Type]
	, PMT_TYPE_DESC.PMT_TYPE_DESC AS [Payment Type Description]
	, IP_OP.IP_OP AS [Receivable Type]
	, HCRA_LINE.HCRA_LINE AS HCRA_LINE
	, '' AS [HCRA Line Description]
	, a.pay_date AS [Payment Received Date]
	, COPAY.COPAY_FLAG AS COPAY_FLAG
	, ISNULL(COPAY.POSITIVE_PAY, 0) AS COPAY_POS_PAY
	, ISNULL(COPAY.NEGATIVE_PAY, 0) AS COPAY_NEG_PAY
	, DEDUC.DEDUCTIBLE_FLAG AS DEDUC_FLAG
	, ISNULL(DEDUC.POSITIVE_PAY, 0) AS DEDUC_POS_PAY
	, ISNULL(DEDUC.NEGATIVE_PAY, 0) AS DEDUC_NEG_PAY
	, COINS.COINSURANCE_FLAG AS COINS_FLAG
	, ISNULL(COINS.POSITIVE_PAY, 0) AS COINS_POS_PAY
	, ISNULL(COINS.NEGATIVE_PAY, 0) AS COINS_NEG_PAY
	, UNID.Unidentifiable_Flag AS [Unidentifiable Flag]
	, ISNULL(UNID.POSITIVE_PAY, 0) AS UNID_POS_PAY
	, ISNULL(UNID.NEGATIVE_PAY, 0) AS UNID_NEG_PAY

	FROM SMSDSS.c_EmpireExchange_mir_pay_2016            AS A
	--LEFT JOIN SMSDSS.c_HCRA_ins_name           AS B
	--ON A.PT_ID = B.PT_ID
	--	  AND A.pyr_cd = B.pyr_cd
	--LEFT JOIN SMSDSS.c_HCRA_ins_addr1          AS C
	--ON A.PT_ID = C.PT_ID
	--	  AND A.pyr_cd = C.pyr_cd
	--LEFT JOIN SMSDSS.c_HCRA_ins_city           AS D
	--ON A.PT_ID = D.PT_ID
	--	  AND A.pyr_cd = D.pyr_cd
	--LEFT JOIN SMSDSS.c_HCRA_ins_state          AS E
	--ON A.PT_ID = E.PT_ID
	--	  AND A.pyr_cd = E.pyr_cd
	--LEFT JOIN SMSDSS.c_HCRA_ins_zip            AS F
	--ON A.PT_ID = F.PT_ID
	--	  AND A.pyr_cd = F.pyr_cd
	--LEFT JOIN SMSDSS.c_HCRA_ins_tele           AS G
	--ON A.PT_ID = G.PT_ID
	--	  AND A.pyr_cd = G.pyr_cd
	LEFT JOIN SMSMIR.pyr_plan                  AS H
	ON A.PT_ID = H.PT_ID
		  AND A.pyr_cd = H.pyr_cd
	LEFT JOIN SMSMIR.pyr_mstr                  AS I
	ON A.pyr_cd = I.pyr_cd
		  AND I.iss_orgz_cd = 'S0X0'
	LEFT JOIN SMSDSS.hosp_svc_dim_v            AS HSVC
	ON A.hosp_svc = HSVC.hosp_svc
		  AND HSVC.orgz_cd = 'S0X0'
	LEFT JOIN SMSDSS.c_EmpireExchange_unique_pt_id_2016  AS ZZZ
	ON A.PT_ID = ZZZ.PT_ID
	LEFT JOIN SMSDSS.BMH_PLM_PTACCT_V          AS XXX
	ON A.PT_ID = XXX.Pt_No
	LEFT JOIN smsdss.c_EmpireExchange_copay_flag         AS COPAY
	ON A.PT_ID = COPAY.PT_ID
	LEFT JOIN smsdss.c_EmpireExchange_deductible_flag    AS DEDUC
	ON A.PT_ID = DEDUC.PT_ID
	LEFT JOIN smsdss.c_EmpireExchange_coins_flag         AS COINS
	ON A.PT_ID = COINS.PT_ID
	LEFT JOIN smsdss.c_EmpireExchange_unidentifiable_flag AS UNID
	ON A.PT_ID = UNID.pt_id

	CROSS APPLY (
		  SELECT
				CASE
					  WHEN LEFT(A.PT_ID, 5) = '00001' THEN 'Inpatient'
					  ELSE 'Outpatient'
		  END AS IP_OP
	) IP_OP

	CROSS APPLY (
		SELECT
			CASE
				WHEN (
					LEFT(A.PYR_CD, 1) IN ('A', 'E', 'Z')
					OR (
						A.PYR_CD = '*'
						AND
						XXX.User_Pyr1_Cat IN ('AAA', 'EEE', 'ZZZ')
					)
				)
					THEN 'Line 2'
				WHEN (
					LEFT(A.PYR_CD, 1) IN ('W', 'I')
					OR
						(
						A.PYR_CD = '*'
						AND
						XXX.User_Pyr1_Cat IN ('WWW', 'III')
					)
				)
					THEN 'Line 5(a)'
				WHEN (
					LEFT(A.PYR_CD, 1) = '*'
					AND	
					XXX.User_Pyr1_Cat NOT IN ('AAA', 'EEE', 'WWW', 'III', 'ZZZ')
				)
					THEN 'Line 7'
				ELSE 'Line 5(c)'
			
		END AS HCRA_LINE
	) HCRA_LINE
	
	CROSS APPLY (
		SELECT
			CASE
				WHEN H.pyr_seq_no = '0' THEN 'Self Pay'
				WHEN H.pyr_seq_no = '1' THEN 'INS1'
				WHEN H.pyr_seq_no = '2' THEN 'INS2'
				WHEN H.pyr_seq_no = '3' THEN 'INS3'
				WHEN H.pyr_seq_no = '4' THEN 'INS4'
		END AS PMT_TYPE
	) PMT_TYPE
	
	CROSS APPLY (
		SELECT
			CASE
				WHEN H.pyr_seq_no = '0' THEN 'Self Pay'
				WHEN H.pyr_seq_no = '1' THEN 'Primary Insurance'
				WHEN H.pyr_seq_no = '2' THEN 'Secondary Insurance'
				WHEN H.pyr_seq_no = '3' THEN 'Tertiary Insurance'
				WHEN H.pyr_seq_no = '4' THEN 'Quaternary Insurance'
		END AS PMT_TYPE_DESC
	) PMT_TYPE_DESC
) A;
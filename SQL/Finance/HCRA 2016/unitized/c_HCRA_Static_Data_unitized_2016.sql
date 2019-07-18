CREATE TABLE smsdss.c_HCRA_Static_Data_Unitized_2016 (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, [Reference Number] VARCHAR(15)
	, [Unit Seq No] VARCHAR(10)
	, [System] VARCHAR(10)
	, [MRN] VARCHAR(8)
	, [Admit Date] DATE
	, [Discharge Date] DATE
	, [Payor Code] VARCHAR(50)
	, [Payor Code Description] VARCHAR(50)
	, [Payor Sub-Code] VARCHAR(200)
	, [Payor ID Number] VARCHAR(5)
	, [Payor City] VARCHAR(40)
	, [Payor State] VARCHAR(5)
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
	--, [Payment Received Date] DATE we are now using pay_entry_date which ties to bank
	, [Payment Entry Date] DATE
	, [PIP Flag] VARCHAR(7)
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

INSERT INTO smsdss.c_HCRA_Static_Data_Unitized_2016

SELECT A.*
FROM (
	SELECT top 500000 substring(a.PT_ID, 5, 8) AS [Reference Number]
	, a.unit_seq_no
	, 'FMS' AS [System]
	, ZZZ.MRN
	, CAST(XXX.Adm_Date AS DATE) AS [Admit Date]
	, CAST(XXX.Dsch_Date AS DATE) AS [Discharge Date]
	, CASE
		WHEN A.PYR_CD = '*'
			THEN 'MIS'
		ELSE A.PYR_CD
	  END AS [Payor Code]
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
		-- end edit 12-15-16
		ELSE I.PYR_NAME
	  END AS [Payor Code Description]
	, '' AS [PAYOR SUB-CODE]
	, '' AS [Payor ID Number]
	, CASE
		WHEN D.CITY IS NULL
		THEN SUBSTRING(E.[State],1,CHARINDEX(',',E.[STATE],1)-1)
		ELSE D.CITY
		END AS [Payor City]
	, ISNULL(SUBSTRING(E.[State], CHARINDEX(',', E.[State],1)+1, 2), '') AS [Payor State]
	, '' as [Payor TIN]
	, ISNULL(XXX.Pyr1_Co_Plan_Cd, '') AS [Primay Payor]
	, ISNULL(XXX.Pyr2_Co_Plan_Cd, '') AS [Secondary Payor]
	, ISNULL(XXX.Pyr3_Co_Plan_Cd, '') AS [Tertiary Payor]
	, ISNULL(XXX.Pyr4_Co_Plan_Cd, '') AS [Quaternary Payor]
	, ISNULL(PYR_No.PYR_SEQ_NO, 0)    AS [Primarv v Secondary Indicator]
	, 'NO' AS [Risk Sharing Payor] -- WE DON'T DO
	, 'Direct' AS [Direct/Non Direct Payor]
	, A.hosp_svc AS [Medical Service Code]
	, HSVC.hosp_svc_name AS [Service Code Description]
	, A.tot_pay_adj_amt AS [Payment Amount]
	, PMT_TYPE.PMT_TYPE               AS [Payment Type]
	, PMT_TYPE_DESC.PMT_TYPE_DESC     AS [Payment Type Description]
	, IP_OP.IP_OP AS [Receivable Type]
	, HCRA_LINE.HCRA_LINE AS HCRA_LINE
	, '' AS [HCRA Line Description]
	, a.pay_entry_date AS [Payment Entry Date]
	, a.pip_flag
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

	FROM smsdss.c_HCRA_mir_pay_unitized_2016            AS A
	LEFT JOIN SMSDSS.c_HCRA_ins_name_unitized           AS B
	ON A.PT_ID = B.PT_ID
		AND A.pyr_cd = B.pyr_cd
	--LEFT JOIN SMSDSS.c_HCRA_ins_addr1_unitized          AS C
	--ON A.PT_ID = C.PT_ID
	--		AND A.pyr_cd = C.pyr_cd
	LEFT JOIN SMSDSS.c_HCRA_ins_city_unitized           AS D
	ON A.PT_ID = D.PT_ID
			AND A.pyr_cd = D.pyr_cd
	LEFT JOIN SMSDSS.c_HCRA_ins_state_unitized          AS E
	ON A.PT_ID = E.PT_ID
			AND A.pyr_cd = E.pyr_cd
	--LEFT JOIN SMSDSS.c_HCRA_ins_zip_unitized            AS F
	--ON A.PT_ID = F.PT_ID
	--		AND A.pyr_cd = F.pyr_cd
	--LEFT JOIN SMSDSS.c_HCRA_ins_tele_unitized           AS G
	--ON A.PT_ID = G.PT_ID
	--		AND A.pyr_cd = G.pyr_cd
	LEFT JOIN SMSMIR.pyr_plan                  AS H
	ON A.PT_ID = H.PT_ID
		AND A.pyr_cd = H.pyr_cd
		AND A.unit_seq_no = H.unit_seq_no
	LEFT JOIN SMSMIR.pyr_mstr                  AS I
	ON A.pyr_cd = I.pyr_cd
			AND I.iss_orgz_cd = 'S0X0'
	LEFT JOIN SMSDSS.hosp_svc_dim_v            AS HSVC
	ON A.hosp_svc = HSVC.hosp_svc
			AND HSVC.orgz_cd = 'S0X0'
	LEFT JOIN SMSDSS.c_HCRA_unique_pt_id_unitized_2016  AS ZZZ
	ON A.PT_ID = ZZZ.PT_ID
		AND A.unit_seq_no = ZZZ.UNIT_SEQ_NO
	LEFT JOIN SMSDSS.BMH_PLM_PTACCT_V          AS XXX
	ON A.PT_ID = XXX.Pt_No
		AND A.unit_seq_no = XXX.unit_seq_no
	LEFT JOIN smsdss.c_HCRA_copay_flag_unitized         AS COPAY
	ON A.PT_ID = COPAY.PT_ID
		AND COPAY.check_digit = 0
		AND A.unit_seq_no = COPAY.unit_seq_no
	LEFT JOIN smsdss.c_HCRA_deductible_flag_unitized    AS DEDUC
	ON A.PT_ID = DEDUC.PT_ID
		AND DEDUC.check_digit = 0
		AND A.unit_seq_no = DEDUC.unit_seq_no
	LEFT JOIN smsdss.c_HCRA_coins_flag_unitized         AS COINS
	ON A.PT_ID = COINS.PT_ID
		AND COINS.check_digit = 0
		AND A.unit_seq_no = COINS.unit_seq_no
	LEFT JOIN smsdss.c_HCRA_unidentifiable_flag_unitized AS UNID
	ON A.PT_ID = UNID.pt_id
		AND UNID.check_digit = 0
		AND A.unit_seq_no = UNID.UNIT_SEQ_NO
	LEFT JOIN SMSDSS.c_HCRA_Pyr_Seq_No_unitized_2016     AS PYR_NO
	ON A.PT_ID = PYR_NO.PT_ID
		AND A.pyr_cd = PYR_NO.PYR_CD
		AND A.unit_seq_no = PYR_NO.UNIT_SEQ_NO

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
				WHEN PYR_NO.PYR_SEQ_NO = 1 THEN 'INS1'
				WHEN PYR_NO.PYR_SEQ_NO = 2 THEN 'INS2'
				WHEN PYR_NO.PYR_SEQ_NO = 3 THEN 'INS3'
				WHEN PYR_NO.PYR_SEQ_NO = 4 THEN 'INS4'
				ELSE 'Self Pay'
		END AS PMT_TYPE
	) PMT_TYPE

	CROSS APPLY (
		SELECT
			CASE
				WHEN PYR_NO.PYR_SEQ_NO = 1 THEN 'Primary Insurance'
				WHEN PYR_NO.PYR_SEQ_NO = 2 THEN 'Secondary Insurance'
				WHEN PYR_NO.PYR_SEQ_NO = 3 THEN 'Tertiary Insurance'
				WHEN PYR_NO.PYR_SEQ_NO = 4 THEN 'Quaternary Insurance'
				ELSE 'Self Pay'
		END AS PMT_TYPE_DESC
	) PMT_TYPE_DESC
) A;
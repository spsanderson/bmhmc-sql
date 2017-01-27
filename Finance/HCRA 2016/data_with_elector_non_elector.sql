SELECT a.*
, CASE
       WHEN a.[Payor Code] = 'MIS' 
              THEN 'Self Pay' + ',' + ISNULL(B.INS_NAME, '') + ',' + ISNULL(I.pyr_name, '') + ',' + ISNULL(H.subscr_ins_grp_name, '') 
       ELSE A.[Payor Code]+ ',' + ISNULL(B.INS_NAME, '') + ',' + ISNULL(I.pyr_name,'') + ',' + ISNULL(H.subscr_ins_grp_name, '')  
  END AS [PAYOR SUB-CODE for elector] 

INTO #temp_a

FROM smsdss.c_HCRA_Static_Data_2016 AS a
LEFT join smsdss.c_hcra_ins_name AS b
ON a.[Reference Number] = SUBSTRING(b.PT_ID, 5, 8)
       and a.[Payor Code] = b.pyr_cd
LEFT JOIN SMSMIR.pyr_plan AS H 
ON A.[Reference Number] = substring(H.PT_ID , 5, 8)
       AND A.[Payor Code] = H.pyr_cd 
LEFT JOIN SMSMIR.pyr_mstr AS I 
ON A.[Payor Code]= I.pyr_cd 
       AND I.iss_orgz_cd = 'S0X0'

--SELECT * FROM #temp_a

-----

SELECT a.[reference number]
, a.[System]
, a.[MRN]
, a.[Admit Date]
, a.[Discharge Date]
--, a.[payor code]
, CASE
       WHEN A.[PAYOR CODE] IN ('C05', 'C30', 'N09', 'N10','N30')
              AND C.[CODE] != 'NULL'
              THEN C.[CODE]
       ELSE A.[Payor Code]
  END AS [Payor Code]
--, a.[Payor Code Description]
, CASE
	WHEN a.[Payor Code] = 'MIS' THEN 'Self Pay'
	WHEN LEFT(a.[Payor Code], 1) = 'A' THEN zzz.[DESCRIPTION]
	WHEN LEFT(a.[Payor Code], 1) = 'B' THEN zzz.[PAYOR]
	--WHEN LEFT(a.[Payor Code], 1) = 'C' THEN zzz.[TYPE]
	WHEN A.[PAYOR CODE] IN ('C05', 'C30', 'N09', 'N10','N30')
         AND C.[CODE] != 'NULL'
		 and c.[NAME] = 'NULL' THEN zzz.[TYPE]
	WHEN A.[PAYOR CODE] IN ('C05', 'C30', 'N09', 'N10','N30')
         AND C.[CODE] != 'NULL' THEN c.[NAME]
	WHEN A.[PAYOR CODE] IN ('C05', 'C30', 'N09', 'N10','N30')
         AND C.[CODE] = 'NULL'   THEN zzz.[TYPE]
	WHEN A.[PAYOR CODE] IN ('C05', 'C30', 'N09', 'N10','N30')
         AND C.[CODE] IS NULL THEN zzz.[TYPE]
	WHEN LEFT(a.[Payor Code], 1) = 'D' THEN zzz.[TYPE]
	WHEN LEFT(a.[payor code], 1) = 'E'
		 and a.[Payor Code] != 'E36'   THEN zzz.[PAYOR]
	WHEN a.[Payor Code] = 'E36'        THEN zzz.[TYPE]
	WHEN LEFT(a.[payor code], 1) = 'I'
		 and a.[Payor Code] != 'I09'   THEN zzz.[PAYOR]
	WHEN a.[Payor Code] = 'I09'        THEN zzz.[Type]
	WHEN LEFT(a.[payor code], 1) = 'J'
		 and a.[Payor Code] != 'J36'   THEN zzz.[PAYOR]
	WHEN a.[Payor Code] = 'J36'        THEN zzz.[TYPE]
	WHEN LEFT(a.[payor code], 1) = 'K'
		 and a.[Payor Code] not IN ('K03', 'K30', 'K79') THEN zzz.[PAYOR]
	WHEN a.[Payor Code] IN ('K03', 'K30', 'K79') THEN zzz.[TYPE]
	WHEN a.[Payor Code] = 'M35' THEN zzz.[TYPE]
	WHEN a.[Payor Code] = 'm96' THEN zzz.[PAYOR]
	--WHEN LEFT(a.[payor code], 1) = 'N' THEN zzz.[TYPE]
	WHEN LEFT(a.[payor code], 1) = 'O' THEN zzz.[TYPE]
	WHEN LEFT(a.[payor code], 1) = 'S' THEN zzz.[PAYOR]
	WHEN LEFT(a.[payor code], 1) = 'W'
		 and a.[Payor Code] != 'W11' THEN zzz.[PAYOR]
	WHEN a.[Payor Code] = 'W11' THEN zzz.[TYPE]
	WHEN LEFT(a.[payor code], 1) = 'X'
		 and a.[Payor Code] not IN ('x21', 'x35', 'x36', 'x41', 'x52', 'x71', 'x91') THEN zzz.[PAYOR]
	WHEN a.[Payor Code] IN ('x21', 'x36', 'x41', 'x52', 'x71', 'x91') THEN zzz.[TYPE]
	WHEN a.[payor code] = 'x35' THEN zzz.[DESCRIPTION]
	WHEN LEFT(a.[payor code], 1) = 'z' THEN zzz.[DESCRIPTION]
  END AS [Payor Code Description]
, a.[PAYOR SUB-CODE for elector] -- comment out of view
, a.[Payor ID Number]
--, a.[Payor City]
, CASE
       WHEN A.[Payor Code] IN ('C05', 'C30','N09', 'N10','N30')
              AND C.[CITY, STATE] != 'NULL'
              THEN REPLACE(SUBSTRING(C.[CITY, STATE], 1, CHARINDEX(',',C.[CITY, STATE], 1)), ',','')
       ELSE A.[Payor City]
  END AS [Payor City]
--, a.[Payor State]
, CASE
       WHEN A.[Payor Code] IN ('C05', 'C30', 'N09', 'N10','N30')
              AND C.[CITY, STATE] != 'NULL'
              THEN RIGHT(C.[CITY, STATE], 2)
       ELSE A.[Payor State]
  END AS [Payor State]
--, a.[Payor TIN]
, CASE
	WHEN A.[Payor Code] IN ('C05', 'C30', 'N09', 'N10','N30')
		AND C.[TIN] != 'NULL'
        THEN C.[TIN]
    WHEN LEFT(a.[Payor Code],1)IN ('A','Z','M')
		AND A.[Payor Code] != 'MIS'
		THEN 'Federal'
	WHEN a.[Payor Code] = 'MIS'
		THEN 'Self Pay'
    WHEN A.[Payor Code] IN ('I09', 'E36', 'X36', 'J20', 'J36','K20')
		THEN COALESCE(B.ELECTOR, B.FEDERAL, B.NON_ELECTOR)
    ELSE ZZZ.[TID]
  END AS [Payor TIN]
, a.[Primary Payor]
, a.[Secondary Payor]
, a.[Tertiary Payor]
, a.[Quaternary Payor]
, a.[Primary v Secondary Indicator]
, a.[Risk Sharing Payor]
--, a.[Direct/Non Direct Payor]
, CASE
	WHEN a.[Payor Code] = 'mis' THEN 'Self Pay'
	else zzz.[ELECTOR STATUS]
  END AS [Direct/Non Direct Payor]
, a.[Medical Service Code]
, a.[Service Code Description]
, a.[Payment Amount]
, a.[Payment Type]
, a.[Payment Type Description]
, a.[Receivable Type]
, a.[HCRA Line]
, a.[HCRA Line Description]
, a.[Payment Entry Date]
, a.[pip flag]
, a.[copay_flag]
, a.copay_positive_pay
, a.copay_negative_pay
, a.deductible_flag
, a.deduc_positive_pay
, a.deduc_negative_pay
, a.coinsurance_flag
, a.coins_positive_pay
, a.coins_negative_pay
, a.un_id_flag
, a.un_id_pos_pay
, a.un_id_neg_pay
, b.Elector
, b.Elector_Name
, b.Federal
, b.Federal_Name
, b.Non_Elector
, b.Non_Elector_Name
, c.*
, CASE WHEN c.NAME = 'null' THEN '1' else '0' END AS name_test
, zzz.*

INTO #temp_b

FROM #temp_a AS a
LEFT join smsdss.c_HCRA_Payor_Code_Elector_Status_2016 AS b
ON a.[Payor Sub-Code for elector] = b.[Payor Sub-Code]
       and a.[Payor Code Description] = b.[Payor Code Description]
LEFT join smsdss.c_HCRA_Payor_Code_Elector_Status_nf_2016 AS c
ON a.[Reference Number] = c.[ref#]
LEFT join smsdss.c_HCRA_pyr_cd_to_elector_2016 AS zzz
ON a.[Payor Code] = zzz.[PYR CODE]

------------------------------

create table smsdss.c_HCRA_Static_Data_w_TIN_2016 (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, [Reference Number] varchar(12)
	, [System] VARCHAR(30)
	, [MRN] VARCHAR(12)
	, [Admit Date] DATE
	, [Discharge Date] DATE
	, [Payor Code] VARCHAR(50)
	, [Payor Code Description] VARCHAR(max)
	, [Payor Sub-Code] VARCHAR(200)
	, [Payor ID Number] VARCHAR(5)
	, [Payor City] VARCHAR(70)
	, [Payor State] VARCHAR(50)
	, [Payor TIN] VARCHAR(20)
	, [Primary Payor] CHAR(30)
	, [Secondary Payor] CHAR(30)
	, [Tertiary Payor] CHAR(30)
	, [Quaternary Payor] CHAR(30)
	, [Primary v Secondary Indicator] varchar(10)
	, [Risk Sharing Payor] CHAR(20)
	, [Direct/Non Direct Payor] CHAR(60)
	, [Medical Service Code] VARCHAR(50)
	, [Service Code Description] VARCHAR(70)
	, [Payment Amount] MONEY
	, [Payment Type] VARCHAR(100)
	, [Payment Type Description] VARCHAR(40)
	, [Receivable Type] VARCHAR(35)
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

INSERT INTO smsdss.c_HCRA_Static_Data_w_TIN_2016

SELECT a.[Reference Number]
, a.[System]
, a.MRN
, a.[Admit Date]
, a.[Discharge Date]
, a.[Payor Code]
, a.[Payor Code Description]
, a.[PAYOR SUB-CODE for elector]
, a.[Payor ID Number]
, a.[payor city]
, a.[Payor State]
, a.[Payor Tin]
, a.[Primary Payor]
, a.[Secondary Payor]
, a.[Tertiary Payor]
, a.[Quaternary Payor]
, a.[primary v secondary indicator]
, a.[Risk Sharing Payor]
, a.[Direct/Non Direct Payor]
, a.[Medical Service Code]
, a.[Service Code Description]
, a.[Payment Amount]
, a.[Payment Type]
, a.[Payment Type Description]
, a.[Receivable Type]
, a.[HCRA Line]
, a.[HCRA Line Description]
, a.[Payment Entry Date]
, a.[pip flag]
, a.copay_flag
, a.copay_positive_pay
, a.copay_negative_pay
, a.deductible_flag
, a.deduc_positive_pay
, a.deduc_negative_pay
, a.coinsurance_flag
, a.coins_positive_pay
, a.coins_negative_pay
, a.un_id_flag
, a.un_id_pos_pay
, a.un_id_neg_pay

From #temp_b AS a

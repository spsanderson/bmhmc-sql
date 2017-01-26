select a.*
, CASE
       WHEN a.[Payor Code] = 'MIS' 
              THEN 'Self Pay' + ',' + ISNULL(B.INS_NAME, '') + ',' + ISNULL(I.pyr_name, '') + ',' + ISNULL(H.subscr_ins_grp_name, '') 
       ELSE A.[Payor Code]+ ',' + ISNULL(B.INS_NAME, '') + ',' + ISNULL(I.pyr_name,'') + ',' + ISNULL(H.subscr_ins_grp_name, '')  
  END AS [PAYOR SUB-CODE for elector] 

into #temp_a

from smsdss.c_HCRA_Static_Data_2016 as a
left join smsdss.c_hcra_ins_name as b
on a.[Reference Number] = SUBSTRING(b.PT_ID, 5, 8)
       and a.[Payor Code] = b.pyr_cd
LEFT JOIN SMSMIR.pyr_plan AS H 
ON A.[Reference Number] = substring(H.PT_ID , 5, 8)
       AND A.[Payor Code] = H.pyr_cd 
LEFT JOIN SMSMIR.pyr_mstr AS I 
ON A.[Payor Code]= I.pyr_cd 
       AND I.iss_orgz_cd = 'S0X0'

--select * from #temp_a

-----

select a.[reference number]
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
, a.[Payor Code Description]
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
, zzz.*

into #temp_b

from #temp_a as a
left join smsdss.c_HCRA_Payor_Code_Elector_Status_2016 as b
on a.[Payor Sub-Code for elector] = b.[Payor Sub-Code]
       and a.[Payor Code Description] = b.[Payor Code Description]
left join smsdss.c_HCRA_Payor_Code_Elector_Status_nf_2016 as c
on a.[Reference Number] = c.[ref#]
left join smsdss.c_HCRA_pyr_cd_to_elector_2016 as zzz
on a.[Payor Code] = zzz.[PYR CODE]

------------------------------

create table smsdss.c_HCRA_Static_Data_w_TIN_2016 (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, [Reference Number] varchar(12)
	, [System] VARCHAR(30)
	, [MRN] VARCHAR(12)
	, [Admit Date] DATE
	, [Discharge Date] DATE
	, [Payor Code] VARCHAR(50)
	, [Payor Code Description] VARCHAR(100)
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

insert into smsdss.c_HCRA_Static_Data_w_TIN_2016

Select a.[Reference Number]
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

From #temp_b as a

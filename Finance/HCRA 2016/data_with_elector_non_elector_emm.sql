select a.[Payment/Invoice] as [Reference Number]
, a.[System]
--, a.Payor
, a.MRN
, a.[Admit Date]
, a.[Discharge Date]
--, a.[Ins Code] as [Payor Code]
, case
	when a.Prim = 'Prim' then a.[Ins Code]
	when a.Prim = 'Sec' then a.[2nd Ins Code]
	when (
		Prim IS null
		and
		[Type Description] in (
			'Medicaid Payment',
			'APG MEDICAID PAYMENT'
		)
	)
	then 'MDCD'
	else 'Self Pay'
  end as [Payor Code]
--, a.[Insurance] as [Payor Code Description]
, case
	when a.Prim = 'Prim' then a.[Insurance]
	when a.Prim = 'Sec' then a.[2nd Ins]
	when (
		Prim IS null
		and
		[Type Description] in (
			'Medicaid Payment',
			'APG MEDICAID PAYMENT'
		)
	)
	then 'Medicaid'
	else 'Self Pay'
  end as [Payor Code Description]
, a.[Payor Sub-code]
, '' as [Payor ID Number]
, a.[Payor City]
, a.[Payor State]
, a.Payor
, a.[Payor ID]
, case
	--when a.Insurance like '%medicare%' then 'Federal'
	--when a.Insurance like '%medicaid%' then 'Federal'
	when a.payor like '%IGA-ISLAND GROUP ADMINISTRAT%' then 'TPA'
	when a.payor like '%MAGE-MAGELLAN BEHAVORIAL%' then 'TPA'
	when a.payor like '%MAGL-MAGELLAN BEHAVIORAL%' then 'TPA'
	when a.payor like '%MALO-MALONEY ASSOCIATES INC%' then 'TPA'
	when a.payor like '%mdcd-medicaid%' then 'Federal'
	when a.payor like '%mdcr-medicare%' then 'Federal'
	when a.payor like '%medicaid%' then 'Federal'
	when a.Payor like '%mediare%' then 'Federal'
	when a.payor like '%ofpp-oxford health plans%' then '222797560'
	when a.payor like '%oxuh-oxford united healthcare%' then '222797560'
	when a.payor like '%self%' then 'self'
	else coalesce(b.tid, b.[elector status])
  end as [Payor TIN]
, case 
	when a.Payor = b.payor then 1 else 0
  end as payor_test
, case
	when a.[Payor City] = b.[Payor City] then 1 else 0
  end as payor_city_test
, case
	when a.[Payor State] = b.[Payor State] then 1 else 0
  end as payor_state_test
, case
	when a.[Payor ID] = b.[Payor ID] then 1 else 0
  end as payor_id_test
, b.payor as b_payor
, b.[Payor ID] as b_payor_id
, b.[payor city] as b_payor_city
, b.[payor state] as b_payor_state
, b.tid
, b.[elector status]
, a.[Ins Code] as [Primary Payor]
, a.[2nd Ins Code]
, a.[2nd ins]
, a.[Primary Vs Secondary Indicator]
, a.[Risk-sharing]
, a.[Direct/Non Direct]
, a.[Medical Service code]
, a.[Service Code Description]
, a.Payment
, a.Prim
, a.[Type Description]
, a.[Receivable Type]
, a.[HCRA Line]
, a.[HCRA Line Description]
, a.[Payment Received Date]

into #temp_a

from smsdss.c_HCRA_EMM as a
left join smsdss.c_hcra_payor_code_elector_status_emm_2016 as b
on ltrim(rtrim(a.Payor)) = ltrim(rtrim(b.payor))
	and a.[Payor City] = b.[payor city]
	and a.[Payor State] = b.[payor state]
	and (
		a.[Payor ID] = b.[payor id]
		or
		right(a.[payor id], 4) = b.[Payor ID]
	)

-----

select a.[reference number]
, a.[System]
, a.MRN
, a.[Admit Date]
, a.[Discharge Date]
, ltrim(rtrim(a.[Payor Code])) as [Payor Code]
, case
	when a.[Payor Code] != 'Self Pay'
		then ltrim(rtrim(a.[Payor Code Description]))
	else 'Self Pay'
  end as [Payor Code Description]
, a.[Payor Sub-code]
, a.[Payor ID number]
, a.[Payor City]
, a.[Payor State]
, case
	when a.[Payor TIN] is null then b.[Payor TIN]
	else a.[Payor TIN]
  end as [Payor TIN]
, coalesce(b.[payor tin], a.[payor tin]) p_tin_test
, a.[Primary Payor]
, a.[2nd ins code]
, a.[2nd ins]
, a.[primary vs secondary indicator]
, a.[Risk-sharing]
, a.[Direct/Non Direct]
, a.[medical service code]
, a.[Service Code Description]
, a.Payment
, a.Prim
, a.[Type Description]
, a.[Receivable Type]
, a.[HCRA Line]
, a.[HCRA Line Description]
, a.[Payment Received Date]

into #temp_b

from #temp_a as a
left join smsdss.c_hcra_emm_commercial_reviewed_2016 as b
on a.[Reference Number] = b.[Payment/Invoice]
	and a.[Payment Received Date] = b.[payment received date]
	and a.[Payment] = b.payment

-----

select b.*
, case
	when b.[Payor TIN] is null
		and b.[payor code] like 'fid%'
		and b.[payor code description] like 'Fidelis%'
		and b.[type description] like '%medicaid%'
		then '113153422'
	when b.[Payor TIN] is null
		and b.[payor code] in ('aetp', 'abmh')
		and b.[payor code description] in ('AETNA PPO', 'aetna us healthcare')
		and b.[type description] like '%medicaid%'
		then '60876836'
	when b.[Payor TIN] is null
		and b.[payor code] in ('bea', 'bea9')
		and b.[payor code description] in ('beacon health strategies')
		and b.[type description] like '%medicaid%'
		then 'Federal'
	when b.[Payor TIN] is null
		and b.[payor code] in ('blsp')
		and b.[payor code description] = 'empire blue shield'
		and b.[type description] like '%medicaid%'
		then '237391136'
	when b.[Payor TIN] is null
		and b.[payor code] = 'ghi5'
		and b.[payor code description] = 'ghi'
		and b.[type description] like '%medicaid%'
		then '135511997'
	when b.[Payor TIN] is null
		and b.[payor code] in ('hea', 'hea9')
		and b.[payor code description] = 'health first inc'
		and b.[type description] like '%medicaid%'
		then '133783732'
	when b.[Payor TIN] is null
		and b.[payor code] in ('hip2', 'hipp')
		and b.[payor code description] in ('hip', 'hip health plan')
		and b.[type description] like '%medicaid%'
		then '131828429'
	when b.[Payor TIN] is null
		and b.[payor code] = 'NHP'
		and b.[payor code description] = 'NEIGHBORHOOD HEALTH'
		and b.[type description] like '%medicaid%'
		then '943474115'
	when b.[Payor TIN] is null
		and b.[payor code] = 'OFPP'
		and b.[payor code description] = 'OXFORD HEALTH PLANS'
		and b.[type description] like '%medicaid%'
		then '222797560'
	when b.[Payor TIN] is null
		and b.[payor code] = 'oppt'
		then 'Non-elector'
	when b.[Payor TIN] is null
		and b.[payor code] = 'shp'
		and b.[payor code description] = 'SUFFOLK HEALTH PLAN'
		and b.[type description] like '%medicaid%'
		then '116000464'
	when b.[Payor TIN] is null
		and b.[payor code] in ('ubh1', 'ubh3', 'ubh4', 'ubh')
		and b.[payor code description] = 'UNITED BEHAVIORAL HEALTH'
		and b.[type description] like '%medicai%'
		then 'TPA'
	when b.[Payor TIN] is null
		and b.[payor code] = 'ubh4'
		and b.[payor code description] = 'united healthcare'
		and b.[type description] like '%medicaid%'
		then '411289245'
	when b.[Payor TIN] is null
		and b.[payor code] = 'valg'
		and b.[payor code description] = 'VALUE OPTIONS GHI'
		and b.[type description] like '%medicaid%'
		then '135511997'
	when b.[Payor TIN] is null
		and b.[payor code] = 'valh'
		and b.[payor code description] = 'value options hip'
		and b.[type description] like '%medicaid%'
		then '131828429'
	when b.[Payor TIN] is null
		and b.[payor code description] like '%unkechaug indian nation%'
		then 'KPMG Question'
	when b.[Payor TIN] IS null 
		and b.[Payor Code Description] like '%medicaid%'
		then 'Federal'
  end as [Payor TIN Third Pass]		

into #temp_c

from #temp_b as b

-----

select c.*
, coalesce(c.p_tin_test, c.[Payor TIN], c.[payor tin third pass]) as [payor tin final]
, [description].[desc]

into #temp_d

from #temp_c as c

cross apply (
	select
		case
			WHEN c.[Payor Code] = '1199' THEN 'L1199 NATL BENEFIT FUND'
			WHEN c.[Payor Code] = 'AAET' THEN 'Aetna'
			WHEN c.[Payor Code] = 'AAET' THEN 'Aetna'
			WHEN c.[Payor Code] = 'AARP' THEN 'AARP Health Care Options Federal'
			WHEN c.[Payor Code] = 'ABMH' THEN 'Aetna'
			WHEN c.[Payor Code] = 'AET' THEN 'Aetna'
			WHEN c.[Payor Code] = 'AETN' THEN 'Aetna'
			WHEN c.[Payor Code] = 'AETP' THEN 'Aetna'
			WHEN c.[Payor Code] = 'AMGP' THEN 'Amrigroup'
			WHEN c.[Payor Code] = 'BEA' THEN 'Beacon Health Strategies'
			WHEN c.[Payor Code] = 'BEA' THEN 'Beacon Health Strategies Federal'
			WHEN c.[Payor Code] = 'BEA9' THEN 'Beacon Health Strategies'
			WHEN c.[Payor Code] = 'BEA9' THEN 'Beacon Health Strategies'
			WHEN c.[Payor Code] = 'BLSC' THEN 'Empire BCBS'
			WHEN c.[Payor Code] = 'BLSC' THEN 'Empire BCBS'
			WHEN c.[Payor Code] = 'BLSC' THEN 'Empire BCBS'
			WHEN c.[Payor Code] = 'BLSF' THEN 'Empire BCBS'
			WHEN c.[Payor Code] = 'BLSF' THEN 'Empire BCBS'
			WHEN c.[Payor Code] = 'BLSH' THEN 'BCBS Federal'
			WHEN c.[Payor Code] = 'BLSH' THEN 'Empire BCBS'
			WHEN c.[Payor Code] = 'BLSP' THEN 'Empire BCBS'
			WHEN c.[Payor Code] = 'BLSP' THEN 'BCBS Federal'
			WHEN c.[Payor Code] = 'BLSP' THEN 'Empire BCBS'
			WHEN c.[Payor Code] = 'CIBG' THEN 'Cigna'
			WHEN c.[Payor Code] = 'CIBH' THEN 'Cigna'
			WHEN c.[Payor Code] = 'CIBH' THEN 'Cigna'
			WHEN c.[Payor Code] = 'CIG3' THEN 'Cigna'
			WHEN c.[Payor Code] = 'CIG3' THEN 'Cigna Federal'
			WHEN c.[Payor Code] = 'CIG7' THEN 'Cigna'
			WHEN c.[Payor Code] = 'CIG8' THEN 'Cigna'
			WHEN c.[Payor Code] = 'CIG8' THEN 'Cigna'
			WHEN c.[Payor Code] = 'CIGB' THEN 'Cigna'
			WHEN c.[Payor Code] = 'CIGN' THEN 'Cigna'
			WHEN c.[Payor Code] = 'CIGU' THEN 'Cigna'
			WHEN c.[Payor Code] = 'COM1' THEN 'Commercial'
			WHEN c.[Payor Code] = 'COMM' THEN 'Commercial'
			WHEN c.[Payor Code] = 'COMM' THEN 'Metrohealth Federal'
			WHEN c.[Payor Code] = 'COMM' THEN 'Commercial Federal'
			WHEN c.[Payor Code] = 'COMM' THEN 'Commercial'
			WHEN c.[Payor Code] = 'COMM' THEN 'Consoidated Health Plans'
			WHEN c.[Payor Code] = 'FID9' THEN 'Fidelis'
			WHEN c.[Payor Code] = 'FID9' THEN 'Fidelis'
			WHEN c.[Payor Code] = 'FID9' THEN 'Fidelis Federal'
			WHEN c.[Payor Code] = 'FID9' THEN 'Fidelis Federal'
			WHEN c.[Payor Code] = 'FIDC' THEN 'Fidelis'
			WHEN c.[Payor Code] = 'FIDC' THEN 'Fidelis'
			WHEN c.[Payor Code] = 'FIDE' THEN 'Fidelis'
			WHEN c.[Payor Code] = 'FIDS' THEN 'Fidelis'
			WHEN c.[Payor Code] = 'FIDS' THEN 'Fidelis'
			WHEN c.[Payor Code] = 'GEAS' THEN 'GEHA-ASA'
			WHEN c.[Payor Code] = 'GHI' THEN 'GHI'
			WHEN c.[Payor Code] = 'GHI' THEN 'GHI Federal'
			WHEN c.[Payor Code] = 'GHI5' THEN 'GHI'
			WHEN c.[Payor Code] = 'GHI5' THEN 'GHI'
			WHEN c.[Payor Code] = 'GHI5' THEN 'GHI Federal'
			WHEN c.[Payor Code] = 'GHI6' THEN 'GHI Federal'
			WHEN c.[Payor Code] = 'GHI6' THEN 'GHI'
			WHEN c.[Payor Code] = 'GHIM' THEN 'GHI Medicare Federal'
			WHEN c.[Payor Code] = 'GHIM' THEN 'GHI'
			WHEN c.[Payor Code] = 'GHIM' THEN 'GHI Medicare Federal'
			WHEN c.[Payor Code] = 'GHIP' THEN 'GHI'
			WHEN c.[Payor Code] = 'HEA' THEN 'Helath First Inc'
			WHEN c.[Payor Code] = 'HEA9' THEN 'Helath First Inc'
			WHEN c.[Payor Code] = 'HEA9' THEN 'Health First Inc Federal'
			WHEN c.[Payor Code] = 'HEA9' THEN 'Helath First Inc'
			WHEN c.[Payor Code] = 'HEAS' THEN 'Helath First Inc'
			WHEN c.[Payor Code] = 'HIPP' THEN 'HIP Health Plan'
			WHEN c.[Payor Code] = 'HIPP' THEN 'HIP Health Plan Federal'
			WHEN c.[Payor Code] = 'HREP' THEN 'Health Republic Ins'
			WHEN c.[Payor Code] = 'IGA' THEN 'Island Group Admistrators'
			WHEN c.[Payor Code] = 'MAG' THEN 'Magnacare'
			WHEN c.[Payor Code] = 'MAGE' THEN 'Magellan Behavioral'
			WHEN c.[Payor Code] = 'MAGL' THEN 'Magellan Behavioral'
			WHEN c.[Payor Code] = 'MAGL' THEN 'Magellan Behavioral Federal'
			WHEN c.[Payor Code] = 'MAGN' THEN 'Magnacare'
			WHEN c.[Payor Code] = 'MALO' THEN 'Maloney Associates Inc'
			WHEN c.[Payor Code] = 'MDCD' THEN 'Medicaid'
			WHEN c.[Payor Code] = 'MDCD' THEN 'Medicaid'
			WHEN c.[Payor Code] = 'MDCD' THEN 'Medicare'
			WHEN c.[Payor Code] = 'MDCR' THEN 'Medicare'
			WHEN c.[Payor Code] = 'MDCR' THEN 'Medicaid'
			WHEN c.[Payor Code] = 'NHP' THEN 'NEIGHBORHOOD HEALTH'
			WHEN c.[Payor Code] = 'OFP' THEN 'Oxford'
			WHEN c.[Payor Code] = 'OFPP' THEN 'Oxford'
			WHEN c.[Payor Code] = 'OFPP' THEN 'Oxford'
			WHEN c.[Payor Code] = 'OPPT' THEN 'Optum Health'
			WHEN c.[Payor Code] = 'OPPT' THEN 'Optum Health Federal'
			WHEN c.[Payor Code] = 'OPT' THEN 'Optum Health Federal'
			WHEN c.[Payor Code] = 'OPT' THEN 'Optum Health'
			WHEN c.[Payor Code] = 'OXUH' THEN 'Oxford'
			WHEN c.[Payor Code] = 'OXUH' THEN 'Oxford'
			WHEN c.[Payor Code] = 'RRMC' THEN 'Railroad Medicare'
			WHEN c.[Payor Code] = 'Self Pay' THEN 'Self Pay'
			WHEN c.[Payor Code] = 'Self Pay' THEN 'Self Pay'
			WHEN c.[Payor Code] = 'SHP' THEN 'SUFFOLK HEALTH PLAN'
			WHEN c.[Payor Code] = 'TRI' THEN 'Tricare'
			WHEN c.[Payor Code] = 'UBAA' THEN 'United Healthcare AARP Federal'
			WHEN c.[Payor Code] = 'UBH' THEN 'United Behaviroal Health'
			WHEN c.[Payor Code] = 'UBH1' THEN 'United Behaviroal Health'
			WHEN c.[Payor Code] = 'UBH1' THEN 'United Behaviroal Health Federal'
			WHEN c.[Payor Code] = 'UBH3' THEN 'United Behaviroal Health'
			WHEN c.[Payor Code] = 'UBH3' THEN 'United Behaviroal Health Federal'
			WHEN c.[Payor Code] = 'UBH4' THEN 'United Healthcare'
			WHEN c.[Payor Code] = 'UBH4' THEN 'United Behaviroal Health'
			WHEN c.[Payor Code] = 'UNGA' THEN 'United Healthcare'
			WHEN c.[Payor Code] = 'UNI3' THEN 'United Healthcare'
			WHEN c.[Payor Code] = 'UNK' THEN 'UNKECHAUG INDIAN NATION'
			WHEN c.[Payor Code] = 'VAL1' THEN 'Value Options'
			WHEN c.[Payor Code] = 'VAL1' THEN 'Value Options Federal'
			WHEN c.[Payor Code] = 'VAL2' THEN 'Value Options Federal'
			WHEN c.[Payor Code] = 'VAL2' THEN 'Value Options'
			WHEN c.[Payor Code] = 'VAL2' THEN 'GHI'
			WHEN c.[Payor Code] = 'VAL3' THEN 'Value Options'
			WHEN c.[Payor Code] = 'VAL3' THEN 'Value Options Federal'
			WHEN c.[Payor Code] = 'VALA' THEN 'Aetna'
			WHEN c.[Payor Code] = 'VALG' THEN 'GHI'
			WHEN c.[Payor Code] = 'VALG' THEN 'Value Options GHI Federal'
			WHEN c.[Payor Code] = 'VALH' THEN 'HIP Health Plan'
			WHEN c.[Payor Code] = 'VALH' THEN 'Value Options HIP'
			WHEN c.[Payor Code] = 'VALH' THEN 'Value Options HIP'
			WHEN c.[Payor Code] = 'VALH' THEN 'Value Options HIP Federal'
			WHEN c.[Payor Code] = 'VALH' THEN 'Value Options HIP'
			WHEN c.[Payor Code] = 'VALO' THEN 'Value Options'
			WHEN c.[Payor Code] = 'VYCD' THEN 'Value Options Vytra'
			WHEN c.[Payor Code] = 'WELC' THEN 'Wellcare Of New York'
			WHEN c.[Payor Code] = 'WELL' THEN 'Wellcare Of New York Federal'
			WHEN c.[Payor Code] = 'WELL' THEN 'Wellcare Of New York'
	end as [desc]
) [description]

--

create table smsdss.c_HCRA_Static_Data_w_TIN_EMM_2016 (
	PK INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
	, [Reference Number] INT
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

insert into smsdss.c_HCRA_Static_Data_w_TIN_EMM_2016

select a.*
from (
	select d.[Reference Number]
	, d.[System]
	, d.MRN
	, d.[Admit Date]
	, d.[Discharge Date]
	, d.[Payor Code]
	, d.[desc] as [Payor Code Description]
	, d.[Payor Sub-Code]
	, d.[Payor ID Number]
	, d.[Payor City]
	, d.[Payor State]
	, d.[Payor Tin final] as [Payor TIN]
	, d.[primary payor]
	, d.[2nd ins code] 
	, '' AS [Tertiary Payor]
	, '' AS [Quaternary Payor]
	, case 
		when d.[primary vs secondary indicator] like 'pri%' then '1'
		when d.[Primary Vs Secondary Indicator] like 'sec%' then '2'
		when d.[Primary Vs Secondary Indicator] like 'sel%' then '0'
		when d.[Primary Vs Secondary Indicator] like 'pt%'  then '0'
		else d.[Primary Vs Secondary Indicator]
	  end as [Primary v Secondary Indicator]
	, d.[Risk-sharing] AS [Risk Sharing Payor]
	, d.[Direct/Non Direct] as [Direct/Non Direct Payor]
	, d.[Medical Service Code]
	, d.[Service Code Description]
	, d.[Payment] as [Payment Amount]
	, d.[Prim] as [Payment Type]
	, d.[Type Description] as [Payment Type Description]
	, 'Outpatient' as [Receivable Type]
	, d.[HCRA Line]
	, d.[HCRA Line Description]
	, d.[Payment Received Date] as [Payment Entry Date]
	, '' as [PIP Flag]
	, '' AS COPAY_FLAG
	, '' AS COPAY_POSITIVE_PAY
	, '' AS COPAY_NEGATIVE_PAY
	, '' AS DEDUCTIBLE_FLAG
	, '' AS DEDUC_POSITIVE_PAY
	, '' AS DEDUC_NEGATIVE_PAY
	, '' AS COINSURANCE_FLAG
	, '' AS COINS_POSITIVE_PAY
	, '' AS COINS_NEGATIVE_PAY
	, '' AS UN_ID_FLAG
	, '' AS UN_ID_POS_PAY
	, '' AS UN_ID_NEG_PAY

	from #temp_d as d
) A

--

select *
from smsdss.c_HCRA_Static_Data_w_TIN_EMM_2016

--drop table #temp_a, #temp_b, #temp_c, #temp_d
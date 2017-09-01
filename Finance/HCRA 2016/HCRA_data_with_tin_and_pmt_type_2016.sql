select a.pk
, a.[reference number]
, a.[system]
, a.mrn
, a.[admit date]
, a.[discharge date]
, a.[payor code]
, a.[payor code description]
, a.[payor sub-code]
, a.[payor id number]
, a.[payor city]
, a.[payor state]
, a.[payor tin]
, a.[primary payor]
, a.[secondary payor]
, a.[tertiary payor]
, a.[quaternary payor]
, a.[primary v secondary indicator]
, a.[risk sharing payor]
, a.[direct/non direct payor]
, a.[medical service code]
, a.[service code description]
, a.[payment amount]
, a.[payment type]
, a.[payment type description]
, a.[receivable type]
, a.[hcra line]
, a.[hcra line description]
, a.[payment entry date]
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
, CASE
	WHEN A.[Payment Type] != 'Self Pay'
		THEN CAST('0' AS MONEY)
	ELSE B.[Total Self Pay Amt]
  END AS [TOTAL SELF PAY AMT]
  
-- CASE STATEMENT TO FOLLOW IN ORDER TRY AND DECIFER WHAT TYPE OF PAYMENT WAS MADE
	/*
	When the Payment Type is NOT Self Pay then just use the Payment Type which will
	be INS1, INS2, INS3 or INS4
	*/
, CASE
	WHEN A.[Payment Type] != 'Self Pay'
		THEN A.[Payment Type] + ' Payment'
	
	/*
	When there is no patient payment then make notice of that, we do not need to use
	the logic of payor code equal to self pay because this column comes from the mir_pay
	table with appropriate patient payment pip codes
	*/
	WHEN (
		B.[TOTAL SELF PAY AMT] IS NULL
		OR
		B.[Total Self Pay Amt] = 0
	)
		THEN 'No Patient Payment'
	
	/*
	When there is a patient payment but there is not dollar amount associated to a 
	copay deductible or coinsurance then 'Patient Payment'
	*/
	WHEN (
		B.[Total Self Pay Amt] != 0
		AND A.[Payment Type] = 'Self Pay'
		AND A.[COPAY_NEGATIVE_PAY] = 0
		AND A.[DEDUC_NEGATIVE_PAY] = 0
		AND A.[COINS_NEGATIVE_PAY] = 0
	)
		THEN 'Patient Payment'
	/*
	When the payment type is Self Pay AND the UN_ID_NEG_PAY does NOT EQUAL 0 AND
	the Total Self Pay Amount does NOT EQUAL $0 THEN unsure
	of payment type
	*/
	WHEN (
		A.[Payment Type] = 'Self Pay'
		AND A.[UN_ID_NEG_PAY] != 0
		AND B.[Total Self Pay Amt] != 0
	)
	OR (
		A.[Payment Type] = 'Self Pay'
		AND A.[UN_ID_NEG_PAY] !=0
		AND	B.[Total Self Pay Amt] = 0
	)
		THEN 'Unsure of Patient Payment Type'
	
	/*
	When the sum of total patient payments > 0 AND is less than the sum of co-pay, deductible and or
	co-insurance then patient paying
	*/
	WHEN A.[Payment Type] = 'Self Pay'
		AND B.[Total Self Pay Amt] IS NOT NULL
		AND A.UN_ID_NEG_PAY = 0
		AND (
			B.[Total Self Pay Amt] > (
					A.[COINS_NEGATIVE_PAY] + A.[DEDUC_NEGATIVE_PAY] + A.[COPAY_NEGATIVE_PAY]
				)
		)
		AND (
			(A.[COINS_NEGATIVE_PAY] != 0 AND A.[DEDUC_NEGATIVE_PAY] != 0)
			OR
			(A.[COINS_NEGATIVE_PAY] != 0 AND A.[COPAY_NEGATIVE_PAY] != 0)
			OR
			(A.[DEDUC_NEGATIVE_PAY] != 0 AND A.[COPAY_NEGATIVE_PAY] != 0)
		)
		THEN 'Patient Making Payments'
	
	/*
	Here we only want a copay payment
	*/
	WHEN A.[Payment Type] = 'Self Pay'
		AND A.[UN_ID_NEG_PAY] = 0
		AND (
			B.[Total Self Pay Amt] = A.[COPAY_NEGATIVE_PAY]
			OR
			B.[Total Self Pay Amt] != A.[COPAY_NEGATIVE_PAY]
		)
		AND A.[COPAY_NEGATIVE_PAY] != 0
		AND (
			A.[DEDUC_NEGATIVE_PAY] = 0
			AND
			A.[COINS_NEGATIVE_PAY] = 0
		)
		THEN 'Patient Co-Pay Payment'
		
	/*
	Here we only want a deductible payment
	*/
	WHEN A.[Payment Type] = 'Self Pay'
		AND A.[UN_ID_NEG_PAY] = 0
		AND (
			B.[Total Self Pay Amt] = A.[DEDUC_NEGATIVE_PAY]
			OR
			B.[Total Self Pay Amt] != A.[DEDUC_NEGATIVE_PAY]
		)
		AND A.[DEDUC_NEGATIVE_PAY] != 0
		AND (
			A.[COPAY_NEGATIVE_PAY] = 0
			AND
			A.[COINS_NEGATIVE_PAY] = 0
		)
		THEN 'Patient Deductible Payment'
	
	/*
	Here we want only Coinsurance payments
	*/
	WHEN A.[Payment Type] = 'Self Pay'
		AND A.[UN_ID_NEG_PAY] = 0
		AND (
			B.[Total Self Pay Amt] = A.[COINS_NEGATIVE_PAY]
			OR
			B.[Total Self Pay Amt] != A.[COINS_NEGATIVE_PAY]
		)
		AND A.[COINS_NEGATIVE_PAY] != 0
		AND (
			A.[COPAY_NEGATIVE_PAY] = 0
			AND
			A.[DEDUC_NEGATIVE_PAY] = 0
		)
		THEN 'Patient Coinsurance Payment'
	/*
	When the total patient payment is equal to the sum of all the three fields
	then payment type of 'Co-Pay, Deductible and Co-Insurance'
	*/
	WHEN  A.[Payment Type] = 'Self Pay'
	AND A.[UN_ID_NEG_PAY] = 0
	AND (
		B.[TOTAL SELF PAY AMT] = (A.[COPAY_NEGATIVE_PAY] + A.[DEDUC_NEGATIVE_PAY] + A.[COINS_NEGATIVE_PAY])
		OR
		B.[TOTAL SELF PAY AMT] != (A.[COPAY_NEGATIVE_PAY] + A.[DEDUC_NEGATIVE_PAY] + A.[COINS_NEGATIVE_PAY])
	)
		THEN 'Co-Pay, Deductible and Co-Insurance'
	
	/*
	When there is no valued co-pay, deductible or co-insurance field and there is a 
	patient payment then the payment type is 'Patient Responsibility'
	*/
	WHEN (
		A.COPAY_FLAG IS NULL
		AND
		A.DEDUCTIBLE_FLAG IS NULL
		AND
		A.COINSURANCE_FLAG IS NULL
		AND
		B.[TOTAL SELF PAY AMT] IS NOT NULL
	)
		THEN 'Patient Responsibility'

  END AS FLAG_A

into #temp_a

from smsdss.c_HCRA_Static_Data_w_TIN_2016 as a
left join smsdss.c_HCRA_Self_Pay_Totals_2016 as b
on A.[Reference Number] = SUBSTRING(B.PT_ID, 5, 8)

---------------------------------------------------------------------------------------------------

select a.pk
, a.[reference number]
, a.[Unit Seq No]
, a.[system]
, a.mrn
, a.[admit date]
, a.[discharge date]
, a.[payor code]
, a.[payor code description]
, a.[payor sub-code]
, a.[payor id number]
, a.[payor city]
, a.[payor state]
, a.[payor tin]
, a.[primary payor]
, a.[secondary payor]
, a.[tertiary payor]
, a.[quaternary payor]
, a.[primary v secondary indicator]
, a.[risk sharing payor]
, a.[direct/non direct payor]
, a.[medical service code]
, a.[service code description]
, a.[payment amount]
, a.[payment type]
, a.[payment type description]
, a.[receivable type]
, a.[hcra line]
, a.[hcra line description]
, a.[payment entry date]
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
, CASE
	WHEN A.[Payment Type] != 'Self Pay'
		THEN CAST('0' AS MONEY)
	ELSE B.[Total_Self_Pay_Amt]
  END AS [TOTAL SELF PAY AMT]
  
-- CASE STATEMENT TO FOLLOW IN ORDER TRY AND DECIFER WHAT TYPE OF PAYMENT WAS MADE
	/*
	When the Payment Type is NOT Self Pay then just use the Payment Type which will
	be INS1, INS2, INS3 or INS4
	*/
, CASE
	WHEN A.[Payment Type] != 'Self Pay'
		THEN A.[Payment Type] + ' Payment'
	
	/*
	When there is no patient payment then make notice of that, we do not need to use
	the logic of payor code equal to self pay because this column comes from the mir_pay
	table with appropriate patient payment pip codes
	*/
	WHEN (
		B.[TOTAL_SELF_PAY_AMT] IS NULL
		OR
		B.[Total_Self_Pay_Amt] = 0
	)
		THEN 'No Patient Payment'
	
	/*
	When there is a patient payment but there is not dollar amount associated to a 
	copay deductible or coinsurance then 'Patient Payment'
	*/
	WHEN (
		B.[Total_Self_Pay_Amt] != 0
		AND A.[Payment Type] = 'Self Pay'
		AND A.[COPAY_NEGATIVE_PAY] = 0
		AND A.[DEDUC_NEGATIVE_PAY] = 0
		AND A.[COINS_NEGATIVE_PAY] = 0
	)
		THEN 'Patient Payment'
	/*
	When the payment type is Self Pay AND the UN_ID_NEG_PAY does NOT EQUAL 0 AND
	the Total Self Pay Amount does NOT EQUAL $0 THEN unsure
	of payment type
	*/
	WHEN (
		A.[Payment Type] = 'Self Pay'
		AND A.[UN_ID_NEG_PAY] != 0
		AND B.[Total_Self_Pay_Amt] != 0
	)
	OR (
		A.[Payment Type] = 'Self Pay'
		AND A.[UN_ID_NEG_PAY] !=0
		AND	B.[Total_Self_Pay_Amt] = 0
	)
		THEN 'Unsure of Patient Payment Type'
	
	/*
	When the sum of total patient payments > 0 AND is less than the sum of co-pay, deductible and or
	co-insurance then patient paying
	*/
	WHEN A.[Payment Type] = 'Self Pay'
		AND B.[Total_Self_Pay_Amt] IS NOT NULL
		AND A.UN_ID_NEG_PAY = 0
		AND (
			B.[Total_Self_Pay_Amt] > (
					A.[COINS_NEGATIVE_PAY] + A.[DEDUC_NEGATIVE_PAY] + A.[COPAY_NEGATIVE_PAY]
				)
		)
		AND (
			(A.[COINS_NEGATIVE_PAY] != 0 AND A.[DEDUC_NEGATIVE_PAY] != 0)
			OR
			(A.[COINS_NEGATIVE_PAY] != 0 AND A.[COPAY_NEGATIVE_PAY] != 0)
			OR
			(A.[DEDUC_NEGATIVE_PAY] != 0 AND A.[COPAY_NEGATIVE_PAY] != 0)
		)
		THEN 'Patient Making Payments'
	
	/*
	Here we only want a copay payment
	*/
	WHEN A.[Payment Type] = 'Self Pay'
		AND A.[UN_ID_NEG_PAY] = 0
		AND (
			B.[Total_Self_Pay_Amt] = A.[COPAY_NEGATIVE_PAY]
			OR
			B.[Total_Self_Pay_Amt] != A.[COPAY_NEGATIVE_PAY]
		)
		AND A.[COPAY_NEGATIVE_PAY] != 0
		AND (
			A.[DEDUC_NEGATIVE_PAY] = 0
			AND
			A.[COINS_NEGATIVE_PAY] = 0
		)
		THEN 'Patient Co-Pay Payment'
		
	/*
	Here we only want a deductible payment
	*/
	WHEN A.[Payment Type] = 'Self Pay'
		AND A.[UN_ID_NEG_PAY] = 0
		AND (
			B.[Total_Self_Pay_Amt] = A.[DEDUC_NEGATIVE_PAY]
			OR
			B.[Total_Self_Pay_Amt] != A.[DEDUC_NEGATIVE_PAY]
		)
		AND A.[DEDUC_NEGATIVE_PAY] != 0
		AND (
			A.[COPAY_NEGATIVE_PAY] = 0
			AND
			A.[COINS_NEGATIVE_PAY] = 0
		)
		THEN 'Patient Deductible Payment'
	
	/*
	Here we want only Coinsurance payments
	*/
	WHEN A.[Payment Type] = 'Self Pay'
		AND A.[UN_ID_NEG_PAY] = 0
		AND (
			B.[Total_Self_Pay_Amt] = A.[COINS_NEGATIVE_PAY]
			OR
			B.[Total_Self_Pay_Amt] != A.[COINS_NEGATIVE_PAY]
		)
		AND A.[COINS_NEGATIVE_PAY] != 0
		AND (
			A.[COPAY_NEGATIVE_PAY] = 0
			AND
			A.[DEDUC_NEGATIVE_PAY] = 0
		)
		THEN 'Patient Coinsurance Payment'
	/*
	When the total patient payment is equal to the sum of all the three fields
	then payment type of 'Co-Pay, Deductible and Co-Insurance'
	*/
	WHEN  A.[Payment Type] = 'Self Pay'
	AND A.[UN_ID_NEG_PAY] = 0
	AND (
		B.[Total_Self_Pay_Amt] = (A.[COPAY_NEGATIVE_PAY] + A.[DEDUC_NEGATIVE_PAY] + A.[COINS_NEGATIVE_PAY])
		OR
		B.[Total_Self_Pay_Amt] != (A.[COPAY_NEGATIVE_PAY] + A.[DEDUC_NEGATIVE_PAY] + A.[COINS_NEGATIVE_PAY])
	)
		THEN 'Co-Pay, Deductible and Co-Insurance'
	
	/*
	When there is no valued co-pay, deductible or co-insurance field and there is a 
	patient payment then the payment type is 'Patient Responsibility'
	*/
	WHEN (
		A.COPAY_FLAG IS NULL
		AND
		A.DEDUCTIBLE_FLAG IS NULL
		AND
		A.COINSURANCE_FLAG IS NULL
		AND
		B.[Total_Self_Pay_Amt] IS NOT NULL
	)
		THEN 'Patient Responsibility'

  END AS FLAG_A

into #temp_b

from smsdss.c_HCRA_Static_Data_w_TIN_Unitized_2016 as a
left join smsdss.c_hcra_self_pay_totals_unitized_2016 as b
on A.[Reference Number] = SUBSTRING(B.PT_ID, 5, 8)
	and a.[Unit Seq No] = b.UNIT_SEQ_NO

---------------------------------------------------------------------------------------------------
select a.*

into #temp_c

from (
	select cast(a.[reference number] as varchar) + cast(pk as varchar) as [Reference Number]
	, a.[system]
	, a.mrn
	, a.[admit date]
	, a.[discharge date]
	, a.[payor code]
	, a.[payor code description]
	, a.[payor sub-code]
	, a.[payor id number]
	, a.[payor city]
	, a.[payor state]
	, a.[payor tin]
	, a.[primary payor]
	, a.[secondary payor]
	, a.[tertiary payor]
	, a.[quaternary payor]
	, a.[primary v secondary indicator]
	, a.[risk sharing payor]
	, a.[direct/non direct payor]
	, a.[medical service code]
	, a.[service code description]
	, a.[payment amount]
	, a.[payment type]
	, a.[payment type description]
	, a.[receivable type]
	, a.[hcra line]
	, a.[hcra line description]
	, a.[payment entry date]
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
	, a.FLAG_A

	from #temp_a as a

	union all

	select cast(a.[reference number] as varchar) + cast(a.[unit seq no] as varchar) + cast(a.pk as varchar) as [Reference Number]
	, a.[system]
	, a.mrn
	, a.[admit date]
	, a.[discharge date]
	, a.[payor code]
	, a.[payor code description]
	, a.[payor sub-code]
	, a.[payor id number]
	, a.[payor city]
	, a.[payor state]
	, a.[payor tin]
	, a.[primary payor]
	, a.[secondary payor]
	, a.[tertiary payor]
	, a.[quaternary payor]
	, a.[primary v secondary indicator]
	, a.[risk sharing payor]
	, a.[direct/non direct payor]
	, a.[medical service code]
	, a.[service code description]
	, a.[payment amount]
	, a.[payment type]
	, a.[payment type description]
	, a.[receivable type]
	, a.[hcra line]
	, a.[hcra line description]
	, a.[payment entry date]
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
	, a.FLAG_A

	from #temp_b as a

	union all

	select cast(a.[reference number] as varchar) + cast(a.pk as varchar) as [Reference Number]
		, 'ADS' as [system]
		, a.mrn
		, a.[admit date]
		, a.[discharge date]
		, a.[payor code]
		, a.[payor code description]
		, a.[payor sub-code]
		, a.[payor id number]
		, a.[payor city]
		, a.[payor state]
		, a.[payor tin]
		, a.[primary payor]
		, a.[secondary payor]
		, a.[tertiary payor]
		, a.[quaternary payor]
		, a.[primary v secondary indicator]
		, a.[risk sharing payor]
		, a.[direct/non direct payor]
		, a.[medical service code]
		, a.[service code description]
		, a.[payment amount]
		, a.[payment type]
		, a.[payment type description]
		, a.[receivable type]
		, a.[hcra line]
		, a.[hcra line description]
		, a.[payment entry date]
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
		, '' as FLAG_A

	from smsdss.c_HCRA_Static_Data_w_TIN_EMM_2016 as a
) a

---------------------------------------------------------------------------------------------------

select a.[Reference Number]
, left(a.[reference number], 8) as test_pt_id
, a.[System]
, a.[MRN]
, a.[Admit Date]
, a.[Discharge Date]
, b.adm_date
, b.dsch_date
, case
	when a.[Admit Date] IS null 
		then b.adm_date
	else a.[Admit Date]
  end as [Admit Date Test]
, case
	when a.[Discharge Date] IS NULL
		and b.dsch_date IS NULL
		then b.adm_date
	when a.[Discharge Date] IS NULL
		then b.dsch_date
	else a.[Discharge Date]
  end as [Discharge Date Test]
, case
	when a.[System] = 'ADS'
		and a.[payor code] is null
		and a.[Payment Type Description] like '%patient%'
		then 'Self'
	when a.[system] = 'ads'
		and a.[payor code] is null
		and a.[Payment Type Description] like '%medic%'
		then 'MDCD'
	else a.[Payor Code]
  end as [Payor Code]
, case 
	when a.[Payor Code Description] is null
		and a.[Payment Type Description] like '%medic%'
		then 'MEDICAID'
	else a.[Payor Code Description]
  end as [Payor Code Description]
, '' as [Payor Sub-Code]
, a.[Payor ID Number]
, a.[Payor City]
, a.[Payor State]
, a.[Payor TIN]
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
, case 
	when a.[System] = 'ADS' 
	and a.[Payment Type] is null
	and a.[Payment Type Description] like '%medic%'
		then 'MEDICAID'
	else a.[Payment Type Description]
  end as [Payment Description]
, case
	when a.[system] = 'fms'
		then coalesce(a.[Flag_A], a.[Payment Type Description])
	else a.[Payment Type Description]
  end as [Payment Type Description]
, a.[Receivable Type]
, a.[HCRA Line]
, a.[HCRA Line Description]
, a.[Payment Entry Date]
, a.[PIP Flag]

into #temp_d

from #temp_c a
left merge join smsmir.vst_rpt as b
on left(a.[reference number], 8) = substring(b.pt_id, 5, 8)
	and left(a.[reference number], 1) != '7'
	and left(a.[reference number], 8) not in (
		'53040861', '53919940'
	)

--where a.[Reference Number] = ''
--where a.[admit date] is null
--and a.[discharge date] is null

---------------------------------------------------------------------------------------------------

select a.[Reference Number]
, a.[System]
, a.MRN
, cast(a.[Admit Date Test] as date) as [Admit Date]
, CAST(a.[discharge date test] as date) as [Discharge Date]
, a.[Payor Code]
, a.[Payor Code Description]
, a.[Payor Sub-Code]
, a.[Payor ID Number]
, a.[Payor City]
, a.[Payor State]
, a.[Payor TIN]
, a.[Primary Payor]
, a.[Secondary Payor]
, a.[Tertiary Payor]
, a.[Quaternary Payor]
, a.[Primary v Secondary Indicator]
, a.[Risk Sharing Payor]
, a.[Direct/Non Direct Payor]
, a.[Medical Service Code]
, a.[Service Code Description]
, ISNULL(a.[Payment Amount], 0) as [Payment Amount]
, a.[Payment Description]
, a.[Receivable Type]
, a.[HCRA Line]
, a.[HCRA Line Description]
, a.[Payment Entry Date]
, a.[PIP Flag]

into #temp_e

from #temp_d as a

---------------------------------------------------------------------------------------------------

select a.[Reference Number]
, a.[System]
, a.[MRN]
, a.[Admit Date]
, a.[Discharge Date]
, coalesce(
	b.[new_pyr_cd], c.[new_pyr_cd], 
	d.[new_pyr_cd], e.[new_pyr_cd], 
	xxx.new_pyr_cd, yyy.new_pyr_cd,
	zzz.new_pyr_cd, a.[Payor Code]
) as [Payor Code]
, zzz.new_pyr_cd
, zzz.pyr_cd
--, a.[Payor Code Description]
, case
	when (
		a.[Payor Code] in ('n09','n10','n30')
		and a.[Payor Code Description] = 'no fault'
	)
		then coalesce(zzz.ins_co, a.[payor code description])
	when (
		a.[Payor Code] in ('c05') 
		and a.[Payor Code Description] like 'Worker%s Comp'
		and yyy.insurance_company != ''
	)
		then coalesce(yyy.insurance_company, a.[payor code description])
	else a.[Payor Code Description]
  end as [Payor Code Description]
, a.[Payor Sub-Code]
, a.[Payor ID Number]
, a.[Payor City]
, a.[Payor State]
, a.[Payor TIN]
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
, a.[Payment Description]
, a.[Receivable Type]
, a.[HCRA Line]
, a.[HCRA Line Description]
, a.[Payment Entry Date]
, a.[PIP Flag]
, zzz.ins_co

into #temp_f

from #temp_e as a
left join smsdss.c_hcra_e36_seq_tbl as b
on a.[Payor Code] = B.[payor code]
	and a.[Payor Code Description] = B.[payor code description]
left join smsdss.c_hcra_x36_seq_tbl as c
on a.[Payor Code] = C.[payor code]
	and a.[Payor Code Description] = C.[payor code description]
left join smsdss.c_hcra_i09_seq_tbl as d
on a.[Payor Code] = d.[payor code]
	and a.[Payor Code Description] = d.[payor code description]
left join smsdss.c_hcra_k20_seq_tbl as e
on a.[Payor Code] = E.[payor code]
	and a.[Payor Code Description] = E.[payor code description]
left join smsdss.c_hcra_no_fault_researched_internally_2016 as zzz
on left(a.[reference number], 8) = zzz.encounter
	and left(a.[Payor Code],3) = zzz.pyr_cd
-- add j36 seq tbl
left join smsdss.c_hcra_j36_seq_tbl as xxx
on a.[Payor Code] = xxx.[payor code]
	and a.[Payor Code Description] = xxx.[payor code description]
-- add c05 wip
left join smsdss.c_hcra_c05_wip_internal_research yyy
on a.[Reference Number] = yyy.[reference number]
	--and a.[Payor Code] = yyy.[payor code]
	--and a.[Payor Code Description] = yyy.[payor code description]


--where a.[System] = 'fms'
--and a.[Payor Code] = 'c05'

---------------------------------------------------------------------------------------------------

select a.[Reference Number]
, a.[System]
, a.[MRN]
, a.[Admit Date]
, a.[Discharge Date]
, case
	when a.[Payor Code] = ''
	and a.[reference number] = d.[reference number]
		then d.[payor code]
	else a.[payor code]
  end as [Payor Code]
, case
	when a.[reference number] = d.[reference number]
	and a.[payor code description] = ''
		then d.[payor code description]
		else coalesce(b.[ins_co], a.[payor code description]) 
  end as [Payor Code Description]
, a.[Payor ID Number]
, coalesce(b.[city], a.[Payor City]) as [Payor City]
, coalesce(b.[State], a.[Payor State]) as [Payor State]
, a.[Payor TIN]
--, a.[Primary Payor]
, case 
	when a.[Primary Payor] = '' 
		then c.Pyr1_Co_Plan_Cd
		else a.[Primary Payor]
  end as [Primary Payor]
, case
	when a.[Secondary Payor] = ''
		then c.Pyr2_Co_Plan_Cd
		else a.[Secondary Payor]
  end as [Secondary Payor]
, case
	when a.[Tertiary Payor] = ''
		then c.Pyr3_Co_Plan_Cd
		else a.[Tertiary Payor]
  end as [Tertiary Payor]
, case
	when a.[Quaternary Payor] = ''
		then c.Pyr4_Co_Plan_Cd
		else a.[Quaternary Payor]
  end as [Quaternary Payor]
, a.[Primary v Secondary Indicator]
, a.[Risk Sharing Payor]
, a.[Direct/Non Direct Payor]
, a.[Medical Service Code]
, a.[Service Code Description]
, a.[Payment Amount]
, a.[Payment Description]
, a.[Receivable Type]
, a.[HCRA Line]
, a.[HCRA Line Description]
, a.[Payment Entry Date]
, a.[PIP Flag]
, rn = ROW_NUMBER() over(partition by a.[reference number] order by a.[reference number])

into #temp_g

from #temp_f as a
left join [smsdss].[c_HCRA_nf_wc_internal] as b
on a.[Payor Code] = B.[Payor code]
left join smsdss.BMH_PLM_PtAcct_V as c
on left(a.[Reference Number], 8) = c.PtNo_Num
	and c.PtNo_Num not in (
			'53040861', '53919940'
		)
	and LEFT(c.ptno_num, 1) != '7'
left join smsdss.c_hcra_blank_pyr_cd_and_desc as d
on a.[reference number] = d.[reference number]

---------------------------------------------------------------------------------------------------

SELECT a.[Reference Number]
, a.[System]
, a.[MRN]
, a.[Admit Date]
, a.[Discharge Date]
, CASE
	WHEN B.[Payor Code] IS NULL
		THEN a.[Payor Code]
	WHEN B.[Payor Code] IN ('S93', 'W29')
		THEN LEFT(B.[Payor Code], 3)
	WHEN B.[Payor Code] NOT IN ('S93', 'W29')
		AND B.[Payor Code] IS NOT NULL
		THEN B.[new_pyr_cd]
	ELSE a.[Payor Code]
  END AS [Payor Code]
, CASE
	WHEN B.[Payor Code] IS NULL
		THEN a.[Payor Code Description]
	WHEN B.[Payor Code] IN ('S93', 'W29')
		THEN B.[Payor Description]
	WHEN B.[Payor Code] NOT IN ('S93', 'W29')
		AND B.[Payor Code] IS NOT NULL
		THEN B.[Payor Description]
	ELSE a.[Payor Code Description]
  END AS [Payor Code Description]
, a.[Payor ID Number]
, a.[Payor City]
, a.[Payor State]
, CASE
	WHEN B.[REFERENCE NUMBER] IS NOT NULL
		THEN ''
		ELSE a.[Payor TIN]
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
, a.[Payment Description]
, a.[Receivable Type]
, a.[HCRA Line]
, a.[HCRA Line Description]
, a.[Payment Entry Date]
, a.[PIP Flag]

into #temp_h

from #temp_g as a
left join smsdss.c_hcra_pyr_cd_d93_d97_w31 as b
on a.[Reference Number] = B.[reference number]

where a.rn = 1

---------------------------------------------------------------------------------------------------

select COUNT(a.[reference number])

from #temp_h as a

---------------------------------------------------------------------------------------------------

-- Get control totals by pip, non-pip, unitized pip and non pip and finally ads/emm
select DATEPART(year, [payment entry date]) as pmt_yr
, DATEPART(month, [payment entry date]) as pmt_mo
, SUM([payment amount]) as pmt_amt

into #temp_pmt_nonunitized_pip

from #temp_h 

where [PIP Flag] = 'pip'
and [System] = 'fms'
and LEFT([reference number], 1) != '7'

group by DATEPART(year, [payment entry date])
, DATEPART(month, [payment entry date])

-----

select DATEPART(year, [payment entry date]) as pmt_yr
, DATEPART(month, [payment entry date]) as pmt_mo
, SUM([payment amount]) as pmt_amt

into #temp_pmt_unitized_pip

from #temp_h 

where [PIP Flag] = 'pip'
and [System] = 'fms'
and LEFT([reference number], 1) = '7'

group by DATEPART(year, [payment entry date])
, DATEPART(month, [payment entry date])

-----

select DATEPART(year, [payment entry date]) as pmt_yr
, DATEPART(month, [payment entry date]) as pmt_mo
, SUM([payment amount]) as pmt_amt

into #temp_pmt_nonunitized_nonpip

from #temp_h 

where [PIP Flag] = 'NON-PIP'
and [System] = 'fms'
and LEFT([reference number], 1) != '7'

group by DATEPART(year, [payment entry date])
, DATEPART(month, [payment entry date])

-----

select DATEPART(year, [payment entry date]) as pmt_yr
, DATEPART(month, [payment entry date]) as pmt_mo
, SUM([payment amount]) as pmt_amt

into #temp_pmt_unitized_nonpip

from #temp_h 

where [PIP Flag] = 'NON-PIP'
and [System] = 'fms'
and LEFT([reference number], 1) = '7'

group by DATEPART(year, [payment entry date])
, DATEPART(month, [payment entry date])

-----

select DATEPART(year, [payment entry date]) as pmt_yr
, DATEPART(month, [payment entry date]) as pmt_mo
, SUM([payment amount]) as pmt_amt

into #temp_pmt_fms_nonpip

from #temp_h 

where [PIP Flag] = 'NON-PIP'
and [System] = 'fms'

group by DATEPART(year, [payment entry date])
, DATEPART(month, [payment entry date])

-----

select DATEPART(year, [payment entry date]) as pmt_yr
, DATEPART(month, [payment entry date]) as pmt_mo
, SUM([payment amount]) as pmt_amt

into #temp_pmt_fms_pip

from #temp_h 

where [PIP Flag] = 'PIP'
and [System] = 'fms'

group by DATEPART(year, [payment entry date])
, DATEPART(month, [payment entry date])

-----

select DATEPART(year, [payment entry date]) as pmt_yr
, DATEPART(month, [payment entry date]) as pmt_mo
, SUM([payment amount]) as pmt_amt

into #temp_pmt_ads

from #temp_h 

where [System] = 'ads'

group by DATEPART(year, [payment entry date])
, DATEPART(month, [payment entry date])

-----

select a.pmt_yr
, a.pmt_mo
, a.pmt_amt as [non-unitized non-pip]
, b.pmt_amt as [non-unitized pip]
, c.pmt_amt as [unitized non-pip]
, d.pmt_amt as [unitized pip]
, e.pmt_amt as [fms non-pip]
, f.pmt_amt as [fms pip]
, g.pmt_amt as [ads]

from #temp_pmt_nonunitized_nonpip as a
left join #temp_pmt_nonunitized_pip as b
on a.pmt_yr = b.pmt_yr
	and a.pmt_mo = b.pmt_mo
left join #temp_pmt_unitized_nonpip as c
on a.pmt_yr = c.pmt_yr
	and a.pmt_mo = c.pmt_mo
left join #temp_pmt_unitized_pip as d
on a.pmt_yr = d.pmt_yr
	and a.pmt_mo = d.pmt_mo
left join #temp_pmt_fms_nonpip as e
on a.pmt_yr = e.pmt_yr
	and a.pmt_mo = e.pmt_mo
left join #temp_pmt_fms_pip as f
on a.pmt_yr = f.pmt_yr
	and a.pmt_mo = f.pmt_mo
left join #temp_pmt_ads as g
on a.pmt_yr = g.pmt_yr
	and a.pmt_mo = g.pmt_mo

order by a.pmt_yr, a.pmt_mo
---------------------------------------------------------------------------------------------------

--drop table #temp_a, #temp_b, #temp_c, #temp_d, #temp_e, #temp_f, #temp_g, #temp_h

---------------------------------------------------------------------------------------------------
SELECT A.[Reference Number]
, A.[Primary Payor]
, A.[Payment Amount]
, A.[Payment Type]
, A.[COPAY_POSITIVE_PAY]
, A.[COPAY_NEGATIVE_PAY]
, A.[DEDUC_POSITIVE_PAY]
, A.[DEDUC_NEGATIVE_PAY]
, A.[COINS_POSITIVE_PAY]
, A.[COINS_NEGATIVE_PAY]
, A.[UN_ID_POS_PAY]
, A.[UN_ID_NEG_PAY]
, B.[Total Self Pay Amt]
, CASE
	WHEN A.[Payment Type] != 'Self Pay'
		THEN CAST('0' AS MONEY)
	ELSE B.[Total Self Pay Amt]
  END AS [TOTAL SELF PAY AMT]
  
-- CAST STATEMENT TO FOLLOW IN ORDER TRY AND DECIFER WHAT TYPE OF PAYMENT WAS MADE
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

FROM smsdss.c_EmpireExchange_Static_Data_2016 AS A
LEFT JOIN smsdss.c_EmpireExchange_SELF_PAY_TOTALS_2016 AS B
ON A.[Reference Number] = SUBSTRING(B.PT_ID, 5, 8)
;
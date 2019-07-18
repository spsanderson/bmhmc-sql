-- Get all relevant data IN order to perform the process of getting pay codes
-- AND their associated description for the HCRA related payments
SELECT '0000' + LEFT(a.[Reference Number], 8) AS [Encounter]
, a.[Reference Number]
, a.[Payment Amount]
, a.[Payment Entry Date]
, CASE
	WHEN a.[Payor Code] = 'MIS'
		THEN '*'
		else a.[Payor Code]
  END AS [Payor Code]
, a.[Primary Payor]
, a.[Secondary Payor]
, a.[Tertiary Payor]
, a.[Quaternary Payor]

INTO #temp1

FROM smsdss.c_HCRA_FMS_Rpt_Tbl_2016 AS a

--SELECT * FROM #temp1

---------------------------------------------------------------------------------------------------
-- Get just the Self Pay records for this step
SELECT a.[Reference Number]
, a.Encounter
, a.[Payment Amount]
, a.[Payment Entry Date]
, a.[Payor Code]
, a.[Primary Payor]
, a.[Secondary Payor]
, a.[Tertiary Payor]
, a.[Quaternary Payor]
, b.pt_id
, b.pay_cd
, c.pay_cd_name

INTO #temp2

FROM #temp1 AS a
-- just get the self pay pay_cd descriptions
LEFT JOIN smsmir.pay AS b
ON a.Encounter = b.pt_id
	AND a.[Payor Code] = b.pyr_cd
	AND a.[Payor Code] = '*'
	AND a.[Payment Amount] = b.tot_pay_adj_amt
	AND a.[Payment Entry Date] = b.pay_entry_date
	AND (b.pay_cd BETWEEN '09600000' AND '09699999'
	OR b.pay_cd BETWEEN '00990000' AND '00999999'
	OR b.pay_cd BETWEEN '09900000' AND '09999999'
	OR b.pay_cd IN (
		'00980300','00980409','00980508','00980607','00980656','00980706',
		'00980755','00980805','00980813','00980821','09800095','09800277',
		'09800301','09800400','09800459','09800509','09800558','09800608',
		'09800707','09800715','09800806','09800814','09800905','09800913',
		'09800921','09800939','09800947','09800962','09800970','09800988',
		'09800996','09801002','09801010','09801028','09801036','09801044',
		'09801051','09801069','09801077','09801085','09801093','09801101',
		'09801119'
		)
	)
LEFT JOIN smsdss.pay_cd_dim_v AS c
ON b.pay_cd = c.pay_cd

--WHERE [Encounter] = ''

ORDER BY a.[Reference Number]
;

--SELECT * FROM #temp2;

---------------------------------------------------------------------------------------------------
-- Use pt_id, payment amount AND payment date AND primary payor code to get pay codes AND desc
-- for payments made by the primary payor, WHERE the primary payor is not self pay AS those
-- are obtained FROM the above section, do the same join for secondary, tertiary AND quaternary
SELECT a.[Reference Number]
, a.Encounter
, a.[Payment Amount]
, a.[Payment Entry Date]
, a.[Payor Code]
, a.[Primary Payor]
, a.[Secondary Payor]
, a.[Tertiary Payor]
, a.[Quaternary Payor]
, a.pt_id AS [Self Pay Pt_ID]
, a.pay_cd AS [Self Pay Pay Cd]
, a.pay_cd_name AS [Self Pay Pay Cd Desc]
--, a.rn AS [Self Pay RN]
, b.pt_id AS [Primary Payor PT_ID]
, b.pay_cd AS [Primary Pay Cd]
, c.pay_cd_name AS [Primary Pay Cd Desc]
, d.pt_id AS [Secondary Payor PT_ID]
, d.pay_cd AS [Secondary Pay Cd]
, e.pay_cd_name AS [Secondary Pay Cd Desc]
, f.pt_id AS [Tertiary Payor PT_ID]
, f.pay_cd AS [Tertiary Pay Cd]
, g.pay_cd_name AS [Tertiary Pay Cd Desc]
, h.pt_id AS [Quaternary Payor PT_ID]
, h.pay_cd AS [Quaternary Pay Cd]
, i.pay_cd_name AS [Quaternary Pay Cd Desc]
--, COALESCE(a.pay_cd, b.pay_cd, d.pay_cd, f.pay_cd, h.pay_cd) AS [Pay_Cd]
--, COALESCE(a.pay_cd_desc, c.pay_cd_desc, e.pay_cd_desc, g.pay_cd_desc, i.pay_cd_desc) AS [Pay Cd Desc]

INTO #temp3

FROM #temp2 AS a
-- Get the Primary Payor Data
LEFT JOIN smsmir.pay AS b
ON a.Encounter = b.pt_id
	AND a.[Primary Payor] = b.pyr_cd
	AND a.[Payment Amount] = b.tot_pay_adj_amt
	AND a.[Payment Entry Date] = b.pay_entry_date
	AND (b.pay_cd BETWEEN '09600000' AND '09699999'
	OR b.pay_cd BETWEEN '00990000' AND '00999999'
	OR b.pay_cd BETWEEN '09900000' AND '09999999'
	OR b.pay_cd IN (
		'00980300','00980409','00980508','00980607','00980656','00980706',
		'00980755','00980805','00980813','00980821','09800095','09800277',
		'09800301','09800400','09800459','09800509','09800558','09800608',
		'09800707','09800715','09800806','09800814','09800905','09800913',
		'09800921','09800939','09800947','09800962','09800970','09800988',
		'09800996','09801002','09801010','09801028','09801036','09801044',
		'09801051','09801069','09801077','09801085','09801093','09801101',
		'09801119'
		)
	)
LEFT JOIN smsdss.pay_cd_dim_v AS c
ON b.pay_cd = c.pay_cd
-- Get the Secondary Payor Data
LEFT JOIN smsmir.pay AS d
ON a.Encounter = d.pt_id
	AND a.[Secondary Payor] = d.pyr_cd
	AND a.[Payment Amount] = d.tot_pay_adj_amt
	AND a.[Payment Entry Date] = d.pay_entry_date
	AND (d.pay_cd BETWEEN '09600000' AND '09699999'
	OR d.pay_cd BETWEEN '00990000' AND '00999999'
	OR d.pay_cd BETWEEN '09900000' AND '09999999'
	OR d.pay_cd IN (
		'00980300','00980409','00980508','00980607','00980656','00980706',
		'00980755','00980805','00980813','00980821','09800095','09800277',
		'09800301','09800400','09800459','09800509','09800558','09800608',
		'09800707','09800715','09800806','09800814','09800905','09800913',
		'09800921','09800939','09800947','09800962','09800970','09800988',
		'09800996','09801002','09801010','09801028','09801036','09801044',
		'09801051','09801069','09801077','09801085','09801093','09801101',
		'09801119'
		)
	)
LEFT JOIN smsdss.pay_cd_dim_v AS e
ON d.pay_cd = e.pay_cd
-- Get the Tertiary Payor Data
LEFT JOIN smsmir.pay AS f
ON a.Encounter = f.pt_id
	AND a.[Tertiary Payor] = f.pyr_cd
	AND a.[Payment Amount] = f.tot_pay_adj_amt
	AND a.[Payment Entry Date] = f.pay_entry_date
	AND (f.pay_cd BETWEEN '09600000' AND '09699999'
	OR f.pay_cd BETWEEN '00990000' AND '00999999'
	OR f.pay_cd BETWEEN '09900000' AND '09999999'
	OR f.pay_cd IN (
		'00980300','00980409','00980508','00980607','00980656','00980706',
		'00980755','00980805','00980813','00980821','09800095','09800277',
		'09800301','09800400','09800459','09800509','09800558','09800608',
		'09800707','09800715','09800806','09800814','09800905','09800913',
		'09800921','09800939','09800947','09800962','09800970','09800988',
		'09800996','09801002','09801010','09801028','09801036','09801044',
		'09801051','09801069','09801077','09801085','09801093','09801101',
		'09801119'
		)
	)
LEFT JOIN smsdss.pay_cd_dim_v AS g
ON f.pay_cd = g.pay_cd
-- Get the Quaternary Payor Data
LEFT JOIN smsmir.pay AS h
ON a.Encounter = h.pt_id
	AND a.[Quaternary Payor] = h.pyr_cd
	AND a.[Payment Amount] = h.tot_pay_adj_amt
	AND a.[Payment Entry Date] = h.pay_entry_date
	AND (h.pay_cd BETWEEN '09600000' AND '09699999'
	OR h.pay_cd BETWEEN '00990000' AND '00999999'
	OR h.pay_cd BETWEEN '09900000' AND '09999999'
	OR h.pay_cd IN (
		'00980300','00980409','00980508','00980607','00980656','00980706',
		'00980755','00980805','00980813','00980821','09800095','09800277',
		'09800301','09800400','09800459','09800509','09800558','09800608',
		'09800707','09800715','09800806','09800814','09800905','09800913',
		'09800921','09800939','09800947','09800962','09800970','09800988',
		'09800996','09801002','09801010','09801028','09801036','09801044',
		'09801051','09801069','09801077','09801085','09801093','09801101',
		'09801119'
		)
	)
LEFT JOIN smsdss.pay_cd_dim_v AS i
ON h.pay_cd = i.pay_cd

--WHERE [Encounter] = ''

ORDER BY a.[Reference Number]
;

--SELECT * FROM #temp3;

---------------------------------------------------------------------------------------------------
-- Make an RN partitioned AND ORDER BY Reference ID so that distinct rows can be grabbed IN the next
-- step
SELECT a.*
, rn = ROW_NUMBER() over(
	partition by a.[reference number]
	ORDER BY a.[reference number]
)
INTO #temp4
FROM #temp3 AS a;

---------------------------------------------------------------------------------------------------
-- Make sure only distinct reference ID's are grabbed so there are no duplicates

---------------------------------------------------------------------------------------------------
-- Get final data
SELECT a.Encounter
, a.[Reference Number]
, a.[Payment Amount]
, a.[Payment Entry Date]
, a.[Payor Code]
, a.[Primary Payor]
, a.[Secondary Payor]
, a.[Tertiary Payor]
, a.[Quaternary Payor]
--, a.[Self Pay Pay Cd]
--, a.[Self Pay Pay Cd Desc]
--, a.[Primary Pay Cd]
--, a.[Primary Pay Cd Desc]
--, a.[Secondary Pay Cd]
--, a.[Secondary Pay Cd Desc]
--, a.[Tertiary Pay Cd]
--, a.[Tertiary Pay Cd Desc]
--, a.[Quaternary Pay Cd]
--, a.[Quaternary Pay Cd Desc]
, COALESCE(
	a.[Self Pay Pay Cd]
	, a.[primary pay cd]
	, a.[secondary pay cd]
	, a.[tertiary pay cd]
	, a.[quaternary pay cd]
) AS [Pay Cd]
, COALESCE(
	a.[Self Pay Pay Cd Desc]
	, a.[primary pay cd desc]
	, a.[secondary pay cd desc]
	, a.[tertiary pay cd desc]
	, a.[quaternary pay cd desc]
) AS [Pay Cd Description]

INTO #temp5

FROM #temp4 AS a

WHERE a.rn = 1

ORDER BY a.[Reference Number];

---------------------------------------------------------------------------------------------------
SELECT A.*
FROM (
	SELECT a.Encounter
	, a.[Pay Cd]
	, a.[Pay Cd Description]
	, a.[Payment Amount]
	, a.[Payment Entry Date]
	, 'No' AS [Adjustment Code]

	FROM #temp5 AS a

	WHERE a.Encounter IN (
		SELECT distinct(pt_id)
		FROM smsmir.pay
		WHERE pay_cd IN (
			'09740002', '09740408', '09740457' -- Admission Denials
			, '09740903', '09740911', '09740929', '09740853' -- Medicare AND Medicaid Admission Denials
			, '09740812', '09740820', '09740754', '09740804'
			, '09740655', '09740705'	
		)
	)
	--AND a.Encounter = ''

	UNION ALL

	SELECT B.pt_id AS [Encounter]
	, B.pay_cd AS [Pay Cd]
	, c.pay_cd_name AS [Pay Cd Description]
	, b.tot_pay_adj_amt AS [Payment Amount]
	, b.pay_entry_date AS [Payment Entry Date]
	, 'Yes' AS [Adjustment Code]

	FROM smsmir.pay AS b
	LEFT JOIN smsdss.pay_cd_dim_v AS c
	ON b.pay_cd = c.pay_cd


	WHERE b.pay_cd IN (
		'09740002', '09740408', '09740457' -- Admission Denials
		, '09740903', '09740911', '09740929', '09740853' -- Medicare AND Medicaid Admission Denials
		, '09740812', '09740820', '09740754', '09740804'
		, '09740655', '09740705'
	)
	AND SUBSTRING(B.pt_id, 5, 8) IN (
		SELECT LEFT(ZZZ.[REFERENCE NUMBER], 8)
		FROM smsdss.c_HCRA_FMS_ADS_Rpt_Tbl_2016 AS ZZZ
	)
	--AND b.pt_id = ''
) AS A

ORDER BY A.Encounter
, A.[Payment Entry Date]
---------------------------------------------------------------------------------------------------
----- Drop Table Statements
--DROP TABLE #temp1;
--DROP TABLE #temp2;
--DROP TABLE #temp3;
--DROP TABLE #temp4;
SELECT a.[payor code]
, a.[payor code long]
, a.[payor code description]
, a.[payor sub-code]
, a.[payor type]
--, b.elector
--, b.non_elector
--, b.federal
, CASE
	WHEN b.elector != 'NULL'     
		THEN b.elector
	WHEN b.non_elector != 'NULL' 
		THEN b.non_elector
	WHEN b.federal != 'NULL'     
		THEN b.federal
	ELSE 'Not yet specified'
  END AS [elector_status]
, CASE
	WHEN B.ELECTOR_NAME != 'NULL'
		THEN B.ELECTOR_NAME
	WHEN B.NON_ELECTOR_NAME != 'NULL'
		THEN B.NON_ELECTOR_NAME
	WHEN B.FEDERAL_NAME != 'NULL'
		THEN B.FEDERAL_NAME
	ELSE 'Not yet specified'
  END AS [elector_name]

FROM smsdss.c_HCRA_Payor_Data_2016                     AS A
LEFT JOIN smsdss.c_HCRA_Payor_Code_Elector_Status_2016 AS B
ON a.[payor sub-code] = b.[payor sub-code]
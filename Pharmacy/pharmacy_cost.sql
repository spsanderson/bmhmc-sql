SELECT A.TRANS_DATE
, [TRANS_MONTH] = DATEPART(MONTH, [TRANS_DATE])
, [TRNS_QTR] = DATEPART(QUARTER, [TRANS_DATE])
, [TRNS_DOW] = DATEPART(WEEKDAY, [TRANS_DATE])
, [TRNS_DOW_LBL] = CASE
	WHEN DATEPART(WEEKDAY, [TRANS_DATE]) = 1 THEN 'SUNDAY'
	WHEN DATEPART(WEEKDAY, [TRANS_DATE]) = 2 THEN 'MONDAY'
	WHEN DATEPART(WEEKDAY, [TRANS_DATE]) = 3 THEN 'TUESDAY'
	WHEN DATEPART(WEEKDAY, [TRANS_DATE]) = 4 THEN 'WEDNESDAY'
	WHEN DATEPART(WEEKDAY, [TRANS_DATE]) = 5 THEN 'THURSDAY'
	WHEN DATEPART(WEEKDAY, [TRANS_DATE]) = 6 THEN 'FRIDAY'
	WHEN DATEPART(WEEKDAY, [TRANS_DATE]) = 7 THEN 'SATURDAY'
  END
, A.PAT_NUM
, A.UNIT_COST
, A.TRANS_QTY
, [COST] = CAST(A.UNIT_COST * A.TRANS_QTY AS money)
, CAST(A.PRICE AS money) AS PRICE
, A.DISPENSING_UNIT
, A.ORD_DRNAME
, A.ORD_DRNO
, A.CDM_NO
, A.PRIMARY_NAME

INTO #TEMPA

FROM smsdss.c_PharmacyJanJun2017 AS A
;

SELECT A.ORD_DRNO
, A.ORD_DRNAME
, A.CDM_NO
, A.PRIMARY_NAME
, COUNT(A.PAT_NUM) AS [ORD_COUNT]
, SUM(A.COST) AS [TOT_COST]
, SUM(A.PRICE) AS [TOT_CHG]
, [MARKUP] = (SUM(A.PRICE) / SUM(A.COST))

FROM #TEMPA AS A

WHERE A.ORD_DRNAME NOT IN (
	'TEST DOCTOR X', ''
)
AND A.ORD_DRNO != '000000'

GROUP BY A.ORD_DRNO
, A.ORD_DRNAME
, A.CDM_NO
, A.PRIMARY_NAME

HAVING SUM(A.COST) > 0

ORDER BY A.ORD_DRNAME
;
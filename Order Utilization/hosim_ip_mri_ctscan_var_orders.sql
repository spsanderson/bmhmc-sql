/*
This query will bring back which LIHN_Svc_Sub_Dept_Desc a provider is in variance for

Version	- Date			- Comment
v1		- 10-23-2017	- Initial creation
*/

----- This is the first part of the query as it brings back all the necessary information
----- to find which LIHN_Svc_Sub_Dept_Desc a provider is in variance for
SELECT RPT.Ord_Pty_Number
, RPT.Ordering_Party
, ELOS.[LIHN Service Line]
, RPT.Svc_Sub_Dept_Desc
, ROUND(AVG(ELOS.Performance), 3) AS [ELOS]
, COUNT(RPT.Order_No) AS [Order_Count]
, COUNT(DISTINCT(RPT.ENCOUNTER)) AS [Pt_Count]
, CONCAT(ELOS.[LIHN Service Line], ' - ', RPT.Svc_Sub_Dept_Desc) AS LIHN_Svc_Dept_Desc

INTO #TEMPA

FROM smsdss.c_HOSIM_IP_RadOrdersUtil_RptTbl AS RPT
LEFT OUTER JOIN smsdss.c_LIHN_SPARCS_BenchmarkRates AS ELOS
ON RPT.APR_DRG = ELOS.[APRDRG Code]
	AND RPT.SOI = ELOS.SOI
	AND RPT.LIHN_Svc_Line = ELOS.[LIHN Service Line]
	AND ELOS.[Measure ID] = 4
	AND ELOS.[Benchmark ID] = 3

WHERE RPT.Ord_Pty_Number NOT IN (
	'000000', '000059', '999995', '999999'
)

GROUP BY RPT.Ord_Pty_Number
, RPT.Ordering_Party
, ELOS.[LIHN Service Line]
, RPT.Svc_Sub_Dept_Desc

ORDER BY RPT.Ordering_Party, ELOS.[LIHN Service Line], RPT.Svc_Sub_Dept_Desc
;

----------

-- This query will get the average orders per patient per expected days stay
SELECT A.Ord_Pty_Number
, A.Ordering_Party
, A.[LIHN Service Line]
, A.Svc_Sub_Dept_Desc
, A.ELOS
, A.Order_Count
, A.Pt_Count
, A.LIHN_Svc_Dept_Desc
, ROUND((A.Order_Count / A.ELOS) / A.PT_COUNT, 3) AS [Avg_Ord_Per_Pt_ELOS]

INTO #TEMPB

FROM #TEMPA AS A
;

-- This query will get the variance of the query above in #tempb
-- Variance = (Actual Performance - Benchmark Performance)
-- A positive variance means that for the time period run, the provider has over ordered
-- compared to the bench
SELECT A.Ord_Pty_Number
, A.Ordering_Party
, A.[LIHN Service Line]
, A.Svc_Sub_Dept_Desc
, A.ELOS
, A.Order_Count
, A.Pt_Count
, A.LIHN_Svc_Dept_Desc
, A.Avg_Ord_Per_Pt_ELOS
, ROUND((A.AVG_ORD_PER_PT_ELOS - BENCH.AVG_ORD_PER_PT_ELOS), 2) AS [Variance]

INTO #TEMPC

FROM #TEMPB AS A
LEFT OUTER JOIN smsdss.c_hosim_ct_mri_lihn_bench AS BENCH
ON A.LIHN_Svc_Dept_Desc = BENCH.LIHN_SVC_DEPT_DESC

ORDER BY A.Ord_Pty_Number
, A.Ordering_Party
, A.[LIHN Service Line]
, A.Svc_Sub_Dept_Desc
;

--This query will make a variance flag 1/0
SELECT A.Ord_Pty_Number
, A.Ordering_Party
, A.[LIHN Service Line]
, A.Svc_Sub_Dept_Desc
, A.ELOS
, A.Order_Count
, A.Pt_Count
, A.LIHN_Svc_Dept_Desc
, A.Avg_Ord_Per_Pt_ELOS
, A.Variance
, CASE
	WHEN A.Variance > 0
		THEN 1
		ELSE 0
  END AS [Variance_Flag]

INTO #TEMPD

FROM #TEMPC AS A
;

-- This query will get the LIHN_Svc_Sub_Dept_Desc in Variance by Provider
SELECT A.*

INTO #TEMPE

FROM #TEMPD AS A

WHERE A.Variance_Flag = 1

ORDER BY A.Ord_Pty_Number
, A.Ordering_Party
, A.[LIHN Service Line]
, A.Svc_Sub_Dept_Desc
;

-- Get the results from the above
SELECT A.*
FROM #TEMPE AS A
;

----------
/*
Get all the individual orders that satisfy as being part of the variance grouping
*/
SELECT ORDERS.*
, ELOS.Threshold
, ELOS.[In or Outside Threshold]
, RN = ROW_NUMBER() OVER(
	PARTITION BY ORDERS.ENCOUNTER, ORDERS.LIHN_SVC_LINE, ORDERS.SVC_SUB_DEPT_DESC
	ORDER BY ORDERS.ORDER_NO
)

FROM smsdss.c_HOSIM_IP_RadOrdersUtil_RptTbl AS ORDERS
LEFT OUTER JOIN smsdss.c_elos_bench_data AS ELOS
ON ORDERS.Encounter = ELOS.Encounter
INNER JOIN #TEMPE AS E
ON ORDERS.Ord_Pty_Number = E.Ord_Pty_Number
	AND ORDERS.LIHN_Svc_Line = E.[LIHN Service Line]
	AND ORDERS.Svc_Sub_Dept_Desc = E.Svc_Sub_Dept_Desc

WHERE ELOS.Encounter IS NOT NULL
AND ORDERS.Ord_Pty_Number = '015669'
AND ORDERS.LIHN_Svc_Line = 'Medical'
AND ORDERS.Svc_Sub_Dept_Desc = 'MRI'

ORDER BY ORDERS.Ord_Pty_Number
, ORDERS.Encounter

----------
--DROP TABLE #TEMPA, #TEMPB, #TEMPC, #TEMPD, #TEMPE
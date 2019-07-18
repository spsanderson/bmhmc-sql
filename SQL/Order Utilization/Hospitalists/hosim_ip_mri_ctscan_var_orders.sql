/*
This query will bring back which LIHN_Svc_Sub_Dept_Desc a provider is in variance for

Before this query is run the following stored procedures must have been run and in the order listed
	1. smsdss.c_Lab_Rad_Order_Utilization_sp
	2. smsdss.c_HOSIM_IP_Rad_Order_Utilization_Rpt_Tbl_sp

Version	- Date			- Comment
v1		- 10-23-2017	- Initial creation
v2		- 10-25-2017	- Fix ELOS computation to properly account for distinct encounters
							for each of the service lines and svc_sub_dept_desc within
v3		- 11-07-2017	- Update to only include orders that were entered in 2017 and forward
						- Update to get rid of the use of smsdss.c_elos_bench data in favor of 
						- smsdss.c_LIHN_APR_DRG_OutlierThresholds table
*/

---------------------------------------------------------------------------------------------------

/* 
This will get the distinct encounters necessary in order to compute the elos
per the following grouping:
	1. Ordering Party Number
	2. LIHN_Service_Line
	3. Svc Sub Dept Desc
*/
SELECT RPT.Ord_Pty_Number
, RPT.Ordering_Party
, RPT.Encounter
, RPT.Performance
, RPT.LIHN_Svc_Line
, RPT.Svc_Sub_Dept_Desc

INTO #ENCOUNTERS

FROM smsdss.c_HOSIM_IP_RadOrdersUtil_RptTbl AS RPT
LEFT JOIN smsdss.c_LIHN_APR_DRG_OutlierThresholds AS THRESHOLD
ON RPT.APR_DRG = THRESHOLD.[APR-DRGCode]

WHERE RPT.Ord_Pty_Number NOT IN (
	'000000', '000059', '999995', '999999'
)
AND RPT.Ord_Entry_Dtime >= '2017-01-01'
AND RPT.LOS < THRESHOLD.[OUTLIER THRESHOLD]

GROUP BY RPT.ORD_PTY_NUMBER
, RPT.Ordering_Party
, RPT.ENCOUNTER
, RPT.PERFORMANCE
, RPT.LIHN_SVC_LINE
, RPT.SVC_SUB_DEPT_DESC

ORDER BY RPT.Ord_Pty_Number, RPT.LIHN_SVC_LINE, RPT.Svc_Sub_Dept_Desc

GO
;

----- This query will get the patient and order counts by ordering party by svc line and svc sub dept
SELECT Ord_Pty_Number
, RPT.Ordering_Party
, LIHN_Svc_Line
, Svc_Sub_Dept_Desc
, COUNT(DISTINCT(ENCOUNTER)) AS [PT_COUNT]
, COUNT(DISTINCT(Order_No)) AS [ORDER_COUNT]

INTO #PT_ORD_COUNT

FROM smsdss.c_HOSIM_IP_RadOrdersUtil_RptTbl AS RPT

WHERE RPT.Ord_Pty_Number NOT IN (
	'000000', '000059', '999995', '999999'
)

GROUP BY Ord_Pty_Number, RPT.Ordering_Party, LIHN_Svc_Line, Svc_Sub_Dept_Desc

GO
;

-- This query will get the elos
SELECT A.Ord_Pty_Number
, A.Ordering_Party
, A.LIHN_Svc_Line
, A.Svc_Sub_Dept_Desc
, A.PT_COUNT
, A.ORDER_COUNT
, ROUND(AVG(B.PERFORMANCE), 3) AS [Performance]

INTO #PERF_1

FROM #PT_ORD_COUNT AS A
LEFT OUTER JOIN #ENCOUNTERS AS B
ON A.Ord_Pty_Number = B.Ord_Pty_Number
	AND A.LIHN_Svc_Line = B.LIHN_Svc_Line
	AND A.Svc_Sub_Dept_Desc = B.Svc_Sub_Dept_Desc

WHERE B.Encounter IS NOT NULL

GROUP BY A.Ord_Pty_Number
, A.Ordering_Party
, A.LIHN_Svc_Line
, A.Svc_Sub_Dept_Desc
, A.PT_COUNT
, A.ORDER_COUNT

GO
;

SELECT A.Ord_Pty_Number
, A.Ordering_Party
, A.LIHN_Svc_Line
, A.Svc_Sub_Dept_Desc
, CONCAT(A.LIHN_SVC_LINE, ' - ', A.SVC_SUB_DEPT_DESC) AS [LIHN_Svc_Dept_Desc]
, A.PT_COUNT
, A.ORDER_COUNT
, A.Performance
, ROUND((A.ORDER_COUNT / CAST(A.PT_COUNT AS float)), 3) AS [Ord_Per_Pt]
, ROUND(((A.ORDER_COUNT / CAST(A.PT_COUNT AS float)) / A.Performance), 3) AS [Ord_Per_Pt_ELOS]

INTO #PERF_2

FROM #PERF_1 AS A

GO
;


----------

/*
This query will get the variance of the query above in #tempb
Variance = (Actual Performance - Benchmark Performance)
A positive variance means that for the time period run, the provider has over ordered
compared to the bench
*/
SELECT A.Ord_Pty_Number
, A.Ordering_Party
, A.LIHN_Svc_Line
, A.Svc_Sub_Dept_Desc
, A.LIHN_Svc_Dept_Desc
, A.Order_Count
, A.Pt_Count
, A.Performance
, A.Ord_Per_Pt_ELOS
, BENCH.AVG_ORD_PER_PT_ELOS AS [Benchmark]
, ROUND((A.ORD_PER_PT_ELOS - BENCH.AVG_ORD_PER_PT_ELOS), 2) AS [Variance]

INTO #TEMPC

FROM #PERF_2 AS A
LEFT OUTER JOIN smsdss.c_hosim_ct_mri_lihn_bench AS BENCH
ON A.LIHN_Svc_Dept_Desc = BENCH.LIHN_SVC_DEPT_DESC

ORDER BY A.Ord_Pty_Number
, A.Ordering_Party
, A.LIHN_Svc_Line
, A.Svc_Sub_Dept_Desc

GO
;

--This query will make a variance flag 1/0
SELECT A.Ord_Pty_Number
, A.Ordering_Party
, A.LIHN_Svc_Line
, A.Svc_Sub_Dept_Desc
, A.Performance
, A.Order_Count
, A.Pt_Count
, A.LIHN_Svc_Dept_Desc
, A.Ord_Per_Pt_ELOS
, A.Benchmark
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
, A.LIHN_Svc_Line
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
, THRESHOLD.[Outlier Threshold]
--, ELOS.[In or Outside Threshold]
, [In or Outside Threshold] = CASE WHEN ORDERS.LOS > THRESHOLD.[Outlier Threshold] THEN 1 ELSE 0 END
, RN = ROW_NUMBER() OVER(
	PARTITION BY ORDERS.ENCOUNTER, ORDERS.LIHN_SVC_LINE, ORDERS.SVC_SUB_DEPT_DESC
	ORDER BY ORDERS.ORDER_NO
)

FROM smsdss.c_HOSIM_IP_RadOrdersUtil_RptTbl AS ORDERS
LEFT OUTER JOIN smsdss.c_LIHN_APR_DRG_OutlierThresholds AS THRESHOLD
ON ORDERS.APR_DRG = THRESHOLD.[APR-DRGCode]
INNER JOIN #TEMPE AS E
ON ORDERS.Ord_Pty_Number = E.Ord_Pty_Number
	AND ORDERS.LIHN_Svc_Line = E.LIHN_Svc_Line
	AND ORDERS.Svc_Sub_Dept_Desc = E.Svc_Sub_Dept_Desc

ORDER BY ORDERS.Ord_Pty_Number
, ORDERS.Encounter

----------
DROP TABLE #TEMPC, #TEMPD, #TEMPE
DROP TABLE #ENCOUNTERS, #PERF_1, #PERF_2, #PT_ORD_COUNT
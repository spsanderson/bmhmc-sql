select B.Ord_Pty_Number
, B.Ordering_Party
, A.LIHN_Service_Line
, B.Svc_Sub_Dept_Desc
, ROUND(AVG(A.Performance), 2) as [ELOS]
, COUNT(b.Order_No) as [Order Count]
, COUNT(distinct(a.Encounter)) as Pt_Count
, CONCAT(a.lihn_service_line, ' - ', b.svc_sub_dept_desc) as LIHN_Svc_Dept_Desc

INTO #TEMP_A

FROM smsdss.c_elos_bench_data AS A
LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization AS B
ON a.Encounter = b.Encounter

WHERE B.Ord_Pty_Number IN (
'017194', '006924'
)
AND B.Ord_Entry_DTime >= '2016-01-01'
AND B.Ord_Entry_DTime < '2017-01-01'
AND B.Svc_Sub_Dept_Desc IS NOT NULL
AND A.Encounter IS NOT NULL
AND B.Ord_Pty_Number IS NOT NULL
AND B.Ord_Pty_Number NOT IN (
'000000', '000059', '999995', '999999'
)
AND A.LIHN_Service_Line IN (
'Surgical', 'MI', 'CHF', 'CVA', 'Pneumonia'
)

GROUP BY B.Ord_Pty_Number, B.Ordering_Party, A.LIHN_Service_Line, B.Svc_Sub_Dept_Desc

ORDER BY B.Ord_Pty_Number, B.Ordering_Party, A.LIHN_Service_Line, B.Svc_Sub_Dept_Desc
;
-----

SELECT A.*
, ROUND((A.[ORDER COUNT] / CAST(A.elos AS float)) / A.[pt_count], 2) AS [AVG_ORD_PER_PT_ELOS]

INTO #TEMP_B

FROM #TEMP_A AS A

ORDER BY A.Ord_Pty_Number, A.Ordering_Party, A.LIHN_Service_Line, A.Svc_Sub_Dept_Desc
;
-----

SELECT A.*
, (A.AVG_ORD_PER_PT_ELOS - B.AVG_ORD_PER_PT_ELOS) AS [Variance]

INTO #TEMP_C

FROM #TEMP_B AS A
LEFT JOIN smsdss.c_order_utilization_lihn_svc_w_order_dept_desc_bench2015 AS B
ON A.lihn_svc_dept_Desc = B.LIHN_SVC_DEPT_DESC

ORDER BY A.Ord_Pty_Number, A.Ordering_Party, A.LIHN_Service_Line, A.Svc_Sub_Dept_Desc
;
-----

SELECT A.*
, CASE
WHEN A.Variance > 0
THEN 1
ELSE 0
  END AS [Variance_Flag]

INTO #TEMP_D

FROM #TEMP_C AS A
;
-----

SELECT *

FROM #TEMP_D

WHERE Variance_Flag = 1
;
-----

DROP TABLE #TEMP_A;
DROP TABLE #TEMP_B;
DROP TABLE #TEMP_C;
DROP TABLE #TEMP_D;

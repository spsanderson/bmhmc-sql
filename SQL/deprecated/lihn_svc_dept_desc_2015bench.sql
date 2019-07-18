/*
Create a benchmark table based upon a grouping of patient visit
characteristics.

LIHN Service Line
|____Order Service Sub Department Description

This grouping gives an ELOS, count of orders and patient count
for each grouping. This allows us to find the average orders per service line
per order type for each patients expected days stay.
*/

SELECT A.LIHN_Service_Line
, B.Svc_Sub_Dept_Desc
, ROUND(AVG(A.Performance), 2) AS [elos]
, COUNT(b.Order_No)            AS [order count]
, COUNT(distinct(a.Encounter)) AS pt_count

INTO #TEMP_A

FROM smsdss.c_elos_bench_data                AS A
LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization AS B
ON a.Encounter = b.Encounter

WHERE B.Ord_Entry_DTime >= '2015-01-01'
AND B.Ord_Entry_DTime < '2016-01-01'
AND B.Svc_Sub_Dept_Desc IS NOT NULL
AND A.Encounter IS NOT NULL
AND B.Ord_Pty_Number IS NOT NULL
AND B.Ord_Pty_Number != '000000'
AND B.Ord_Pty_Number != '000059'

GROUP BY  A.LIHN_Service_Line, B.Svc_Sub_Dept_Desc

ORDER BY A.LIHN_Service_Line, B.Svc_Sub_Dept_Desc

-----

SELECT CONCAT(A.LIHN_SERVICE_LINE, ' - ', A.SVC_SUB_DEPT_DESC) AS LIHN_SVC_DEPT_DESC
, A.LIHN_Service_Line
, A.Svc_Sub_Dept_Desc
, A.elos
, A.[order count]
, A.pt_count
, ROUND((A.[order count] / A.elos) / A.pt_count, 2) AS AVG_ORD_PER_PT_ELOS
, ROUND(A.[ORDER COUNT] / CAST(A.PT_COUNT AS float), 2)  AS AVG_ORD_PER_PT

INTO smsdss.c_order_utilization_lihn_svc_w_order_dept_desc_bench2015

FROM #TEMP_A AS A

DROP TABLE #TEMP_A
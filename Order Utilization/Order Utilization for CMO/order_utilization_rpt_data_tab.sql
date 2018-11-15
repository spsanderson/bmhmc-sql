DECLARE @TODAY DATE;
DECLARE @START DATE;
DECLARE @END   DATE;

SET @TODAY = GETDATE();
SET @START = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) - 13, 0);
SET @END   = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) - 1, 0);

SELECT B.Ord_Pty_Number
, B.Ordering_Party
, A.LIHN_Service_Line
, B.Svc_Sub_Dept_Desc
, YEAR(B.Ord_Entry_DTime)      AS [Order_Year]
, ROUND(AVG(A.Performance), 2) AS [ELOS]
, COUNT(b.Order_No)            AS [Order Count]
, COUNT(distinct(a.Encounter)) AS Pt_Count
, CONCAT(a.lihn_service_line, ' - ', b.svc_sub_dept_desc) AS LIHN_Svc_Dept_Desc

INTO #TEMP_A

FROM smsdss.c_elos_bench_data AS A
LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization AS B
ON a.Encounter = b.Encounter

WHERE B.Ord_Entry_DTime >= @START
AND B.Ord_Entry_DTime < @END
AND B.Svc_Sub_Dept_Desc IS NOT NULL
AND A.Encounter IS NOT NULL
AND B.Ord_Pty_Number IS NOT NULL
AND B.Ord_Pty_Number NOT IN (
	'000000', '000059', '999995', '999999'
)
AND A.LIHN_Service_Line IN (
	'Surgical', 'MI', 'CHF', 'CVA', 'Pneumonia'
)
-- Get rid of Glucose Testing
AND B.svc_cd NOT IN (
	'00401760'
	, '00425157'
	, '00409748'
)

GROUP BY B.Ord_Pty_Number
, B.Ordering_Party
, A.LIHN_Service_Line
, B.Svc_Sub_Dept_Desc
, YEAR(B.Ord_Entry_DTime)

ORDER BY B.Ord_Pty_Number
, B.Ordering_Party
, A.LIHN_Service_Line
, B.Svc_Sub_Dept_Desc
, YEAR(B.Ord_Entry_DTime)
;
-----

SELECT A.*
, ROUND((A.[ORDER COUNT] / CAST(A.elos AS float)) / A.[pt_count], 2) AS [AVG_ORD_PER_PT_ELOS]

INTO #TEMP_B

FROM #TEMP_A AS A

ORDER BY A.Ord_Pty_Number
, A.Ordering_Party
, A.LIHN_Service_Line
, A.Svc_Sub_Dept_Desc
;
-----

SELECT A.*
, Round((A.AVG_ORD_PER_PT_ELOS - B.AVG_ORD_PER_PT_ELOS), 2) AS [Variance]

INTO #TEMP_C

FROM #TEMP_B AS A
LEFT JOIN smsdss.c_order_utilization_lihn_svc_w_order_dept_desc_bench AS B
ON A.lihn_svc_dept_Desc = B.LIHN_SVC_DEPT_DESC
	AND A.Order_Year = B.Report_Year

ORDER BY A.Ord_Pty_Number
, A.Ordering_Party
, A.LIHN_Service_Line
, A.Svc_Sub_Dept_Desc
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

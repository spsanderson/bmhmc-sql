/*
=======================================================================
THIS QUERY WILL BRING BACK THE RESULTS OF SELECT PROVIDERS FOR A SELECT
ORDER ENTRY DATE TIME. IT GIVES THE VISIT ELOS, ORDER COUNT FOR SELECT
TYPES OF ORDERS AND PATIENT COUNT, THE LIHN SERVICE LINE CONCATENATED
WITH THE ORDER'S SERVICE SUB DEPT DESC.
=======================================================================
*/
SELECT B.Ord_Pty_Number
, B.Ordering_Party
, A.LIHN_Service_Line
, B.Svc_Sub_Dept_Desc
, ROUND(AVG(A.Performance), 2)                            AS [ELOS]
, COUNT(b.Order_No)                                       AS [Order Count]
, COUNT(distinct(a.Encounter))                            AS Pt_Count
, CONCAT(a.lihn_service_line, ' - ', b.svc_sub_dept_desc) AS LIHN_Svc_Dept_Desc

INTO #TEMP_A

FROM smsdss.c_elos_bench_data                AS A
LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization AS B
ON a.Encounter = b.Encounter

WHERE B.Ord_Pty_Number IN (
'017194', '006924'
)
AND B.Ord_Entry_DTime >= '2016-01-01'
AND B.Ord_Entry_DTime < '2017-01-01'
-- WE DON'T WANT NULL DEPT DESCRIPTIONS
AND B.Svc_Sub_Dept_Desc IS NOT NULL
AND A.Encounter IS NOT NULL
-- WE DON'T WANT ORDERS WHERE THE ORDERING PTY ID IS NULL
AND B.Ord_Pty_Number IS NOT NULL
-- WE DON'T WANT TEST CPOE OR OTHER ERRONEOUS PROVIDER ID NUMBERS
AND B.Ord_Pty_Number NOT IN (
'000000', '000059', '999995', '999999'
)
-- WE WILL ONLY FOCUS ON THESE LIHN SERVICE LINES AS PREVIOUSLY DISCUSSED
AND A.LIHN_Service_Line IN (
'Surgical', 'MI', 'CHF', 'CVA', 'Pneumonia'
)

GROUP BY B.Ord_Pty_Number, B.Ordering_Party, A.LIHN_Service_Line, B.Svc_Sub_Dept_Desc

ORDER BY B.Ord_Pty_Number, B.Ordering_Party, A.LIHN_Service_Line, B.Svc_Sub_Dept_Desc
;
-----------------------------------------------------------------------
-- THIS QUERY WILL GET THE AVERAGE ORDERS PER PATIENT PER EXPECTED DAYS STAY
SELECT A.*
, ROUND((A.[ORDER COUNT] / CAST(A.elos AS float)) / A.[pt_count], 2) AS [AVG_ORD_PER_PT_ELOS]

INTO #TEMP_B

FROM #TEMP_A AS A

ORDER BY A.Ord_Pty_Number, A.Ordering_Party, A.LIHN_Service_Line, A.Svc_Sub_Dept_Desc
;
-----------------------------------------------------------------------
-- THIS QUERY WILL GET THE VARIANCE OF THE QUERY ABOVE IN #TEMP_B
SELECT A.*
, (A.AVG_ORD_PER_PT_ELOS - B.AVG_ORD_PER_PT_ELOS) AS [Variance]

INTO #TEMP_C

FROM #TEMP_B AS A
LEFT JOIN smsdss.c_order_utilization_lihn_svc_w_order_dept_desc_bench2015 AS B
ON A.lihn_svc_dept_Desc = B.LIHN_SVC_DEPT_DESC

ORDER BY A.Ord_Pty_Number, A.Ordering_Party, A.LIHN_Service_Line, A.Svc_Sub_Dept_Desc
;
-----------------------------------------------------------------------
-- THIS QUERY WILL MAKE A VARIANCE FLAG OF 0/1
SELECT A.*
, CASE
WHEN A.Variance > 0
THEN 1
ELSE 0
  END AS [Variance_Flag]

INTO #TEMP_D

FROM #TEMP_C AS A
;
-----------------------------------------------------------------------
-- THIS QUERY GETS THE RPT_TBL DATA FOR THE ORDER UTILIZATION SPREADSHEET
SELECT *

FROM #TEMP_D

WHERE Variance_Flag = 1
;
-----------------------------------------------------------------------
-- THIS QUERY GRABS ONLY THOSE LINES WHERE A VARIANCE HAS OCCURRED AND
-- INSERTS THOSE RESULTS INTO #TEMP_E IN ORDER TO GRAB ONLY THOSE ORDERS
-- THAT ARE IN VARIANCE FROM THE QUERY ABOVE.
SELECT A.Ord_Pty_Number
, A.LIHN_Svc_Dept_Desc

INTO #TEMP_E 

FROM #TEMP_D AS A

WHERE A.Variance_Flag = 1

GROUP BY A.Ord_Pty_Number
, A.LIHN_Svc_Dept_Desc

-----------------------------------------------------------------------
/*
=======================================================================
THIS QUERY WILL BRING BACK ONLY THOSE ORDERS THAT ARE IN VARIANCE FOR
THE GIVEN LIHN SERVICE LINE AND SERVICE SUB DEPARTMENT DESCRIPTION, FOR
EXAMPLE IF A PROVIDER IS IN VARIANCE FOR MI - ULTRASOUND, THEN ONLY THE
ORDERS FOR PATIENTS FOR 'MI - ULTRASOUND' WILL RETURN.
=======================================================================
*/

SELECT a.Encounter AS PT_ID
, A.Dsch_Date
, A.LOS
, A.LIHN_Service_Line
, A.[AP-DRG]
, A.SOI
, A.LIHN_Svc_Line_APR_SOI
, A.Performance
, A.[ Threshold]
, A.[In or Outside Threshold]
, b.*
, c.Atn_Dr_No
, d.pract_rpt_name AS [Attending Dr]
, CASE
WHEN d.src_spclty_cd = 'HOSIM'
THEN 'Hospitalist'
ELSE 'Community'
  END AS hospitalist_flag
, CONCAT(a.lihn_service_line, ' - ', b.svc_sub_dept_desc) as [svc_line_and_dept_desc]
, rn = ROW_NUMBER() OVER(
PARTITION BY A.ENCOUNTER, CONCAT(a.lihn_service_line, ' - ', b.svc_sub_dept_desc)
ORDER BY B.ORDER_NO 
)

INTO #TEMP_F

FROM smsdss.c_elos_bench_data                AS A
LEFT JOIN smsdss.c_Lab_Rad_Order_Utilization AS B
ON a.Encounter = b.Encounter
LEFT JOIN smsdss.BMH_PLM_PtAcct_V            AS C
ON a.Encounter = c.PtNo_Num
LEFT JOIN smsdss.pract_dim_v                 AS D
ON c.Atn_Dr_No = d.src_pract_no
AND c.Regn_Hosp = d.orgz_cd
INNER JOIN #TEMP_E                           AS E
ON B.Ord_Pty_Number = E.Ord_Pty_Number
AND CONCAT(a.lihn_service_line, ' - ', b.svc_sub_dept_desc) = E.LIHN_Svc_Dept_Desc

WHERE B.Ord_Entry_DTime >= '2016-01-01'
AND B.Ord_Entry_DTime < '2017-01-01'
AND B.Svc_Sub_Dept_Desc IS NOT NULL
AND A.Encounter IS NOT NULL
AND B.Ord_Pty_Number IS NOT NULL

OPTION(FORCE ORDER)
;

/*
=======================================================================

=======================================================================
*/
-----

DROP TABLE #TEMP_A;
DROP TABLE #TEMP_B;
DROP TABLE #TEMP_C;
DROP TABLE #TEMP_D;
DROP TABLE #TEMP_E;
DROP TABLE #TEMP_F;


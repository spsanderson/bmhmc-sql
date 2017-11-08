/*
This query will bring back which LIHN_Svc_Sub_Dept_Desc a provider is in variance for, this also has
period information like, ord_ent_mo, etc.

Before this query is run the following stored procedures must have been run and in the order listed
	1. smsdss.c_Lab_Rad_Order_Utilization_sp
	2. smsdss.c_HOSIM_IP_Rad_Order_Utilization_Rpt_Tbl_sp

Version	- Date			- Comment
v1		- 10-26-2017	- Initial creation
v2		- 11-07-2017	- Update to only include orders that were entered in 2017 and forward
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
	
The variable @TrendParam can take one of the following values:
	1. Dsch_Year
	2. Dsch_Qtr
	3. Dsch_Mo
	4. Dsch_Hr
	5. Ord_Ent_Yr
	6. Ord_Ent_Qtr
	7. Ord_Ent_Mo
	8. Ord_Ent_Hr
	9. Ord_Start_Yr
	10. Ord_Start_Qtr
	11. Ord_Start_Mo
	12. Ord_Start_Hr
	13. Ord_Stop_Yr
	14. Ord_Stop_Qtr
	15. Ord_Stop_Mo
	16. Ord_Stop_Hr
*/

DECLARE @TrendParam as nvarchar(max);
DECLARE @sql as nvarchar(max);

SET @TrendParam = 'Ord_Ent_Mo';
SET @sql = 'SELECT RPT.Ord_Pty_Number
			, RPT.Ordering_Party
			, RPT.Encounter
			, RPT.Performance
			, RPT.LIHN_SVC_LINE
			, RPT.Svc_Sub_Dept_Desc
			, ' + quotename(@TrendParam) + ' as [TrendParam]
			INTO #encounters
			FROM smsdss.c_HOSIM_IP_RadOrdersUtil_RptTbl AS RPT
			LEFT JOIN smsdss.c_LIHN_APR_DRG_OutlierThresholds AS THRESHOLD
			ON RPT.APR_DRG = THRESHOLD.[APR-DRGCode]
			WHERE RPT.Ord_Pty_Number NOT IN (
				''000000'', ''000059'', ''999995'', ''999999''
			)

			AND RPT.Ord_Entry_Dtime >= ''2017-01-01''
			AND RPT.LOS < THRESHOLD.[OUTLIER THRESHOLD]
			GROUP BY RPT.ORD_PTY_NUMBER
			, RPT.Ordering_Party
			, RPT.Encounter
			, RPT.Performance
			, RPT.LIHN_SVC_LINE
			, RPT.SVC_SUB_DEPT_DESC
			, ' +
			quotename(@TrendParam) +
			'ORDER BY RPT.Ord_Pty_Number, RPT.LIHN_SVC_LINE, RPT.Svc_Sub_Dept_Desc
			;

			SELECT Ord_Pty_Number
			, RPT.Ordering_Party
			, LIHN_Svc_Line
			, Svc_Sub_Dept_Desc
			, ' +
			QUOTENAME(@TrendParam) + 
			'
			, COUNT(DISTINCT(RPT.Encounter)) AS [PT_COUNT]
			, COUNT(DISTINCT(Order_No)) AS [ORDER_COUNT]

			INTO #PT_ORD_COUNT

			FROM smsdss.c_HOSIM_IP_RadOrdersUtil_RptTbl AS RPT
			LEFT JOIN smsdss.c_LIHN_APR_DRG_OutlierThresholds AS THRESHOLD
			ON RPT.APR_DRG = THRESHOLD.[APR-DRGCode]

			WHERE RPT.Ord_Pty_Number NOT IN (
				''000000'', ''000059'', ''999995'', ''999999''
			)
			AND RPT.Ord_Entry_Dtime >= ''2017-01-01''
			AND RPT.LOS < THRESHOLD.[OUTLIER THRESHOLD]

			GROUP BY Ord_Pty_Number, RPT.Ordering_Party, LIHN_Svc_Line, Svc_Sub_Dept_Desc, ' + QUOTENAME(@TrendParam) +
			'
			;
	
			SELECT A.Ord_Pty_Number
			, A.Ordering_Party
			, A.LIHN_Svc_Line
			, A.Svc_Sub_Dept_Desc
			, ' + QUOTENAME(@TrendParam) + '
			, A.PT_COUNT
			, A.ORDER_COUNT
			, ROUND(AVG(B.PERFORMANCE), 3) AS [Performance]

			INTO #PERF_1

			FROM #PT_ORD_COUNT AS A
			LEFT OUTER JOIN #ENCOUNTERS AS B
			ON A.Ord_Pty_Number = B.Ord_Pty_Number
				AND A.LIHN_Svc_Line = B.LIHN_SVC_Line
				AND A.Svc_Sub_Dept_Desc = B.Svc_Sub_Dept_Desc

			WHERE B.Encounter IS NOT NULL

			GROUP BY A.Ord_Pty_Number
			, A.Ordering_Party
			, A.LIHN_Svc_Line
			, A.Svc_Sub_Dept_Desc
			, ' + QUOTENAME(@TrendParam) + '
			, A.PT_COUNT
			, A.ORDER_COUNT
			;

			SELECT A.Ord_Pty_Number
			, A.Ordering_Party
			, A.LIHN_Svc_Line
			, A.Svc_Sub_Dept_Desc
			, ' + QUOTENAME(@TrendParam) + '
			, CONCAT(A.LIHN_SVC_LINE, '' - '', A.SVC_SUB_DEPT_DESC) AS [LIHN_Svc_Dept_Desc]
			, A.PT_COUNT
			, A.ORDER_COUNT
			, A.Performance
			, ROUND((A.ORDER_COUNT / CAST(A.PT_COUNT AS float)), 3) AS [Ord_Per_Pt]
			, ROUND(((A.ORDER_COUNT / CAST(A.PT_COUNT AS float)) / A.Performance), 3) AS [Ord_Per_Pt_ELOS]

			INTO #PERF_2

			FROM #PERF_1 AS A
			;

			SELECT A.Ord_Pty_Number
			, A.Ordering_Party
			, A.LIHN_Svc_Line
			, A.Svc_Sub_Dept_Desc
			, A.LIHN_Svc_Dept_Desc
			, ' + QUOTENAME(@TrendParam) + '
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
			;
			-- This query will make a variance flag
			SELECT A.Ord_Pty_Number
			, A.Ordering_Party
			, A.LIHN_Svc_Line
			, A.Svc_Sub_Dept_Desc
			, ' + QUOTENAME(@TrendParam) + '
			, A.Performance
			, A.Order_Count
			, A.Pt_Count
			, A.LIHN_Svc_Dept_Desc
			, A.Ord_Per_Pt_ELOS
			, A.Benchmark
			, A.Variance
			, CASE WHEN A.Variance > ''0'' 
					THEN ''1'' 
					ELSE ''0'' 
			  END AS [Variance_Flag]

			INTO #TEMPD

			FROM #TEMPC AS A
			;
			SELECT A.*
			INTO #TEMPE
			FROM #TEMPD AS A
			WHERE A.Variance_Flag = 1
			ORDER BY A.Ord_Pty_Number
			, A.Ordering_Party
			, A.LIHN_Svc_Line
			, A.Svc_Sub_Dept_Desc
			;
			SELECT A.*
			FROM #TEMPE AS A
			;
			'
;
--DECLARE @pos as int
--SELECT @pos = CHARINDEX(char(13) + char(10), @sql, 7500)
--PRINT SUBSTRING(@sql, 1, @pos)
--PRINT SUBSTRING(@sql, @pos, 8000)
--PRINT SUBSTRING(@sql, @pos, 8000)

EXEC (@sql)

GO
;
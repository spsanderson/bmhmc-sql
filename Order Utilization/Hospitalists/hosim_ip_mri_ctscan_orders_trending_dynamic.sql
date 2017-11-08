/*
This query will bring back trending order information by the variable @TrendParm only, there will be no variance
calculation in this partiticular query. 

The report will include the following
	1. @TrendParm, i.e. Dsch_Yr etc.
	2. Number of Distinct Patients
	3. Number of Distinct Orders
	4. Orders Per Encounter
	5. Orders Per Encounter Per ELOS

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
	
Version	- Date			- Comment
v1		- 11-07-2017	- Initial creation
						- Update to only include orders that were entered in 2017 and forward
						- Update to get rid of the use of smsdss.c_elos_bench data in favor of 
						- smsdss.c_LIHN_APR_DRG_OutlierThresholds table
*/

DECLARE @TrendParm AS NVARCHAR(MAX);
DECLARE @sql AS NVARCHAR(MAX);

SET @TrendParm = 'Ord_Ent_Mo';
SET @sql = 'SELECT DISTINCT(RPT.Encounter) AS [Encounter]
			, RPT.PERFORMANCE
			, ' + QUOTENAME(@TrendParm) + ' AS [TrendParm]

			INTO #ENCOUNTERS
						
			FROM smsdss.c_HOSIM_IP_RadOrdersUtil_RptTbl AS RPT
			LEFT JOIN smsdss.c_LIHN_APR_DRG_OutlierThresholds AS THRESHOLD
			ON RPT.APR_DRG = THRESHOLD.[APR-DRGCode]
			
			WHERE RPT.Ord_Pty_Number NOT IN (
				''000000'', ''000059'', ''999995'', ''999999''
			)
			AND RPT.Ord_Entry_Dtime >= ''2017-01-01''
			AND RPT.LOS < THRESHOLD.[OUTLIER THRESHOLD] 

			ORDER BY RPT.Encounter
			;

			SELECT ' + QUOTENAME(@TrendParm) + ' AS [TrendParm]
			, COUNT(DISTINCT(RPT.Encounter)) AS [PT_COUNT]
			, COUNT(DISTINCT(RPT.Order_No)) AS [ORDER_COUNT]

			INTO #PT_ORD_COUNT

			FROM smsdss.c_HOSIM_IP_RadOrdersUtil_RptTbl AS RPT
			LEFT JOIN smsdss.c_LIHN_APR_DRG_OutlierThresholds AS THRESHOLD
			ON RPT.APR_DRG = THRESHOLD.[APR-DRGCode]
			
			WHERE RPT.Ord_Pty_Number NOT IN (
				''000000'', ''000059'', ''999995'', ''999999''
			)
			AND RPT.Ord_Entry_Dtime >= ''2017-01-01''
			AND RPT.LOS < THRESHOLD.[OUTLIER THRESHOLD] 

			GROUP BY ' + QUOTENAME(@TrendParm) + '
			;
			
			-- get elos
			SELECT A.[TrendParm]
			, A.PT_COUNT
			, A.ORDER_COUNT
			, ROUND(AVG(B.Performance), 3) AS [Performance]

			INTO #PERF_1

			FROM #PT_ORD_COUNT AS A
			LEFT OUTER JOIN #ENCOUNTERS AS B
			ON A.TrendParm = B.TrendParm

			WHERE B.Encounter IS NOT NULL

			GROUP BY A.[TrendParm], A.PT_COUNT, A.ORDER_COUNT
			;

			SELECT A.TrendParm
			, A.PT_COUNT
			, A.ORDER_COUNT
			, ROUND((A.ORDER_COUNT / CAST(A.PT_COUNT AS float)), 3) AS [Ord_Per_Pt]
			, ROUND(((A.ORDER_COUNT / CAST(A.PT_COUNT AS float)) / A.Performance), 3) AS [Ord_Per_Pt_ELOS]

			FROM #PERF_1 AS A

			ORDER BY CAST(A.TrendParm AS INT)
			;
			'
			
;

EXEC(@sql)

GO
;
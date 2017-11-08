/*
Create a benchmark table based upon a grouping of patient visit
characteristics.

LIHN Service Line
|____Order Service Sub Department Description

This grouping gives an ELOS, count of orders and patient count
for each grouping. This allows us to find the average orders per service line
per order type for each patients expected days stay.

The criterion are:
	1. Orders are placed by a hospitalist
	2. The encounter is an inpatient encounter
	3. The service sub department is either:
		a. MRI
		b. Cat Scan
	4. The patients must be discharged in 2015 or 2016
	
	Dead Criterion
	XXX 4. The orders must fall in the years 2014, 2015 and 2016 XXX

Change log
Version	- Date			- Comment
--------------------------------------------------------------------------------------
v1      - 10-23-2017 	- Initial load
v1.1    - 10-23-2017 	- Change to exclude patients who's los falls outside of 
							threshold this was done as these individuals are also 
							excluded from the monthly elos report and are also excluded 
							from the LIHN variance reports
v1.2 	- 10-24-2017	- Fix ELOS computation to properly account for distinct encounters
							for each of the service lines and svc_sub_dept_desc within
						- Changed criterion 4 to Discharge_DT must be in years 2015 & 2016
*/

SELECT DISTINCT(a.Encounter) AS Encounter
, b.Performance
, b.LIHN_Service_Line
, a.Svc_Sub_Dept_Desc

INTO #TEMP_A

FROM smsdss.c_LabRad_OrdUtil_by_DschDT AS A
LEFT OUTER JOIN smsdss.c_elos_bench_data AS B
ON a.Encounter = b.Encounter

WHERE a.ED_IP_FLAG = 'ip'
AND a.Dsch_DateTime >= '2015-01-01'
AND a.Dsch_DateTime < '2017-01-01'
AND b.Encounter IS NOT NULL
AND a.Ord_Pty_Number NOT IN (
	'000000', '000059'
)
AND a.Svc_Sub_Dept_Desc IN (
	'mri', 'cat scan'
)
AND B.[In or Outside Threshold] = 'Inside Threshold'

-----
-- Get the averages per LIHN Service Line and Svc_Sub_Dept_Desc
SELECT LIHN_Service_Line
, Svc_Sub_Dept_Desc
, ROUND(AVG(A.PERFORMANCE), 3) AS [ELOS]
, COUNT(DISTINCT(ENCOUNTER)) AS [PT_COUNT]

INTO #TEMP_B

FROM #TEMP_A AS A

GROUP BY LIHN_Service_Line
, Svc_Sub_Dept_Desc

ORDER BY LIHN_Service_Line
;

-----
-- Get count of orders by service line and svc_sub_dept_desc
SELECT LIHN_Service_Line
, Svc_Sub_Dept_Desc
, COUNT(DISTINCT(ORDER_NO)) AS [ORDER_COUNT]

INTO #TEMP_C

FROM smsdss.c_LabRad_OrdUtil_by_DschDT AS A
LEFT OUTER JOIN smsdss.c_elos_bench_data AS B
ON a.Encounter = b.Encounter

WHERE a.ED_IP_FLAG = 'ip'
AND a.Dsch_DateTime >= '2015-01-01'
AND a.Dsch_DateTime < '2017-01-01'
AND b.Encounter IS NOT NULL
AND a.Ord_Pty_Number NOT IN (
	'000000', '000059'
)
AND a.Svc_Sub_Dept_Desc IN (
	'mri', 'cat scan'
)
AND B.[In or Outside Threshold] = 'Inside Threshold'

GROUP BY LIHN_Service_Line
, Svc_Sub_Dept_Desc

ORDER BY LIHN_Service_Line
;

-----

SELECT CONCAT(A.LIHN_SERVICE_LINE, ' - ', A.SVC_SUB_DEPT_DESC) AS LIHN_SVC_DEPT_DESC
, A.LIHN_Service_Line
, A.Svc_Sub_Dept_Desc
, A.ELOS
, A.PT_COUNT
, B.ORDER_COUNT
, ROUND(B.[ORDER_COUNT] / CAST(A.PT_COUNT AS float), 3)  AS AVG_ORD_PER_PT
, ROUND((B.[ORDER_COUNT] / A.elos) / CAST(A.pt_count AS float), 3) AS AVG_ORD_PER_PT_ELOS

INTO smsdss.c_hosim_ct_mri_lihn_bench

FROM #TEMP_B AS A
LEFT OUTER JOIN #TEMP_C AS B
ON A.LIHN_Service_Line = B.LIHN_Service_Line
	AND A.Svc_Sub_Dept_Desc = B.Svc_Sub_Dept_Desc
;

DROP TABLE #TEMP_A, #TEMP_B, #TEMP_C
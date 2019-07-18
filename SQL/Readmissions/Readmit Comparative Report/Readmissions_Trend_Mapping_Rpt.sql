DECLARE @TODAY DATE;
DECLARE @START DATE;
DECLARE @END   DATE;

SET @TODAY = CAST(GETDATE() AS date);
SET @START = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) - 7, 0);
SET @END   = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY), 0);

SELECT A.Med_Rec_No
, A.PtNo_Num
, A.Adm_Date
, A.Dsch_Date
, A.Payor_Category
, A.Atn_Dr_No
, A.pract_rpt_name
, A.med_staff_dept
, A.LIHN_Svc_Line
, C.MDCDescText
, A.SEVERITY_OF_ILLNESS
, A.Dsch_YR
, A.Dsch_Qtr
, A.Dsch_Month
, A.Dsch_Week
, A.Dsch_Day
, A.Dsch_Day_Name
, A.Rpt_Month
, A.Rpt_Qtr
, A.DSCH_DISP
, A.Dsch_Disp_Desc
, A.drg_no
, A.drg_cost_weight
, A.Hospitalist_Private
, A.Hospitaslit_Private_Flag
, A.LOS
, A.INTERIM
, 1 AS [Pt_Count]
, A.RA_Flag AS [Readmit_Count]
, B.BENCH_YR
, B.READMIT_RATE AS [Readmit_Rate_Bench]
, D.WARD_CD

INTO #TEMPA

FROM SMSDSS.C_READMIT_DASHBOARD_DETAIL_TBL AS A
LEFT OUTER JOIN smsdss.c_Readmit_Dashboard_Bench_Tbl AS B
ON A.LIHN_Svc_Line = B.LIHN_SVC_LINE
	AND (A.Dsch_YR - 1) = B.BENCH_YR
	AND A.SEVERITY_OF_ILLNESS = B.SOI
LEFT OUTER JOIN smsdss.drg_dim_v AS C
ON A.drg_no = C.drg_no
	AND C.drg_vers = 'MS-V25'
LEFT OUTER JOIN SMSMIR.VST_RPT AS D 
ON A.PTNO_NUM = SUBSTRING(D.PT_ID, 5, 8)

WHERE B.SOI IS NOT NULL

ORDER BY A.Dsch_YR, A.Dsch_Qtr, B.SOI
;

SELECT A.*
, [Z-Score] = ROUND((A.[Readmit_Count] - A.[READMIT_RATE_BENCH]) / STDEV(A.Readmit_Count) OVER(), 4)
, GEO.LON
, GEO.LAT
, GEO.FullAddress
, GEO.ZipCode

FROM #TEMPA AS A
LEFT OUTER JOIN smsdss.c_geocoded_address AS GEO
ON A.PtNo_Num = GEO.Encounter

WHERE A.med_staff_dept != 'Emergency Department'
AND A.pract_rpt_name != 'TEST DOCTOR X'
-- UNHASH BELOW TO GET READMIT_MAPPING_FILE DATA ONLY
AND Dsch_Date >= @START
AND Dsch_Date < @END 

ORDER BY Dsch_Date

GO
;

DROP TABLE #TEMPA
GO
;
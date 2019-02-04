DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2014-04-01';
SET @END   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0)

SELECT CAST(A.DSCH_DATE AS date) AS [Dsch_Date]
, A.PTNO_NUM
, DATEPART(YEAR, A.DSCH_DATE) AS [Dsch_YR]
, C.SEVERITY_OF_ILLNESS
, D.LIHN_Svc_Line
, 1 AS [DSCH]
, CASE
	WHEN E.[READMIT] IS NOT NULL
		THEN 1
		ELSE 0
	END AS [RA_Flag]
, F.READMIT_RATE AS [RR_Bench]
, F.BENCH_YR

INTO #TEMPA

FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT OUTER JOIN smsdss.pract_dim_v AS B
ON A.Atn_Dr_No = B.src_pract_no
	AND A.Regn_Hosp = B.orgz_cd
LEFT OUTER JOIN Customer.Custom_DRG AS C
ON A.PtNo_Num = C.PATIENT#
LEFT OUTER JOIN smsdss.c_LIHN_Svc_Line_Tbl AS D
ON A.PtNo_Num = D.Encounter
	AND A.prin_dx_cd_schm = D.prin_dx_cd_schme
LEFT OUTER JOIN smsdss.vReadmits AS E
ON A.PtNo_Num = E.[INDEX]
	AND E.[INTERIM] < 31
	AND E.[READMIT SOURCE DESC] != 'Scheduled Admission'
LEFT OUTER JOIN smsdss.c_Readmit_Dashboard_Bench_Tbl AS F
ON D.LIHN_Svc_Line = F.LIHN_SVC_LINE
	AND (DATEPART(YEAR, A.DSCH_DATE) - 1) = F.BENCH_YR
	AND C.SEVERITY_OF_ILLNESS = F.SOI

WHERE A.DSCH_DATE >= @START
AND A.Dsch_Date < @END
AND A.tot_chg_amt > 0
AND LEFT(A.PtNo_Num, 1) != '2'
AND LEFT(A.PTNO_NUM, 4) != '1999'
AND A.drg_no IS NOT NULL
AND A.dsch_disp IN ('AHR','ATW')
AND C.APRDRGNO NOT IN (	
	SELECT ZZZ.[APR-DRG]
	FROM smsdss.c_ppr_apr_drg_global_exclusions AS ZZZ
)
AND B.med_staff_dept != 'Emergency Department'
AND B.pract_rpt_name != 'TEST DOCTOR X'

ORDER BY A.Dsch_Date

GO
;
-----------------------------------------------------------------------
-- Daily Readmits 
-- Time = day of discharge
-- DSCH_COUNT = count of patients discharged at Time t
-- READMIT_COUNT = count of patients discharged at Time t who 
--	were readmitted within 30 days
SELECT A.Dsch_Date AS [Time]
, SUM(DSCH) AS [DSCH_COUNT]
, SUM(RA_FLAG) AS [READMIT_COUNT]

FROM #TEMPA AS A

GROUP BY A.Dsch_Date

ORDER BY A.Dsch_Date
;
-----------------------------------------------------------------------
-- Daily Readmits with excess above/below bench negative is better
-- Time = day of discharge
-- DSCH_COUNT = count of patients discharged at Time t
-- READMIT_COUNT = count of patients discharged at Time t who 
--	were readmitted within 30 days
-- RR_Bench = Benchmark Readmit Rate
-- RR_ACT = Actual Readmit Rate
-- Excess = ( RR_Bench - RR_ACT ) negative is better
SELECT A.Dsch_Date AS [Time]
, SUM(DSCH) AS [DSCH_COUNT]
, SUM(RA_FLAG) AS [READMIT_COUNT]
, ROUND(CAST(SUM(RA_FLAG) AS float) / CAST(SUM(DSCH) AS float), 4) * 100 AS [RR_ACT]
, ROUND(AVG(RR_BENCH), 4) * 100 AS [RR_BENCH]
, ROUND(
	(
		ROUND(CAST(SUM(RA_FLAG) AS float) / CAST(SUM(DSCH) AS float), 4)
		-
		ROUND(AVG(RR_BENCH), 4)
	)
	, 4) * 100
  AS [EXCESS]

FROM #TEMPA AS A

WHERE BENCH_YR >= (SELECT MIN(BENCH_YR) FROM #TEMPA)

GROUP BY A.Dsch_Date

ORDER BY A.Dsch_Date
;

DROP TABLE #TEMPA
;
/*
I have spoken with the SCC and they have approved our criteria for our Medicaid patient list.

All Medicaid pts that have had:
	1. 3 or more ED visits in the last 12 months
	2. and/or 1 re-admission.

We will use this as our list pf patients to consider flagging in WELLSOFT,(and possibly SOARIAN as well)  and will have the OP RN Care Manager outreach.

*/

DECLARE @START DATETIME;
DECLARE @END   DATETIME;
DECLARE @ThisDate DATETIME;

SET @ThisDate = GETDATE();
SET @START = dateadd(mm, datediff(mm, 0, @ThisDate) - 12, 0) -- Beginning of previous month
SET @END   = dateadd(mm, datediff(mm, 0, @ThisDate), 0)      -- Beginning of this month

SELECT PLM.Med_Rec_No	
, PLM.PtNo_Num
, RA.[READMIT]
, CASE
	WHEN RA.[READMIT] IS NOT NULL
		THEN 1
		ELSE 0
  END AS [RA_FLAG]
, CASE
	WHEN LEFT(PLM.PtNo_Num, 1) = '8'
		THEN 1
		ELSE 0
  END AS [ED_FLAG]
, CASE
	WHEN LEFT(PLM.PtNo_Num, 1) = '1'
		THEN 1
		ELSE 0
  END AS [IP_FLAG]
, [VISIT_NUM] = ROW_NUMBER() OVER(
		PARTITION BY PLM.MED_REC_NO
		ORDER BY PLM.ADM_DATE
	)

INTO #TEMPA

FROM smsdss.BMH_PLM_PtAcct_V AS PLM
LEFT OUTER JOIN SMSDSS.VREADMITS AS RA
ON PLM.PTNO_NUM = RA.[INDEX]
	AND RA.[INTERIM] < 31
	AND RA.[READMIT SOURCE DESC] != 'SCHEDULED ADMISSION'

WHERE PLM.Dsch_Date >= @START
AND PLM.Dsch_Date < @END
AND PLM.User_Pyr1_Cat IN ('III', 'WWW')
AND LEFT(PLM.PTNO_NUM, 1) IN ('1', '8')
AND LEFT(PLM.PTNO_NUM, 1) != '2'
AND LEFT(PLM.PTNO_NUM, 4) != '1999'
AND PLM.tot_chg_amt > 0

-----

SELECT MED_REC_NO
, SUM(IP_FLAG) AS [IP_VISIT_COUNT]
, SUM(ED_FLAG) AS [ED_VISIT_COUNT]
, SUM(RA_FLAG) AS [RA_VISIT_COUNT]
, (SUM(IP_FLAG) + SUM(ED_FLAG)) [Visits]

INTO #TEMPB

FROM #TEMPA

GROUP BY MED_REC_NO

ORDER BY (SUM(IP_FLAG) + SUM(ED_FLAG)) DESC

-----

SELECT A.*
, CASE
	WHEN B.Med_Rec_No IS NOT NULL
		THEN 1
		ELSE 0
  END AS [COPD_COHORT_FLAG]

INTO #TEMPC

FROM #TEMPB AS A
LEFT JOIN smsdss.c_DSRIP_COPD AS B
ON A.MED_REC_NO = B.Med_Rec_No

WHERE (
	ED_VISIT_COUNT >=3 
	OR
	RA_VISIT_COUNT >= 1
)

-----

SELECT *
FROM #TEMPC
WHERE COPD_COHORT_FLAG = 0

-----
-- check an mrn
SELECT *
FROM #TEMPA
WHERE MED_REC_NO = ''

--DROP TABLE #TEMPA, #TEMPB, #TEMPC
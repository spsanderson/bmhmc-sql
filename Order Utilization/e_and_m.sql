SELECT A.Account
, CASE 
	WHEN B.actv_cd IN ('04600409','04600458') THEN 'LEVEL 1'
	WHEN B.actv_cd IN ('04600508','04600557') THEN 'LEVEL 2'
	WHEN B.actv_cd IN ('04600607','04600656') THEN 'LEVEL 3'
	WHEN B.actv_cd IN ('04600706','04600755') THEN 'LEVEL 4'
	WHEN B.actv_cd IN ('04600805','04600854') THEN 'LEVEL 5'
	WHEN B.actv_cd IN ('04600904','04600953') THEN 'CRITICAL CARE'
	WHEN B.actv_cd IN ('04600011') THEN 'ER IP ADMIT FEE'
  END AS [er_level]
, A.Arrival
, A.TimeLeftED
, C.vst_start_dtime
, C.vst_end_dtime

INTO #ER_TMP_A

FROM smsdss.c_Wellsoft_Rpt_tbl AS A
LEFT OUTER MERGE JOIN SMSMIR.mir_actv AS B
ON A.Account = SUBSTRING(B.PT_ID, 5, 8)
	AND actv_cd IN (
	'04600409','04600458','04600508','04600557','04600607','04600656',
	'04600706','04600755','04600805','04600854','04600904','04600953',
	'04600011'
)
LEFT OUTER MERGE JOIN smsdss.BMH_PLM_PtAcct_V AS C
ON A.Account = C.PtNo_Num

WHERE A.Arrival >= '2013-01-01'
AND A.Arrival < '2016-01-01'
AND A.EDMDID IS NOT NULL
AND A.ED_MD IS NOT NULL
-----------------------------------------------------------------------
SELECT *
, CASE
	WHEN LEFT(Account, 1) = '1'
		THEN 'ER IP ADMIT FEE'
		ELSE er_level
  END AS [er_level_B]

INTO #ER_TMP_B

FROM #ER_TMP_A
-----------------------------------------------------------------------
SELECT *
, ROW_NUMBER() OVER(
	PARTITION BY ACCOUNT
	ORDER BY ER_LEVEL_B
) RN

INTO #ER_TMP_C

FROM #ER_TMP_B
-----------------------------------------------------------------------
SELECT *
FROM #ER_TMP_C
WHERE RN = 1
-----------------------------------------------------------------------
DROP TABLE #ER_TMP_A
DROP TABLE #ER_TMP_B
DROP TABLE #ER_TMP_C
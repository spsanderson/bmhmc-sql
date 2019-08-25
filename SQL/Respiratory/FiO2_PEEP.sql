/*
***********************************************************************
File: Fi02_PEEP.sql

Input Parameters:
	None

Tables/Views:
	smsmir.obsv

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Entere Here

Revision History:
Date		Version		Description
----		----		----
2019-06-10	v1			Initial Creation
2019-07-12	v2			Add daily observation value delta
						Fi02 and PEEP Threshold Flags
						DECLARE @EVENTS TABLE AND EVENTID AS:
						EVENTID INT IDNEITY(1,1) PRIMARY KEY
2019-08-05	v3			Add AND dsply_val != '-'
						Add dbo.c_udf_NumericChars(A.Min_Val) AS Min_Val,
***********************************************************************
*/
SELECT episode_no,
	pt_id,
	vst_id,
	vst_no,
	obsv_cd,
	obsv_cd_name,
	obsv_user_id,
	dsply_val,
	val_sts_cd,
	coll_dtime,
	rslt_obj_id,
	CAST(perf_dtime AS DATE) AS [Perf_Date]
INTO #TEMPA
FROM SMSMIR.obsv
WHERE obsv_cd IN ('A_BMH_VFFiO2', 'A_BMH_VFPEEP')
	AND episode_no IN ('')
	AND dsply_val != '-'
ORDER BY obsv_cd,
	perf_dtime;

SELECT A.episode_no,
	A.pt_id,
	A.vst_id,
	A.vst_no,
	A.obsv_cd,
	A.obsv_cd_name,
	A.obsv_user_id,
	A.dsply_val,
	A.val_sts_cd,
	A.coll_dtime,
	A.rslt_obj_id,
	A.Perf_Date,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY A.EPISODE_NO,
		A.OBSV_CD ORDER BY A.PERF_DATE
		)
INTO #TEMPB
FROM #TEMPA AS A;

SELECT A.episode_no,
	A.pt_id,
	A.vst_id,
	A.vst_no,
	A.obsv_cd,
	A.obsv_cd_name,
	A.obsv_user_id,
	A.dsply_val,
	B.Min_Val,
	A.val_sts_cd,
	A.Perf_Date,
	a.RN,
	[KeepFlag] = ROW_NUMBER() OVER (
		PARTITION BY A.EPISODE_NO,
		A.OBSV_CD,
		A.PERF_DATE,
		B.MIN_VAL ORDER BY A.RN
		)
INTO #TEMPC
FROM #TEMPB AS A
INNER JOIN (
	SELECT episode_no,
		Perf_Date,
		obsv_cd,
		MIN(dsply_val) AS [Min_Val]
	FROM #TEMPB AS Z
	GROUP BY episode_no,
		Perf_Date,
		obsv_cd
	) AS B ON A.episode_no = B.episode_no
	AND A.PERF_DATE = B.Perf_Date
	AND A.obsv_cd = B.obsv_cd;

WITH CTE
AS (
	SELECT A.episode_no,
		A.pt_id,
		A.vst_id,
		A.vst_no,
		A.obsv_cd,
		A.obsv_cd_name,
		A.obsv_user_id,
		dbo.c_udf_NumericChars(A.Min_Val) AS Min_Val,
		A.val_sts_cd,
		A.Perf_Date,
		A.RN,
		A.KeepFlag,
		[EventNum] = ROW_NUMBER() OVER (
			PARTITION BY A.EPISODE_NO,
			A.OBSV_CD ORDER BY A.PERF_DATE
			)
	FROM #TEMPC AS A
	WHERE A.KeepFlag = 1
	)
SELECT C1.episode_no,
	C1.obsv_cd,
	C1.obsv_cd_name,
	C1.obsv_user_id,
	C1.Min_Val,
	C1.Perf_Date,
	C1.EventNum,
	[Delta] = (CAST(C1.Min_Val AS FLOAT) - CAST(C2.Min_Val AS FLOAT))
INTO #Deltas
FROM CTE AS C1
LEFT OUTER JOIN CTE AS C2 ON C1.episode_no = C2.episode_no
	AND C1.obsv_cd = C2.obsv_cd
	AND C1.EventNum = C2.EventNum + 1
;

-- Check to see if there is an increase in 20 or more for Fi02
-- Check to see if there is an increase in 3 or more for PEEP
-- Fi02 Delta >= 20
-- Peep Delta >= 3
SELECT A.episode_no
, A.obsv_cd
, A.obsv_cd_name
, A.obsv_user_id
, A.Perf_Date
, A.Min_Val
, A.EventNum
, A.Delta
, [Threshold_Flag] = 
	CASE
		WHEN A.obsv_cd = 'A_BMH_VFFiO2'
		AND A.Delta >= 20
			THEN 1
		WHEN A.obsv_cd = 'A_BMH_VFPEEP'
			AND A.Delta >= 3
			THEN 1
			ELSE 0
    END
, [Fi02_Threshold_Flag] = CASE WHEN A.obsv_cd = 'A_BMH_VFFiO2' AND A.Delta >= 20 THEN 1 ELSE 0 END
, [PEEP_Threshold_Flag] = CASE WHEN A.obsv_cd = 'A_BMH_VFPEEP' AND A.Delta >= 3 THEN 1 ELSE 0 END
INTO #ThresholdFlags
FROM #Deltas AS A
;

/*
Period of Stability Check

Stability or improvement is defined by ≥ 2 calendar days of stable or decreasing daily minimum† 
FiO2 or PEEP values. 

The baseline period is defined as the 2 calendar days immediately preceding the first day of 
increased daily minimum PEEP or FiO2.

Part A is build a flag to show possible stability, so Fi02 and PEEP threshold flags = 0 then 
Stability_Check_A = 1
*/
SELECT A.episode_no
, A.obsv_cd
, A.obsv_cd_name
, A.obsv_user_id
, A.Perf_Date
, A.Min_Val
, A.EventNum
, A.Delta
, A.Threshold_Flag
, A.Fi02_Threshold_Flag
, A.PEEP_Threshold_Flag
, [Stability_Check_A] = CASE WHEN A.Threshold_Flag = 0 AND A.Delta IS NOT NULL THEN 1 ELSE 0 END 
, [Fi02_Stability] = CASE 
	WHEN a.Delta IS NOT NULL
	AND A.obsv_cd = 'A_BMH_VFFiO2'
	AND a.Fi02_Threshold_Flag = 0
		THEN 1
		ELSE 0
	END
, [PEEP_Stability] = CASE
	WHEN A.DELTA IS NOT NULL
	AND A.obsv_cd = 'A_BMH_VFPEEP'
	AND A.PEEP_THRESHOLD_FLAG = 0
		THEN 1
		ELSE 0
	END
INTO #StabilityA
FROM #ThresholdFlags AS A
;

SELECT CRT.episode_no
--, CRT.obsv_cd
, CRT.EventNum
, CRT.obsv_cd_name
--, CRT.obsv_user_id
, CRT.Perf_Date
, CRT.Min_Val AS [Min_Daily_Fi02]
, CRT.Delta AS [Fi02_Delta]
--, CRT.Fi02_Threshold_Flag
, CRT2.obsv_cd_name
, CRT2.Min_Val AS [Min_Daily_PEEP]
, CRT2.Delta AS [PEEP_Delta]
--, CRT2.PEEP_Threshold_Flag
--, CRT.Fi02_Threshold_Flag
--, CRT.PEEP_Threshold_Flag
--, CRT.Stability_Check_A
--, CRT.Fi02_Stability
--, CRT.PEEP_Stability
--, 1 AS GroupNum
--, 1 AS GroupEventNum
FROM #StabilityA AS CRT
LEFT OUTER JOIN #StabilityA AS CRT2
ON CRT.episode_no = CRT2.episode_no
	AND CRT.obsv_cd != CRT2.obsv_cd
	AND CRT.Perf_Date = CRT2.Perf_Date
	
WHERE CRT.obsv_cd = 'A_BMH_VFFiO2'

-- DROP TABLE STATEMENTS
DROP TABLE #TEMPA
DROP TABLE #TEMPB
DROP TABLE #TEMPC
DROP TABLE #Deltas
DROP TABLE #ThresholdFlags
DROP TABLE #StabilityA
;
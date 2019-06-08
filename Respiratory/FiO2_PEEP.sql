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
	AND episode_no = '14450357'
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
		MIN(dsply_val) AS [Min_Val]
	FROM #TEMPB AS Z
	GROUP BY episode_no,
		Perf_Date
	) AS B ON A.episode_no = B.episode_no
	AND A.PERF_DATE = B.Perf_Date;

SELECT A.episode_no,
	A.pt_id,
	A.vst_id,
	A.vst_no,
	A.obsv_cd,
	A.obsv_cd_name,
	A.obsv_user_id,
	A.Min_Val,
	A.val_sts_cd,
	A.Perf_Date,
	A.RN,
	A.KeepFlag,
	[EventNum] = ROW_NUMBER() OVER (
		PARTITION BY A.EPISODE_NO,
		A.OBSV_CD ORDER BY A.PERF_DATE
		)
FROM #TEMPC AS A
WHERE A.KeepFlag = 1;

WITH CTE
AS (
	SELECT A.episode_no,
		A.pt_id,
		A.vst_id,
		A.vst_no,
		A.obsv_cd,
		A.obsv_cd_name,
		A.obsv_user_id,
		A.Min_Val,
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
	C2.obsv_cd,
	C2.obsv_cd_name,
	C2.obsv_user_id,
	C2.Min_Val,
	C2.Perf_Date,
	C3.obsv_cd,
	C3.obsv_cd_name,
	C3.obsv_user_id,
	C3.Min_Val,
	C3.Perf_Date,
	C1.RN,
	C2.RN,
	C3.RN,
	C1.KeepFlag,
	C2.KeepFlag,
	C3.KeepFlag,
	C1.EventNum AS C1EVNTNUM,
	C2.EventNum AS C2EVNTNUM,
	C3.EventNum AS C3EVNTNUM
FROM CTE AS C1
LEFT OUTER JOIN CTE AS C2 ON C1.episode_no = C2.episode_no
	AND C1.obsv_cd = C2.obsv_cd
	AND C1.EventNum = C2.EventNum - 1
LEFT OUTER JOIN CTE AS C3 ON C1.episode_no = C2.episode_no
	AND C1.obsv_cd = C3.obsv_cd
	AND C1.EventNum = C3.EventNum - 2
WHERE C2.episode_no IS NOT NULL;

--DROP TABLE #TEMPA
--DROP TABLE #TEMPB
--DROP TABLE #TEMPC
--;
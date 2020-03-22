/*
***********************************************************************
File: respiratory_fs_audit.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_soarian_real_time_census_cdi_v
    smsmir.obsv

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Audit Respiratory FS data for inhouse patients

Revision History:
Date		Version		Description
----		----		----
2020-03-03	v1			Initial Creation
***********************************************************************
*/
-- RT CENSUS
SELECT DISTINCT PT_ID,
	pt_no_num,
	pt_first_name,
	pt_last_name,
	adm_dtime
INTO #CENSUS
FROM SMSDSS.c_soarian_real_time_census_CDI_v

-- base pop
SELECT OBS.episode_no,
	OBS.obsv_cd,
	OBS.obsv_cd_name,
	OBS.form_usage,
	OBS.dsply_val,
	CAST(OBS.perf_date AS DATE) AS [Perf_Date],
	CAST(CEN.adm_dtime AS DATE) AS [Adm_Date],
	CEN.pt_first_name,
	CEN.pt_last_name
INTO #BASEPOP
FROM SMSMIR.obsv AS OBS
INNER JOIN #CENSUS AS CEN ON OBS.episode_no = CEN.pt_no_num
WHERE (OBS.obsv_cd IN ('A_BMH_VFSTART', 'A_BMH_VFSTOP', 'A_BMH_VFFiO2', 'A_BMH_VFPEEP', 'A_BMH_RESPEDU'))
	AND OBS.dsply_val != '-';

-- VFSTART
SELECT DISTINCT A.episode_no,
	CAST(A.Adm_Date AS DATE) AS [Adm_Date],
	A.pt_first_name,
	A.pt_last_name,
	A.obsv_cd,
	CAST(A.dsply_val AS DATETIME) AS [Vent_Start_DT],
	MAX(A.Perf_Date) OVER (
		PARTITION BY A.EPISODE_NO,
		A.DSPLY_VAL
		) AS [Last_Start_Check],
	[Vent_Days] = DATEDIFF(DAY, CAST(A.DSPLY_VAL AS DATETIME), MAX(A.Perf_Date) OVER (
			PARTITION BY A.EPISODE_NO,
			A.DSPLY_VAL
			))
INTO #VFSTART
FROM #BASEPOP AS A
WHERE A.obsv_cd = 'A_BMH_VFStart';

-- VFSTOP
SELECT DISTINCT A.episode_no,
	CAST(A.Adm_Date AS DATE) AS [Adm_Date],
	A.pt_first_name,
	A.pt_last_name,
	A.obsv_cd,
	CAST(A.dsply_val AS DATETIME) AS [Vent_Stop_DT],
	MAX(A.Perf_Date) OVER (
		PARTITION BY A.EPISODE_NO,
		A.DSPLY_VAL
		) AS [Last_Stop_Check]
INTO #VFSTOP
FROM #BASEPOP AS A
WHERE A.obsv_cd = 'A_BMH_VFStop';

-- vffi02
SELECT DISTINCT A.episode_no,
	CAST(A.Adm_Date AS DATE) AS [Adm_Date],
	A.pt_first_name,
	A.pt_last_name,
	A.obsv_cd,
	MIN(dsply_val) OVER (
		PARTITION BY EPISODE_NO ORDER BY PERF_DATE
		) AS [FI02_Val],
	MAX(Perf_Date) OVER (
		PARTITION BY EPISODE_NO,
		PERF_DATE ORDER BY PERF_DATE
		) AS [Last_FiO2_Check]
INTO #VFFI02
FROM #BASEPOP AS A
WHERE A.obsv_cd = 'A_BMH_VFFiO2';

-- peep
SELECT DISTINCT A.episode_no,
	CAST(A.Adm_Date AS DATE) AS [Adm_Date],
	A.pt_first_name,
	A.pt_last_name,
	A.obsv_cd,
	MIN(dsply_val) OVER (
		PARTITION BY EPISODE_NO ORDER BY PERF_DATE
		) AS [PEEP_Val],
	MAX(Perf_Date) OVER (
		PARTITION BY EPISODE_NO,
		PERF_DATE ORDER BY PERF_DATE
		) AS [Last_PEEP_Check]
INTO #VFPEEP
FROM #BASEPOP AS A
WHERE A.obsv_cd = 'A_BMH_VFPEEP';

-- edu
SELECT DISTINCT A.episode_no,
	CAST(A.Adm_Date AS DATE) AS [Adm_Date],
	A.pt_first_name,
	A.pt_last_name,
	A.obsv_cd,
	MIN(dsply_val) OVER (
		PARTITION BY EPISODE_NO ORDER BY PERF_DATE
		) AS [EDU_Val],
	MAX(Perf_Date) OVER (
		PARTITION BY EPISODE_NO,
		PERF_DATE ORDER BY PERF_DATE
		) AS [Last_EDU_Check]
INTO #EDUC
FROM #BASEPOP AS A
WHERE A.obsv_cd = 'A_BMH_RESPEDU';

SELECT A.episode_no,
	A.Adm_Date,
	A.pt_first_name,
	A.pt_last_name,
	A.obsv_cd,
	A.Vent_Start_DT,
	A.Last_Start_Check,
	A.Vent_Days,
	B.Vent_Stop_DT,
	B.Last_Stop_Check,
	C.FI02_Val,
	C.Last_FiO2_Check,
	D.PEEP_Val,
	D.Last_PEEP_Check,
	E.EDU_Val,
	E.Last_EDU_Check
FROM #VFSTART AS A
LEFT JOIN #VFSTOP AS B ON A.episode_no = B.episode_no
	AND B.Last_Stop_Check >= A.Last_Start_Check
	AND B.Last_Stop_Check <= A.Last_Start_Check
OUTER APPLY (
	SELECT TOP 1 *
	FROM #VFFI02 AS ZZZ
	WHERE ZZZ.episode_no = A.episode_no
	ORDER BY ZZZ.[Last_FiO2_Check] DESC
	) AS C
OUTER APPLY (
	SELECT TOP 1 *
	FROM #VFPEEP AS ZZZ
	WHERE ZZZ.episode_no = A.episode_no
	ORDER BY ZZZ.Last_PEEP_Check DESC
	) AS D
OUTER APPLY (
	SELECT TOP 1 *
	FROM #EDUC AS ZZZ
	WHERE ZZZ.episode_no = A.episode_no
	ORDER BY ZZZ.Last_EDU_Check DESC
	) AS E;

DROP TABLE #CENSUS

DROP TABLE #BASEPOP

DROP TABLE #VFSTART

DROP TABLE #VFSTOP

DROP TABLE #VFFI02

DROP TABLE #VFPEEP

DROP TABLE #EDUC;

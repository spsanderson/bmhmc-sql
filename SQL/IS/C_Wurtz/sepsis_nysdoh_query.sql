/*
***********************************************************************
File: sepsis_nysdoh_query.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_sepsis_evaluator_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get the encounters and associated data for the NYSDOH sepsis abstraction

	To get all of the csv file tables (appendix tables) run the following:
	SELECT schema_name(t.schema_id) AS schema_name,
		t.name AS table_name,
		[full_name] = cast(SCHEMA_NAME(t.schema_id) as varchar) + '.' + t.name
	FROM sys.tables t
	WHERE t.name LIKE 'c_nysdoh_sepsis_%'
	ORDER BY table_name,
		schema_name;

	lab dsply_val regex from https://stackoverflow.com/questions/20116769/extract-float-from-string-text-sql-server

Revision History:
Date		Version		Description
----		----		----
2021-03-15	v1			Initial Creation
***********************************************************************
*/

-- Get the base population of persons we are interested in
DROP TABLE IF EXISTS #BasePopulation
	CREATE TABLE #BasePopulation (
		Pt_No VARCHAR(12),
		PtNo_Num VARCHAR(12),
		unit_seq_no VARCHAR(12),
		from_file_ind VARCHAR(10),
		Bl_Unit_Key VARCHAR(25),
		Pt_Key VARCHAR(25),
		vst_start_dtime DATETIME,
		vst_end_dtime DATETIME
		)

INSERT INTO #BasePopulation (
	Pt_No,
	PtNo_Num,
	unit_seq_no,
	from_file_ind,
	Bl_Unit_Key,
	Pt_Key,
	vst_start_dtime,
	vst_end_dtime
	)
SELECT A.Pt_No,
	SUBSTRING(A.Pt_No, 5, 8) AS [PtNo_Num],
	A.unit_seq_no,
	A.from_file_ind,
	A.Bl_Unit_Key,
	A.Pt_Key,
	A.vst_start_dtime,
	A.vst_end_dtime
FROM [smsdss].[c_sepsis_evaluator_v] AS A
WHERE (
		SEP_Ind = 1
		OR (
			COVID_Ind = 1
			AND ORGF_Ind = 1
			)
		)
	AND Dsch_Date >= '2020-12-01'
	AND Dsch_Date < '2021-01-01'
	AND PT_Age >= 21
	AND LEFT(A.PT_NO, 5) NOT IN ('00003', '00006', '00007');

-- Comorbidities ------------------------------------------------------
-- acute cardiovascular conditions
DROP TABLE IF EXISTS #acc_tbl;
	WITH ACC
	AS (
		SELECT DISTINCT A.pt_id,
			B.icd10_cm_code,
			B.icd10_cm_code_description,
			B.subcategory,
			CASE 
				WHEN B.subcategory = 'Stroke/TIA'
					THEN '2'
				WHEN B.subcategory = 'MI'
					THEN '1'
				ELSE '0'
				END AS [acute_cardiovascular_conditions]
		FROM smsmir.dx_grp AS A
		INNER JOIN smsdss.c_nysdoh_sepsis_acute_cardiovascular_conditions_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
		)
	SELECT PVT.pt_id,
		SUBSTRING(PVT.PT_ID, 5, 8) AS [PtNo_Num],
		[acute_cardiovascular_conditions] = CASE 
			WHEN LEN(COALESCE(PVT.[0] + ':', '') + COALESCE(PVT.[1] + ':', '') + COALESCE(PVT.[2] + ':', '')) = 2
				THEN LEFT(COALESCE(PVT.[0] + ':', '') + COALESCE(PVT.[1] + ':', '') + COALESCE(PVT.[2] + ':', ''), 1)
			WHEN LEN(COALESCE(PVT.[0] + ':', '') + COALESCE(PVT.[1] + ':', '') + COALESCE(PVT.[2] + ':', '')) = 4
				THEN LEFT(COALESCE(PVT.[0] + ':', '') + COALESCE(PVT.[1] + ':', '') + COALESCE(PVT.[2] + ':', ''), 3)
			WHEN LEN(COALESCE(PVT.[0] + ':', '') + COALESCE(PVT.[1] + ':', '') + COALESCE(PVT.[2] + ':', '')) = 6
				THEN LEFT(COALESCE(PVT.[0] + ':', '') + COALESCE(PVT.[1] + ':', '') + COALESCE(PVT.[2] + ':', ''), 5)
			END
	INTO #acc_tbl
	FROM ACC
	INNER JOIN #BasePopulation AS BP ON ACC.pt_id = BP.Pt_No
	PIVOT(MAX(ACUTE_CARDIOVASCULAR_CONDITIONS) FOR ACUTE_CARDIOVASCULAR_CONDITIONS IN ("0", "1", "2")) AS PVT;

-- AIDS / HIV
DROP TABLE IF EXISTS #aids_hiv_tbl
	CREATE TABLE #aids_hiv_tbl (
		pt_id VARCHAR(12),
		aids_hiv VARCHAR(10)
		)

INSERT INTO #aids_hiv_tbl (
	pt_id,
	aids_hiv
	)
SELECT DISTINCT A.pt_id,
	[aids_hiv] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_aids_hiv_disease_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No

-- altered mental status
DROP TABLE IF EXISTS #ams
	CREATE TABLE #ams (
		pt_id VARCHAR(12),
		altered_mental_status VARCHAR(10)
		)

INSERT INTO #ams (
	pt_id,
	altered_mental_status
	)
SELECT DISTINCT A.pt_id,
	[altered_mental_status] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_altered_mental_status_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- Asthma
DROP TABLE IF EXISTS #asthma
	CREATE TABLE #asthma (
		pt_id VARCHAR(12),
		asthma VARCHAR(10)
		)

INSERT INTO #asthma (
	pt_id,
	asthma
	)
SELECT DISTINCT A.pt_id,
	[asthma] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_asthma_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No

-- Chronic Liver Disease
DROP TABLE IF EXISTS #cld
	CREATE TABLE #cld (
		pt_id VARCHAR(12),
		chronic_liver_disease VARCHAR(10)
		)

INSERT INTO #cld (
	pt_id,
	chronic_liver_disease
	)
SELECT DISTINCT A.pt_id,
	[chronic_liver_disease] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_chronic_liver_disease_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No

-- Chronic Renal Failure
DROP TABLE IF EXISTS #crf
	CREATE TABLE #crf (
		pt_id VARCHAR(12),
		chronic_renal_failure VARCHAR(10)
		)

INSERT INTO #crf (
	pt_id,
	chronic_renal_failure
	)
SELECT DISTINCT A.pt_id,
	[chronic_renal_failure] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_chronic_renal_failure_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.PT_NO

-- Chronic Respiratory Failure
DROP TABLE IF EXISTS #crespfailure
	CREATE TABLE #crespfailure (
		pt_id VARCHAR(12),
		chronic_respiratory_failure VARCHAR(10)
		)

INSERT INTO #crespfailure (
	pt_id,
	chronic_respiratory_failure
	)
SELECT DISTINCT A.pt_id,
	[chronic_respiratory_failure] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_chronic_respiratory_failure_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No

-- Coagulopathy
DROP TABLE IF EXISTS #coagulopathy
	CREATE TABLE #coagulopathy (
		pt_id VARCHAR(12),
		coagulopathy VARCHAR(10)
		)

INSERT INTO #coagulopathy (
	pt_id,
	coagulopathy
	)
SELECT DISTINCT A.pt_id,
	[coagulopathy] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_coagulopathy_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No

-- Congestive Heart Failure
DROP TABLE IF EXISTS #chf
	CREATE TABLE #chf (
		pt_id VARCHAR(12),
		congestive_heart_failure VARCHAR(10)
		)

INSERT INTO #chf (
	pt_id,
	congestive_heart_failure
	)
SELECT DISTINCT A.pt_id,
	[congestive_heart_failure] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_congestive_heart_failure_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- COPD
DROP TABLE IF EXISTS #copd
	CREATE TABLE #copd (
		pt_id VARCHAR(12),
		copd VARCHAR(10)
		)

INSERT INTO #copd (
	pt_id,
	copd
	)
SELECT DISTINCT A.pt_id,
	[copd] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_copd_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- Organ Dysfunction CNS
DROP TABLE IF EXISTS #od_cns
	CREATE TABLE #od_cns (
		pt_id VARCHAR(12),
		organ_dysfunc_cns VARCHAR(10)
		)

INSERT INTO #od_cns (
	pt_id,
	organ_dysfunc_cns
	)
SELECT DISTINCT pt_id,
	[organ_dysfunc_cns] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_copd_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- Organ Dysfunction Respiratory
DROP TABLE IF EXISTS #od_resp
	CREATE TABLE #od_resp (
		pt_id VARCHAR(12),
		organ_dysfunc_respiratory VARCHAR(10)
		)

INSERT INTO #od_resp
SELECT DISTINCT pt_id,
	[organ_dysfunc_respiratory] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_organ_dysfunc_respiratory_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No


-- Dementia
DROP TABLE IF EXISTS #dementia_tbl
CREATE TABLE #dementia_tbl (
	pt_id VARCHAR(12),
	dementia VARCHAR(10)
	)

INSERT INTO #dementia_tbl (
	pt_id,
	dementia
	)
SELECT DISTINCT A.pt_id,
	[dementia] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_dementia_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No


-- DIABETES
DROP TABLE IF EXISTS #diabetes_tbl
CREATE TABLE #diabetes_tbl (
	pt_id VARCHAR(12),
	diabetes VARCHAR(10)
	)

INSERT INTO #diabetes_tbl (
	pt_id,
	diabetes
	)
SELECT DISTINCT A.pt_id,
	[diabetes] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_diabetes_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No


-- dialysis_comorbidity
DROP TABLE IF EXISTS #dialysis_comorbidity_tbl
CREATE TABLE #dialysis_comorbidity_tbl (
	pt_id VARCHAR(12),
	dialysis_comorbidity VARCHAR(10)
	)

INSERT INTO #dialysis_comorbidity_tbl (
	pt_id,
	dialysis_comorbidity
	)
SELECT DISTINCT A.pt_id,
	[dialysis_comorbidity] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_dialysis_comorbidity_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No


-- History Of COVID
DROP TABLE IF EXISTS #history_of_covid_tbl
CREATE TABLE #history_of_covid_tbl (
	pt_id VARCHAR(12),
	history_of_covid DATETIME
	)

INSERT INTO #history_of_covid_tbl (
	pt_id,
	history_of_covid
	)
SELECT DISTINCT A.PTNO_NUM,
	[history_of_covid] = A.first_positive_flag_dtime
FROM SMSDSS.c_covid_extract_tbl AS a
INNER JOIN #BasePopulation AS BP ON A.PTNO_NUM = BP.PtNo_Num
WHERE A.first_positive_flag_dtime IS NOT NULL


-- History of Other CVD 
/*
subcategory
Cerebrovascular Disease      - 4
Coronary Heart Disease       - 1
Peripheral arterial disease  - 2 
Valve disorder               - 3

1 = Coronary heart disease (e.g. angina pectoris, coronary atherosclerosis)
2 = Peripheral artery disease
3 = Valve disorder
4 = Cerebrovascular disease
0 = No history of coronary heart disease, peripheral artery disease, valve disorder or cerebrovascular disease
*/
DROP TABLE IF EXISTS #history_of_other_cvd_tbl
CREATE TABLE #history_of_other_cvd_tbl (
	pt_id VARCHAR(12),
	subcategory VARCHAR(100)
	)

INSERT INTO #history_of_other_cvd_tbl (
	pt_id,
	subcategory
	)
SELECT DISTINCT A.pt_id,
	b.subcategory
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_history_of_other_cvd_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No


DROP TABLE IF EXISTS #history_of_other_cvd_pvt_tbl
CREATE TABLE #history_of_other_cvd_pvt_tbl (
	pt_id VARCHAR(12),
	cvd VARCHAR(50),
	chd VARCHAR(50),
	pad VARCHAR(50),
	vd VARCHAR(50)
	)

INSERT INTO #history_of_other_cvd_pvt_tbl
SELECT PVT_HX_OTHER_CVD.pt_id,
	PVT_HX_OTHER_CVD.[Cerebrovascular Disease] AS [cvd],
	PVT_HX_OTHER_CVD.[Coronary Heart Disease] AS [chd],
	PVT_HX_OTHER_CVD.[Peripheral arterial disease] AS [pad],
	PVT_HX_OTHER_CVD.[Valve disorder] AS [vd]
FROM (
	SELECT pt_id,
		subcategory
	FROM #history_of_other_cvd_tbl
	) AS A
PIVOT(MAX(SUBCATEGORY) FOR SUBCATEGORY IN ("Cerebrovascular Disease", "Coronary Heart Disease", "Peripheral arterial disease", "Valve disorder")) AS PVT_HX_OTHER_CVD


DROP TABLE IF EXISTS #history_of_other_cvd_pvt_final_tbl
CREATE TABLE #history_of_other_cvd_pvt_final_tbl (
	pt_id VARCHAR(12),
	CHD VARCHAR(1),
	PAD VARCHAR(1),
	VD VARCHAR(1),
	CVD VARCHAR(1)
	)

INSERT INTO #history_of_other_cvd_pvt_final_tbl (
	pt_id,
	CHD,
	PAD,
	VD,
	CVD
	)
SELECT pt_id,
	CASE 
		WHEN chd IS NOT NULL
			THEN 1
		ELSE NULL
		END AS CHD,
	CASE 
		WHEN PAD IS NOT NULL
			THEN 2
		ELSE NULL
		END AS PAD,
	CASE 
		WHEN VD IS NOT NULL
			THEN 3
		ELSE NULL
		END AS VD,
	CASE 
		WHEN CVD IS NOT NULL
			THEN 4
		ELSE NULL
		END AS CVD
FROM #history_of_other_cvd_pvt_tbl


DROP TABLE IF EXISTS #hx_of_other_cvd_tbl
CREATE TABLE #hx_of_other_cvd_tbl (
	pt_id VARCHAR(12),
	history_of_other_cvd VARCHAR(20)
)
INSERT INTO #hx_of_other_cvd_tbl (pt_id, history_of_other_cvd)
SELECT pt_id,
	CASE
		WHEN LEN(CONCAT(chd,pad,vd,cvd)) = 1
			THEN CONCAT(chd,pad,vd,cvd)
		WHEN LEN(CONCAT(chd,pad,vd,cvd)) = 2
			THEN SUBSTRING(CONCAT(chd,pad,vd,cvd), 1, 1) 
				+ ':' 
				+ SUBSTRING(CONCAT(chd,pad,vd,cvd), 2, 1)
		WHEN LEN(CONCAT(chd,pad,vd,cvd)) = 3
			THEN SUBSTRING(CONCAT(chd,pad,vd,cvd), 1, 1) 
				+ ':' 
				+ SUBSTRING(CONCAT(chd,pad,vd,cvd), 2, 1) 
				+ ':' 
				+ SUBSTRING(CONCAT(chd,pad,vd,cvd), 3, 1)
		WHEN LEN(CONCAT(chd,pad,vd,cvd)) = 4
			THEN SUBSTRING(CONCAT(chd,pad,vd,cvd), 1, 1) 
				+ ':' 
				+ SUBSTRING(CONCAT(chd,pad,vd,cvd), 2, 1) 
				+ ':' 
				+ SUBSTRING(CONCAT(chd,pad,vd,cvd), 3, 1)
				+ ':'
				+ SUBSTRING(CONCAT(CHD,PAD,VD,CVD), 4, 1)
		END
FROM #history_of_other_cvd_pvt_final_tbl

-- HYPERTENSION
DROP TABLE IF EXISTS #hyptertension
CREATE TABLE #hypertension (
	pt_id VARCHAR(12),
	hypertension VARCHAR(10)
	)

INSERT INTO #hypertension (
	pt_id,
	hypertension
	)
SELECT A.pt_id,
	[hypertension] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM SMSMIR.dx_grp AS A
INNER JOIN SMSDSS.c_nysdoh_sepsis_hypertension_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No


-- Severity Variables -------------------------------------------------
-- aPPT
DROP TABLE IF EXISTS #appt
CREATE TABLE #appt (
	episode_no VARCHAR(12),
	coll_dtime DATETIME,
	lab_number INT,
	disp_val VARCHAR(200)
	)

INSERT INTO #appt (
	episode_no,
	coll_dtime,
	lab_number,
	disp_val
	)
SELECT A.episode_no,
	A.coll_dtime,
	[lab_number] = ROW_NUMBER() OVER (
		PARTITION BY A.episode_no ORDER BY A.coll_dtime
		),
	[disp_val] = CASE 
		WHEN CAST(a.val_no AS VARCHAR) IS NULL
			THEN CAST(LEFT(SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1), PatIndex('%[^0-9.-]%', SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1))) AS VARCHAR)
		ELSE CAST(A.VAL_NO AS VARCHAR)
		END
--[dsply_val] = LEFT(SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1), PatIndex('%[^0-9.-]%', SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1)))
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE obsv_cd = '00403154'



DROP TABLE IF EXISTS #max_appt
CREATE TABLE #max_appt (
	episode_no VARCHAR(12),
	appt_max VARCHAR(200),
	appt_dt_max DATETIME,
	rn INT
	)

INSERT INTO #max_appt (
	episode_no,
	appt_max,
	appt_dt_max,
	rn
	)
SELECT episode_no,
	disp_val,
	coll_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY EPISODE_NO ORDER BY DISP_VAL DESC
		)
FROM #appt

DELETE
FROM #max_appt
WHERE RN != 1


DROP TABLE IF EXISTS #appt_pvt 
CREATE TABLE #appt_pvt (
	episode_no VARCHAR(12),
	appt_1 VARCHAR(10) NULL,
	appt_dt_1 DATETIME NULL,
	appt_2 VARCHAR(10) NULL,
	appt_dt_2 DATETIME NULL,
	appt_3 VARCHAR(10) NULL,
	appt_dt_3 DATETIME NULL
	)

INSERT INTO #appt_pvt (
	episode_no,
	appt_1,
	appt_dt_1,
	appt_2,
	appt_dt_2,
	appt_3,
	appt_dt_3
	)
SELECT episode_no,
	MAX([1]) AS [appt_1],
	MAX([01]) AS [appt_dt_1],
	MAX([2]) AS [appt_2],
	MAX([02]) AS [appt_dt_2],
	MAX([3]) AS [appt_3],
	MAX([03]) AS [appt_dt_3]
FROM (
	SELECT episode_no,
		disp_val,
		coll_dtime,
		lab_number,
		lab_number2 = '0' + CAST(lab_number AS VARCHAR)
	FROM #APPT
	WHERE lab_number <= 3
	) AS A
PIVOT(MAX(disp_val) FOR LAB_NUMBER IN ("1", "2", "3")) AS PVT_APPT
PIVOT(MAX(coll_dtime) FOR LAB_NUMBER2 IN ("01", "02", "03")) AS PVT_COLL_DTIME
GROUP BY episode_no



-- Diastolic BP
-- WellSoft
DROP TABLE IF EXISTS #ws_diastolic
CREATE TABLE #ws_diastolic (
	episode_no VARCHAR(10),
	bp_diastolic VARCHAR(10),
	collected_datetime DATETIME
	)

INSERT INTO #ws_diastolic (
	episode_no,
	bp_diastolic,
	collected_datetime
	)
SELECT A.account,
	A.bp_diastolic,
	A.collected_datetime
FROM smsdss.c_sepsis_ws_vitals_tbl AS A
INNER JOIN #BasePopulation AS BP ON A.account = BP.PtNo_Num
WHERE bp_diastolic IS NOT NULL
	AND bp_diastolic NOT IN ('Patient refused', 'Refused', 'refused v/s', 'unknown')


-- Soarian
DROP TABLE IF EXISTS #sr_diastolic
CREATE TABLE #sr_diastolic (
	episode_no VARCHAR(12),
	bp_diastolic VARCHAR(20),
	obsv_cre_dtime DATETIME
	)

INSERT INTO #sr_diastolic (
	episode_no,
	bp_diastolic,
	obsv_cre_dtime
	)
SELECT episode_no,
	bp_diastolic = RIGHT(DSPLY_VAL, CHARINDEX('/', REVERSE(DSPLY_VAL), 1) - 1),
	obsv_cre_dtime
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE obsv_cd = 'A_BP'



DROP TABLE IF EXISTS #bp_diastolic
CREATE TABLE #bp_diastolic (
	episode_no VARCHAR(12),
	bp_diastolic VARCHAR(20),
	obsv_dtime DATETIME,
	bp_reading_num INT
	)

INSERT INTO #bp_diastolic (
	episode_no,
	bp_diastolic,
	obsv_dtime,
	bp_reading_num
	)
SELECT A.episode_no,
	A.bp_diastolic,
	A.collected_datetime,
	[bp_reading_num] = ROW_NUMBER() OVER (
		PARTITION BY A.episode_no ORDER BY A.collected_datetime
		)
FROM (
	SELECT *
	FROM #ws_diastolic
	
	UNION
	
	SELECT *
	FROM #sr_diastolic
	) AS A



DROP TABLE IF EXISTS #min_ws_diastolic
CREATE TABLE #min_ws_diastolic (
	episode_no VARCHAR(12),
	diastolic_min VARCHAR(10),
	diastolic_dt_min DATETIME,
	rn INT
	)

INSERT INTO #min_ws_diastolic (
	episode_no,
	diastolic_min,
	diastolic_dt_min,
	rn
	)
SELECT episode_no,
	bp_diastolic,
	obsv_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY CAST(bp_diastolic AS INT) ASC
		)
FROM #bp_diastolic

DELETE
FROM #min_ws_diastolic
WHERE rn != 1;



DROP TABLE IF EXISTS #ws_bp_diastolic_pvt
CREATE TABLE #ws_bp_diastolic_pvt (
	episode_no VARCHAR(10),
	diastolic_1 VARCHAR(10),
	diastolic_dt_1 DATETIME,
	diastolic_2 VARCHAR(10),
	diastolic_dt_2 DATETIME,
	diastolic_3 VARCHAR(10),
	diastolic_dt_3 DATETIME
	)

INSERT INTO #ws_bp_diastolic_pvt (
	episode_no,
	diastolic_1,
	diastolic_dt_1,
	diastolic_2,
	diastolic_dt_2,
	diastolic_3,
	diastolic_dt_3
	)
SELECT episode_no,
	MAX([1]) AS [diastolic_1],
	MAX([01]) AS [diastolic_dt_1],
	MAX([2]) AS [diastolic_2],
	MAX([02]) AS [diastolic_dt_2],
	MAX([3]) AS [diastolic_3],
	MAX([03]) AS [diastolic_dt_3]
FROM (
	SELECT episode_no,
		bp_diastolic,
		obsv_dtime,
		bp_reading_num,
		bp_reading_num2 = '0' + CAST(bp_reading_num AS VARCHAR)
	FROM #bp_diastolic
	WHERE bp_reading_num <= 3
	) AS A
PIVOT(MAX(bp_diastolic) FOR bp_reading_num IN ("1", "2", "3")) AS PVT_BP_DIASTOLIC
PIVOT(MAX(obsv_dtime) FOR bp_reading_num2 IN ("01", "02", "03")) AS PVT_BP_COLL_DTIME
GROUP BY episode_no


-- INR
DROP TABLE IF EXISTS #inr
CREATE TABLE #inr (
	episode_no VARCHAR(12),
	coll_dtime DATETIME,
	lab_number INT,
	disp_val VARCHAR(200)
	)

INSERT INTO #inr (
	episode_no,
	coll_dtime,
	lab_number,
	disp_val
	)
SELECT A.episode_no,
	A.coll_dtime,
	[lab_number] = ROW_NUMBER() OVER (
		PARTITION BY A.episode_no ORDER BY A.coll_dtime
		),
	[disp_val] = CASE 
		WHEN CAST(a.val_no AS VARCHAR) IS NULL
			THEN CAST(LEFT(SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1), PatIndex('%[^0-9.-]%', SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1))) AS VARCHAR)
		ELSE CAST(A.VAL_NO AS VARCHAR)
		END
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE A.obsv_cd = '2012'



DROP TABLE IF EXISTS #max_inr
CREATE TABLE #max_inr (
	episode_no VARCHAR(12),
	inr_max VARCHAR(20),
	inr_dt_max DATETIME,
	rn INT
	)

INSERT INTO #max_inr (
	episode_no,
	inr_max,
	inr_dt_max,
	rn
	)
SELECT episode_no,
	disp_val,
	coll_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY disp_val DESC
		)
FROM #inr

DELETE
FROM #max_inr
WHERE rn != 1


DROP TABLE IF EXISTS #inr_pvt
CREATE TABLE #inr_pvt (
	episode_no VARCHAR(12),
	inr_1 VARCHAR(10) NULL,
	inr_dt_1 DATETIME NULL,
	inr_2 VARCHAR(10) NULL,
	inr_dt_2 DATETIME NULL,
	inr_3 VARCHAR(10) NULL,
	inr_dt_3 DATETIME NULL
	)

INSERT INTO #inr_pvt (
	episode_no,
	inr_1,
	inr_dt_1,
	inr_2,
	inr_dt_2,
	inr_3,
	inr_dt_3
	)
SELECT episode_no,
	MAX([1]) AS [inr_1],
	MAX([01]) AS [inr_dt_1],
	MAX([2]) AS [inr_2],
	MAX([02]) AS [inr_dt_2],
	MAX([3]) AS [inr_3],
	MAX([03]) AS [inr_dt_3]
FROM (
	SELECT episode_no,
		disp_val,
		coll_dtime,
		lab_number,
		lab_number2 = '0' + CAST(lab_number AS VARCHAR)
	FROM #inr
	WHERE lab_number <= 3
	) AS A
PIVOT(MAX(disp_val) FOR LAB_NUMBER IN ("1", "2", "3")) AS PVT_INR
PIVOT(MAX(coll_dtime) FOR LAB_NUMBER2 IN ("01", "02", "03")) AS PVT_COLL_DTIME
GROUP BY episode_no


-- lactate
DROP TABLE IF EXISTS #lactate
CREATE TABLE #lactate (
	episode_no VARCHAR(12),
	coll_dtime DATETIME,
	lab_number INT,
	disp_val VARCHAR(200)
	)

INSERT INTO #lactate (
	episode_no,
	coll_dtime,
	lab_number,
	disp_val
	)
SELECT a.episode_no,
	a.coll_dtime,
	[lab_number] = ROW_NUMBER() OVER (
		PARTITION BY A.episode_no ORDER BY A.coll_dtime
		),
	[disp_val] = CASE 
		WHEN CAST(a.val_no AS VARCHAR) IS NULL
			THEN CAST(LEFT(SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1), PatIndex('%[^0-9.-]%', SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1))) AS VARCHAR)
		ELSE CAST(A.VAL_NO AS VARCHAR)
		END
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE A.obsv_cd = '00402347'


DROP TABLE IF EXISTS #max_lactate
CREATE TABLE #max_lactate (
	episode_no VARCHAR(12),
	lactate_level_max VARCHAR(20),
	lactate_level_dt_max DATETIME,
	rn INT
	)

INSERT INTO #max_lactate (
	episode_no,
	lactate_level_max,
	lactate_level_dt_max,
	rn
	)
SELECT episode_no,
	disp_val,
	coll_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY disp_val DESC
		)
FROM #lactate

DELETE
FROM #max_lactate
WHERE RN != 1


DROP TABLE IF EXISTS #lactate_pvt
CREATE TABLE #lactate_pvt (
	episode_no VARCHAR(12),
	lactate_level_1 VARCHAR(10) NULL,
	lactate_level_dt_1 DATETIME NULL,
	lactate_level_2 VARCHAR(10) NULL,
	lactate_level_dt_2 DATETIME NULL,
	lactate_level_3 VARCHAR(10) NULL,
	lactate_level_dt_3 DATETIME NULL
	)

INSERT INTO #lactate_pvt (
	episode_no,
	lactate_level_1,
	lactate_level_dt_1,
	lactate_level_2,
	lactate_level_dt_2,
	lactate_level_3,
	lactate_level_dt_3
	)
SELECT episode_no,
	MAX([1]) AS [lactate_level_1],
	MAX([01]) AS [lactate_level_dt_1],
	MAX([2]) AS [lactate_level_2],
	MAX([02]) AS [lactate_level_dt_2],
	MAX([3]) AS [lactate_level_3],
	MAX([03]) AS [lactate_level_dt_3]
FROM (
	SELECT episode_no,
		disp_val,
		coll_dtime,
		lab_number,
		lab_number2 = '0' + CAST(lab_number AS VARCHAR)
	FROM #lactate
	WHERE lab_number <= 3
	) AS A
PIVOT(MAX(disp_val) FOR LAB_NUMBER IN ("1", "2", "3")) AS PVT_INR
PIVOT(MAX(coll_dtime) FOR LAB_NUMBER2 IN ("01", "02", "03")) AS PVT_COLL_DTIME
GROUP BY episode_no


-- Organ Dysfunction Hepatic
DROP TABLE IF EXISTS #od_bilirubin
CREATE TABLE #od_bilirubin (
	episode_no VARCHAR(12),
	coll_dtime DATETIME,
	lab_number INT,
	disp_val VARCHAR(200)
	)

INSERT INTO #od_bilirubin (
	episode_no,
	coll_dtime,
	lab_number,
	disp_val
	)
SELECT A.episode_no,
	A.coll_dtime,
	[lab_number] = ROW_NUMBER() OVER (
		PARTITION BY A.episode_no ORDER BY A.coll_dtime
		),
	[disp_val] = CASE 
		WHEN CAST(a.val_no AS VARCHAR) IS NULL
			THEN CAST(LEFT(SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1), PatIndex('%[^0-9.-]%', SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1))) AS VARCHAR)
		ELSE CAST(A.VAL_NO AS VARCHAR)
		END
--[dsply_val] = LEFT(SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1), PatIndex('%[^0-9.-]%', SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1)))
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE obsv_cd = '00400408'


DROP TABLE IF EXISTS #arrival_bilirubin
CREATE TABLE #arrival_bilirubin (
	episode_no VARCHAR(12),
	organ_dysfunc_hepatic_arrival VARCHAR(20),
	organ_dysfunc_hepatic_arrival_dt DATETIME,
	)

INSERT INTO #arrival_bilirubin (
	episode_no,
	organ_dysfunc_hepatic_arrival,
	organ_dysfunc_hepatic_arrival_dt
	)
SELECT episode_no,
	disp_val,
	coll_dtime
FROM #od_bilirubin
WHERE lab_number = 1


DROP TABLE IF EXISTS #max_bilirubin
CREATE TABLE #max_bilirubin (
	episode_no VARCHAR(12),
	organ_dysfunc_hepatic_max VARCHAR(20),
	organ_dysfunc_hepatic_max_dt DATETIME,
	rn INT
	)

INSERT INTO #max_bilirubin (
	episode_no,
	organ_dysfunc_hepatic_max,
	organ_dysfunc_hepatic_max_dt,
	rn
	)
SELECT episode_no,
	disp_val,
	coll_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY disp_val DESC
		)
FROM #od_bilirubin

DELETE
FROM #max_bilirubin
WHERE RN != 1


-- Organ Dysfunction Renal (creatinine)
DROP TABLE IF EXISTS #od_renal
CREATE TABLE #od_renal (
	episode_no VARCHAR(12),
	coll_dtime DATETIME,
	lab_number INT,
	disp_val VARCHAR(200)
	)

INSERT INTO #od_renal (
	episode_no,
	coll_dtime,
	lab_number,
	disp_val
	)
SELECT A.episode_no,
	A.coll_dtime,
	[lab_number] = ROW_NUMBER() OVER (
		PARTITION BY A.episode_no ORDER BY A.coll_dtime
		),
	[disp_val] = CASE 
		WHEN CAST(a.val_no AS VARCHAR) IS NULL
			THEN CAST(LEFT(SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1), PatIndex('%[^0-9.-]%', SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1))) AS VARCHAR)
		ELSE CAST(A.VAL_NO AS VARCHAR)
		END
--[dsply_val] = LEFT(SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1), PatIndex('%[^0-9.-]%', SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1)))
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE obsv_cd = '00400945'


DROP TABLE IF EXISTS #arrival_creatinine
CREATE TABLE #arrival_creatinine (
	episode_no VARCHAR(12),
	organ_dysfunc_renal_arrival VARCHAR(20),
	organ_dysfunc_renal_arrival_dt DATETIME
	)

INSERT INTO #arrival_creatinine (
	episode_no,
	organ_dysfunc_renal_arrival,
	organ_dysfunc_renal_arrival_dt
	)
SELECT episode_no,
	disp_val,
	coll_dtime
FROM #od_renal
WHERE lab_number = 1


DROP TABLE IF EXISTS #max_creatinine
CREATE TABLE #max_creatinine (
	episode_no VARCHAR(12),
	organ_dysfunc_renal_max VARCHAR(20),
	organ_dysfunc_renal_max_dt DATETIME,
	rn INT
	)

INSERT INTO #max_creatinine (
	episode_no,
	organ_dysfunc_renal_max,
	organ_dysfunc_renal_max_dt,
	rn
	)
SELECT episode_no,
	disp_val,
	coll_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY disp_val DESC
		)
FROM #od_renal

DELETE
FROM #max_creatinine
WHERE RN != 1


-- Platelets
DROP TABLE IF EXISTS #platelets
CREATE TABLE #platelets (
	episode_no VARCHAR(12),
	coll_dtime DATETIME,
	lab_number INT,
	disp_val VARCHAR(200)
	)

INSERT INTO #platelets (
	episode_no,
	coll_dtime,
	lab_number,
	disp_val
	)
SELECT A.episode_no,
	A.coll_dtime,
	[lab_number] = ROW_NUMBER() OVER (
		PARTITION BY A.episode_no ORDER BY A.coll_dtime
		),
	[disp_val] = CASE 
		WHEN CAST(a.val_no AS VARCHAR) IS NULL
			THEN CAST(LEFT(SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1), PatIndex('%[^0-9.-]%', SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1))) AS VARCHAR)
		ELSE CAST(A.VAL_NO AS VARCHAR)
		END
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE A.obsv_cd = '00402958'


DROP TABLE IF EXISTS #min_platelet
CREATE TABLE #min_platelet (
	episode_no VARCHAR(12),
	platelets_min VARCHAR(20),
	platelets_dt_min DATETIME,
	rn INT
	)

INSERT INTO #min_platelet (
	episode_no,
	platelets_min,
	platelets_dt_min,
	rn
	)
SELECT episode_no,
	disp_val,
	coll_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY disp_val
		)
FROM #platelets

DELETE
FROM #min_platelet
WHERE RN != 1


DROP TABLE IF EXISTS #platelet_pvt 
CREATE TABLE #platelet_pvt (
	episode_no VARCHAR(12),
	platelets_1 VARCHAR(10) NULL,
	platelets_dt_1 DATETIME NULL,
	platelets_2 VARCHAR(10) NULL,
	platelets_dt_2 DATETIME NULL,
	platelets_3 VARCHAR(10) NULL,
	platelets_dt_3 DATETIME NULL
	)

INSERT INTO #platelet_pvt (
	episode_no,
	platelets_1,
	platelets_dt_1,
	platelets_2,
	platelets_dt_2,
	platelets_3,
	platelets_dt_3
	)
SELECT episode_no,
	MAX([1]),
	MAX([01]),
	MAX([2]),
	MAX([02]),
	MAX([3]),
	MAX([03])
FROM (
	SELECT episode_no,
		disp_val,
		coll_dtime,
		lab_number,
		lab_number2 = '0' + CAST(lab_number AS VARCHAR)
	FROM #platelets
	WHERE lab_number <= 3
	) AS A
PIVOT(MAX(disp_val) FOR LAB_NUMBER IN ("1", "2", "3")) AS PVT_INR
PIVOT(MAX(coll_dtime) FOR LAB_NUMBER2 IN ("01", "02", "03")) AS PVT_COLL_DTIME
GROUP BY episode_no


-- Heartrate
DROP TABLE IF EXISTS #ws_hr
CREATE TABLE #ws_hr (
	episode_no VARCHAR(12),
	sirs_heartrate VARCHAR(10),
	coll_dtime DATETIME
	)

INSERT INTO #ws_hr (
	episode_no,
	sirs_heartrate,
	coll_dtime
	)
SELECT A.account,
	A.heart_rate,
	A.collected_datetime
FROM SMSDSS.c_sepsis_ws_vitals_tbl AS A
INNER JOIN #BasePopulation AS BP ON A.account = BP.PtNo_Num
WHERE A.heart_rate NOT IN ('100-110', '101-114', '107-135', '110-130', '114-142', '115-130', '118-136', '120-145', '145-155', '158-173', '49-51', '82-100', '88-106', '98-130', 'CPR', 'rare', 'refused')
	AND A.heart_rate IS NOT NULL


-- Soarian
DROP TABLE IF EXISTS #sr_hr 
CREATE TABLE #sr_hr (
	episode_no VARCHAR(12),
	sirs_heartrate VARCHAR(20),
	coll_dtime DATETIME
	)

INSERT INTO #sr_hr (
	episode_no,
	sirs_heartrate,
	coll_dtime
	)
SELECT episode_no,
	[disp_val] = CASE 
		WHEN CAST(a.val_no AS VARCHAR) IS NULL
			THEN CAST(A.dsply_val AS VARCHAR)
		ELSE CAST(A.VAL_NO AS VARCHAR)
		END,
	A.obsv_cre_dtime
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE obsv_cd = 'A_Pulse'


DROP TABLE IF EXISTS #sirs_hr
CREATE TABLE #sirs_hr (
	episode_no VARCHAR(12),
	sirs_heartrate VARCHAR(20),
	obsv_dtime DATETIME,
	lab_number INT
	)

INSERT INTO #sirs_hr (
	episode_no,
	sirs_heartrate,
	obsv_dtime,
	lab_number
	)
SELECT a.episode_no,
	a.sirs_heartrate,
	a.coll_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY A.episode_no ORDER BY A.coll_dtime
		)
FROM (
	SELECT episode_no,
		sirs_heartrate,
		coll_dtime
	FROM #ws_hr
	
	UNION
	
	SELECT episode_no,
		sirs_heartrate,
		coll_dtime
	FROM #sr_hr
	) AS A


DROP TABLE IF EXISTS #max_sirs_hr
CREATE TABLE #max_sirs_hr (
	episode_no VARCHAR(12),
	sirs_heartrate_max VARCHAR(10),
	sirs_heartrate_dt_max DATETIME,
	rn INT
	)

INSERT INTO #max_sirs_hr (
	episode_no,
	sirs_heartrate_max,
	sirs_heartrate_dt_max,
	rn
	)
SELECT episode_no,
	sirs_heartrate,
	obsv_dtime,
	[rn] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY CAST(sirs_heartrate AS INT) ASC
		)
FROM #sirs_hr

DELETE
FROM #max_sirs_hr
WHERE RN != 1


DROP TABLE IF EXISTS #sirs_hr_pvt
CREATE TABLE #sirs_hr_pvt (
	episode_no VARCHAR(12),
	sirs_heartrate_1 VARCHAR(10),
	sirs_heartrate_dt_1 DATETIME,
	sirs_heartrate_2 VARCHAR(10),
	sirs_heartrate_dt_2 DATETIME,
	sirs_heartrate_3 VARCHAR(10),
	sirs_heartrate_dt_3 DATETIME,
	)

INSERT INTO #sirs_hr_pvt (
	episode_no,
	sirs_heartrate_1,
	sirs_heartrate_dt_1,
	sirs_heartrate_2,
	sirs_heartrate_dt_2,
	sirs_heartrate_3,
	sirs_heartrate_dt_3
	)
SELECT episode_no,
	MAX([1]),
	MAX([01]),
	MAX([2]),
	MAX([02]),
	MAX([3]),
	MAX([03])
FROM (
	SELECT episode_no,
		sirs_heartrate,
		obsv_dtime,
		lab_number,
		lab_number2 = '0' + CAST(lab_number AS VARCHAR)
	FROM #sirs_hr
	WHERE lab_number <= 3
	) AS A
PIVOT(MAX(sirs_heartrate) FOR LAB_NUMBER IN ("1", "2", "3")) AS PVT_HR
PIVOT(MAX(obsv_dtime) FOR LAB_NUMBER2 IN ("01", "02", "03")) AS PVT_COLL_DTIME
GROUP BY episode_no


-- WBC
DROP TABLE IF EXISTS #wbc
CREATE TABLE #wbc (
	episode_no VARCHAR(12),
	coll_dtime DATETIME,
	disp_val VARCHAR(200)
	)

INSERT INTO #wbc (
	episode_no,
	coll_dtime,
	disp_val
	)
SELECT A.episode_no,
	A.coll_dtime,
	[disp_val] = CASE 
		WHEN CAST(a.val_no AS VARCHAR) IS NULL
			THEN CAST(LEFT(SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1), PatIndex('%[^0-9.-]%', SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1))) AS VARCHAR)
		ELSE CAST(A.VAL_NO AS VARCHAR)
		END
FROM SMSMIR.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE A.obsv_cd = '1000'

DELETE
FROM #wbc
WHERE disp_val = '. '


DROP TABLE IF EXISTS #arr_wbc
CREATE TABLE #arr_wbc (
	episode_no VARCHAR(12),
	sirs_leuckocyte_arrival VARCHAR(200),
	sirs_leuckocyte_arrival_dt DATETIME,
	rn INT
	)

INSERT INTO #arr_wbc (
	episode_no,
	sirs_leuckocyte_arrival,
	sirs_leuckocyte_arrival_dt,
	rn
	)
SELECT episode_no,
	disp_val,
	coll_dtime,
	[rn] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY coll_dtime
		)
FROM #wbc

DELETE
FROM #arr_wbc
WHERE RN != 1


DROP TABLE IF EXISTS #min_wbc
CREATE TABLE #min_wbc (
	episode_no VARCHAR(12),
	sirs_leuckocyte_min VARCHAR(200),
	sirs_leuckocyte_min_dt DATETIME,
	rn INT
	)

INSERT INTO #min_wbc (
	episode_no,
	sirs_leuckocyte_min,
	sirs_leuckocyte_min_dt,
	rn
	)
SELECT episode_no,
	disp_val,
	coll_dtime,
	[rn] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY CAST(REPLACE(disp_val, CHAR(13), '') AS FLOAT)
		)
FROM #wbc

DELETE
FROM #min_wbc
WHERE RN != 1


DROP TABLE IF EXISTS #max_wbc
CREATE TABLE #max_wbc (
	episode_no VARCHAR(12),
	sirs_leuckocyte_max VARCHAR(20),
	sirs_leuckocyte_max_dt DATETIME,
	rn INT
	)

INSERT INTO #max_wbc (
	episode_no,
	sirs_leuckocyte_max,
	sirs_leuckocyte_max_dt,
	rn
	)
SELECT episode_no,
	disp_val,
	coll_dtime,
	[rn] = ROW_NUMBER() OVER (
		PARTITION BY episode_NO ORDER BY CAST(REPLACE(disp_val, CHAR(13), '') AS FLOAT) DESC
		)
FROM #wbc

DELETE
FROM #max_wbc
WHERE RN != 1


-- SIRS RESPIRATORY RATE
-- WellSoft
DROP TABLE IF EXISTS #ws_resp_rate
CREATE TABLE #ws_resp_rate (
	episode_no VARCHAR(12),
	sirs_respiratoryrate VARCHAR(10),
	coll_dtime DATETIME
	)

INSERT INTO #ws_resp_rate
SELECT A.account,
	a.respiratory_rate,
	a.collected_datetime
FROM SMSDSS.c_sepsis_ws_vitals_tbl AS A
INNER JOIN #BasePopulation AS BP ON A.account = BP.PtNo_Num
WHERE A.respiratory_rate IS NOT NULL
	AND A.respiratory_rate NOT IN ('4 0', 'AGONAL', 'assisted', 'rare')


-- Soarian
DROP TABLE IF EXISTS #sr_resp_rate
CREATE TABLE #sr_resp_rate (
	episode_no VARCHAR(12),
	sirs_respiratoryrate VARCHAR(200),
	coll_dtime DATETIME
	)

INSERT INTO #sr_resp_rate
SELECT a.episode_no,
	[disp_val] = CASE 
		WHEN CAST(a.val_no AS VARCHAR) IS NULL
			THEN CAST(a.dsply_val AS VARCHAR)
		ELSE CAST(A.VAL_NO AS VARCHAR)
		END,
	a.obsv_cre_dtime
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE A.obsv_cd = 'A_Respirations'


DROP TABLE IF EXISTS #sirs_respiratoryrate 
CREATE TABLE #sirs_respiratoryrate (
	episode_no VARCHAR(12),
	sirs_respiratoryrate VARCHAR(20),
	obsv_dtime DATETIME,
	lab_number INT
	)

INSERT INTO #sirs_respiratoryrate (
	episode_no,
	sirs_respiratoryrate,
	obsv_dtime,
	lab_number
	)
SELECT A.episode_no,
	A.sirs_respiratoryrate,
	A.coll_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY A.episode_no ORDER BY A.coll_dtime
		)
FROM (
	SELECT episode_no,
		sirs_respiratoryrate,
		coll_dtime
	FROM #ws_resp_rate
	
	UNION
	
	SELECT episode_no,
		sirs_respiratoryrate,
		coll_dtime
	FROM #sr_resp_rate
	) AS A


DROP TABLE IF EXISTS #max_sirs_respiratoryrate
CREATE TABLE #max_sirs_respiratoryrate (
	episode_no VARCHAR(12),
	sirs_respiratoryrate_max VARCHAR(20),
	sirs_respiratoryrate_dt_max DATETIME,
	rn INT
	)

INSERT INTO #max_sirs_respiratoryrate (
	episode_no,
	sirs_respiratoryrate_max,
	sirs_respiratoryrate_dt_max,
	rn
	)
SELECT episode_no,
	sirs_respiratoryrate,
	obsv_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY CAST(sirs_respiratoryrate AS INT) DESC
		)
FROM #sirs_respiratoryrate

DELETE
FROM #max_sirs_respiratoryrate
WHERE RN != 1


DROP TABLE IF EXISTS #sirs_resp_pvt
CREATE TABLE #sirs_resp_pvt (
	episode_no VARCHAR(12),
	sirs_respiratoryrate_1 VARCHAR(10),
	sirs_respiratoryrate_dt_1 DATETIME,
	sirs_respiratoryrate_2 VARCHAR(10),
	sirs_respiratoryrate_dt_2 DATETIME,
	sirs_respiratoryrate_3 VARCHAR(10),
	sirs_respiratoryrate_dt_3 DATETIME
	)

INSERT INTO #sirs_resp_pvt (
	episode_no,
	sirs_respiratoryrate_1,
	sirs_respiratoryrate_dt_1,
	sirs_respiratoryrate_2,
	sirs_respiratoryrate_dt_2,
	sirs_respiratoryrate_3,
	sirs_respiratoryrate_dt_3
	)
SELECT episode_no,
	MAX([1]),
	MAX([01]),
	MAX([2]),
	MAX([02]),
	MAX([3]),
	MAX([03])
FROM (
	SELECT episode_no,
		sirs_respiratoryrate,
		obsv_dtime,
		lab_number,
		lab_number2 = '0' + CAST(lab_number AS VARCHAR)
	FROM #sirs_respiratoryrate
	WHERE lab_number <= 3
	) AS A
PIVOT(MAX(sirs_respiratoryrate) FOR LAB_NUMBER IN ("1", "2", "3")) AS PVT_HR
PIVOT(MAX(obsv_dtime) FOR LAB_NUMBER2 IN ("01", "02", "03")) AS PVT_COLL_DTIME
GROUP BY episode_no


-- SIRS Temperature
DROP TABLE IF EXISTS #ws_temp
CREATE TABLE #ws_temp (
	episode_no VARCHAR(12),
	sirs_temperature VARCHAR(10),
	coll_dtime DATETIME
	)

INSERT INTO #ws_temp
SELECT A.account,
	a.TEMP,
	a.collected_datetime
FROM SMSDSS.c_sepsis_ws_vitals_tbl AS A
INNER JOIN #BasePopulation AS BP ON A.account = BP.PtNo_Num
WHERE A.TEMP IS NOT NULL
	AND A.TEMP NOT IN ('*** DELETE ***', '.', '<90.0', '100 . 0', '33.1ºC', '33.3ºC', '33.7ºC', '34.6 C', '34.6ºC', '35.0ºC', '35.6C', '36.8 C', 'patient refused', 'Pt left', 'pt refused temp', 'ref vs', 'refudes', 'refused', 'refused oral temp', 'refused temp', 'Unable to assess')


-- Soarian
DROP TABLE IF EXISTS #sr_temp
CREATE TABLE #sr_temp (
	episode_no VARCHAR(12),
	sirs_temperature VARCHAR(200),
	coll_dtime DATETIME
	)

INSERT INTO #sr_temp
SELECT a.episode_no,
	[disp_val] = CASE 
		WHEN CAST(a.val_no AS VARCHAR) IS NULL
			THEN CAST(a.dsply_val AS VARCHAR)
		ELSE CAST(A.VAL_NO AS VARCHAR)
		END,
	a.obsv_cre_dtime
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE A.obsv_cd = 'A_Temperature'


DROP TABLE IF EXISTS #sirs_temp
CREATE TABLE #sirs_temp (
	episode_no VARCHAR(12),
	sirs_temperature VARCHAR(20),
	obsv_dtime DATETIME,
	lab_number INT
	)

INSERT INTO #sirs_temp (
	episode_no,
	sirs_temperature,
	obsv_dtime,
	lab_number
	)
SELECT A.episode_no,
	A.sirs_temperature,
	A.coll_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY A.episode_no ORDER BY A.coll_dtime
		)
FROM (
	SELECT episode_no,
		sirs_temperature,
		coll_dtime
	FROM #ws_temp
	
	UNION
	
	SELECT episode_no,
		sirs_temperature,
		coll_dtime
	FROM #sr_temp
	) AS A


DROP TABLE IF EXISTS #max_sirs_temp
CREATE TABLE #max_sirs_temp (
	episode_no VARCHAR(12),
	sirs_temperature_max VARCHAR(20),
	sirs_temperature_dt_max DATETIME,
	rn INT
	)

INSERT INTO #max_sirs_temp (
	episode_no,
	sirs_temperature_max,
	sirs_temperature_dt_max,
	rn
	)
SELECT episode_no,
	sirs_temperature,
	obsv_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY CAST(sirs_temperature AS FLOAT) DESC
		)
FROM #sirs_temp

DELETE
FROM #max_sirs_temp
WHERE RN != 1


DROP TABLE IF EXISTS #sirs_temp_pvt
CREATE TABLE #sirs_temp_pvt (
	episode_no VARCHAR(12),
	sirs_temperature_1 VARCHAR(10),
	sirs_temperature_dt_1 DATETIME,
	sirs_temperature_2 VARCHAR(10),
	sirs_temperature_dt_2 DATETIME,
	sirs_temperature_3 VARCHAR(10),
	sirs_temperature_dt_3 DATETIME
	)

INSERT INTO #sirs_temp_pvt (
	episode_no,
	sirs_temperature_1,
	sirs_temperature_dt_1,
	sirs_temperature_2,
	sirs_temperature_dt_2,
	sirs_temperature_3,
	sirs_temperature_dt_3
	)
SELECT episode_no,
	MAX([1]),
	MAX([01]),
	MAX([2]),
	MAX([02]),
	MAX([3]),
	MAX([03])
FROM (
	SELECT episode_no,
		sirs_temperature,
		obsv_dtime,
		lab_number,
		lab_number2 = '0' + CAST(lab_number AS VARCHAR)
	FROM #sirs_temp
	WHERE lab_number <= 3
	) AS A
PIVOT(MAX(sirs_temperature) FOR LAB_NUMBER IN ("1", "2", "3")) AS PVT_HR
PIVOT(MAX(obsv_dtime) FOR LAB_NUMBER2 IN ("01", "02", "03")) AS PVT_COLL_DTIME
GROUP BY episode_no


-- Systolic BP
-- WellSoft
DROP TABLE IF EXISTS #ws_systolic
CREATE TABLE #ws_systolic (
	episode_no VARCHAR(10),
	bp_systolic VARCHAR(10),
	collected_datetime DATETIME
	)

INSERT INTO #ws_systolic (
	episode_no,
	bp_systolic,
	collected_datetime
	)
SELECT A.account,
	A.bp_systolic,
	A.collected_datetime
FROM smsdss.c_sepsis_ws_vitals_tbl AS A
INNER JOIN #BasePopulation AS BP ON A.account = BP.PtNo_Num
WHERE ISNUMERIC(bp_systolic) = 1


-- Soarian
DROP TABLE IF EXISTS #sr_systolic
CREATE TABLE #sr_systolic (
	episode_no VARCHAR(12),
	bp_systolic VARCHAR(20),
	obsv_cre_dtime DATETIME
	)

INSERT INTO #sr_systolic (
	episode_no,
	bp_systolic,
	obsv_cre_dtime
	)
SELECT episode_no,
	bp_systolic = LEFT(DSPLY_VAL, CHARINDEX('/', (DSPLY_VAL), 1) - 1),
	obsv_cre_dtime
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE obsv_cd = 'A_BP'


DROP TABLE IF EXISTS #bp_systolic
CREATE TABLE #bp_systolic (
	episode_no VARCHAR(12),
	bp_systolic VARCHAR(20),
	obsv_dtime DATETIME,
	bp_reading_num INT
	)

INSERT INTO #bp_systolic (
	episode_no,
	bp_systolic,
	obsv_dtime,
	bp_reading_num
	)
SELECT A.episode_no,
	A.bp_systolic,
	A.collected_datetime,
	[bp_reading_num] = ROW_NUMBER() OVER (
		PARTITION BY A.episode_no ORDER BY A.collected_datetime
		)
FROM (
	SELECT episode_no,
		bp_systolic,
		collected_datetime
	FROM #ws_systolic
	
	UNION
	
	SELECT episode_no,
		bp_systolic,
		obsv_cre_dtime
	FROM #sr_systolic
	) AS A


DROP TABLE IF EXISTS #min_systolic
CREATE TABLE #min_systolic (
	episode_no VARCHAR(12),
	systolic_min VARCHAR(10),
	systolic_dt_min DATETIME,
	rn INT
	)

INSERT INTO #min_systolic (
	episode_no,
	systolic_min,
	systolic_dt_min,
	rn
	)
SELECT episode_no,
	bp_systolic,
	obsv_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY CAST(bp_systolic AS INT) ASC
		)
FROM #bp_systolic

DELETE
FROM #min_systolic
WHERE rn != 1;



DROP TABLE IF EXISTS #bp_systolic_pvt
CREATE TABLE #bp_systolic_pvt (
	episode_no VARCHAR(10),
	systolic_1 VARCHAR(10),
	systolic_dt_1 DATETIME,
	systolic_2 VARCHAR(10),
	systolic_dt_2 DATETIME,
	systolic_3 VARCHAR(10),
	systolic_dt_3 DATETIME
	)

INSERT INTO #bp_systolic_pvt (
	episode_no,
	systolic_1,
	systolic_dt_1,
	systolic_2,
	systolic_dt_2,
	systolic_3,
	systolic_dt_3
	)
SELECT episode_no,
	MAX([1]),
	MAX([01]),
	MAX([2]),
	MAX([02]),
	MAX([3]),
	MAX([03])
FROM (
	SELECT episode_no,
		bp_systolic,
		obsv_dtime,
		bp_reading_num,
		bp_reading_num2 = '0' + CAST(bp_reading_num AS VARCHAR)
	FROM #bp_systolic
	WHERE bp_reading_num <= 3
	) AS A
PIVOT(MAX(bp_systolic) FOR bp_reading_num IN ("1", "2", "3")) AS PVT_BP_SYSTOLIC
PIVOT(MAX(obsv_dtime) FOR bp_reading_num2 IN ("01", "02", "03")) AS PVT_BP_COLL_DTIME
GROUP BY episode_no


-- Pull it all together
SELECT [admission_dt] = CONVERT(CHAR(10), PV.VisitStartDateTime, 126) + ' ' + CONVERT(CHAR(5), PV.VisitStartDateTime, 108),
	[arrival_dt] = CONVERT(CHAR(10), PV.PresentingDateTime, 126) + ' ' + CONVERT(CHAR(5), PV.PresentingDateTime, 108),
	[date_of_birth] = CONVERT(CHAR(10), PAV.Pt_Birthdate, 126),
	[discharge_dt] = CONVERT(CHAR(10), PV.VisitEndDateTime, 126) + ' ' + CONVERT(CHAR(5), PV.VisitEndDateTime, 108),
	[discharge_status] = CASE 
		WHEN PAV.dsch_disp IN ('AHR', 'HR', ' HR')
			THEN '01'
		WHEN PAV.dsch_disp IN ('ATW', 'TW', ' TW')
			THEN '06'
		WHEN PAV.dsch_disp IN ('AMA', 'MA', ' MA')
			THEN '07'
		WHEN PAV.dsch_disp IN ('ATE', 'ATL', 'TE', 'TL', ' TE', ' TL')
			THEN '03'
		WHEN PAV.dsch_disp IN ('ATH', 'TH', ' TH', 'ATN', 'TN', ' TN')
			THEN '02'
		WHEN PAV.dsch_disp IN ('ATF', 'TF', ' TF')
			THEN '05'
		WHEN PAV.dsch_disp IN ('ATT', 'TT', ' TT')
			THEN '50'
		WHEN PAV.dsch_disp IN ('AHI', 'HI', ' HI')
			THEN '51'
		WHEN PAV.dsch_disp IN ('ATP', 'TP', ' TP')
			THEN '65'
		WHEN PAV.dsch_disp IN ('ATX', 'TX', ' TX')
			THEN '62'
		WHEN PAV.dsch_disp IN ('AHB', 'HB', ' HB')
			THEN '70'
		WHEN PAV.dsch_disp IN ('ATB', 'TB', ' TB')
			THEN '21'
		WHEN PAV.dsch_disp IN ('ADZ', 'DZ', ' DZ')
			THEN '69'
		WHEN LEFT(PAV.dsch_disp, 1) IN ('C', 'D')
			THEN '20'
		ELSE 'M'
		END,
	[ethnicity] = CASE 
		WHEN TWOFACT.UserDataText = '1'
			THEN 'E1.02'
		WHEN TWOFACT.UserDataText = '2'
			THEN 'E1.04.010'
		WHEN TWOFACT.UserDataText = '3'
			THEN 'E1.03.002'
		WHEN TWOFACT.UserDataText = '4'
			THEN 'E1.03.003'
		WHEN TWOFACT.UserDataText = '5'
			THEN 'E1.03.006'
		WHEN TWOFACT.UserDataText = '6'
			THEN 'E1.04.001'
		WHEN TWOFACT.UserDataText = '7'
			THEN 'E1.04.004'
		WHEN TWOFACT.UserDataText = '8'
			THEN 'E1.04.005'
		WHEN TWOFACT.UserDataText = '9'
			THEN 'E1.06'
		WHEN TWOFACT.UserDataText = 'A'
			THEN 'E1.07'
		WHEN TWOFACT.UserDataText = 'B'
			THEN 'E1.08'
		WHEN TWOFACT.UserDataText = 'H '
			THEN 'E1'
		WHEN TWOFACT.UserDataText = 'N'
			THEN 'E2'
		WHEN TWOFACT.UserDataText = 'U'
			THEN 'E9'
		END,
	[facility_identifier] = '000885',
	[gender] = CASE 
		WHEN PAV.Pt_Sex IN ('M', 'F')
			THEN PAV.Pt_Sex
		ELSE 'U'
		END,
	[icd_10_cm_code_01] = DX_CDS.[01],
	[icd_10_cm_code_02] = DX_CDS.[02],
	[icd_10_cm_code_03] = DX_CDS.[03],
	[icd_10_cm_code_04] = DX_CDS.[04],
	[icd_10_cm_code_05] = DX_CDS.[05],
	[icd_10_cm_code_06] = DX_CDS.[06],
	[icd_10_cm_code_07] = DX_CDS.[07],
	[icd_10_cm_code_08] = DX_CDS.[08],
	[icd_10_cm_code_09] = DX_CDS.[09],
	[icd_10_cm_code_10] = DX_CDS.[10],
	[icd_10_cm_code_11] = DX_CDS.[11],
	[icd_10_cm_code_12] = DX_CDS.[12],
	[icd_10_cm_code_13] = DX_CDS.[13],
	[icd_10_cm_code_14] = DX_CDS.[14],
	[icd_10_cm_code_15] = DX_CDS.[15],
	[icd_10_cm_code_16] = DX_CDS.[16],
	[icd_10_cm_code_17] = DX_CDS.[17],
	[icd_10_cm_code_18] = DX_CDS.[18],
	[icd_10_cm_code_19] = DX_CDS.[19],
	[icd_10_cm_code_20] = DX_CDS.[20],
	[icd_10_cm_code_21] = DX_CDS.[21],
	[icd_10_cm_code_22] = DX_CDS.[22],
	[icd_10_cm_code_23] = DX_CDS.[23],
	[icd_10_cm_code_24] = DX_CDS.[24],
	[icd_10_cm_code_25] = DX_CDS.[25],
	[icd_10_cm_poa_indicator_01] = DX_POA.[01],
	[icd_10_cm_poa_indicator_02] = DX_POA.[02],
	[icd_10_cm_poa_indicator_03] = DX_POA.[03],
	[icd_10_cm_poa_indicator_04] = DX_POA.[04],
	[icd_10_cm_poa_indicator_05] = DX_POA.[05],
	[icd_10_cm_poa_indicator_06] = DX_POA.[06],
	[icd_10_cm_poa_indicator_07] = DX_POA.[07],
	[icd_10_cm_poa_indicator_08] = DX_POA.[08],
	[icd_10_cm_poa_indicator_09] = DX_POA.[09],
	[icd_10_cm_poa_indicator_10] = DX_POA.[10],
	[icd_10_cm_poa_indicator_11] = DX_POA.[11],
	[icd_10_cm_poa_indicator_12] = DX_POA.[12],
	[icd_10_cm_poa_indicator_13] = DX_POA.[13],
	[icd_10_cm_poa_indicator_14] = DX_POA.[14],
	[icd_10_cm_poa_indicator_15] = DX_POA.[15],
	[icd_10_cm_poa_indicator_16] = DX_POA.[16],
	[icd_10_cm_poa_indicator_17] = DX_POA.[17],
	[icd_10_cm_poa_indicator_18] = DX_POA.[18],
	[icd_10_cm_poa_indicator_19] = DX_POA.[19],
	[icd_10_cm_poa_indicator_20] = DX_POA.[20],
	[icd_10_cm_poa_indicator_21] = DX_POA.[21],
	[icd_10_cm_poa_indicator_22] = DX_POA.[22],
	[icd_10_cm_poa_indicator_23] = DX_POA.[23],
	[icd_10_cm_poa_indicator_24] = DX_POA.[24],
	[icd_10_cm_poa_indicator_25] = DX_POA.[25],
	[insurance_number] = CASE 
		WHEN LEFT(PYRPLAN.PYR_CD, 1) IN ('A', 'Z')
			THEN PYRPLAN.POL_NO
		WHEN LEFT(PYRPLAN.pyr_cd, 1) IN ('B', 'E', 'I', 'J', 'K', 'X')
			THEN PYRPLAN.subscr_ins_grp_id
		ELSE RTRIM(LTRIM(ISNULL(pol_no, ''))) + RTRIM(LTRIM(ISNULL(grp_no, '')))
		END,
	[medical_record_number] = pav.Med_Rec_No,
	[other_payer] = CASE 
		WHEN Payer.PYR2 != ''
			AND Payer.PYR3 != ''
			THEN CAST(Payer.PYR2 AS VARCHAR) + ':' + CAST(Payer.PYR3 AS VARCHAR)
		WHEN Payer.PYR2 != ''
			THEN CAST(Payer.PYR2 AS VARCHAR)
		END,
	[patient_control_number] = pv.PatientAccountID,
	[patient_zip_code_of_residence] = CAST(PAV.Pt_Zip_Cd AS VARCHAR) + '-' + '0000',
	[payer] = CASE 
		WHEN Payer.PYR1 != ''
			AND Payer.PYR2 != ''
			AND Payer.PYR3 != ''
			THEN CAST(Payer.[PYR1] AS VARCHAR) + ':' + CAST(Payer.[PYR2] AS VARCHAR) + ':' + CAST(Payer.[PYR3] AS VARCHAR)
		WHEN Payer.PYR1 != ''
			AND Payer.PYR2 != ''
			AND Payer.PYR3 = ''
			THEN CAST(Payer.[PYR1] AS VARCHAR) + ':' + CAST(Payer.[PYR2] AS VARCHAR)
		WHEN Payer.PYR1 != ''
			AND Payer.PYR2 = ''
			AND Payer.PYR3 = ''
			THEN CAST(Payer.PYR1 AS VARCHAR)
		END,
	[race] = CASE 
		WHEN LTRIM(RTRIM(PAV.race_cd)) = 'I'
			THEN 'R1'
		WHEN LTRIM(RTRIM(PAV.race_cd)) = 'A'
			THEN 'R2'
		WHEN LTRIM(RTRIM(PAV.race_cd)) = 'S'
			THEN 'R2.01'
		WHEN LTRIM(RTRIM(PAV.race_cd)) = 'B'
			THEN 'R3'
		WHEN LTRIM(RTRIM(PAV.race_cd)) = 'N'
			THEN 'R4'
		WHEN LTRIM(RTRIM(PAV.race_cd)) = 'W'
			THEN 'R5'
		WHEN LTRIM(RTRIM(PAV.race_cd)) = 'O'
			THEN 'R9'
		END,
	[source_of_admission] = CASE 
		WHEN PAV.Adm_Source = 'AS'
			THEN 'E'
		WHEN PAV.Adm_Source = 'EO'
			THEN '1'
		WHEN PAV.Adm_Source = 'HS'
			THEN 'F'
		WHEN PAV.Adm_Source = 'NB'
			THEN '9'
		WHEN PAV.Adm_Source = 'NE'
			THEN '9'
		WHEN PAV.Adm_Source = 'OP'
			THEN '2'
		WHEN PAV.Adm_Source = 'RA'
			THEN '1'
		WHEN PAV.Adm_Source = 'RM'
			THEN '9'
		WHEN PAV.Adm_Source = 'RP'
			THEN '1'
		WHEN PAV.Adm_Source = 'RS'
			THEN '9'
		WHEN PAV.Adm_Source = 'TB'
			THEN '8'
		WHEN PAV.Adm_Source = 'TE'
			THEN '5'
		WHEN PAV.Adm_Source = 'TH'
			THEN '4'
		WHEN PAV.Adm_Source = 'TO'
			THEN '9'
		WHEN PAV.Adm_Source = 'TV'
			THEN '1'
		END,
	[transferred_in] = CASE 
		WHEN LTRIM(RTRIM(PAV.Adm_Source)) IN ('TH')
			THEN '1'
		ELSE '0'
		END,
	[transferred_out] = CASE 
		WHEN LTRIM(RTRIM(RIGHT(PAV.dsch_disp, 2))) IN ('TH', 'TN')
			THEN '1'
		ELSE '0'
		END,
	[transfer_facility_id_receiving] = '',
	[transfer_facility_id_sending] = '',
	[transfer_facility_nm_receiving] = '',
	[transfer_facility_nm_sending] = '',
	PAV.PT_NAME,
	[unique_personal_identifier] = CAST(LEFT(pav.Pt_Name, 2) AS VARCHAR) + CAST(RIGHT(LTRIM(RTRIM(SUBSTRING(PAV.PT_NAME, 1, CHARINDEX(' ,', PAV.PT_NAME, 1)))), 2) AS VARCHAR) + LEFT(LTRIM(RTRIM(REVERSE(SUBSTRING(REVERSE(pav.pt_name), 1, CHARINDEX(',', REVERSE(PAV.PT_NAME), 1) - 1)))), 2) + CAST(LTRIM(RTRIM(RIGHT(PAV.Pt_SSA_No, 4))) AS VARCHAR),
	[acute_cardiovascular_conditions] = ISNULL(ACC_TBL.acute_cardiovascular_conditions, 0),
	[aids_hiv_disease] = CASE 
		WHEN AIDS_HIV_TBL.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[altered_mental_status] = CASE 
		WHEN AMS.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[asthma] = CASE 
		WHEN ASTHMA.asthma IS NULL
			THEN 0
		ELSE 1
		END,
	[chronic_liver_disease] = CASE 
		WHEN CLD.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[chronic_renal_failure] = CASE 
		WHEN CRF.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[chronic_respiratory_failure] = CASE 
		WHEN CRESPF.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[coagulopathy] = CASE 
		WHEN COAG.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[congestive_heart_failure] = CASE 
		WHEN CHF.PT_ID IS NULL
			THEN 0
		ELSE 1
		END,
	[copd] = CASE 
		WHEN COPD.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[dementia] = CASE 
		WHEN DEMENTIA.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[diabetes] = CASE 
		WHEN DIABETES.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[dialysis_comorbidity] = CASE 
		WHEN DIALYSIS_COMORBID.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[history_of_covid] = CASE 
		WHEN COVID_HIST.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[history_of_covid_dt] = CASE 
		WHEN COVID_HIST.history_of_covid IS NULL
			THEN NULL
		ELSE CONVERT(CHAR(10), COVID_HIST.history_of_covid, 126) + ' ' + CONVERT(CHAR(5), COVID_HIST.history_of_covid, 108)
		END,
	CASE 
		WHEN HX_OTH_CVD.history_of_other_cvd IS NULL
			THEN '0'
		ELSE HX_OTH_CVD.history_of_other_cvd
		END AS history_of_other_cvd,
	[hypertension] = CASE 
		WHEN HYPERTENSION.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	APPT_PVT.appt_1,
	APPT_PVT.appt_2,
	APPT_PVT.appt_3,
	MAX_APPT.appt_max,
	CONVERT(CHAR(10), APPT_PVT.appt_dt_1, 126) + ' ' + CONVERT(CHAR(5), APPT_PVT.appt_dt_1, 108) AS appt_dt_1,
	CONVERT(CHAR(10), APPT_PVT.appt_dt_2, 126) + ' ' + CONVERT(CHAR(5), APPT_PVT.appt_dt_2, 108) AS appt_dt_2,
	CONVERT(CHAR(10), APPT_PVT.appt_dt_3, 126) + ' ' + CONVERT(CHAR(5), APPT_PVT.appt_dt_3, 108) AS appt_dt_3,
	CONVERT(CHAR(10), MAX_APPT.appt_dt_max, 126) + ' ' + CONVERT(CHAR(5), MAX_APPT.appt_dt_max, 108) AS appt_dt_max,
	WS_BPD_PVT.diastolic_1,
	WS_BPD_PVT.diastolic_2,
	WS_BPD_PVT.diastolic_3,
	CONVERT(CHAR(10), WS_BPD_PVT.diastolic_dt_1, 126) + ' ' + CONVERT(CHAR(5), WS_BPD_PVT.diastolic_dt_1, 108) AS diastolic_dt_1,
	CONVERT(CHAR(10), WS_BPD_PVT.diastolic_dt_2, 126) + ' ' + CONVERT(CHAR(5), WS_BPD_PVT.diastolic_dt_3, 108) AS diastolic_dt_2,
	CONVERT(CHAR(10), WS_BPD_PVT.diastolic_dt_3, 126) + ' ' + CONVERT(CHAR(5), WS_BPD_PVT.diastolic_dt_3, 108) AS diastolic_dt_3,
	WS_MIN_BPD.diastolic_min,
	CONVERT(CHAR(10), WS_MIN_BPD.diastolic_dt_min, 126) + ' ' + CONVERT(CHAR(5), WS_MIN_BPD.diastolic_dt_min, 108) AS diastolic_dt_min,
	INR_PVT.inr_1,
	INR_PVT.inr_2,
	INR_PVT.inr_3,
	MAX_INR.inr_max,
	CONVERT(CHAR(10), INR_PVT.inr_dt_1, 126) + ' ' + CONVERT(CHAR(5), INR_PVT.inr_dt_1, 108) AS inr_dt_1,
	CONVERT(CHAR(10), INR_PVT.inr_dt_2, 126) + ' ' + CONVERT(CHAR(5), INR_PVT.inr_dt_2, 108) AS inr_dt_2,
	CONVERT(CHAR(10), INR_PVT.inr_dt_3, 126) + ' ' + CONVERT(CHAR(5), INR_PVT.inr_dt_3, 108) AS inr_dt_3,
	CONVERT(CHAR(10), MAX_INR.inr_dt_max, 126) + ' ' + CONVERT(CHAR(5), MAX_INR.inr_dt_max, 108) AS inr_dt_max,
	LACTATE_PVT.lactate_level_1,
	LACTATE_PVT.lactate_level_2,
	LACTATE_PVT.lactate_level_3,
	MAX_LACTATE.lactate_level_max,
	CONVERT(CHAR(10), LACTATE_PVT.lactate_level_dt_1, 126) + ' ' + CONVERT(CHAR(5), LACTATE_PVT.lactate_level_dt_1, 108) AS lactate_level_dt_1,
	CONVERT(CHAR(10), LACTATE_PVT.lactate_level_dt_2, 126) + ' ' + CONVERT(CHAR(5), LACTATE_PVT.lactate_level_dt_2, 108) AS lactate_level_dt_2,
	CONVERT(CHAR(10), LACTATE_PVT.lactate_level_dt_3, 126) + ' ' + CONVERT(CHAR(5), LACTATE_PVT.lactate_level_dt_3, 108) AS lactate_level_dt_3,
	CONVERT(CHAR(10), MAX_LACTATE.lactate_level_dt_max, 126) + ' ' + CONVERT(CHAR(5), MAX_LACTATE.lactate_level_dt_max, 108) AS lactate_level_dt_max,
	[organ_dysfunc_cns] = CASE 
		WHEN OD_CNS.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	ARR_BILIRUBIN.organ_dysfunc_hepatic_arrival,
	MAX_BILIRUBIN.organ_dysfunc_hepatic_max,
	CONVERT(CHAR(10), ARR_BILIRUBIN.organ_dysfunc_hepatic_arrival_dt, 126) + ' ' + CONVERT(CHAR(5), ARR_BILIRUBIN.organ_dysfunc_hepatic_arrival_dt, 108) AS organ_dysfunc_hepatic_arrival_dt,
	CONVERT(CHAR(10), MAX_BILIRUBIN.organ_dysfunc_hepatic_max_dt, 126) + ' ' + CONVERT(CHAR(5), MAX_BILIRUBIN.organ_dysfunc_hepatic_max_dt, 108) AS organ_dysfunc_hepatic_max_dt,
	ARR_CREATININE.organ_dysfunc_renal_arrival,
	MAX_CREATININE.organ_dysfunc_renal_max,
	CONVERT(CHAR(10), ARR_CREATININE.organ_dysfunc_renal_arrival_dt, 126) + ' ' + CONVERT(CHAR(5), ARR_CREATININE.organ_dysfunc_renal_arrival_dt, 108) AS organ_dysfunc_renal_arrival_dt,
	CONVERT(CHAR(10), MAX_CREATININE.organ_dysfunc_renal_max_dt, 126) + ' ' + CONVERT(CHAR(5), MAX_CREATININE.organ_dysfunc_renal_max_dt, 108) AS organ_dysfunc_renal_max_dt,
	[organ_dysfunc_respiratory] = CASE 
		WHEN OD_RESP.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	PLT_PVT.platelets_1,
	PLT_PVT.platelets_2,
	PLT_PVT.platelets_3,
	MIN_PLT.platelets_min,
	CONVERT(CHAR(10), PLT_PVT.platelets_dt_1, 126) + ' ' + CONVERT(CHAR(5), PLT_PVT.platelets_dt_1, 108) AS platelets_dt_1,
	CONVERT(CHAR(10), PLT_PVT.platelets_dt_2, 126) + ' ' + CONVERT(CHAR(5), PLT_PVT.platelets_dt_2, 108) AS platelets_dt_2,
	CONVERT(CHAR(10), PLT_PVT.platelets_dt_3, 126) + ' ' + CONVERT(CHAR(5), PLT_PVT.platelets_dt_3, 108) AS platelets_dt_3,
	CONVERT(CHAR(10), MIN_PLT.platelets_dt_min, 126) + ' ' + CONVERT(CHAR(5), MIN_PLT.platelets_dt_min, 108) AS platelets_dt_min,
	SIRS_HR_PVT.sirs_heartrate_1,
	SIRS_HR_PVT.sirs_heartrate_2,
	SIRS_HR_PVT.sirs_heartrate_3,
	MAX_HR.sirs_heartrate_max,
	CONVERT(CHAR(10), SIRS_HR_PVT.sirs_heartrate_dt_1, 126) + ' ' + CONVERT(CHAR(5), SIRS_HR_PVT.sirs_heartrate_dt_1, 108) AS sirs_heartrate_dt_1,
	CONVERT(CHAR(10), SIRS_HR_PVT.sirs_heartrate_dt_2, 126) + ' ' + CONVERT(CHAR(5), SIRS_HR_PVT.sirs_heartrate_dt_2, 108) AS sirs_heartrate_dt_2,
	CONVERT(CHAR(10), SIRS_HR_PVT.sirs_heartrate_dt_3, 126) + ' ' + CONVERT(CHAR(5), SIRS_HR_PVT.sirs_heartrate_dt_3, 108) AS sirs_heartrate_dt_3,
	CONVERT(CHAR(10), MAX_HR.sirs_heartrate_dt_max, 126) + ' ' + CONVERT(CHAR(5), MAX_HR.sirs_heartrate_dt_max, 108) AS sirs_heartrate_dt_max,
	ARR_WBC.sirs_leuckocyte_arrival,
	MIN_WBC.sirs_leuckocyte_min,
	MAX_WBC.sirs_leuckocyte_max,
	CONVERT(CHAR(10), ARR_WBC.sirs_leuckocyte_arrival_dt, 126) + ' ' + CONVERT(CHAR(5), ARR_WBC.sirs_leuckocyte_arrival_dt, 108) AS sirs_leuckocyte_arrival_dt,
	CONVERT(CHAR(10), MIN_WBC.sirs_leuckocyte_min_dt, 126) + ' ' + CONVERT(CHAR(5), MIN_WBC.sirs_leuckocyte_min_dt, 108) AS sirs_keuckocyte_min_dt,
	CONVERT(CHAR(10), MAX_WBC.sirs_leuckocyte_max_dt, 126) + ' ' + CONVERT(CHAR(5), MAX_WBC.sirs_leuckocyte_max_dt, 108) AS sirs_leuckocyte_max_dt,
	SIRS_RESP_PVT.sirs_respiratoryrate_1,
	SIRS_RESP_PVT.sirs_respiratoryrate_2,
	SIRS_RESP_PVT.sirs_respiratoryrate_3,
	CONVERT(CHAR(10), SIRS_RESP_PVT.sirs_respiratoryrate_dt_1, 126) + ' ' + CONVERT(CHAR(5), SIRS_RESP_PVT.sirs_respiratoryrate_dt_1, 108) AS sirs_respiratoryrate_dt_1,
	CONVERT(CHAR(10), SIRS_RESP_PVT.sirs_respiratoryrate_dt_2, 126) + ' ' + CONVERT(CHAR(5), SIRS_RESP_PVT.sirs_respiratoryrate_dt_2, 108) AS sirs_respiratoryrate_dt_2,
	CONVERT(CHAR(10), SIRS_RESP_PVT.sirs_respiratoryrate_dt_3, 126) + ' ' + CONVERT(CHAR(5), SIRS_RESP_PVT.sirs_respiratoryrate_dt_3, 108) AS sirs_respiratoryrate_dt_3,
	MAX_SIRS_RESP_RATE.sirs_respiratoryrate_max,
	CONVERT(CHAR(10), MAX_SIRS_RESP_RATE.sirs_respiratoryrate_dt_max, 126) + ' ' + CONVERT(CHAR(5), MAX_SIRS_RESP_RATE.sirs_respiratoryrate_dt_max, 108) AS sirs_respiratoryrate_dt_max,
	SIRS_TEMP_PVT.sirs_temperature_1,
	SIRS_TEMP_PVT.sirs_temperature_2,
	SIRS_TEMP_PVT.sirs_temperature_3,
	CONVERT(CHAR(10), SIRS_TEMP_PVT.sirs_temperature_dt_1, 126) + ' ' + CONVERT(CHAR(5), SIRS_TEMP_PVT.sirs_temperature_dt_1, 108) AS sirs_temperature_dt_1,
	CONVERT(CHAR(10), SIRS_TEMP_PVT.sirs_temperature_dt_2, 126) + ' ' + CONVERT(CHAR(5), SIRS_TEMP_PVT.sirs_temperature_dt_2, 108) AS sirs_temperature_dt_2,
	CONVERT(CHAR(10), SIRS_TEMP_PVT.sirs_temperature_dt_3, 126) + ' ' + CONVERT(CHAR(5), SIRS_TEMP_PVT.sirs_temperature_dt_3, 108) AS sirs_temperature_dt_3,
	MAX_SIRS_TEMP.sirs_temperature_max,
	CONVERT(CHAR(10), MAX_SIRS_TEMP.sirs_temperature_dt_max, 126) + ' ' + CONVERT(CHAR(5), MAX_SIRS_TEMP.sirs_temperature_dt_max, 108) AS sirs_temperature_dt_max,
	BP_SYS_PVT.systolic_1,
	BP_SYS_PVT.systolic_2,
	BP_SYS_PVT.systolic_3,
	CONVERT(CHAR(10), BP_SYS_PVT.systolic_dt_1, 126) + ' ' + CONVERT(CHAR(5), BP_SYS_PVT.systolic_dt_1, 108) AS systolic_dt_1,
	CONVERT(CHAR(10), BP_SYS_PVT.systolic_dt_2, 126) + ' ' + CONVERT(CHAR(5), BP_SYS_PVT.systolic_dt_2, 108) AS systolic_dt_2,
	CONVERT(CHAR(10), BP_SYS_PVT.systolic_dt_3, 126) + ' ' + CONVERT(CHAR(5), BP_SYS_PVT.systolic_dt_3, 108) AS systolic_dt_3,
	MIN_SYS.systolic_min,
	CONVERT(CHAR(10), MIN_SYS.systolic_dt_min, 126) + ' ' + CONVERT(CHAR(5), MIN_SYS.systolic_dt_min, 108) AS systolic_dt_min
FROM #BasePopulation AS BP
INNER JOIN SMSMIR.sc_PatientVisit AS PV ON BP.PtNo_Num = PV.PatientAccountID
INNER JOIN SMSDSS.BMH_PLM_PtAcct_V AS PAV ON BP.PtNo_Num = PAV.PtNo_Num
	AND BP.UNIT_SEQ_NO = PAV.unit_seq_no
	AND BP.FROM_FILE_IND = PAV.from_file_ind
	AND BP.PT_KEY = PAV.Pt_Key
	AND BP.BL_UNIT_KEY = PAV.Bl_Unit_Key
LEFT OUTER JOIN SMSDSS.BMH_UserTwoFact_V AS TWOFACT ON PAV.PtNo_Num = TWOFACT.PtNo_Num
	AND TWOFACT.UserDataKey = '620'
LEFT OUTER JOIN (
	SELECT PVT.*
	FROM (
		SELECT pt_id,
			dx_cd,
			dx_cd_prio
		FROM SMSMIR.dx_grp
		WHERE LEFT(DX_CD_TYPE, 2) = 'DF'
			AND dx_cd_prio < '26'
		) AS A
	PIVOT(MAX(DX_CD) FOR DX_CD_PRIO IN ("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26")) AS PVT
	) AS DX_CDS ON BP.Pt_No = DX_CDS.pt_id
LEFT OUTER JOIN (
	SELECT PVT.*
	FROM (
		SELECT pt_id,
			dx_cd_prio,
			[poa] = right(dx_cd_type, 1)
		FROM SMSMIR.dx_grp
		WHERE LEFT(DX_CD_TYPE, 2) = 'DF'
			AND dx_cd_prio < '26'
		) AS A
	PIVOT(MAX([poa]) FOR DX_CD_PRIO IN ("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26")) AS PVT
	) AS DX_POA ON BP.Pt_No = DX_POA.pt_id
LEFT OUTER JOIN SMSMIR.pyr_plan AS PYRPLAN ON PAV.Pt_No = PYRPLAN.pt_id
	--AND PAV.unit_seq_no = PYRPLAN.unit_seq_no
	AND PAV.from_file_ind = PYRPLAN.from_file_ind
	AND PYRPLAN.pyr_seq_no = '1'
-- PAYER
LEFT OUTER JOIN (
	SELECT PtNo_Num,
		unit_seq_no,
		from_file_ind,
		[PYR1] = CASE 
			WHEN PDVA.pyr_group2 IN ('SELF PAY')
				THEN 'A'
			WHEN PDVA.pyr_group2 IN ('COMPENSATION')
				THEN 'B'
			WHEN PDVA.pyr_group2 IN ('MEDICARE A', 'MEDICARE B')
				THEN 'C'
			WHEN PDVA.PYR_GROUP2 IN ('MEDICAID')
				THEN 'D'
			WHEN PDVA.pyr_group2 IN ('EXCHANGE PLANS', 'MEDICARE HMO', 'MEDICAID HMO')
				THEN 'E'
			WHEN PDVA.pyr_group2 IN ('COMMERCIAL', 'CONTRACTED SERVICES', 'HMO')
				THEN 'F'
			WHEN PDVA.PYR_GROUP2 IN ('BLUE CROSS')
				THEN 'G'
			WHEN PAV.Pyr1_Co_Plan_Cd IN ('M32')
				THEN 'H'
			WHEN PDVA.pyr_group2 IN ('NO FAULT')
				THEN 'I'
			ELSE ''
			END,
		[PYR2] = CASE 
			WHEN PDVB.pyr_group2 IN ('SELF PAY')
				THEN 'A'
			WHEN PDVB.pyr_group2 IN ('COMPENSATION')
				THEN 'B'
			WHEN PDVB.pyr_group2 IN ('MEDICARE A', 'MEDICARE B')
				THEN 'C'
			WHEN PDVB.PYR_GROUP2 IN ('MEDICAID')
				THEN 'D'
			WHEN PDVB.pyr_group2 IN ('EXCHANGE PLANS', 'MEDICARE HMO', 'MEDICAID HMO')
				THEN 'E'
			WHEN PDVB.pyr_group2 IN ('COMMERCIAL', 'CONTRACTED SERVICES', 'HMO')
				THEN 'F'
			WHEN PDVB.PYR_GROUP2 IN ('BLUE CROSS')
				THEN 'G'
			WHEN PAV.Pyr2_Co_Plan_Cd IN ('M32')
				THEN 'H'
			WHEN PDVB.pyr_group2 IN ('NO FAULT')
				THEN 'I'
			ELSE ''
			END,
		[PYR3] = CASE 
			WHEN PDVC.pyr_group2 IN ('SELF PAY')
				THEN 'A'
			WHEN PDVC.pyr_group2 IN ('COMPENSATION')
				THEN 'B'
			WHEN PDVC.pyr_group2 IN ('MEDICARE A', 'MEDICARE B')
				THEN 'C'
			WHEN PDVC.PYR_GROUP2 IN ('MEDICAID')
				THEN 'D'
			WHEN PDVC.pyr_group2 IN ('EXCHANGE PLANS', 'MEDICARE HMO', 'MEDICAID HMO')
				THEN 'E'
			WHEN PDVC.pyr_group2 IN ('COMMERCIAL', 'CONTRACTED SERVICES', 'HMO')
				THEN 'F'
			WHEN PDVC.PYR_GROUP2 IN ('BLUE CROSS')
				THEN 'G'
			WHEN PAV.Pyr3_Co_Plan_Cd IN ('M32')
				THEN 'H'
			WHEN PDVC.pyr_group2 IN ('NO FAULT')
				THEN 'I'
			ELSE ''
			END
	FROM smsdss.BMH_PLM_PtAcct_V AS PAV
	LEFT JOIN SMSDSS.pyr_dim_v AS PDVA ON PAV.Pyr1_Co_Plan_Cd = PDVA.src_pyr_cd
		AND PAV.Regn_Hosp = PDVA.orgz_cd
	LEFT JOIN SMSDSS.pyr_dim_v AS PDVB ON PAV.Pyr2_Co_Plan_Cd = PDVB.src_pyr_cd
		AND PAV.Regn_Hosp = PDVB.orgz_cd
	LEFT JOIN SMSDSS.pyr_dim_v AS PDVC ON PAV.Pyr3_Co_Plan_Cd = PDVC.src_pyr_cd
		AND PAV.Regn_Hosp = PDVC.orgz_cd
	) AS Payer ON BP.PtNo_Num = Payer.PtNo_Num
	AND BP.unit_seq_no = PAYER.unit_seq_no
	AND BP.from_file_ind = PAYER.from_file_ind
-- Comorbidities / Risck Factors
LEFT JOIN #acc_tbl AS ACC_TBL ON PAV.PtNo_Num = ACC_TBL.PtNo_Num
LEFT JOIN #aids_hiv_tbl AS AIDS_HIV_TBL ON PAV.PT_NO = AIDS_HIV_TBL.pt_id
LEFT JOIN #ams AS AMS ON PAV.Pt_No = AMS.pt_id
LEFT JOIN #asthma AS ASTHMA ON PAV.Pt_NO = ASTHMA.pt_id
LEFT JOIN #cld AS CLD ON PAV.Pt_No = CLD.pt_id
LEFT JOIN #crf AS CRF ON PAV.PT_NO = CRF.pt_id
LEFT JOIN #crespfailure AS CRESPF ON PAV.Pt_No = CRESPF.pt_id
LEFT JOIN #coagulopathy AS COAG ON PAV.PT_NO = COAG.pt_id
LEFT JOIN #chf AS CHF ON PAV.PT_NO = CHF.pt_id
LEFT JOIN #copd AS COPD ON PAV.PT_NO = COPD.pt_id
LEFT JOIN #appt_pvt AS APPT_PVT ON PAV.PtNo_Num = APPT_PVT.episode_no
LEFT JOIN #MAX_APPT AS MAX_APPT ON PAV.PtNo_Num = MAX_APPT.episode_no
LEFT JOIN #ws_bp_diastolic_pvt AS WS_BPD_PVT ON PAV.PtNo_Num = WS_BPD_PVT.episode_no
LEFT JOIN #min_ws_diastolic AS WS_MIN_BPD ON PAV.PtNo_Num = WS_MIN_BPD.episode_no
LEFT JOIN #inr_pvt AS INR_PVT ON PAV.PtNo_Num = INR_PVT.episode_no
LEFT JOIN #max_inr AS MAX_INR ON PAV.PtNo_Num = MAX_INR.episode_no
LEFT JOIN #lactate_pvt AS LACTATE_PVT ON PAV.PtNo_Num = LACTATE_PVT.episode_no
LEFT JOIN #max_lactate AS MAX_LACTATE ON PAV.PtNo_Num = MAX_LACTATE.episode_no
LEFT JOIN #od_cns AS OD_CNS ON PAV.Pt_No = OD_CNS.pt_id
LEFT JOIN #arrival_bilirubin AS ARR_BILIRUBIN ON PAV.PtNo_Num = ARR_BILIRUBIN.episode_no
LEFT JOIN #max_bilirubin AS MAX_BILIRUBIN ON PAV.PtNo_Num = MAX_BILIRUBIN.episode_no
LEFT JOIN #arrival_creatinine AS ARR_CREATININE ON PAV.PtNo_Num = ARR_CREATININE.episode_no
LEFT JOIN #max_creatinine AS MAX_CREATININE ON PAV.PtNo_Num = MAX_CREATININE.episode_no
LEFT JOIN #od_resp AS OD_RESP ON PAV.PT_NO = OD_RESP.pt_id
LEFT JOIN #platelet_pvt AS PLT_PVT ON PAV.PtNo_Num = PLT_PVT.episode_no
LEFT JOIN #min_platelet AS MIN_PLT ON PAV.PtNo_Num = MIN_PLT.episode_no
LEFT JOIN #sirs_hr_pvt AS SIRS_HR_PVT ON PAV.PtNo_Num = SIRS_HR_PVT.episode_no
LEFT JOIN #max_sirs_hr AS MAX_HR ON PAV.PtNo_Num = MAX_HR.episode_no
LEFT JOIN #arr_wbc AS ARR_WBC ON PAV.PtNo_Num = ARR_WBC.episode_no
LEFT JOIN #min_wbc AS MIN_WBC ON PAV.PtNo_Num = MIN_WBC.episode_no
LEFT JOIN #max_wbc AS MAX_WBC ON PAV.PtNo_Num = MAX_WBC.episode_no
LEFT JOIN #sirs_resp_pvt AS SIRS_RESP_PVT ON PAV.PtNo_Num = SIRS_RESP_PVT.episode_no
LEFT JOIN #max_sirs_respiratoryrate AS MAX_SIRS_RESP_RATE ON PAV.PtNo_Num = MAX_SIRS_RESP_RATE.episode_no
LEFT JOIN #sirs_temp_pvt AS SIRS_TEMP_PVT ON PAV.PtNo_Num = SIRS_TEMP_PVT.episode_no
LEFT JOIN #max_sirs_temp AS MAX_SIRS_TEMP ON PAV.PtNo_Num = MAX_SIRS_TEMP.episode_no
LEFT JOIN #bp_systolic_pvt AS BP_SYS_PVT ON PAV.PtNo_Num = BP_SYS_PVT.episode_no
LEFT JOIN #min_systolic AS MIN_SYS ON PAV.PtNo_Num = MIN_SYS.episode_no
LEFT JOIN #dementia_tbl AS DEMENTIA ON PAV.PT_NO = DEMENTIA.pt_id
LEFT JOIN #diabetes_tbl AS DIABETES ON PAV.PT_NO = DIABETES.pt_id
LEFT JOIN #dialysis_comorbidity_tbl AS DIALYSIS_COMORBID ON PAV.Pt_No = DIALYSIS_COMORBID.pt_id
LEFT JOIN #history_of_covid_tbl AS COVID_HIST ON PAV.PtNo_Num = COVID_HIST.pt_id
LEFT JOIN #hx_of_other_cvd_tbl AS HX_OTH_CVD ON PAV.Pt_No = HX_OTH_CVD.pt_id
LEFT JOIN #hypertension AS HYPERTENSION ON PAV.Pt_No = HYPERTENSION.pt_id

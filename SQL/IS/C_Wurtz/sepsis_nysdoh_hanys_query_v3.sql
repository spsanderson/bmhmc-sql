/*
***********************************************************************
File: sepsis_nysdoh_hanys_query_v3.sql

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
	Get the encounters and associated data for the NYSDOH sepsis abstraction for 
    the HANYS SEPSIS PLATFORM file validator

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
2021-08-26	v2			Add logic to some obsrvations
							AND A.def_type_ind != 'TX'
							AND A.val_sts_cd != 'C'
2021-08-30	v3			Add REPLACE to insurance_number to drop hyphens
2021-10-05	v4			Added
							AND A.def_type_ind != 'TX'
							AND A.val_sts_cd != 'C'
						To creatinine section
						Added AND a.collected_datetime IS NOT NULL
						to wellsoft vitals sections
2021-10-13	v5			Use perf_dtime or sort_dtime instead of 
						obsv_cre_dtime from smsmir.mir_sr_obsv_new
2021-10-18	v6			Change WBC values to CAST(REPLACE(a.disp_val), CHAR(13), '') as float)
2021-10-20	v7			Change:
						DROP: 
							AND A.def_type_ind != 'TX'
							AND A.val_sts_cd != 'C'
						Add:
							AND CONCAT(RTRIM(LTRIM(A.def_type_ind)), RTRIM(LTRIM(A.val_sts_cd))) != 'TXC';
2021-10-21	v8			Change Platelets where clause to A.def_type_ind != 'TX'
2021-11-16	v9			Add:
							WHERE disp_val IN ('.','S') The 'S' is new to 
							Delete from #appt
						Add:
							WHERE (
								disp_val IN ('.D', '.','U','S')
								OR disp_val IS NULL
							);
							To the delete statement from delete from #inr
						Add:
							DELETE
							FROM #sirs_temp
							WHERE (
								RIGHT(sirs_temperature, 1) = 'C'
								OR sirs_temperature IN (
										'9836.0000','982.0000','976.0000','968.0000'
									) 
								)
2021-12-08	v10			Minor fixes to exclude bad values
2021-12-20	v11			Fix order of columns and add _poa to certain ones
						update version number
2022-04-05	v12			Add inclusion_septic_shock
							inclusion_severe_covid
							inclusion_severe_sepsis
							pat_addr_city
							pat_addr_cnty_cd
							pat_addr_line1
							pat_addr_line2
							pat_addr_state
							Skin Disorders/Burns
						Drop altered_mental_status
							medication_anticoagulation_poa
							during_hospital_anticoagulation
							cardiovascular_outcomes_at_hospital
							pe/dvt
2022-04-25	v13			Make fixes
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
		vst_end_dtime DATETIME,
		inclusion_septic_shock INT,
		inclusion_severe_covid INT,
		inclusion_severe_sepsis INT
		)

INSERT INTO #BasePopulation (
	Pt_No,
	PtNo_Num,
	unit_seq_no,
	from_file_ind,
	Bl_Unit_Key,
	Pt_Key,
	vst_start_dtime,
	vst_end_dtime,
	inclusion_septic_shock,
	inclusion_severe_covid,
	inclusion_severe_sepsis
	)
SELECT A.Pt_No,
	SUBSTRING(A.Pt_No, 5, 8) AS [PtNo_Num],
	A.unit_seq_no,
	A.from_file_ind,
	A.Bl_Unit_Key,
	A.Pt_Key,
	A.vst_start_dtime,
	A.vst_end_dtime,
	[inclusion_septic_shock] = A.SEP_Ind,
	[inclusion_severe_covid] = CASE	
		WHEN A.COVID_Ind = '1'
		AND A.ORGF_Ind = '1'
			THEN 1
		ELSE 0
	END,
	[inclusion_severe_sepsis] = A.SEP_Ind
FROM [smsdss].[c_sepsis_evaluator_v] AS A
WHERE (
		A.SEP_Ind = 1
		OR (
			A.COVID_Ind = 1
			AND A.ORGF_Ind = 1
			)
		)
	AND Dsch_Date >= '2022-01-01'
	AND Dsch_Date < '2022-04-01'
	AND PT_Age >= 21
	AND LEFT(A.PT_NO, 5) NOT IN ('00003', '00006', '00007');

-- Patient address information
DROP TABLE IF EXISTS #Patient_Address_tbl
CREATE TABLE #Patient_Address_tbl (
	pt_no VARCHAR(12),
	ptno_num VARCHAR(12),
	unit_seq_no VARCHAR(12),
	pat_addr_city VARCHAR(255),
	pat_addr_cnty_cd VARCHAR(255),
	pat_addr_line1 VARCHAR(255),
	pat_addr_line2 VARCHAR(255),
	pat_addr_st VARCHAR(12),
	patient_zip_code_of_residence VARCHAR(12)
)	

INSERT INTO #Patient_Address_tbl (
	pt_no,
	ptno_num,
	unit_seq_no,
	pat_addr_city,
	pat_addr_cnty_cd,
	pat_addr_line1,
	pat_addr_line2,
	pat_addr_st,
	patient_zip_code_of_residence
)
SELECT A.pt_id,
	b.PtNo_Num,
	b.unit_seq_no,
	a.Pt_Addr_City,
	pat_addr_cnty_cd = NULL,
	a.addr_line1,
	a.Pt_Addr_Line2,
	a.Pt_Addr_State,
	a.Pt_Addr_Zip
FROM SMSDSS.c_patient_demos_v AS A
INNER JOIN #BasePopulation AS B ON A.pt_id = B.Pt_No

-- TEST DEATH INFORMATION --
DROP TABLE IF EXISTS #death_info_tbl 
CREATE TABLE #death_info_tbl (
	Patient_OID INT,
	Visit_OID INT,
	PatientDeathDateTime SMALLDATETIME,
	PatientAccountID INT,
	Has_Time_Flag VARCHAR(12)
)

INSERT INTO #death_info_tbl(Patient_OID, Visit_OID, PatientDeathDateTime, PatientAccountID, Has_Time_Flag)
SELECT PT.ObjectID AS [Patient_OID],
	VISIT.ObjectID AS [Visit_OID],
	DEATH.PatientDeathDateTime,
	VISIT.PatientAccountID,
	[HAS_TIME_FLAG] = CASE
		WHEN SUBSTRING(CAST(DEATH.PATIENTDEATHDATETIME AS VARCHAR), 12, 12) = ' 12:00AM'
			THEN 'NO_TIME'
			ELSE 'HAS_TIME'
		END
FROM smsmir.sc_Patient AS PT
INNER JOIN smsmir.sc_DeathInformation AS DEATH ON PT.DeathInformation_oid = DEATH.ObjectID
INNER JOIN smsmir.sc_PatientVisit AS VISIT ON PT.ObjectID = VISIT.Patient_oid
INNER JOIN #BasePopulation AS BP ON BP.PtNo_Num = VISIT.PatientAccountID
-- END TEST --

-- Comorbidities ------------------------------------------------------
-- acute cardiovascular conditions
DROP TABLE IF EXISTS #acc_temp_tbl
CREATE TABLE #acc_temp_tbl (
	pt_id VARCHAR(12),
	PtNo_Num VARCHAR(8),
	acute_cardiovascular_conditions VARCHAR(20)
)

INSERT INTO #acc_temp_tbl (pt_id, PtNo_Num, acute_cardiovascular_conditions)
SELECT A.pt_id,
	SUBSTRING(a.pt_id, 5, 8) AS [PtNo_Num],
	CASE
		WHEN B.subcategory = 'MYOCARDITIS COVID'
			THEN '3'
		WHEN B.subcategory = 'Stroke/TIA'
			THEN '2'
		WHEN B.subcategory = 'MI'
			THEN '1'
		ELSE '0'
		END AS [acute_cardiovascular_conditions]
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_acute_cardiovascular_conditions_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No
	AND A.unit_seq_no = BP.unit_seq_no

DROP TABLE IF EXISTS #acc_tbl
CREATE TABLE #acc_tbl (
	pt_id VARCHAR(12),
	ptno_num VARCHAR(8),
	acute_cardiovascular_conditions VARCHAR(20)
)

INSERT INTO #acc_tbl (pt_id, ptno_num, acute_cardiovascular_conditions)
SELECT pvt.pt_id,
	pvt.ptno_num, 
	acute_cardiovascular_conditions = REPLACE(STUFF(
		COALESCE(': ' + RTRIM(PVT.[0]), '')
		+ COALESCE(': ' + RTRIM(PVT.[1]), '')
		+ COALESCE(': ' + RTRIM(PVT.[2]), '')
		+ COALESCE(': ' + RTRIM(PVT.[3]), '')
	, 1, 2, ''), ': ',':')
FROM #acc_temp_tbl AS A
PIVOT(MAX(acute_cardiovascular_conditions) FOR acute_cardiovascular_conditions IN ("0","1","2","3")) AS PVT

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
	AND A.unit_seq_no = BP.unit_seq_no

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
	AND A.unit_seq_no = BP.unit_seq_no

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
	AND A.unit_seq_no = BP.unit_seq_no

-- Chronic Renal Failure THIS WAS RENAMED TO chronic_kidney_disease.
-- they added a new table but all the codes already exist in the current with zero exceptions
DROP TABLE IF EXISTS #crf
	CREATE TABLE #crf (
		pt_id VARCHAR(12),
		chronic_kidney_disease VARCHAR(10)
		)

INSERT INTO #crf (
	pt_id,
	chronic_kidney_disease
	)
SELECT DISTINCT A.pt_id,
	[chronic_kidney_disease] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_chronic_kidney_disease_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.PT_NO
	AND A.unit_seq_no = BP.unit_seq_no

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
		AND A.unit_seq_no = BP.unit_seq_no

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
	--[coagulopathy] = CASE 
	--	WHEN B.icd10_cm_code IS NULL
	--		THEN 0
	--	ELSE 1
	--	END,
	--3.0 LOGIC
	[poa] = CASE
		WHEN A.poa_ind = 'N'
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_coagulopathy_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No
	AND A.unit_seq_no = BP.unit_seq_no

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
	AND A.unit_seq_no = BP.unit_seq_no

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
	AND A.unit_seq_no = BP.unit_seq_no

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
	AND A.unit_seq_no = BP.unit_seq_no

-- Organ Dysfunction Respiratory
DROP TABLE IF EXISTS #od_resp
	CREATE TABLE #od_resp (
		pt_id VARCHAR(12),
		organ_dysfunc_respiratory VARCHAR(10)
		)

INSERT INTO #od_resp (pt_id, organ_dysfunc_respiratory)
SELECT DISTINCT pt_id,
	[organ_dysfunc_respiratory] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_organ_dysfunc_respiratory_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- Organ Dysfunction Cardiovascular
DROP TABLE IF EXISTS #od_cardiovascular;
CREATE TABLE #od_cardiovascular (
	pt_id VARCHAR(12),
	organ_dysfunction_cardiovascular VARCHAR(10)
)

INSERT INTO #od_cardiovascular (pt_id, organ_dysfunction_cardiovascular)
SELECT DISTINCT pt_id,
	[organ_dysfunction_cardiovascular] = CASE
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_organ_dysfunc_cardiovascular_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- Organ Dysfunction Hematologic
DROP TABLE IF EXISTS #od_hematologic
CREATE TABLE #od_hematologic (
	pt_id VARCHAR(12),
	organ_dysfunc_hematologic VARCHAR(10)
)

INSERT INTO #od_hematologic (pt_id, organ_dysfunc_hematologic)
SELECT DISTINCT pt_id,
	[organ_dysfunc_hematologic] = CASE
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_organ_dysfunc_hematologic_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No

-- Organ Dysfunction Hepatic
DROP TABLE IF EXISTS #od_hepatic
CREATE TABLE #od_hepatic (
	pt_id VARCHAR(12),
	organ_dysfun_hepatic VARCHAR(10)
)

INSERT INTO #od_hepatic (pt_id, organ_dysfun_hepatic)
SELECT DISTINCT pt_id,
	[organ_dysfunc_heptatic] = CASE
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_organ_dysfunc_hepatic_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No

-- Organ Dysfunction Renal
DROP TABLE IF EXISTS #ogd_renal 
CREATE TABLE #ogd_renal (
	pt_id VARCHAR(12),
	organ_dysfunc_renal VARCHAR(10)
)

INSERT INTO #ogd_renal (pt_id, organ_dysfunc_renal)
SELECT DISTINCT pt_id,
	[organ_dysfunc_renal] = CASE
		WHEN b.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_organ_dysfunc_renal_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
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
	--[dialysis_comorbidity] = CASE 
	--	WHEN B.icd10_cm_code IS NULL
	--		THEN 0
	--	ELSE 1
	--	END,
	-- 3.0 LOGIC
	[poa] = CASE
		WHEN a.poa_ind = 'N'
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_dialysis_comorbidity_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No
	AND A.unit_seq_no = BP.unit_seq_no

-- History Of COVID
DROP TABLE IF EXISTS #history_of_covid_tbl
CREATE TABLE #history_of_covid_tbl (
	pt_id VARCHAR(12),
	history_of_covid_dt DATETIME,
	history_of_covid INT
	)

INSERT INTO #history_of_covid_tbl (
	pt_id,
	history_of_covid_dt,
	history_of_covid
	)
SELECT DISTINCT A.PTNO_NUM,
	[history_of_covid_dt] = A.Last_Positive_Result_DTime,
	[history_of_covid] = CASE
		WHEN ABS(DATEDIFF(DAY, BP.vst_start_dtime, A.Last_Positive_Result_DTime)) <= (12*7)
			THEN 1
		ELSE 0
		END
FROM SMSDSS.c_covid_extract_tbl AS a
INNER JOIN #BasePopulation AS BP ON A.PTNO_NUM = BP.PtNo_Num
WHERE A.Last_Positive_Result_DTime IS NOT NULL

-- History of Other CVD 
/*
Subcategory
Coronary Heart Disease       - 1
Peripheral arterial disease  - 2 
Valve disorder               - 3
Cerebrovascular Disease      - 4
Cardiomyopathy               - 5

1 = Coronary heart disease (e.g. angina pectoris, coronary atherosclerosis)
2 = Peripheral artery disease
3 = Valve disorder
4 = Cerebrovascular disease
5 = Cardiomyopathy
0 = No history of coronary heart disease, peripheral artery disease, valve disorder or cerebrovascular disease
*/
DROP TABLE IF EXISTS #history_of_other_cvd_tbl
CREATE TABLE #history_of_other_cvd_tbl (
	pt_id VARCHAR(12),
	history_of_other_cvd VARCHAR(100)
	)

INSERT INTO #history_of_other_cvd_tbl (
	pt_id,
	history_of_other_cvd
	)
SELECT DISTINCT A.pt_id,
	[history_of_other_cvd] = CASE 
	    WHEN B.subcategory = 'Cerebrovascular Disease'
			THEN '4'
		WHEN B.subcategory = 'Coronary Heart Disease'
			THEN '1'
		WHEN B.subcategory = 'Peripheral arterial disease'
			THEN '2'
		WHEN B.subcategory = 'Valve disorder'
			THEN '3'
		WHEN B.subcategory = 'Cardiomyopathy'
			THEN '5'
		ELSE '0'
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_history_of_other_cvd_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No

DROP TABLE IF EXISTS #hx_of_other_cvd_tbl
CREATE TABLE #hx_of_other_cvd_tbl (
	pt_id VARCHAR(12),
	history_of_other_cvd VARCHAR(20)
)
INSERT INTO #hx_of_other_cvd_tbl (pt_id, history_of_other_cvd)
SELECT PVT.pt_id,
	[history_of_other_cvd] = REPLACE(STUFF(
		COALESCE(': ' + RTRIM(PVT.[0]), '')
		+ COALESCE(': ' + RTRIM(PVT.[1]), '')
		+ COALESCE(': ' + RTRIM(PVT.[2]), '')
		+ COALESCE(': ' + RTRIM(PVT.[3]), '')
		+ COALESCE(': ' + RTRIM(PVT.[4]), '')
		+ COALESCE(': ' + RTRIM(PVT.[5]), '')
	, 1, 2, ''), ': ',':')
FROM #history_of_other_cvd_tbl AS A
PIVOT(MAX(history_of_other_cvd) FOR history_of_other_cvd IN ("0","1","2","3","4","5")) AS PVT

-- HYPERTENSION
DROP TABLE IF EXISTS #hypertension
CREATE TABLE #hypertension (
	pt_id VARCHAR(12),
	hypertension VARCHAR(10)
	)

INSERT INTO #hypertension (
	pt_id,
	hypertension
	)
SELECT DISTINCT A.pt_id,
	[hypertension] = CASE 
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM SMSMIR.dx_grp AS A
INNER JOIN SMSDSS.c_nysdoh_sepsis_hypertension_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- IMMUNOCOMPROMISING
DROP TABLE IF EXISTS #immunocompromising
CREATE TABLE #immunocompromising (
	pt_id VARCHAR(12),
	immunocompromising VARCHAR(10)
)
INSERT INTO #immunocompromising (
	pt_id,
	immunocompromising
	)
SELECT DISTINCT A.pt_id,
	[immunocompromising] = CASE
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN SMSDSS.c_nysdoh_sepsis_immunocompromising_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- Lymphoma Leukemia Multiple Myeloma
DROP TABLE IF EXISTS #llmL_tbl
CREATE TABLE #llml_tbl (
	pt_id VARCHAR(12),
	lymphoma_leukemia_multi_myeloma VARCHAR(10)
	)
INSERT INTO #llml_tbl (
	pt_id,
	lymphoma_leukemia_multi_myeloma
	)
SELECT DISTINCT A.pt_id,
	[lymphoma_leukemia_multi_myeloma] = CASE
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_lymphoma_leukemia_multi_myeloma_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.PT_NO

-- Mechanical Vent
DROP TABLE IF EXISTS #vent_tbl
CREATE TABLE #vent_tbl (
	pt_id VARCHAR(12),
	mechanical_vent_comorbidity VARCHAR(10)
	)
INSERT INTO #vent_tbl (
	pt_id,
	mechanical_vent_comorbidity
	)
SELECT DISTINCT A.pt_id,
	[mechanical_vent_comorbidity] = CASE
		WHEN A.poa_ind = 'N'
			THEN 0
		ELSE 1
		END
	--[mechanical_vent_comorbidity] = CASE
	--	WHEN b.icd10_cm_code IS NULL
	--		THEN 0
	--	ELSE 1
	--	END
FROM SMSMIR.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_mechanical_vent_comorbidity_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

---- MEDICAITON ANTICOAGULATION HOME MED LIST
--DECLARE @HML_Medication_Anticoagulation TABLE (
--	NDC VARCHAR(12)
--)
--INSERT INTO @HML_Medication_Anticoagulation (NDC)
--SELECT CASE
--	WHEN LEN(NDC) = 10
--		THEN '0' + NDC
--	WHEN LEN(NDC) = 9
--		THEN '00' + NDC
--	WHEN LEN(NDC) = 8
--		THEN '000' + NDC
--	WHEN LEN(NDC) = 7
--		THEN '0000' + NDC
--	ELSE NDC
--	END
--FROM smsdss.c_nysdoh_sepsis_medication_anticoagulation_ndc_code

--DROP TABLE IF EXISTS #hml_med_anticoag
--CREATE TABLE #hml_med_anticoag (
--	episode_no VARCHAR(12)
--)
--INSERT INTO #hml_med_anticoag
--SELECT DISTINCT c.PatientAccountID
--FROM smsmir.mir_sc_vw_MRC_Medlist AS a
--INNER JOIN smsmir.mir_sc_XMLDocStorage AS b
--ON a.XMLDocStorageOid = b.XMLDocStorageOid
--INNER JOIN smsmir.mir_sc_PatientVisit AS c
--ON b.Patient_OID = c.Patient_oid
--    AND b.PatientVisit_OID = c.StartingVisitOID
--INNER JOIN smsmir.mir_PHM_DrugMstr as d on upper(coalesce(a.GenericName, a.brandname)) = upper(coalesce(d.gnrcname, d.brandname))
--INNER JOIN @HML_Medication_Anticoagulation AS E ON REPLACE(D.NDC, '-','') = E.NDC
--INNER JOIN #BasePopulation AS BP ON C.PatientAccountID = BP.PtNo_Num
--WHERE a.DocumentType = 'hml'

-- MEDICATION IMMUNE MODIFYING HOME MED LIST
DECLARE @HML_Medication_Immune_Modifying TABLE (
	NDC VARCHAR(12)
)
INSERT INTO @HML_Medication_Immune_Modifying (NDC)
SELECT CASE
	WHEN LEN(NDC) = 10
		THEN '0' + NDC
	WHEN LEN(NDC) = 9
		THEN '00' + NDC
	WHEN LEN(NDC) = 8
		THEN '000' + NDC
	WHEN LEN(NDC) = 7
		THEN '0000' + NDC
	ELSE NDC
	END
FROM smsdss.c_nysdoh_sepsis_medication_immune_modifying_ndc_code

DROP TABLE IF EXISTS #hml_med_imm_mod
CREATE TABLE #hml_med_imm_mod (
	episode_no VARCHAR(12)
)
INSERT INTO #hml_med_imm_mod
SELECT DISTINCT c.PatientAccountID
FROM smsmir.mir_sc_vw_MRC_Medlist AS a
INNER JOIN smsmir.mir_sc_XMLDocStorage AS b
ON a.XMLDocStorageOid = b.XMLDocStorageOid
INNER JOIN smsmir.mir_sc_PatientVisit AS c
ON b.Patient_OID = c.Patient_oid
    AND b.PatientVisit_OID = c.StartingVisitOID
INNER JOIN smsmir.mir_PHM_DrugMstr as d on upper(coalesce(a.GenericName, a.brandname)) = upper(coalesce(d.gnrcname, d.brandname))
INNER JOIN @HML_Medication_Immune_Modifying AS E ON REPLACE(D.NDC, '-','') = E.NDC
INNER JOIN #BasePopulation AS BP ON C.PatientAccountID = BP.PtNo_Num
WHERE a.DocumentType = 'hml'

---- MEDICATION ANTICOAGULATION IN HOSPITAL
--DECLARE @Medication_Anticoagulation TABLE (
--	NDC VARCHAR(12)
--)
--INSERT INTO @Medication_Anticoagulation (NDC)
--SELECT CASE
--	WHEN LEN(NDC) = 10
--		THEN '0' + NDC
--	WHEN LEN(NDC) = 9
--		THEN '00' + NDC
--	WHEN LEN(NDC) = 8
--		THEN '000' + NDC
--	WHEN LEN(NDC) = 7
--		THEN '0000' + NDC
--	ELSE NDC
--	END
--FROM smsdss.c_nysdoh_sepsis_medication_anticoagulation_ndc_code

--DROP TABLE IF EXISTS #med_anticoag 
--CREATE TABLE #med_anticoag (
--	episode_no VARCHAR(12)
--)

--INSERT INTO #med_anticoag (episode_no)
--SELECT DISTINCT C.EpisodeNo
--FROM @Medication_Anticoagulation AS A
--INNER JOIN smsmir.mir_PHM_DrugMstr AS B ON A.NDC = REPLACE(B.NDC, '-', '')
--INNER JOIN SMSMIR.mir_PHM_Ord AS C ON B.NDC = C.NDC
--INNER JOIN #BasePopulation AS BP ON C.EpisodeNo = BP.PtNo_Num

-- MEDICATION IMMUNE MODIFYING IN HOSPITAL
DECLARE @Medication_Immune_Modifying TABLE (
	NDC VARCHAR(12)
)
INSERT INTO @Medication_Immune_Modifying (NDC)
SELECT CASE
	WHEN LEN(NDC) = 10
		THEN '0' + NDC
	WHEN LEN(NDC) = 9
		THEN '00' + NDC
	WHEN LEN(NDC) = 8
		THEN '000' + NDC
	WHEN LEN(NDC) = 7
		THEN '0000' + NDC
	ELSE NDC
	END
FROM smsdss.c_nysdoh_sepsis_medication_immune_modifying_ndc_code

DROP TABLE IF EXISTS #med_imm_mod 
CREATE TABLE #med_imm_mod (
	episode_no VARCHAR(12)
)

INSERT INTO #med_imm_mod (episode_no)
SELECT DISTINCT C.EpisodeNo
FROM @Medication_Immune_Modifying AS A
INNER JOIN smsmir.mir_PHM_DrugMstr AS B ON A.NDC = REPLACE(B.NDC, '-', '')
INNER JOIN SMSMIR.mir_PHM_Ord AS C ON B.NDC = C.NDC
INNER JOIN #BasePopulation AS BP ON C.EpisodeNo = BP.PtNo_Num

-- Vasopressor Administration during hospital
DECLARE @Medication_Vasopressor TABLE (
	NDC VARCHAR(12)
)
INSERT INTO @Medication_Vasopressor (NDC)
SELECT CASE
	WHEN LEN(NDC) = 10
		THEN '0' + NDC
	WHEN LEN(NDC) = 9
		THEN '00' + NDC
	WHEN LEN(NDC) = 8
		THEN '000' + NDC
	WHEN LEN(NDC) = 7
		THEN '0000' + NDC
	ELSE NDC
	END
FROM smsdss.c_nysdoh_sepsis_vasopressor_administration_ndc_code

DROP TABLE IF EXISTS #med_vasopressor 
CREATE TABLE #med_vasopressor (
	episode_no VARCHAR(12)
)

INSERT INTO #med_vasopressor (episode_no)
SELECT DISTINCT C.EpisodeNo
FROM @Medication_Vasopressor AS A
INNER JOIN smsmir.mir_PHM_DrugMstr AS B ON A.NDC = REPLACE(B.NDC, '-', '')
INNER JOIN SMSMIR.mir_PHM_Ord AS C ON B.NDC = C.NDC
INNER JOIN #BasePopulation AS BP ON C.EpisodeNo = BP.PtNo_Num

-- METASTATIC CANCER
DROP TABLE IF EXISTS #metastatic_cx_tbl
CREATE TABLE #metastatic_cx_tbl (
	pt_id VARCHAR(12),
	metastatic_cancer VARCHAR(10)
	)
INSERT INTO #metastatic_cx_tbl (
	pt_id,
	metastatic_cancer
	)
SELECT DISTINCT A.pt_id,
	[metastatic_cancer] = CASE
		WHEN b.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM SMSMIR.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_metastatic_cancer_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- OBESITY
DROP TABLE IF EXISTS #obesity_tbl
CREATE TABLE #obesity_tbl (
	pt_id VARCHAR(12),
	obesity VARCHAR(10)
	)
INSERT INTO #obesity_tbl (
	pt_id,
	obesity
	)
SELECT DISTINCT A.pt_id,
	[obesity] = CASE
		WHEN b.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM SMSMIR.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_obesity_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- BMI
DROP TABLE IF EXISTS #bmi_tbl
CREATE TABLE #bmi_tbl (
	episode_no VARCHAR(12),
	coll_dtime DATETIME,
	lab_number INT,
	disp_val VARCHAR(200),
	obesity_flag INT
	)

INSERT INTO #bmi_tbl (
	episode_no,
	coll_dtime,
	lab_number,
	disp_val,
	obesity_flag
	)
SELECT A.episode_no,
	coalesce(a.perf_dtime, a.sort_dtime),
	--a.obsv_cre_dtime,
	[lab_number] = ROW_NUMBER() OVER(
		PARTITION BY A.episode_no
		ORDER BY coalesce(a.perf_dtime, a.sort_dtime)
	),
	replace(a.dsply_val, char(13), '') as disp_val,
	[obesity_bmi_flag] = case when cast(replace(a.dsply_val, char(13), '') as numeric) > 30.0 then 1 else 0 end
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE A.obsv_cd = 'A_BMI'

DELETE
FROM #bmi_tbl
WHERE lab_number != 1
OR obesity_flag = 0;

-- Patient Care Concerns
DROP TABLE IF EXISTS #dnr_dni_asmt_tbl
CREATE TABLE #dnr_dni_asmt_tbl (
	episode_no VARCHAR(12),
	obsv_cd VARCHAR(255),
	dsply_val VARCHAR(255)
	)

INSERT INTO #dnr_dni_asmt_tbl (
	episode_no,
	obsv_cd,
	dsply_val
	)
SELECT DISTINCT a.episode_no,
	a.obsv_cd,
	[dsply_val] = CASE 
		WHEN RTRIM(LTRIM(UPPER(a.dsply_val))) = 'YES'
			AND obsv_cd = 'A_BMH_DNR'
			THEN 1
		WHEN RTRIM(LTRIM(UPPER(A.DSPLY_VAL))) = 'YES'
			AND obsv_cd = 'A_BMH_DNI'
			THEN 2
		ELSE NULL
		END
FROM SMSMIR.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE A.obsv_cd IN ('A_BMH_DNR', 'A_BMH_DNI')

DROP TABLE IF EXISTS #dnr_dni_asmt_pvt_tbl
CREATE TABLE #dnr_dni_asmt_pvt_tbl (
	episode_no VARCHAR(12),
	[patient_care_considerations] VARCHAR(255)
)

INSERT INTO #dnr_dni_asmt_pvt_tbl (episode_no, patient_care_considerations)
SELECT PVT.episode_no,
	[patient_care_concerns] = REPLACE(
		STUFF(
			COALESCE(': ' + RTRIM(PVT.[A_BMH_DNR]), '') 
			+ COALESCE(': ' + RTRIM(PVT.[A_BMH_DNI]), '')
			, 1, 2, ''
			)
		, ': ', ':'
	)
FROM (
	SELECT episode_no,
		obsv_cd,
		dsply_val
	FROM #dnr_dni_asmt_tbl
	) AS A
PIVOT(MAX(dsply_val) FOR obsv_cd IN ("A_BMH_DNR", "A_BMH_DNI")) AS PVT

-- DNR/DNI ORDER
DROP TABLE IF EXISTS #dnr_dni_ord_tbl
CREATE TABLE #dnr_dni_ord_tbl (
	episode_no VARCHAR(12),
	obsv_cd VARCHAR(255),
	dsply_val VARCHAR(1)
)

INSERT INTO #dnr_dni_ord_tbl (episode_no, obsv_cd, dsply_val)
SELECT A.episode_no,
svc_cd, 
dsply_val = CASE
	WHEN A.svc_cd = 'PCO_DNR'
		THEN 1
	ELSE 2
	END
FROM smsmir.mir_sr_ord AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE A.svc_cd IN ('PCO_DNR','PCO_DNI')
GROUP BY A.episode_no, 
A.svc_cd

DROP TABLE IF EXISTS #dnr_dni_ord_pvt_tbl
CREATE TABLE #dnr_dni_ord_pvt_tbl (
	episode_no VARCHAR(12),
	[patient_care_considerations] VARCHAR(255)
)

INSERT INTO #dnr_dni_ord_pvt_tbl (episode_no, patient_care_considerations)
SELECT PVT.episode_no,
	[patient_care_concerns] = REPLACE(
		STUFF(
			COALESCE(': ' + RTRIM(PVT.[PCO_DNR]), '') 
			+ COALESCE(': ' + RTRIM(PVT.[PCO_DNI]), '')
			, 1, 2, ''
			)
		, ': ', ':'
	)
FROM (
	SELECT episode_no,
		obsv_cd,
		dsply_val
	FROM #dnr_dni_ord_tbl
	) AS A
PIVOT(MAX(dsply_val) FOR obsv_cd IN ("PCO_DNR", "PCO_DNI")) AS PVT

-- DNR DNI PVT TABLE FINAL
DROP TABLE IF EXISTS #dnr_dni_final_tbl
CREATE TABLE #dnr_dni_final_tbl (
	episode_no VARCHAR(12),
	patient_care_considerations VARCHAR(255),
	rn INT
)

INSERT INTO #dnr_dni_final_tbl (episode_no, patient_care_considerations, rn)
SELECT A.episode_no,
	A.patient_care_considerations,
	[rn] = ROW_NUMBER() OVER(
		PARTITION BY A.episode_no
		ORDER BY LEN(A.patient_care_considerations) DESC
	)
FROM (
	SELECT episode_no,
		patient_care_considerations
	FROM #dnr_dni_asmt_pvt_tbl
	--WHERE episode_no = '14909667'
	UNION 
	SELECT episode_no,
		patient_care_considerations
	FROM #dnr_dni_ord_pvt_tbl
	--WHERE episode_no = '14909667'
) AS A

DELETE
FROM #dnr_dni_final_tbl
WHERE RN != 1


-- Patient Care Concerns Date
-- Assessments
DROP TABLE IF EXISTS #dnr_dni_asmt_date_tbl 
CREATE TABLE #dnr_dni_asmt_date_tbl (
	episode_no VARCHAR(12),
	patient_care_considerations_date VARCHAR (255)
)

INSERT INTO #dnr_dni_asmt_date_tbl (episode_no, patient_care_considerations_date)
SELECT A.episode_no,
	CONVERT(CHAR(10), MIN(coalesce(a.perf_dtime, a.sort_dtime)), 126)
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #dnr_dni_asmt_pvt_tbl AS B ON A.episode_no = B.episode_no
WHERE A.obsv_cd IN ('A_BMH_DNR','A_BMH_DNI')
GROUP BY A.episode_no

-- Orders
DROP TABLE IF EXISTS #dnr_dni_ord_date_tbl
CREATE TABLE #dnr_dni_ord_date_tbl (
	episode_no VARCHAR(12),
	patient_care_considerations_date VARCHAR(255)
)

INSERT INTO #dnr_dni_ord_date_tbl
SELECT A.episode_no,
	CONVERT(CHAR(10), MIN(A.ent_dtime), 126)
FROM smsmir.mir_sr_ord AS A
INNER JOIN #dnr_dni_ord_pvt_tbl AS B ON A.episode_no = B.episode_no
WHERE A.SVC_CD IN ('PCO_DNR','PCO_DNI')
GROUP BY A.episode_no

-- Final Table
DROP TABLE IF EXISTS #dnr_dni_date_tbl 
CREATE TABLE #dnr_dni_date_tbl (
	episode_no VARCHAR(12),
	patient_care_considerations_date VARCHAR(255),
	RN INT
)

INSERT INTO #dnr_dni_date_tbl (episode_no, patient_care_considerations_date, RN)
SELECT A.episode_no,
	a.patient_care_considerations_date,
	[rn] = ROW_NUMBER() OVER(
		PARTITION BY A.EPISODE_NO
		ORDER BY A.PATIENT_CARE_CONSIDERATIONS_DATE ASC
	)
FROM (
	SELECT episode_no,
		patient_care_considerations_date
	FROM #dnr_dni_asmt_date_tbl

	UNION

	SELECT episode_no,
		patient_care_considerations_date
	FROM #dnr_dni_ord_date_tbl
) AS A

DELETE
FROM #dnr_dni_date_tbl
WHERE RN != 1

-- pregnancy comorbidity
DROP TABLE IF EXISTS #preg_comorbid_tbl
CREATE TABLE #preg_comorbid_tbl (
	pt_id VARCHAR(12),
	pregnancy_comorbidity VARCHAR(10)
	)
INSERT INTO #preg_comorbid_tbl (
	pt_id,
	pregnancy_comorbidity
	)
SELECT DISTINCT A.pt_id,
	[pregnancy_comorbidity] = CASE
		WHEN b.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM SMSMIR.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_pregnancy_comorbidity_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- pregnancy status
DROP TABLE IF EXISTS #preg_status_tbl
CREATE TABLE #preg_status_tbl (
	pt_id VARCHAR(12),
	pregnancy_status VARCHAR(10)
	)
INSERT INTO #preg_status_tbl (
	pt_id,
	pregnancy_status
	)
SELECT DISTINCT A.pt_id,
	[pregnancy_status] = CASE
		WHEN b.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM SMSMIR.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_pregnancy_status_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- Skin Disorders new to 3.0 Logic
DROP TABLE IF EXISTS #skin_disorders_tbl
CREATE TABLE #skin_disorders_tbl (
	pt_id VARCHAR(12),
	skin_disorder_cat VARCHAR(255),
	skin_disorder_flag INT
)

INSERT INTO #skin_disorders_tbl (
	pt_id,
	skin_disorder_cat,
	skin_disorder_flag
)
SELECT A.pt_id,	
	c.Subcategory,
	skin_disorder_flag = CASE
		WHEN C.Subcategory = 'Epidermolysis bullosa'
			THEN 1
		WHEN C.Subcategory = 'Burn/Corrosion of skin'
			THEN 1
		WHEN C.Subcategory = 'Frostbite'
			THEN 1
		ELSE 0
		END
FROM smsmir.dx_grp AS A
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No
	AND A.unit_seq_no = BP.unit_seq_no
INNER JOIN smsdss.c_nysdoh_sepsis_skin_disorders_burn_disease_code AS C ON REPLACE(A.DX_CD, '.', '') = C.[ICD.10.CM.Code]

DROP TABLE IF EXISTS #skin_disorders_pvt_tbl
CREATE TABLE #skin_disorders_pvt_tbl (
	pt_id VARCHAR(12),
	skin_disorders_burns VARCHAR(255)
)

INSERT INTO #skin_disorders_pvt_tbl
SELECT PVT.pt_id,	
	[skin_disorders_burns] = REPLACE(
		STUFF(
			COALESCE(': ' + RTRIM(PVT.[Epidermolysis bullosa]), '')
			+ COALESCE(': ' + RTRIM(PVT.[Burn/Corrosion of skin]), '')
			+ COALESCE(': ' + RTRIM(PVT.[Frostbite]), '')
			, 1, 2, ''
			)
		, ': ', ':'
	)
FROM (
	SELECT pt_id,
		skin_disorder_cat,
		skin_disorder_flag
	FROM #skin_disorders_tbl
) AS A
PIVOT(MAX(skin_disorder_flag) FOR skin_disorder_cat IN ("Epidermolysis bullosa","Burn/Corrosion of skin","Frostbite")) AS PVT

-- smoking vaping
DROP TABLE IF EXISTS #smoking_vaping_tbl
CREATE TABLE #smoking_vaping_tbl (
	pt_id VARCHAR(12),
	smoking_vaping VARCHAR(10)
	)
INSERT INTO #smoking_vaping_tbl (
	pt_id,
	smoking_vaping
	)
SELECT DISTINCT A.pt_id,
	[smoking_vaping] = CASE
		WHEN b.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM SMSMIR.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_smoking_vaping_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- trach on arrival
DROP TABLE IF EXISTS #trach_arrival_tbl
CREATE TABLE #trach_arrival_tbl (
	pt_id VARCHAR(12),
	tracheostomy_on_arrival VARCHAR(10)
	)
INSERT INTO #trach_arrival_tbl (
	pt_id,
	tracheostomy_on_arrival
	)
SELECT DISTINCT A.pt_id,
	[tracheostomy_on_arrival] = CASE
		WHEN b.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM SMSMIR.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_tracheostomy_on_arrival_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- exposure variables
-- covid exposure
DROP TABLE IF EXISTS #covid_exposure_tbl
CREATE TABLE #covid_exposure_tbl (
	pt_id VARCHAR(12),
	covid_exposure VARCHAR(10)
	)
INSERT INTO #covid_exposure_tbl (
	pt_id,
	covid_exposure
	)
SELECT DISTINCT A.pt_id,
	[covid_exposure] = CASE
		WHEN b.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM SMSMIR.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_covid_exposure_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- covid virus
DROP TABLE IF EXISTS #covid_virus_tbl
CREATE TABLE #covid_virus_tbl (
	pt_id VARCHAR(12),
	covid_virus VARCHAR(10)
	)
INSERT INTO #covid_virus_tbl (
	pt_id,
	covid_virus
	)
SELECT DISTINCT A.pt_id,
	[covid_virus] = CASE
		WHEN b.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM SMSMIR.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_covid_virus_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- drug resistant pathogen
DROP TABLE IF EXISTS #drp_tbl
CREATE TABLE #drp_tbl (
	pt_id VARCHAR(12),
	drug_resistant_pathogen VARCHAR(10)
	)
INSERT INTO #drp_tbl (
	pt_id,
	drug_resistant_pathogen
	)
SELECT DISTINCT A.pt_id,
	[drug_resistant_pathogen] = CASE
		WHEN b.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM SMSMIR.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_drug_resistant_pathogen_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- flu positive
DROP TABLE IF EXISTS #flu_pos_tbl
CREATE TABLE #flu_pos_tbl (
	pt_id VARCHAR(12),
	flu_positive VARCHAR(10)
	)
INSERT INTO #flu_pos_tbl (
	pt_id,
	flu_positive
	)
SELECT DISTINCT A.pt_id,
	[flu_positive] = CASE
		WHEN b.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM SMSMIR.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_flu_positive_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- flu test
DROP TABLE IF EXISTS #flu_tbl
CREATE TABLE #flu_tbl (
	episode_no VARCHAR(12),
	flu_positive VARCHAR(200)
	)

INSERT INTO #flu_tbl (
	episode_no,
	flu_positive
	)
SELECT A.episode_no,
	[flu_flag] = CASE WHEN A.dsply_val LIKE '%POSITIVE%' THEN 1 ELSE 0 END
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE A.obsv_cd IN ('00424721', '00424739')
GROUP BY A.episode_no, 
CASE WHEN A.dsply_val LIKE '%POSITIVE%' THEN 1 ELSE 0 END

DELETE
FROM #flu_tbl
WHERE flu_positive != 1;

-- Suspected Source of Infection
DROP TABLE IF EXISTS #ssoi_tbl
CREATE TABLE #ssoi_tbl (
	pt_id VARCHAR(12),
	subcategory VARCHAR(100)
	)

INSERT INTO #ssoi_tbl (
	pt_id,
	subcategory
	)
SELECT DISTINCT A.pt_id,
	b.subcategory
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_suspected_source_of_infection_code AS B ON REPLACE(A.DX_CD, '.', '') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.PT_ID = BP.Pt_No

DROP TABLE IF EXISTS #ssoi_pvt_temp_tbl 
CREATE TABLE #ssoi_pvt_temp_tbl (
	pt_id VARCHAR(12),
	bacteremia VARCHAR(2),
	central_nervous_system_infection VARCHAR(2),
	fungal_infection VARCHAR(2),
	gastrointestinal_infection VARCHAR(2),
	genitourinary_infection VARCHAR(2),
	heart_infection VARCHAR(2),
	lung_infection VARCHAR(2),
	other_infection_source VARCHAR(2),
	peritoneal_infection VARCHAR(2),
	septicemia VARCHAR(2),
	soft_tissue_infection VARCHAR(2),
	upper_respiratory_infection VARCHAR(2),
	unknown VARCHAR(2)
)

INSERT INTO #ssoi_pvt_temp_tbl (
	pt_id,
	bacteremia,
	central_nervous_system_infection,
	fungal_infection,
	gastrointestinal_infection,
	genitourinary_infection,
	heart_infection,
	lung_infection,
	other_infection_source,
	peritoneal_infection,
	septicemia,
	soft_tissue_infection,
	upper_respiratory_infection,
	unknown
)
SELECT SSOI_PVT.pt_id,
CASE WHEN SSOI_PVT.[Bacteremia] IS NOT NULL THEN '2' ELSE NULL END AS [bacteria],
CASE WHEN SSOI_PVT.[Central nervous system infection] IS NOT NULL THEN '8' END AS [central_nervos_system_infection],
CASE WHEN SSOI_PVT.[Fungal infection] IS NOT NULL THEN '3' END AS [fungal_infection],
CASE WHEN SSOI_PVT.[Gastrointestinal infection] IS NOT NULL THEN '9' END AS [gastrointestinal_infection],
CASE WHEN SSOI_PVT.[Genitourinary infectio] IS NOT NULL THEN '10' END AS [genitourinary_infection],
CASE WHEN SSOI_PVT.[Heart infection] IS NOT NULL THEN '5' END AS [heart_infection],
CASE WHEN SSOI_PVT.[Lung infection] IS NOT NULL THEN '7' END AS [lung_infection],
CASE WHEN SSOI_PVT.[Other infection] IS NOT NULL THEN '12' END AS [other_infection],
CASE WHEN SSOI_PVT.[Peritoneal infection] IS NOT NULL THEN '4' END AS [peritoneal_infection],
CASE WHEN SSOI_PVT.[Septicemia] IS NOT NULL THEN '1' ELSE NULL END AS [septicemia],
CASE WHEN SSOI_PVT.[Soft tissue infection] IS NOT NULL THEN '11' END AS [soft_tissue_infection],
CASE WHEN SSOI_PVT.[Upper respiratory infection] IS NOT NULL THEN '6' END AS [upper_respiratory_infection],
CASE
	WHEN SSOI_PVT.[Bacteremia] IS NULL
		AND SSOI_PVT.[Central nervous system infection] IS NULL
		AND SSOI_PVT.[Fungal infection] IS NULL
		AND SSOI_PVT.[Gastrointestinal infection] IS NULL
		AND SSOI_PVT.[Genitourinary infectio] IS NULL
		AND SSOI_PVT.[Heart infection] IS NULL
		AND SSOI_PVT.[Lung infection] IS NULL
		AND SSOI_PVT.[Other infection] IS NULL
		AND SSOI_PVT.[Peritoneal infection] IS NULL
		AND SSOI_PVT.[Septicemia] IS NULL 
		AND SSOI_PVT.[Soft tissue infection] IS NULL 
		AND SSOI_PVT.[Upper respiratory infection] IS NULL
			THEN '13'
	ELSE NULL
	END AS [unknown]
FROM (
	SELECT pt_id,
		subcategory
	FROM #ssoi_tbl
) AS A
PIVOT(
	MAX(SUBCATEGORY)
	FOR SUBCATEGORY IN (
		"Bacteremia","Central nervous system infection","Fungal infection","Gastrointestinal infection",
		"Genitourinary infectio","Heart infection","Lung infection","Other infection","Peritoneal infection",
		"Septicemia","Soft tissue infection","Upper respiratory infection"
	)
) AS SSOI_PVT

DROP TABLE IF EXISTS #ssoi_pvt_tbl
CREATE TABLE #ssoi_pvt_tbl (
	pt_id VARCHAR(12),
	suspected_source_of_infection VARCHAR(100)
)

INSERT INTO #ssoi_pvt_tbl (
	pt_id,
	suspected_source_of_infection
	)
SELECT pt_id,
ssoi = STUFF(
      COALESCE(', ' + RTRIM(bacteremia), '') 
    + COALESCE(', ' + RTRIM(central_nervous_system_infection), '') 
    + COALESCE(', ' + RTRIM(fungal_infection), '')
	+ COALESCE(', ' + RTRIM(gastrointestinal_infection), '')
	+ COALESCE(', ' + RTRIM(genitourinary_infection), '')
	+ COALESCE(', ' + RTRIM(heart_infection), '')
	+ COALESCE(', ' + RTRIM(lung_infection), '')
	+ COALESCE(', ' + RTRIM(other_infection_source), '')
	+ COALESCE(', ' + RTRIM(peritoneal_infection), '')
	+ COALESCE(', ' + RTRIM(septicemia), '')
	+ COALESCE(', ' + RTRIM(soft_tissue_infection), '')
	+ COALESCE(', ' + RTRIM(upper_respiratory_infection), '')
	+ COALESCE(', ' + RTRIM(unknown), '')
    , 1, 2, '')
FROM #ssoi_pvt_temp_tbl

DROP TABLE IF EXISTS #ssoi_final_tbl
CREATE TABLE #ssoi_final_tbl (
	pt_id VARCHAR(12),
	suspected_source_of_infection VARCHAR(500)
	)

INSERT INTO #ssoi_final_tbl (pt_id, suspected_source_of_infection)
SELECT pt_id, 
REPLACE(suspected_source_of_infection, ', ', ':') AS [ssoi]
FROM #ssoi_pvt_tbl

-- Dialysis Treatment
DROP TABLE IF EXISTS #dialysis_treatment_tbl
CREATE TABLE #dialysis_treatment_tbl (
	pt_id VARCHAR(12),
	dialysis_treatment VARCHAR(10)
	)
INSERT INTO #dialysis_treatment_tbl (pt_id, dialysis_treatment)
SELECT A.pt_id,
	[dialysis_treatment] = CASE
		WHEN B.pcs_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.sproc AS a
INNER JOIN smsdss.c_nysdoh_sepsis_dialysis_treatment_code AS B ON REPLACE(A.proc_cd, '.','') = B.pcs_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- Dialysis Order
DROP TABLE IF EXISTS #dialysis_order_tbl
CREATE TABLE #dialysis_order_tbl (
	episode_no VARCHAR(12)
	)

INSERT INTO #dialysis_order_tbl (
	episode_no
	)
SELECT A.episode_no
FROM smsmir.mir_sr_ord AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE a.svc_cd IN ('05400023')-- may have other svc codes
GROUP BY A.episode_no
;

-- During Hospital Remdesivir
DROP TABLE IF EXISTS #during_hospital_remdesivir_tbl
CREATE TABLE #during_hospital_remdesivir_tbl (
	pt_id VARCHAR(12),
	during_hospital_remdesivir VARCHAR(10)
	)
INSERT INTO #during_hospital_remdesivir_tbl (pt_id, during_hospital_remdesivir)
SELECT A.pt_id,
	[during_hospital_remdesivir] = CASE
		WHEN B.pcs_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.sproc AS a
INNER JOIN smsdss.c_nysdoh_sepsis_during_hospital_remdesivir_code AS B ON REPLACE(A.proc_cd, '.','') = B.pcs_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- Remdesivir Order
DROP TABLE IF EXISTS #remdesivir_ord_tbl
CREATE TABLE #remdesivir_ord_tbl (
	episode_no VARCHAR(12)
)

INSERT INTO #remdesivir_ord_tbl (episode_no)
SELECT a.episode_no
FROM smsmir.mir_sr_ord AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.ptno_num
WHERE a.svc_cd IN ('P_3183','PRE_3183DayOne','PRE_3183Day2-10','R_179015')
GROUP BY a.episode_no

-- Ecmo
DROP TABLE IF EXISTS #ecmo_tbl
CREATE TABLE #ecmo_tbl (
	pt_id VARCHAR(12),
	ecmo VARCHAR(10)
	)
INSERT INTO #ecmo_tbl (pt_id, ecmo)
SELECT A.pt_id,
	[ecmo] = CASE
		WHEN B.pcs_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.sproc AS a
INNER JOIN smsdss.c_nysdoh_sepsis_ecmo_code AS B ON REPLACE(A.proc_cd, '.','') = B.pcs_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- Nasal Cannula
DROP TABLE IF EXISTS #nasal_cannula_tbl
CREATE TABLE #nasal_cannula_tbl (
	episode_no VARCHAR(12)
	)
INSERT INTO #nasal_cannula_tbl (episode_no)
--SELECT DISTINCT A.episode_no
--FROM smsmir.mir_sr_obsv_new AS A
--INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
--WHERE dsply_val = 'nasal cannula'
SELECT DISTINCT C.PatientAccountID
FROM smsmir.sc_Order as a
INNER JOIN smsmir.sc_OrderSuppInfo AS B ON A.OrderSuppInfo_oid = B.ObjectID
INNER JOIN smsmir.sc_PatientVisit AS C ON A.Patient_oid = C.Patient_oid
	AND A.PatientVisit_oid = C.StartingVisitOID
INNER JOIN #BasePopulation AS BP ON C.PatientAccountID = BP.PtNo_Num
WHERE A.OrderAbbreviation = 'RT_O2Tx'
AND B.Device = 'HIGH FLOW NASAL CANNULA'

-- Mechanical Vent Treatment
DROP TABLE IF EXISTS #mech_vent_treat_tbl
CREATE TABLE #mech_vent_treat_tbl (
	pt_id VARCHAR(12),
	mechanical_vent_treatment VARCHAR(10)
	)
INSERT INTO #mech_vent_treat_tbl (pt_id, mechanical_vent_treatment)
SELECT DISTINCT A.pt_id,
	[mechanical_vent_treatment] = CASE
		WHEN B.pcs_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.sproc AS a
INNER JOIN smsdss.c_nysdoh_sepsis_mechanical_vent_treatment_code AS B ON REPLACE(A.proc_cd, '.','') = B.pcs_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- Non-invasive Positive Pressure Ventilation
DROP TABLE IF EXISTS #nippv_tbl
CREATE TABLE #nippv_tbl (
	pt_id VARCHAR(12),
	non_invasive_pos_pressure_vent VARCHAR(10)
	)
INSERT INTO #nippv_tbl (pt_id, non_invasive_pos_pressure_vent)
SELECT DISTINCT A.pt_id,
	[non_invasive_pos_pressure_vent] = CASE
		WHEN B.pcs_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.sproc AS a
INNER JOIN smsdss.c_nysdoh_sepsis_non_invasive_pos_pressure_vent_code AS B ON REPLACE(A.proc_cd, '.','') = B.pcs_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- CV Outcomes at Discharge
DROP TABLE IF EXISTS #cv_outcome_dsch_tbl 
CREATE TABLE #cv_outcome_dsch_tbl (
	pt_id VARCHAR(12),
	cv_outcomes_at_discharge VARCHAR(10)
)
INSERT INTO #cv_outcome_dsch_tbl (pt_id, cv_outcomes_at_discharge)
SELECT A.pt_id,
	[cv_outcomes_at_discharge] = CASE
		WHEN B.subcategory = 'ACS'
			THEN '1'
		WHEN B.subcategory = 'ISCHEMIC STROKE'
			THEN '2'
		WHEN B.subcategory = 'MYOCARDITIS COVID'
			THEN '3'
		WHEN B.subcategory = 'Cardiomyopathy'
			THEN '4'
		ELSE '0'
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_cv_outcomes_at_discharge_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

DROP TABLE IF EXISTS #cv_outcome_dsch_pvt_tbl
CREATE TABLE #cv_outcome_dsch_pvt_tbl (
	pt_id VARCHAR(12),
	cv_outcomes_at_discharge VARCHAR(20)
)

INSERT INTO #cv_outcome_dsch_pvt_tbl (pt_id, cv_outcomes_at_discharge)
SELECT PVT.pt_id,
	[cv_outcomes_at_discharge] = REPLACE(STUFF(
		COALESCE(': ' + RTRIM(PVT.[0]), '')
		+ COALESCE(': ' + RTRIM(PVT.[1]), '')
		+ COALESCE(': ' + RTRIM(PVT.[2]), '')
		+ COALESCE(': ' + RTRIM(PVT.[3]), '')
		+ COALESCE(': ' + RTRIM(PVT.[4]), '')
	, 1, 2, ''), ': ', ':')
FROM #cv_outcome_dsch_tbl AS A
PIVOT(MAX(CV_OUTCOMES_AT_DISCHARGE) FOR CV_OUTCOMES_AT_DISCHARGE IN ("0","1","2","3","4")) AS PVT

-- CV Outcomes in hospital
DROP TABLE IF EXISTS #cv_outcome_hosp_tbl
CREATE TABLE #cv_outcome_hosp_tbl (
	pt_id VARCHAR(12),
	cv_outcomes_in_hospital VARCHAR(20)
)
INSERT INTO #cv_outcome_hosp_tbl (pt_id, cv_outcomes_in_hospital)
SELECT A.pt_id,
	[cv_outcomes_in_hospital] = CASE
		WHEN B.subcategory = 'ACS'
			THEN '1'
		WHEN B.subcategory = 'Cardiomyopathy'
			THEN '4'
		WHEN B.subcategory = 'ISCHEMIC STROKE'
			THEN '2'
		WHEN B.subcategory = 'MYOCARDITIS COVID'
			THEN '3'
		ELSE '0'
		END
FROM SMSMIR.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_cv_outcomes_in_hospital_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

DROP TABLE IF EXISTS #cv_outcome_hosp_pvt_tbl
CREATE TABLE #cv_outcome_hosp_pvt_tbl (
	pt_id VARCHAR(12),
	cv_outcomes_in_hospital VARCHAR(20)
)

INSERT INTO #cv_outcome_hosp_pvt_tbl (pt_id, cv_outcomes_in_hospital)
SELECT PVT.pt_id,
	[cv_outcomes_in_hospital] = REPLACE(STUFF(
		COALESCE(': ' + RTRIM(PVT.[0]), '')
		+ COALESCE(': ' + RTRIM(PVT.[1]), '')
		+ COALESCE(': ' + RTRIM(PVT.[2]), '')
		+ COALESCE(': ' + RTRIM(PVT.[3]), '')
		+ COALESCE(': ' + RTRIM(PVT.[4]), '')
	, 1, 2, ''), ': ', ':')
FROM #cv_outcome_hosp_tbl AS A
PIVOT(MAX(CV_OUTCOMES_IN_HOSPITAL) FOR CV_OUTCOMES_IN_HOSPITAL IN ("0","1","2","3","4")) AS PVT

-- Dialysis Outcome
DROP TABLE IF EXISTS #dialysis_outcome
CREATE TABLE #dialysis_outcome (
	pt_id VARCHAR(12),
	dialysis_treatment VARCHAR(10)
)

INSERT INTO #dialysis_outcome (pt_id, dialysis_treatment)
SELECT A.pt_id,
	[dialysis_outcome] = CASE
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_dialysis_outcome_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- Mechanical Vent Outcome
DROP TABLE IF EXISTS #mvo_tbl
CREATE TABLE #mvo_tbl (
	pt_id VARCHAR(12),
	mechanical_vent_outcome VARCHAR(10)
)

INSERT INTO #mvo_tbl (pt_id, mechanical_vent_outcome)
SELECT A.pt_id,
	[mechanical_vent_outcome] = CASE
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_mechanical_vent_outcome_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- Trach at Discharge
DROP TABLE IF EXISTS #trach_outcome_tbl
CREATE TABLE #trach_outcome_tbl (
	pt_id VARCHAR(12),
	tracheostomy_at_discharge VARCHAR(10)
)

INSERT INTO #trach_outcome_tbl (pt_id, tracheostomy_at_discharge)
SELECT A.pt_id,
	[tracheostomy_at_discharge] = CASE
		WHEN B.icd10_cm_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.dx_grp AS A
INNER JOIN smsdss.c_nysdoh_sepsis_tracheostomy_at_discharge_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

---- PE/DVT
--DROP TABLE IF EXISTS #pe_dvt_tbl
--CREATE TABLE #pe_dvt_tbl (
--	pt_id VARCHAR(12),
--	pe_dvt VARCHAR(12)
--)

--INSERT INTO #pe_dvt_tbl (pt_id, pe_dvt)
--SELECT DISTINCT A.pt_id,
--	[pe_dvt] = CASE
--		WHEN B.icd10_cm_code IS NULL
--			THEN 0
--		ELSE 1
--		END
--FROM smsmir.dx_grp AS A
--INNER JOIN smsdss.c_nysdoh_sepsis_pe_dvt_code AS B ON REPLACE(A.DX_CD, '.','') = B.icd10_cm_code
--INNER JOIN #BasePopulation AS BP ON A.pt_id = BP.Pt_No

-- Tracheostomy In Hospital
DROP TABLE IF EXISTS #trach_in_hosp_tbl
CREATE TABLE #trach_in_hosp_tbl (
	pt_id VARCHAR(12),
	tracheostomy_in_hospital VARCHAR(12)
)

INSERT INTO #trach_in_hosp_tbl (pt_id, tracheostomy_in_hospital)
SELECT DISTINCT A.pt_id,
	[pe_dvt] = CASE
		WHEN B.pcs_code IS NULL
			THEN 0
		ELSE 1
		END
FROM smsmir.sproc AS A
INNER JOIN smsdss.c_nysdoh_sepsis_tracheostomy_in_hospital_code AS B ON REPLACE(A.proc_cd, '.','') = B.pcs_code
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
WHERE obsv_cd = '00403154';

DELETE
FROM #appt
WHERE disp_val IN ('.','S','1/','R');

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
	ROUND(CAST(REPLACE(disp_val, CHAR(13), '') AS FLOAT), 1) AS [disp_val],
	coll_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY EPISODE_NO ORDER BY ROUND(CAST(REPLACE(DISP_VAL, CHAR(13),'') AS FLOAT), 1) DESC
		)
FROM #appt;

DELETE
FROM #max_appt
WHERE RN != 1;

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
		ROUND(CAST(REPLACE(disp_val, CHAR(13), '') AS FLOAT), 1) AS [disp_val],
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
	AND bp_diastolic NOT IN ('Patient refused', 'Refused', 'refused v/s', 'unknown','','0','palp')
	AND bp_systolic != '0'
	AND A.collected_datetime IS NOT NULL

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
	coalesce(a.perf_dtime, a.sort_dtime)
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
	WHERE bp_diastolic != ''
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
WHERE A.obsv_cd = '2012';

DELETE
FROM #inr
WHERE (
	RTRIM(LTRIM(disp_val)) IN ('.D', '.','U','S','12/','02/','. ')
	OR REPLACE(disp_val, CHAR(13), '') = '.'
	OR disp_val IS NULL
);

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
	ROUND(CAST(REPLACE(disp_val, CHAR(13), '') AS FLOAT), 1) AS [disp_val],
	coll_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY ROUND(CAST(REPLACE(disp_val, CHAR(13), '') AS FLOAT), 1) DESC
		)
FROM #inr;

DELETE
FROM #max_inr
WHERE rn != 1;

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
		ROUND(CAST(REPLACE(disp_val, CHAR(13), '') AS FLOAT), 1) AS [disp_val],
		coll_dtime,
		lab_number,
		lab_number2 = '0' + CAST(lab_number AS VARCHAR)
	FROM #inr
	WHERE lab_number <= 3
	) AS A
PIVOT(MAX(disp_val) FOR LAB_NUMBER IN ("1", "2", "3")) AS PVT_INR
PIVOT(MAX(coll_dtime) FOR LAB_NUMBER2 IN ("01", "02", "03")) AS PVT_COLL_DTIME
GROUP BY episode_no;


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
	AND CONCAT(RTRIM(LTRIM(A.def_type_ind)), RTRIM(LTRIM(A.val_sts_cd))) != 'TXC';

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
	ROUND(CAST(REPLACE(disp_val, CHAR(13), '') AS FLOAT), 1) AS [disp_val],
	coll_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY ROUND(CAST(REPLACE(disp_val, CHAR(13), '') AS FLOAT), 1) DESC
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
		ROUND(CAST(REPLACE(disp_val, CHAR(13), '') AS FLOAT), 1) AS [disp_val],
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
	AND CONCAT(RTRIM(LTRIM(A.def_type_ind)), RTRIM(LTRIM(A.val_sts_cd))) != 'TXC';

DELETE
FROM #od_bilirubin
WHERE disp_val = 'R';

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
	ROUND(CAST(REPLACE(disp_val, CHAR(13), '') AS FLOAT), 1) AS [disp_val],
	coll_dtime
FROM #od_bilirubin
WHERE lab_number = 1;

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
	ROUND(CAST(REPLACE(disp_val, CHAR(13), '') AS FLOAT), 1) AS [disp_val],
	coll_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY ROUND(CAST(REPLACE(disp_val, CHAR(13), '') AS FLOAT), 1) DESC
		)
FROM #od_bilirubin;

DELETE
FROM #max_bilirubin
WHERE RN != 1;


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
	AND CONCAT(RTRIM(LTRIM(A.def_type_ind)), RTRIM(LTRIM(A.val_sts_cd))) != 'TXC';

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
	--AND CONCAT(RTRIM(LTRIM(A.def_type_ind)), RTRIM(LTRIM(A.val_sts_cd))) != 'TXC'
	AND A.def_type_ind != 'TX';

DELETE
FROM #platelets
WHERE disp_val IN ('.','. ')

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
--WHERE disp_val NOT IN ('.','. ')

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
	AND LEN(A.heart_rate) <= 3
	AND A.collected_datetime IS NOT NULL

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
	coalesce(a.perf_dtime, a.sort_dtime)
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
	REPLACE(a.sirs_heartrate, '.',''),
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
		PARTITION BY episode_no ORDER BY CAST(sirs_heartrate AS INT) DESC
		)
FROM #sirs_hr
WHERE LEN(sirs_heartrate) <= 3

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
	AND CONCAT(RTRIM(LTRIM(A.def_type_ind)), RTRIM(LTRIM(A.val_sts_cd))) != 'TXC';

DELETE
FROM #wbc
WHERE disp_val IN ('. ', 'S','R','d','11P');

DROP TABLE IF EXISTS #arr_wbc
CREATE TABLE #arr_wbc (
	episode_no VARCHAR(12),
	sirs_leukocyte_arrival VARCHAR(200),
	sirs_leukocyte_arrival_dt DATETIME,
	rn INT
	)

INSERT INTO #arr_wbc (
	episode_no,
	sirs_leukocyte_arrival,
	sirs_leukocyte_arrival_dt,
	rn
	)
SELECT episode_no,
	CAST(REPLACE(disp_val, CHAR(13), '') AS float) * 1000,
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
	sirs_leukocyte_min VARCHAR(200),
	sirs_leukocyte_min_dt DATETIME,
	rn INT
	)

INSERT INTO #min_wbc (
	episode_no,
	sirs_leukocyte_min,
	sirs_leukocyte_min_dt,
	rn
	)
SELECT episode_no,
	CAST(REPLACE(disp_val, CHAR(13), '') AS float) * 1000,
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
	sirs_leukocyte_max VARCHAR(20),
	sirs_leukocyte_max_dt DATETIME,
	rn INT
	)

INSERT INTO #max_wbc (
	episode_no,
	sirs_leukocyte_max,
	sirs_leukocyte_max_dt,
	rn
	)
SELECT episode_no,
	CAST(REPLACE(disp_val, CHAR(13), '') AS float) * 1000,
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
	AND LEN(A.respiratory_rate) <= 2
	AND A.collected_datetime IS NOT NULL

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
	coalesce(a.perf_dtime, a.sort_dtime)
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
WHERE LEN(sirs_respiratoryrate) <= 2

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
	sirs_temperature VARCHAR(100),
	coll_dtime DATETIME
	)

INSERT INTO #ws_temp
SELECT A.account,
	REPLACE(REPLACE(a.TEMP, ' oral', ''), ' rectal', '') AS [TEMP],
	a.collected_datetime
FROM SMSDSS.c_sepsis_ws_vitals_tbl AS A
INNER JOIN #BasePopulation AS BP ON A.account = BP.PtNo_Num
WHERE A.TEMP IS NOT NULL
	AND A.collected_datetime IS NOT NULL
	AND A.TEMP NOT IN ('*** DELETE ***', '.', '<90.0', '100 . 0', '33.1ºC', '33.3ºC', '33.7ºC', '34.6 C', '34.6ºC', '35.0ºC', '35.6C', '36.8 C', 'patient refused', 'Pt left', 'pt refused temp', 'ref vs', 'refudes', 'refused', 'refused oral temp', 'refused temp', 'Unable to assess','31.0 C')

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
	coalesce(a.perf_dtime, a.sort_dtime)
FROM smsmir.mir_sr_obsv_new AS A
INNER JOIN #BasePopulation AS BP ON A.episode_no = BP.PtNo_Num
WHERE A.obsv_cd = 'A_Temperature'
	--AND A.def_type_ind != 'TX'
	--AND A.val_sts_cd != 'C'

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

DELETE
FROM #sirs_temp
WHERE (
	RIGHT(sirs_temperature, 1) = 'C'
	OR sirs_temperature IN (
			'9836.0000','982.0000','976.0000','968.0000','uto','venti-mask',
			'pt refused','93.5rectal','88.0F','87.8 F','bvm'

		)
	OR cast(sirs_temperature as float) > '110.0'
	)

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
	ROUND(CAST(REPLACE(sirs_temperature, CHAR(13),'') AS FLOAT), 1) AS [sirs_temperature],
	obsv_dtime,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY episode_no ORDER BY ROUND(CAST(REPLACE(sirs_temperature, CHAR(13),'') AS FLOAT), 1) DESC
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
		ROUND(CAST(REPLACE(sirs_temperature, CHAR(13), '') AS FLOAT), 1) AS [sirs_temperature],
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
	AND bp_diastolic != '0'
	AND bp_systolic != '0'
	AND A.collected_datetime IS NOT NULL

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
	coalesce(a.perf_dtime, a.sort_dtime)
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
		REPLACE(bp_systolic, '.','') AS [bp_systolic],
		collected_datetime
	FROM #ws_systolic
	
	UNION
	
	SELECT episode_no,
		REPLACE(bp_systolic, '.','') AS [bp_systolic],
		obsv_cre_dtime
	FROM #sr_systolic
	) AS A

DELETE
FROM #bp_systolic
WHERE LEN(bp_systolic) > 3;

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
SELECT 	[facility_identifier] = '0885',
	[unique_personal_identifier] = CAST(LEFT(pav.Pt_Name, 2) AS VARCHAR) 
		+ CAST(RIGHT(LTRIM(RTRIM(SUBSTRING(PAV.PT_NAME, 1, CHARINDEX(' ,', PAV.PT_NAME, 1)))), 2) AS VARCHAR) 
		+ LEFT(LTRIM(RTRIM(REVERSE(SUBSTRING(REVERSE(pav.pt_name), 1, CHARINDEX(',', REVERSE(PAV.PT_NAME), 1) - 1)))), 2) 
		+ REPLACE(CAST(LTRIM(RTRIM(RIGHT(PAV.Pt_SSA_No, 4))) AS VARCHAR), '9???','0000'),
	[admission_dt] = CONVERT(CHAR(10), PV.VisitStartDateTime, 126) + ' ' + CONVERT(CHAR(5), PV.VisitStartDateTime, 108),
	[arrival_dt] = CONVERT(CHAR(10), PV.PresentingDateTime, 126) + ' ' + CONVERT(CHAR(5), PV.PresentingDateTime, 108),
	[date_of_birth] = CONVERT(CHAR(10), PAV.Pt_Birthdate, 126),
	[discharge_dt] = CONVERT(CHAR(10), PV.VisitEndDateTime, 126) + ' ' + CONVERT(CHAR(5), PV.VisitEndDateTime, 108),
	-- death dtime test
	DEATH.PatientDeathDateTime,
	-- end test
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
	[gender] = CASE 
		WHEN PAV.Pt_Sex IN ('M', 'F')
			THEN PAV.Pt_Sex
		ELSE 'U'
		END,
	[icd_10_cm_code_1] = DX_CDS.[01],
	[icd_10_cm_poa_indicator_1] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[01] IS NOT NULL
			AND DX_POA.[01] != ' '
			THEN 'U'
		ELSE DX_POA.[01]
		END,
	[icd_10_cm_code_2] = DX_CDS.[02],
	[icd_10_cm_poa_indicator_2] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[02] IS NOT NULL
			AND DX_POA.[02] != ' ' 
			THEN 'U'
		ELSE DX_POA.[02]
		END,
	[icd_10_cm_code_3] = DX_CDS.[03],
	[icd_10_cm_poa_indicator_3] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[03] IS NOT NULL
			AND DX_POA.[03] != ' '
			THEN 'U'
		ELSE DX_POA.[03]
		END,
	[icd_10_cm_code_4] = DX_CDS.[04],
	[icd_10_cm_poa_indicator_4] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[04] IS NOT NULL
			AND DX_POA.[04] != ' '
			THEN 'U'
		ELSE DX_POA.[04]
		END,

	[icd_10_cm_code_5] = DX_CDS.[05],
	[icd_10_cm_poa_indicator_5] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[05] IS NOT NULL
			AND DX_POA.[05] != ' '
			THEN 'U'
		ELSE DX_POA.[05]
		END,
	[icd_10_cm_code_6] = DX_CDS.[06],
	[icd_10_cm_poa_indicator_6] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[06] IS NOT NULL
			AND DX_POA.[06] != ' '
			THEN 'U'
		ELSE DX_POA.[06]
		END,
	[icd_10_cm_code_7] = DX_CDS.[07],
	[icd_10_cm_poa_indicator_7] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[07] IS NOT NULL
			AND DX_POA.[07] != ' '
			THEN 'U'
		ELSE DX_POA.[07]
		END,
	[icd_10_cm_code_8] = DX_CDS.[08],
	[icd_10_cm_poa_indicator_8] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[08] IS NOT NULL
			AND DX_POA.[08] != ' '
			THEN 'U'
		ELSE DX_POA.[08]
		END,
	[icd_10_cm_code_9] = DX_CDS.[09],
	[icd_10_cm_poa_indicator_9] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[09] IS NOT NULL
			AND DX_POA.[09] != ' '
			THEN 'U'
		ELSE DX_POA.[09]
		END,
	[icd_10_cm_code_10] = DX_CDS.[10],
	[icd_10_cm_poa_indicator_10] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[10] IS NOT NULL
			AND DX_POA.[10] != ' '
			THEN 'U'
		ELSE DX_POA.[10]
		END,
	[icd_10_cm_code_11] = DX_CDS.[11],
	[icd_10_cm_poa_indicator_11] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[11] IS NOT NULL
			AND DX_POA.[11] != ' '
			THEN 'U'
		ELSE DX_POA.[11]
		END,
	[icd_10_cm_code_12] = DX_CDS.[12],
	[icd_10_cm_poa_indicator_12] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[12] IS NOT NULL
			AND DX_POA.[12] != ' '
			THEN 'U'
		ELSE DX_POA.[12]
		END,
	[icd_10_cm_code_13] = DX_CDS.[13],
	[icd_10_cm_poa_indicator_13] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[13] IS NOT NULL
			AND DX_POA.[13] != ' '
			THEN 'U'
		ELSE DX_POA.[13]
		END,
	[icd_10_cm_code_14] = DX_CDS.[14],
	[icd_10_cm_poa_indicator_14] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[14] IS NOT NULL
			AND DX_POA.[14] != ' '
			THEN 'U'
		ELSE DX_POA.[14]
		END,
	[icd_10_cm_code_15] = DX_CDS.[15],
	[icd_10_cm_poa_indicator_15] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[15] IS NOT NULL
			AND DX_POA.[15] != ' '
			THEN 'U'
		ELSE DX_POA.[15]
		END,
	[icd_10_cm_code_16] = DX_CDS.[16],
	[icd_10_cm_poa_indicator_16] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[16] IS NOT NULL
			AND DX_POA.[16] != ' '
			THEN 'U'
		ELSE DX_POA.[16]
		END,
	[icd_10_cm_code_17] = DX_CDS.[17],
	[icd_10_cm_poa_indicator_17] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[17] IS NOT NULL
			AND DX_POA.[17] != ' '
			THEN 'U'
		ELSE DX_POA.[17]
		END,
	[icd_10_cm_code_18] = DX_CDS.[18],
	[icd_10_cm_poa_indicator_18] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[18] IS NOT NULL
			AND DX_POA.[18] != ' '
			THEN 'U'
		ELSE DX_POA.[18]
		END,
	[icd_10_cm_code_19] = DX_CDS.[19],
	[icd_10_cm_poa_indicator_19] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[19] IS NOT NULL
			AND DX_POA.[19] != ' '
			THEN 'U'
		ELSE DX_POA.[19]
		END,
	[icd_10_cm_code_20] = DX_CDS.[20],
	[icd_10_cm_poa_indicator_20] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[20] IS NOT NULL
			AND DX_POA.[20] != ' '
			THEN 'U'
		ELSE DX_POA.[20]
		END,
	[icd_10_cm_code_21] = DX_CDS.[21],
	[icd_10_cm_poa_indicator_21] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[21] IS NOT NULL
			AND DX_POA.[21] != ' '
			THEN 'U'
		ELSE DX_POA.[21]
		END,
	[icd_10_cm_code_22] = DX_CDS.[22],
	[icd_10_cm_poa_indicator_22] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[22] IS NOT NULL
			AND DX_POA.[22] != ' '
			THEN 'U'
		ELSE DX_POA.[22]
		END,
	[icd_10_cm_code_23] = DX_CDS.[23],
	[icd_10_cm_poa_indicator_23] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[23] IS NOT NULL
			AND DX_POA.[23] != ' '
			THEN 'U'
		ELSE DX_POA.[23]
		END,
	[icd_10_cm_code_24] = DX_CDS.[24],
	[icd_10_cm_poa_indicator_24] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[24] IS NOT NULL
			AND DX_POA.[24] != ' '
			THEN 'U'
		ELSE DX_POA.[24]
		END,
	[icd_10_cm_code_25] = DX_CDS.[25],
	[icd_10_cm_poa_indicator_25] = CASE 
		WHEN LEFT(pv.PatientAccountID, 1) = '8'
			AND DX_POA.[25] IS NOT NULL
			AND DX_POA.[25] != ' '
			THEN 'U'
		ELSE DX_POA.[25]
		END,
    [inclusion_septic_shock] = bp.inclusion_septic_shock,
    [inclusion_severe_covid] = bp.inclusion_severe_covid,
    [inclusion_severe_sepsis] = bp.inclusion_severe_sepsis,
	[insurance_number] = CASE 
		WHEN LEFT(PYRPLAN.PYR_CD, 1) IN ('A', 'Z')
			THEN REPLACE(PYRPLAN.POL_NO, '-','')
		WHEN LEFT(PYRPLAN.pyr_cd, 1) IN ('B', 'E', 'I', 'J', 'K', 'X')
			THEN REPLACE(PYRPLAN.subscr_ins_grp_id, '-','')
		ELSE REPLACE(RTRIM(LTRIM(ISNULL(pol_no, ''))),'-','') + REPLACE(RTRIM(LTRIM(ISNULL(grp_no, ''))), '-', '')
		END,
	[medical_record_number] = pav.Med_Rec_No,
	[payer] = Payer.PYR1,
	[other_payer] = CASE WHEN PAYER.PYR1 IN ('E','I') THEN PAYER.PYR2 ELSE NULL END,
	[payer_2] = Payer.Pyr2,
	[other_payer_2] = CASE WHEN PAYER.PYR2 IN ('E','I') THEN PAYER.PYR3 ELSE NULL END,
	[payer_3] = PAYER.Pyr3,
	[other_payer_3] = NULL,
	[patient_control_number] = pv.PatientAccountID,
    [pat_addr_city] = ADDR.pat_addr_city,
    [pat_addr_cnty_cd] = ADDR.pat_addr_cnty_cd,
    [pat_addr_line1] = ADDR.pat_addr_line1,
    [pat_addr_line2] = ADDR.pat_addr_line2,
    [pat_addr_st] = ADDR.pat_addr_st,
	[patient_zip_code_of_residence] = CAST(PAV.Pt_Zip_Cd AS VARCHAR) + '-' + '0000',
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
	[acute_cardiovascular_conditions_poa] = ISNULL(ACC_TBL.acute_cardiovascular_conditions, 0),
	[aids_hiv_disease] = CASE 
		WHEN AIDS_HIV_TBL.pt_id IS NULL
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
	[chronic_kidney_disease] = CASE 
		WHEN CRF.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[chronic_respiratory_failure] = CASE 
		WHEN CRESPF.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[coagulopathy_poa] = CASE 
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
	[dialysis_comorbidity_poa] = CASE 
		WHEN DIALYSIS_COMORBID.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[history_of_covid] = CASE 
		WHEN COVID_HIST.pt_id IS NULL
			THEN 0
		ELSE COVID_HIST.history_of_covid
		END,
	[history_of_covid_dt] = CASE 
		WHEN COVID_HIST.PT_ID IS NULL
			THEN NULL
		WHEN COVID_HIST.history_of_covid = 0
			THEN NULL
		ELSE CONVERT(CHAR(10), COVID_HIST.history_of_covid_dt, 126) + ' ' + CONVERT(CHAR(5), COVID_HIST.history_of_covid_dt, 108)
		END,
	[history_of_other_cvd] = CASE 
		WHEN HX_OTH_CVD.history_of_other_cvd IS NULL
			THEN '0'
		ELSE HX_OTH_CVD.history_of_other_cvd
		END,
	[hypertension] = CASE 
		WHEN HYPERTENSION.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[immunocompromising] = CASE 
		WHEN IMMUNO.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[lymphoma_leukemia_multi_myeloma] = CASE 
		WHEN LLML.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[mechanical_vent_comorbidity_poa] = CASE 
		WHEN VENTS.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	--[medication_anticoagulation_poa] = CASE 
	--	WHEN HML_MED_ANTICOAG.episode_no IS NULL
	--		THEN 0
	--	ELSE 1
	--	END,
	[medication_immune_modifying_pre_hospital] = CASE 
		WHEN HML_IMM_MOD.episode_no IS NULL
			THEN 0
		ELSE 1
		END,
	[metastatic_cancer] = CASE 
		WHEN METASTATIC_CX.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[obesity] = CASE 
		WHEN OBESITY.pt_id IS NULL
			AND BMI_TBL.episode_no IS NULL
			THEN 0
		ELSE 1
		END,
	[patient_care_considerations] = CASE 
		WHEN DNR_DNI.patient_care_considerations IS NULL
			THEN '0'
		ELSE DNR_DNI.patient_care_considerations
		END,
	[patient_care_considerations_date] = CASE 
		WHEN DNR_DNI.patient_care_considerations IS NULL
			THEN NULL
		ELSE DNR_DNI_DATE.patient_care_considerations_date
		END,
	[pregnancy_comorbidity] = CASE 
		WHEN PREG_COMORBID.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[pregnancy_status] = CASE 
		WHEN PREG_STATUS.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[skin_disorders_burns] = CASE
		WHEN SKIN.skin_disorders_burns IS NULL
			THEN 0
		ELSE 1
		END,
	[smoking_vaping] = CASE 
		WHEN SMOKING_VAPING.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[tracheostomy_on_arrival_poa] = CASE 
		WHEN TRACH_ARR.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[covid_exposure] = CASE 
		WHEN CV_EXPOSURE.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[covid_virus] = CASE 
		WHEN CV_VIRUS.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[drug_resistant_pathogen] = CASE 
		WHEN DRP_TBL.PT_ID IS NULL
			THEN 0
		ELSE 1
		END,
	[flu_positive] = CASE 
		WHEN FLU_POS.pt_id IS NULL
			AND FLU_TBL.episode_no IS NULL
			THEN 0
		ELSE 1
		END,
	[suspected_source_of_infection] = CASE 
		WHEN SSOI.suspected_source_of_infection IS NULL
			THEN '13'
		ELSE SSOI.suspected_source_of_infection
		END,
	[dialysis_treatment] = CASE 
		WHEN DIA_TREAT.pt_id IS NULL
			AND DIA_ORD.EPISODE_NO IS NULL
			THEN 0
		ELSE 1
		END,
	--[during_hospital_anticoagulation] = CASE 
	--	WHEN MED_ANTICOAG.episode_no IS NULL
	--		THEN 0
	--	ELSE 1
	--	END,
	[during_hospital_immune_mod_med] = CASE 
		WHEN MED_IMM_MOD.episode_no IS NULL
			THEN 0
		ELSE 1
		END,
	[during_hospital_remdesivir] = CASE 
		WHEN DH_REMDESIVIR.pt_id IS NULL
			AND REMDESIVIR_ORD.EPISODE_NO IS NULL
			THEN 0
		ELSE 1
		END,
	[ecmo] = CASE 
		WHEN ECMO_TBL.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[high_flow_nasal_cannula] = CASE 
		WHEN NASAL_CANNULA.episode_no IS NULL
			THEN 0
		ELSE 1
		END,
	[mechanical_vent_treatment] = CASE 
		WHEN MVT_TBL.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[non_invasive_pos_pressure_vent] = CASE 
		WHEN NIPPV_TBL.pt_id IS NULL
			THEN 0		ELSE 1
		END,
	[vasopressor_administration] = CASE 
		WHEN MED_VASO.episode_no IS NULL
			THEN 0
		ELSE 1
		END,
	--[cv_outcomes_at_discharge] = CASE 
	--	WHEN CV_OUT_DSCH.pt_id IS NULL
	--		THEN 0
	--	ELSE 1
	--	END,
	[dialysis_outcome] = CASE 
		WHEN DO.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[mechanical_vent_outcome] = CASE 
		WHEN MVO_TBL.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[tracheostomy_at_discharge] = CASE 
		WHEN TRACH_OUT.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[cv_outcomes_in_hospital] = CASE 
		WHEN CV_IN_HOSP.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[icu_during_hospitalization] = CASE 
		WHEN (
				SELECT DISTINCT ICU_FLAG.episode_no
				FROM smsmir.mir_cen_hist AS ICU_FLAG
				WHERE ICU_FLAG.pt_type = 'I'
					AND ICU_FLAG.episode_no = BP.PtNo_Num
					AND ICU_FLAG.unit_seq_no = BP.unit_seq_no
				) IS NULL
			THEN 0
		ELSE 1
		END,
	--[pe_dvt] = CASE 
	--	WHEN PEDVT_TBL.pt_id IS NULL
	--		THEN 0
	--	ELSE 1
	--	END,
	[tracheostomy_in_hospital] = CASE 
		WHEN TRACH_IN.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	CASE 
		WHEN SUBSTRING(RIGHT(APPT_PVT.appt_1, 2), 1, 1) = '.'
			THEN APPT_PVT.appt_1
		ELSE APPT_PVT.appt_1 + '.0'
		END AS [aptt_1],
	CASE 
		WHEN SUBSTRING(RIGHT(APPT_PVT.appt_2, 2), 1, 1) = '.'
			THEN APPT_PVT.appt_2
		ELSE APPT_PVT.appt_2 + '.0'
		END AS [aptt_2],
	CASE 
		WHEN SUBSTRING(RIGHT(APPT_PVT.appt_3, 2), 1, 1) = '.'
			THEN APPT_PVT.appt_3
		ELSE APPT_PVT.appt_3 + '.0'
		END AS [aptt_3],
	CASE 
		WHEN SUBSTRING(RIGHT(MAX_APPT.appt_max, 2), 1, 1) = '.'
			THEN MAX_APPT.appt_max
		ELSE MAX_APPT.appt_max + '.0'
		END AS [aptt_max],
	CONVERT(CHAR(10), APPT_PVT.appt_dt_1, 126) + ' ' + CONVERT(CHAR(5), APPT_PVT.appt_dt_1, 108) AS aptt_dt_1,
	CONVERT(CHAR(10), APPT_PVT.appt_dt_2, 126) + ' ' + CONVERT(CHAR(5), APPT_PVT.appt_dt_2, 108) AS aptt_dt_2,
	CONVERT(CHAR(10), APPT_PVT.appt_dt_3, 126) + ' ' + CONVERT(CHAR(5), APPT_PVT.appt_dt_3, 108) AS aptt_dt_3,
	CONVERT(CHAR(10), MAX_APPT.appt_dt_max, 126) + ' ' + CONVERT(CHAR(5), MAX_APPT.appt_dt_max, 108) AS aptt_dt_max,
	CASE 
		WHEN SUBSTRING(RIGHT(ARR_BILIRUBIN.organ_dysfunc_hepatic_arrival, 2), 1, 1) = '.'
			THEN ARR_BILIRUBIN.organ_dysfunc_hepatic_arrival
		ELSE ARR_BILIRUBIN.organ_dysfunc_hepatic_arrival + '.0'
		END AS [bilirubin_arrival],
	CASE 
		WHEN SUBSTRING(RIGHT(MAX_BILIRUBIN.organ_dysfunc_hepatic_max, 2), 1, 1) = '.'
			THEN MAX_BILIRUBIN.organ_dysfunc_hepatic_max
		ELSE MAX_BILIRUBIN.organ_dysfunc_hepatic_max + '.0'
		END AS [bilirubin_max],
	CONVERT(CHAR(10), ARR_BILIRUBIN.organ_dysfunc_hepatic_arrival_dt, 126) + ' ' + CONVERT(CHAR(5), ARR_BILIRUBIN.organ_dysfunc_hepatic_arrival_dt, 108) AS bilirubin_arrival_dt,
	CONVERT(CHAR(10), MAX_BILIRUBIN.organ_dysfunc_hepatic_max_dt, 126) + ' ' + CONVERT(CHAR(5), MAX_BILIRUBIN.organ_dysfunc_hepatic_max_dt, 108) AS bilirubin_max_dt,
	ARR_CREATININE.organ_dysfunc_renal_arrival AS [creatinine_arrival],
	MAX_CREATININE.organ_dysfunc_renal_max AS [creatinine_max],
	CONVERT(CHAR(10), ARR_CREATININE.organ_dysfunc_renal_arrival_dt, 126) + ' ' + CONVERT(CHAR(5), ARR_CREATININE.organ_dysfunc_renal_arrival_dt, 108) AS creatinine_arrival_dt,
	CONVERT(CHAR(10), MAX_CREATININE.organ_dysfunc_renal_max_dt, 126) + ' ' + CONVERT(CHAR(5), MAX_CREATININE.organ_dysfunc_renal_max_dt, 108) AS creatinine_max_dt,
	WS_BPD_PVT.diastolic_1,
	WS_BPD_PVT.diastolic_2,
	WS_BPD_PVT.diastolic_3,
	WS_MIN_BPD.diastolic_min,
	CONVERT(CHAR(10), WS_BPD_PVT.diastolic_dt_1, 126) + ' ' + CONVERT(CHAR(5), WS_BPD_PVT.diastolic_dt_1, 108) AS diastolic_dt_1,
	CONVERT(CHAR(10), WS_BPD_PVT.diastolic_dt_2, 126) + ' ' + CONVERT(CHAR(5), WS_BPD_PVT.diastolic_dt_2, 108) AS diastolic_dt_2,
	CONVERT(CHAR(10), WS_BPD_PVT.diastolic_dt_3, 126) + ' ' + CONVERT(CHAR(5), WS_BPD_PVT.diastolic_dt_3, 108) AS diastolic_dt_3,
	CONVERT(CHAR(10), WS_MIN_BPD.diastolic_dt_min, 126) + ' ' + CONVERT(CHAR(5), WS_MIN_BPD.diastolic_dt_min, 108) AS diastolic_dt_min,
	CASE 
		WHEN SUBSTRING(RIGHT(INR_PVT.inr_1, 2), 1, 1) = '.'
			THEN INR_PVT.inr_1
		ELSE INR_PVT.inr_1 + '.0'
		END AS [inr_1],
	CASE 
		WHEN SUBSTRING(RIGHT(INR_PVT.inr_2, 2), 1, 1) = '.'
			THEN INR_PVT.inr_2
		ELSE INR_PVT.inr_2 + '.0'
		END AS [inr_2],
	CASE 
		WHEN SUBSTRING(RIGHT(INR_PVT.inr_3, 2), 1, 1) = '.'
			THEN INR_PVT.inr_3
		ELSE INR_PVT.inr_3 + '.0'
		END AS [inr_3],
	CASE 
		WHEN SUBSTRING(RIGHT(MAX_INR.inr_max, 2), 1, 1) = '.'
			THEN MAX_INR.inr_max
		ELSE MAX_INR.inr_max + '.0'
		END AS [inr_max],
	CONVERT(CHAR(10), INR_PVT.inr_dt_1, 126) + ' ' + CONVERT(CHAR(5), INR_PVT.inr_dt_1, 108) AS inr_dt_1,
	CONVERT(CHAR(10), INR_PVT.inr_dt_2, 126) + ' ' + CONVERT(CHAR(5), INR_PVT.inr_dt_2, 108) AS inr_dt_2,
	CONVERT(CHAR(10), INR_PVT.inr_dt_3, 126) + ' ' + CONVERT(CHAR(5), INR_PVT.inr_dt_3, 108) AS inr_dt_3,
	CONVERT(CHAR(10), MAX_INR.inr_dt_max, 126) + ' ' + CONVERT(CHAR(5), MAX_INR.inr_dt_max, 108) AS inr_dt_max,
	CASE 
		WHEN SUBSTRING(RIGHT(LACTATE_PVT.lactate_level_1, 2), 1, 1) = '.'
			THEN LACTATE_PVT.lactate_level_1
		ELSE LACTATE_PVT.lactate_level_1 + '.0'
		END AS [lactate_level_1],
	CASE 
		WHEN SUBSTRING(RIGHT(LACTATE_PVT.lactate_level_2, 2), 1, 1) = '.'
			THEN LACTATE_PVT.lactate_level_2
		ELSE LACTATE_PVT.lactate_level_2 + '.0'
		END AS [lactate_level_2],
	CASE 
		WHEN SUBSTRING(RIGHT(LACTATE_PVT.lactate_level_3, 2), 1, 1) = '.'
			THEN LACTATE_PVT.lactate_level_3
		ELSE LACTATE_PVT.lactate_level_3 + '.0'
		END AS [lactate_level_3],
	CASE 
		WHEN SUBSTRING(RIGHT(MAX_LACTATE.lactate_level_max, 2), 1, 1) = '.'
			THEN MAX_LACTATE.lactate_level_max
		ELSE MAX_LACTATE.lactate_level_max + '.0'
		END AS [lactate_level_max],
	CONVERT(CHAR(10), LACTATE_PVT.lactate_level_dt_1, 126) + ' ' + CONVERT(CHAR(5), LACTATE_PVT.lactate_level_dt_1, 108) AS lactate_level_dt_1,
	CONVERT(CHAR(10), LACTATE_PVT.lactate_level_dt_2, 126) + ' ' + CONVERT(CHAR(5), LACTATE_PVT.lactate_level_dt_2, 108) AS lactate_level_dt_2,
	CONVERT(CHAR(10), LACTATE_PVT.lactate_level_dt_3, 126) + ' ' + CONVERT(CHAR(5), LACTATE_PVT.lactate_level_dt_3, 108) AS lactate_level_dt_3,
	CONVERT(CHAR(10), MAX_LACTATE.lactate_level_dt_max, 126) + ' ' + CONVERT(CHAR(5), MAX_LACTATE.lactate_level_dt_max, 108) AS lactate_level_dt_max,
	[organ_dysfunc_cardiovascular] = CASE 
		WHEN OD_CARD.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[organ_dysfunc_cns] = CASE 
		WHEN OD_CNS.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[organ_dysfunc_hematologic] = CASE 
		WHEN OD_HEMA.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[organ_dysfunc_hepatic] = CASE 
		WHEN OD_HEPA.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[organ_dysfunc_renal] = CASE 
		WHEN OGD_RENAL.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	[organ_dysfunc_respiratory] = CASE 
		WHEN OD_RESP.pt_id IS NULL
			THEN 0
		ELSE 1
		END,
	CAST(ROUND(CAST(REPLACE(PLT_PVT.platelets_1, CHAR(13), '') AS FLOAT), 0) AS VARCHAR) + '000' AS [platelets_1],
	CAST(ROUND(CAST(REPLACE(PLT_PVT.platelets_2, CHAR(13), '') AS FLOAT), 0) AS VARCHAR) + '000' AS [platelets_2],
	CAST(ROUND(CAST(REPLACE(PLT_PVT.platelets_3, CHAR(13), '') AS FLOAT), 0) AS VARCHAR) + '000' AS [platelets_3],
	CAST(ROUND(CAST(REPLACE(MIN_PLT.platelets_min, CHAR(13), '') AS FLOAT), 0) AS VARCHAR) + '000' AS [platelets_min],
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
	--REPLACE(REPLACE(ARR_WBC.sirs_leukocyte_arrival, '.', ''), CHAR(13), '') + '0' AS [sirs_leukocyte_arrival],
	--REPLACE(REPLACE(MIN_WBC.sirs_leukocyte_min, '.', ''), CHAR(13), '') + '0' AS [sirs_leukocyte_min],
	--REPLACE(REPLACE(MAX_WBC.sirs_leukocyte_max, '.', ''), CHAR(13), '') + '0' AS [sirs_leukocyte_max],
	ARR_WBC.sirs_leukocyte_arrival,
	MIN_WBC.sirs_leukocyte_min,
	MAX_WBC.sirs_leukocyte_max,
	CONVERT(CHAR(10), ARR_WBC.sirs_leukocyte_arrival_dt, 126) + ' ' + CONVERT(CHAR(5), ARR_WBC.sirs_leukocyte_arrival_dt, 108) AS sirs_leukocyte_arrival_dt,
	CONVERT(CHAR(10), MIN_WBC.sirs_leukocyte_min_dt, 126) + ' ' + CONVERT(CHAR(5), MIN_WBC.sirs_leukocyte_min_dt, 108) AS sirs_leukocyte_min_dt,
	CONVERT(CHAR(10), MAX_WBC.sirs_leukocyte_max_dt, 126) + ' ' + CONVERT(CHAR(5), MAX_WBC.sirs_leukocyte_max_dt, 108) AS sirs_leukocyte_max_dt,
	SIRS_RESP_PVT.sirs_respiratoryrate_1,
	SIRS_RESP_PVT.sirs_respiratoryrate_2,
	SIRS_RESP_PVT.sirs_respiratoryrate_3,
	MAX_SIRS_RESP_RATE.sirs_respiratoryrate_max,
	CONVERT(CHAR(10), SIRS_RESP_PVT.sirs_respiratoryrate_dt_1, 126) + ' ' + CONVERT(CHAR(5), SIRS_RESP_PVT.sirs_respiratoryrate_dt_1, 108) AS sirs_respiratoryrate_dt_1,
	CONVERT(CHAR(10), SIRS_RESP_PVT.sirs_respiratoryrate_dt_2, 126) + ' ' + CONVERT(CHAR(5), SIRS_RESP_PVT.sirs_respiratoryrate_dt_2, 108) AS sirs_respiratoryrate_dt_2,
	CONVERT(CHAR(10), SIRS_RESP_PVT.sirs_respiratoryrate_dt_3, 126) + ' ' + CONVERT(CHAR(5), SIRS_RESP_PVT.sirs_respiratoryrate_dt_3, 108) AS sirs_respiratoryrate_dt_3,
	CONVERT(CHAR(10), MAX_SIRS_RESP_RATE.sirs_respiratoryrate_dt_max, 126) + ' ' + CONVERT(CHAR(5), MAX_SIRS_RESP_RATE.sirs_respiratoryrate_dt_max, 108) AS sirs_respiratoryrate_dt_max,
	CASE 
		WHEN SUBSTRING(RIGHT(SIRS_TEMP_PVT.sirs_temperature_1, 2), 1, 1) = '.'
			THEN SIRS_TEMP_PVT.sirs_temperature_1
		ELSE SIRS_TEMP_PVT.sirs_temperature_1 + '.0'
		END AS sirs_temperature_1,
	CASE 
		WHEN SUBSTRING(RIGHT(SIRS_TEMP_PVT.sirs_temperature_2, 2), 1, 1) = '.'
			THEN SIRS_TEMP_PVT.sirs_temperature_2
		ELSE SIRS_TEMP_PVT.sirs_temperature_2 + '.0'
		END AS sirs_temperature_2,
	CASE 
		WHEN SUBSTRING(RIGHT(SIRS_TEMP_PVT.sirs_temperature_3, 2), 1, 1) = '.'
			THEN SIRS_TEMP_PVT.sirs_temperature_3
		ELSE SIRS_TEMP_PVT.SIRS_TEMPERATURE_3 + '.0'
		END AS sirs_temperature_3,
	CASE 
		WHEN SUBSTRING(RIGHT(MAX_SIRS_TEMP.sirs_temperature_max, 2), 1, 1) = '.'
			THEN MAX_SIRS_TEMP.sirs_temperature_max
		ELSE MAX_SIRS_TEMP.sirs_temperature_max + '.0'
		END AS sirs_temperature_max,
	CONVERT(CHAR(10), SIRS_TEMP_PVT.sirs_temperature_dt_1, 126) + ' ' + CONVERT(CHAR(5), SIRS_TEMP_PVT.sirs_temperature_dt_1, 108) AS sirs_temperature_dt_1,
	CONVERT(CHAR(10), SIRS_TEMP_PVT.sirs_temperature_dt_2, 126) + ' ' + CONVERT(CHAR(5), SIRS_TEMP_PVT.sirs_temperature_dt_2, 108) AS sirs_temperature_dt_2,
	CONVERT(CHAR(10), SIRS_TEMP_PVT.sirs_temperature_dt_3, 126) + ' ' + CONVERT(CHAR(5), SIRS_TEMP_PVT.sirs_temperature_dt_3, 108) AS sirs_temperature_dt_3,
	CONVERT(CHAR(10), MAX_SIRS_TEMP.sirs_temperature_dt_max, 126) + ' ' + CONVERT(CHAR(5), MAX_SIRS_TEMP.sirs_temperature_dt_max, 108) AS sirs_temperature_dt_max,
	BP_SYS_PVT.systolic_1,
	BP_SYS_PVT.systolic_2,
	BP_SYS_PVT.systolic_3,
	MIN_SYS.systolic_min,
	CONVERT(CHAR(10), BP_SYS_PVT.systolic_dt_1, 126) + ' ' + CONVERT(CHAR(5), BP_SYS_PVT.systolic_dt_1, 108) AS systolic_dt_1,
	CONVERT(CHAR(10), BP_SYS_PVT.systolic_dt_2, 126) + ' ' + CONVERT(CHAR(5), BP_SYS_PVT.systolic_dt_2, 108) AS systolic_dt_2,
	CONVERT(CHAR(10), BP_SYS_PVT.systolic_dt_3, 126) + ' ' + CONVERT(CHAR(5), BP_SYS_PVT.systolic_dt_3, 108) AS systolic_dt_3,
	CONVERT(CHAR(10), MIN_SYS.systolic_dt_min, 126) + ' ' + CONVERT(CHAR(5), MIN_SYS.systolic_dt_min, 108) AS systolic_dt_min,
	[version] = 'd3.0',
	[quarter] = DATEPART(QUARTER, PV.VisitEndDateTime),
	[year] = DATEPART(YEAR, PV.VisitEndDateTime)
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
			[poa] = CASE 
				WHEN right(dx_cd_type, 1) = ''
					AND LEFT(pt_id, 5) != '00008'
					THEN '1'
				ELSE RIGHT(DX_CD_TYPE, 1)
				END
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
			WHEN PDVA.pyr_group2 IN ('MEDICARE A', 'MEDICARE B', 'MEDICARE HMO')
				THEN 'C'
			WHEN PDVA.PYR_GROUP2 IN ('MEDICAID', 'MEDICAID HMO')
				THEN 'D'
					--WHEN PDVA.pyr_group2 IN ('EXCHANGE PLANS')
					--	THEN 'E'
			WHEN PDVA.pyr_group2 IN ('COMMERCIAL', 'CONTRACTED SERVICES', 'HMO', 'EXCHANGE PLANS')
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
			WHEN PDVB.pyr_group2 IN ('MEDICARE A', 'MEDICARE B', 'MEDICARE HMO')
				THEN 'C'
			WHEN PDVB.PYR_GROUP2 IN ('MEDICAID', 'MEDICAID HMO')
				THEN 'D'
					--WHEN PDVB.pyr_group2 IN ('EXCHANGE PLANS')
					--	THEN 'E'
			WHEN PDVB.pyr_group2 IN ('COMMERCIAL', 'CONTRACTED SERVICES', 'HMO', 'EXCHANGE PLANS')
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
			WHEN PDVC.pyr_group2 IN ('MEDICARE A', 'MEDICARE B', 'MEDICARE HMO')
				THEN 'C'
			WHEN PDVC.PYR_GROUP2 IN ('MEDICAID', 'MEDICAID HMO')
				THEN 'D'
					--WHEN PDVC.pyr_group2 IN ('EXCHANGE PLANS')
					--	THEN 'E'
			WHEN PDVC.pyr_group2 IN ('COMMERCIAL', 'CONTRACTED SERVICES', 'HMO', 'EXCHANGE PLANS')
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
LEFT JOIN #immunocompromising AS IMMUNO ON PAV.PT_no = IMMUNO.pt_id
LEFT JOIN #llml_tbl AS LLML ON PAV.Pt_NO = LLML.pt_id
LEFT JOIN #vent_tbl AS VENTS ON PAV.Pt_No = VENTS.pt_id
LEFT JOIN #metastatic_cx_tbl AS METASTATIC_CX ON PAV.Pt_No = METASTATIC_CX.pt_id
LEFT JOIN #obesity_tbl AS OBESITY ON PAV.PT_NO = OBESITY.pt_id
LEFT JOIN #bmi_tbl AS BMI_TBL ON PAV.PtNo_Num = BMI_TBL.episode_no
LEFT JOIN #preg_comorbid_tbl AS PREG_COMORBID ON PAV.PT_NO = PREG_COMORBID.pt_id
LEFT JOIN #preg_status_tbl AS PREG_STATUS ON PAV.Pt_No = PREG_STATUS.pt_id
LEFT JOIN #smoking_vaping_tbl AS SMOKING_VAPING ON PAV.Pt_No = SMOKING_VAPING.pt_id
LEFT JOIN #trach_arrival_tbl AS TRACH_ARR ON PAV.Pt_No = TRACH_ARR.pt_id
LEFT JOIN #covid_exposure_tbl AS CV_EXPOSURE ON PAV.Pt_No = CV_EXPOSURE.pt_id
LEFT JOIN #covid_virus_tbl AS CV_VIRUS ON PAV.Pt_No = CV_VIRUS.pt_id
LEFT JOIN #drp_tbl AS DRP_TBL ON PAV.Pt_No = DRP_TBL.pt_id
LEFT JOIN #flu_pos_tbl AS FLU_POS ON PAV.Pt_No = FLU_POS.pt_id
LEFT JOIN #FLU_TBL AS FLU_TBL ON PAV.PtNo_Num = FLU_TBL.episode_no
LEFT JOIN #ssoi_final_tbl AS SSOI ON PAV.PT_NO = SSOI.pt_id
LEFT JOIN #dialysis_treatment_tbl AS DIA_TREAT ON PAV.Pt_No = DIA_TREAT.pt_id
LEFT JOIN #dialysis_order_tbl AS DIA_ORD ON PAV.PTNO_NUM = DIA_ORD.EPISODE_NO
LEFT JOIN #during_hospital_remdesivir_tbl AS DH_REMDESIVIR ON PAV.Pt_No = DH_REMDESIVIR.pt_id
LEFT JOIN #remdesivir_ord_tbl AS REMDESIVIR_ORD ON PAV.PTNO_NUM = REMDESIVIR_ORD.EPISODE_NO
LEFT JOIN #ecmo_tbl AS ECMO_TBL ON PAV.Pt_No = ECMO_TBL.pt_id
LEFT JOIN #nasal_cannula_tbl AS NASAL_CANNULA ON PAV.PtNo_Num = NASAL_CANNULA.episode_no
LEFT JOIN #mech_vent_treat_tbl AS MVT_TBL ON PAV.Pt_No = MVT_TBL.pt_id
LEFT JOIN #nippv_tbl AS NIPPV_TBL ON PAV.Pt_No = NIPPV_TBL.pt_id
LEFT JOIN #dialysis_outcome AS DO ON PAV.PT_NO = DO.pt_id
LEFT JOIN #mvo_tbl AS MVO_TBL ON PAV.Pt_No = MVO_TBL.pt_id
LEFT JOIN #trach_outcome_tbl AS TRACH_OUT ON PAV.PT_NO = TRACH_OUT.pt_id
LEFT JOIN #cv_outcome_dsch_pvt_tbl AS CV_OUT_DSCH ON PAV.Pt_No = CV_OUT_DSCH.pt_id
LEFT JOIN #cv_outcome_hosp_pvt_tbl AS CV_IN_HOSP ON PAV.Pt_No = CV_IN_HOSP.pt_id
--LEFT JOIN #pe_dvt_tbl AS PEDVT_TBL ON PAV.Pt_No = PEDVT_TBL.pt_id
LEFT JOIN #trach_in_hosp_tbl AS TRACH_IN ON PAV.Pt_No = TRACH_IN.pt_id
LEFT JOIN #dnr_dni_final_tbl AS DNR_DNI ON PAV.PtNo_Num = DNR_DNI.episode_no
LEFT JOIN #dnr_dni_date_tbl AS DNR_DNI_DATE ON PAV.PtNo_Num = DNR_DNI_DATE.episode_no
LEFT JOIN #od_cardiovascular AS OD_CARD ON PAV.Pt_No = OD_CARD.pt_id
LEFT JOIN #od_hematologic AS OD_HEMA ON PAV.PT_NO = OD_HEMA.pt_id
LEFT JOIN #od_hepatic AS OD_HEPA ON PAV.PT_NO = OD_HEPA.pt_id
LEFT JOIN #ogd_renal AS OGD_RENAL ON PAV.Pt_No = OGD_RENAL.pt_id
--LEFT JOIN #med_anticoag AS MED_ANTICOAG ON PAV.PtNo_Num = MED_ANTICOAG.episode_no
LEFT JOIN #med_imm_mod AS MED_IMM_MOD ON PAV.PtNo_Num = MED_IMM_MOD.episode_no
LEFT JOIN #med_vasopressor AS MED_VASO ON PAV.PtNo_Num = MED_VASO.episode_no
--LEFT JOIN #hml_med_anticoag AS HML_MED_ANTICOAG ON PAV.PtNo_Num = HML_MED_ANTICOAG.episode_no
LEFT JOIN #hml_med_imm_mod AS HML_IMM_MOD ON PAV.PtNo_Num = HML_IMM_MOD.episode_no
-- death test
LEFT JOIN #death_info_tbl AS DEATH ON DEATH.PatientAccountID = BP.PtNo_Num
	AND DEATH.Has_Time_Flag = 'HAS_TIME'
LEFT JOIN #Patient_Address_tbl AS ADDR ON BP.PtNo_Num = ADDR.ptno_num
	AND BP.unit_seq_no = ADDR.unit_seq_no
LEFT JOIN #skin_disorders_pvt_tbl AS SKIN ON BP.Pt_No = SKIN.pt_id
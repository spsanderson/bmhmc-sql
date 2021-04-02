/*
***********************************************************************
File: sepsis_nysdoh_query.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_sepsis_evaluator_v

Creates Table:
	

Functions:
	

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get the encounters and associated data for the NYSDOH sepsis abstraction

	To get all of the csv file tables (appendix tables) run the following:
	SELECT schema_name(t.schema_id) AS schema_name,
		t.name AS table_name
	FROM sys.tables t
	WHERE t.name LIKE 'c_nysdoh_sepsis_%'
	ORDER BY table_name,
		schema_name;

Revision History:
Date		Version		Description
----		----		----
2021-03-15	v1			Initial Creation
***********************************************************************
*/

-- Get the base population of persons we are interested in
SELECT A.Pt_No,
	SUBSTRING(A.Pt_No, 5, 8) AS [PtNo_Num],
	A.unit_seq_no,
	A.from_file_ind,
	A.Bl_Unit_Key,
	A.Pt_Key,
	A.vst_start_dtime,
	A.vst_end_dtime
INTO #BasePopulation
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
	AND PT_Age >= 21;

-- Comorbidities
-- acute cardiovascular conditions
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
	--PVT.[0],
	--PVT.[1],
	--PVT.[2],
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
PIVOT(MAX(ACUTE_CARDIOVASCULAR_CONDITIONS) FOR ACUTE_CARDIOVASCULAR_CONDITIONS IN ("0", "1", "2")) AS PVT

-- Get
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
	[unique_personal_identifier] = CAST(LEFT(pav.Pt_Name, 2) AS VARCHAR) + CAST(RIGHT(LTRIM(RTRIM(SUBSTRING(PAV.PT_NAME, 1, CHARINDEX(' ,', PAV.PT_NAME, 1)))), 2) AS VARCHAR) + LEFT(LTRIM(RTRIM(REVERSE(SUBSTRING(REVERSE(pav.pt_name), 1, CHARINDEX(',', REVERSE(PAV.PT_NAME), 1) - 1)))), 2) + CAST(LTRIM(RTRIM(RIGHT(PAV.Pt_SSA_No, 4))) AS VARCHAR)
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
	--DROP TABLE #BasePopulation, #acc_tbl
	--SELECT * FROM #BasePopulation

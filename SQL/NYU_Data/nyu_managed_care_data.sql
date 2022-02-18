/*
***********************************************************************
File: nyu_managed_care_data.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
    smsdss.pyr_dim_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get data for the managed care team, date for discharge years
    2019
    2020
    2021

Revision History:
Date		Version		Description
----		----		----
2022-01-24  v1          Initial Creation
***********************************************************************
*/

-- Inpatient ----------------------------------------------------------

DECLARE @START DATE;
DECLARE @END DATE;

SET @START = '2019-01-01'
SET @END = '2022-01-01'

DROP TABLE IF EXISTS #base_tbl
	CREATE TABLE #base_tbl (
		med_rec_no VARCHAR(12),
		encounter_id VARCHAR(12),
		pt_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		admit_date DATE,
		discharge_date DATE,
		admit_source VARCHAR(100),
		disposition VARCHAR(100),
		length_of_stay INT,
		payer_one_code CHAR(3),
		payer_one_name VARCHAR(255),
		payer_two_code CHAR(3),
		payer_two_name VARCHAR(255),
		payer_three_code CHAR(3),
		payer_three_name VARCHAR(255),
		payer_four_code CHAR(3),
		payer_four_name VARCHAR(255),
		payer_one_type VARCHAR(100),
		pt_name VARCHAR(255),
		pt_age INT,
		pt_dob DATE,
		pt_sex VARCHAR(5),
		pt_ssn_last_four VARCHAR(4),
		department_id VARCHAR(5),
		department_name VARCHAR(100),
		billing_drg_no VARCHAR(12),
		billing_drg_weight VARCHAR(12),
		total_charges MONEY,
		total_payments MONEY,
		total_amount_due MONEY
		)

INSERT INTO #base_tbl (
	med_rec_no,
	encounter_id,
	pt_id,
	unit_seq_no,
	admit_date,
	discharge_date,
	admit_source,
	disposition,
	length_of_stay,
	payer_one_code,
	payer_one_name,
	payer_two_code,
	payer_two_name,
	payer_three_code,
	payer_three_name,
	payer_four_code,
	payer_four_name,
	payer_one_type,
	pt_name,
	pt_age,
	pt_dob,
	pt_sex,
	pt_ssn_last_four,
	department_id,
	department_name,
	billing_drg_no,
	billing_drg_weight,
	total_charges,
	total_payments,
	total_amount_due
	)
SELECT PAV.Med_Rec_No,
	PAV.PtNo_Num,
	PAV.Pt_No,
	PAV.unit_seq_no,
	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
	CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date],
	[admit_source] = CASE 
		WHEN PAV.adm_prio = 'N'
			THEN 'Newborn'
		WHEN PAV.adm_prio = 'O'
			THEN 'Other'
		WHEN PAV.adm_prio = 'P'
			THEN 'Pregnancy'
		WHEN PAV.adm_prio = 'Q'
			THEN 'Other'
		WHEN PAV.adm_prio = 'R'
			THEN 'Routine Elective Admission'
		WHEN PAV.adm_prio = 'S'
			THEN 'Semiurgent Admission'
		WHEN PAV.adm_prio = 'U'
			THEN 'Urgent Admission'
		WHEN PAV.adm_prio = 'W'
			THEN 'Other'
		WHEN PAV.adm_prio = 'X'
			THEN 'Emergency Admission'
		END,
	[disposition] = CASE 
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'HB'
			THEN 'Drug/Alcohol Rehab Non-Hospital Facility'
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'HI'
			THEN 'Hospice at Hospice Facility, SNF or Inpatient Facility'
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'HR'
			THEN 'Home, Home with Public Health Nurse, Adult Home, Assisted Living'
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'MA'
			THEN 'Left Against Medical Advice, Elopement'
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TB'
			THEN 'Correctional Institution'
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TE'
			THEN 'SNF -Sub Acute'
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TF'
			THEN 'Specialty Hospital ( i.e Sloan, Schneiders)'
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TH'
			THEN 'Hospital - Med/Surg (i.e Stony Brook)'
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TL'
			THEN 'SNF - Long Term'
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TN'
			THEN 'Hospital - VA'
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TP'
			THEN 'Hospital - Psych or Drug/Alcohol (i.e BMH 1EAST, South Oaks)'
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TT'
			THEN 'Hospice at Home, Adult Home, Assisted Living'
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TW'
			THEN 'Home, Adult Home, Assisted Living with Homecare'
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TX'
			THEN 'Hospital - Acute Rehab ( I.e. St. Charles, Southside)'
		WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = '1A'
			THEN 'Postoperative Death, Autopsy'
		WHEN LEFT(PAV.dsch_disp, 1) IN ('C', 'D')
			THEN 'Mortality'
		END,
	[length_of_stay] = CAST(PAV.Days_Stay AS INT),
	[payer_one_code] = PAV.Pyr1_Co_Plan_Cd,
	[payer_one_name] = PDVA.pyr_name,
	[payer_two_code] = PAV.Pyr2_Co_Plan_Cd,
	[payer_two_name] = PDVB.pyr_name,
	[payer_three_code] = PAV.Pyr3_Co_Plan_Cd,
	[payer_three_name] = PDVC.pyr_name,
	[payer_four_code] = PAV.Pyr4_Co_Plan_Cd,
	[payer_four_name] = PDVD.pyr_name,
	[payer_one_type] = PDVA.pyr_group2,
	pav.Pt_Name,
	PAV.Pt_Age,
	PAV.Pt_Birthdate,
	PAV.Pt_Sex,
	[pt_ssn_last_four] = RIGHT(PAV.Pt_SSA_No, 4),
	PAV.hosp_svc,
	HSVC.hosp_svc_name,
	PAV.drg_no,
	PAV.drg_cost_weight,
	PAV.tot_chg_amt,
	CASE 
		WHEN PAV.Plm_Pt_Acct_Type = 'I'
			THEN PIP.tot_pymts_w_pip
		ELSE PAV.tot_pay_amt
		END,
	PAV.Tot_Amt_Due
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
LEFT OUTER JOIN SMSDSS.pyr_dim_v AS PDVA ON PAV.Pyr1_Co_Plan_Cd = PDVA.src_pyr_cd
	AND PAV.Regn_Hosp = PDVA.orgz_cd
LEFT OUTER JOIN SMSDSS.pyr_dim_v AS PDVB ON PAV.Pyr2_Co_Plan_Cd = PDVB.src_pyr_cd
	AND PAV.Regn_Hosp = PDVB.orgz_cd
LEFT OUTER JOIN SMSDSS.pyr_dim_v AS PDVC ON PAV.Pyr3_Co_Plan_Cd = PDVC.src_pyr_cd
	AND PAV.Regn_Hosp = PDVC.orgz_cd
LEFT OUTER JOIN SMSDSS.pyr_dim_v AS PDVD ON PAV.Pyr4_Co_Plan_Cd = PDVD.src_pyr_cd
	AND PAV.Regn_Hosp = PDVD.orgz_cd
LEFT OUTER JOIN SMSDSS.hosp_svc_dim_v AS HSVC ON PAV.hosp_svc = HSVC.src_hosp_svc
	AND PAV.Regn_Hosp = HSVC.orgz_cd
LEFT OUTER JOIN SMSDSS.c_tot_pymts_w_pip_v AS PIP ON PAV.Pt_No = PIP.pt_id
	AND PAV.unit_seq_no = PIP.unit_seq_no
WHERE PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) != '2'
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.Plm_Pt_Acct_Type = 'I'
	AND PAV.Dsch_Date >= @START
	AND PAV.Dsch_Date < @END;

-- get unique visit numbers
DROP TABLE IF EXISTS #unique_visits_tbl
	CREATE TABLE #unique_visits_tbl (
		pt_id VARCHAR(12),
		unit_seq_no VARCHAR(12)
		)

INSERT INTO #unique_visits_tbl (
	pt_id,
	unit_seq_no
	)
SELECT pt_id,
	unit_seq_no
FROM #base_tbl
GROUP BY pt_id,
	unit_seq_no;

-- PT Demos address
DROP TABLE IF EXISTS #pt_demos_tbl
CREATE TABLE #pt_demos_tbl (
	encounter_id VARCHAR(12),
	pt_street_address VARCHAR(255),
	pt_city VARCHAR(255),
	pt_state VARCHAR(50),
	pt_zip_cd VARCHAR(10)
)

INSERT INTO #pt_demos_tbl (
	encounter_id,
	pt_street_address,
	pt_city,
	pt_state,
	pt_zip_cd
)
SELECT PTDEMOS.pt_id,
	PTDEMOS.addr_line1,
	PTDEMOS.Pt_Addr_City,
	PTDEMOS.Pt_Addr_State,
	PTDEMOS.Pt_Addr_Zip
FROM SMSDSS.c_patient_demos_v AS PTDEMOS
INNER JOIN #unique_visits_tbl AS UV ON PTDEMOS.pt_id = UV.pt_id
GROUP BY PTDEMOS.pt_id,
	PTDEMOS.addr_line1,
	PTDEMOS.Pt_Addr_City,
	PTDEMOS.Pt_Addr_State,
	PTDEMOS.Pt_Addr_Zip;

-- GET ADMITTING DX
DROP TABLE IF EXISTS #admit_dx_tbl
	CREATE TABLE #admit_dx_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		admitting_dx_code VARCHAR(12)
		)

INSERT INTO #admit_dx_tbl (
	encounter_id,
	unit_seq_no,
	admitting_dx_code
	)
SELECT DX.pt_id,
	DX.unit_seq_no,
	DX.dx_cd
FROM smsmir.dx_grp AS DX
INNER JOIN #unique_visits_tbl AS PV ON DX.pt_id = PV.pt_id
	AND DX.unit_seq_no = PV.unit_seq_no
WHERE DX.dx_cd_prio = '01'
	AND LEFT(DX.dx_cd_type, 2) = 'DA'
GROUP BY DX.pt_id,
	DX.unit_seq_no,
	DX.dx_cd

-- Dx codes 1-6
DROP TABLE IF EXISTS #dx_codes_tbl
	CREATE TABLE #dx_codes_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		dx_cd VARCHAR(12),
		dx_cd_prio VARCHAR(5)
		)

INSERT INTO #dx_codes_tbl (
	encounter_id,
	unit_seq_no,
	dx_cd,
	dx_cd_prio
	)
SELECT DX.pt_id,
	DX.unit_seq_no,
	DX.dx_cd,
	DX.dx_cd_prio
FROM smsmir.dx_grp AS DX
INNER JOIN #unique_visits_tbl AS PV ON DX.pt_id = PV.pt_id
	AND DX.unit_seq_no = PV.unit_seq_no
WHERE LEFT(DX.dx_cd_type, 2) = 'DF'
	AND DX.dx_cd_prio IN ('01', '02', '03', '04', '05', '06')

-- PIVOT THE TABLE
DROP TABLE IF EXISTS #dx_cd_pvt_tbl
	CREATE TABLE #dx_cd_pvt_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		dx_cd_one VARCHAR(12),
		dx_cd_two VARCHAR(12),
		dx_cd_three VARCHAR(12),
		dx_cd_four VARCHAR(12),
		dx_cd_five VARCHAR(12),
		dx_cd_six VARCHAR(12)
		)

INSERT INTO #dx_cd_pvt_tbl (
	encounter_id,
	unit_seq_no,
	dx_cd_one,
	dx_cd_two,
	dx_cd_three,
	dx_cd_four,
	dx_cd_five,
	dx_cd_six
	)
SELECT PVT.encounter_id,
	PVT.unit_seq_no,
	PVT.[01] AS [dx_cd_one],
	PVT.[02] AS [dx_cd_two],
	PVT.[03] AS [dx_cd_three],
	PVT.[04] AS [dx_cd_four],
	PVT.[05] AS [dx_cd_five],
	PVT.[06] AS [dx_cd_six]
FROM #dx_codes_tbl
PIVOT(MAX(DX_CD) FOR DX_CD_PRIO IN ("01", "02", "03", "04", "05", "06")) AS PVT

-- procedure codes
DROP TABLE IF EXISTS #proc_cd_tbl
	CREATE TABLE #proc_cd_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		principal_proc_cd VARCHAR(12),
		proc_cd_one VARCHAR(12),
		proc_cd_two VARCHAR(12),
		proc_cd_three VARCHAR(12),
		proc_cd_four VARCHAR(12),
		proc_cd_five VARCHAR(12),
		proc_cd_six VARCHAR(12)
		)

INSERT INTO #proc_cd_tbl (
	encounter_id,
	unit_seq_no,
	principal_proc_cd,
	proc_cd_one,
	proc_cd_two,
	proc_cd_three,
	proc_cd_four,
	proc_cd_five,
	proc_cd_six
	)
SELECT PVT.pt_id,
	PVT.unit_seq_no,
	PVT.[01] AS principal_proc_cd,
	pvt.[01],
	PVT.[02],
	PVT.[03],
	PVT.[04],
	PVT.[05],
	PVT.[06]
FROM (
	SELECT SPROC.pt_id,
		SPROC.unit_seq_no,
		SPROC.proc_cd,
		SPROC.proc_cd_prio
	FROM smsmir.sproc AS SPROC
	INNER JOIN #unique_visits_tbl PV ON SPROC.pt_id = PV.pt_id
		AND SPROC.unit_seq_no = PV.unit_seq_no
	WHERE proc_cd_prio IN ('01', '02', '03', '04', '05', '06')
		AND SPROC.proc_cd_type != 'C'
	) AS A
PIVOT(MAX(PROC_CD) FOR PROC_CD_PRIO IN ("01", "02", "03", "04", "05", "06")) AS PVT

-- apr drg data
DROP TABLE IF EXISTS #apr_drg_tbl
	CREATE TABLE #apr_drg_tbl (
		encounter_id VARCHAR(12),
		apr_drg VARCHAR(5),
		apr_severity VARCHAR(5)
		)

INSERT INTO #apr_drg_tbl (
	encounter_id,
	apr_drg,
	apr_severity
	)
SELECT APR.[Patient#],
	APR.[APRDRGNO],
	APR.[SEVERITY_OF_ILLNESS]
FROM Customer.Custom_DRG AS APR
INNER JOIN #unique_visits_tbl PV ON APR.[PATIENT#] = SUBSTRING(PV.pt_id, 5, 8);

-- Referring provider
DROP TABLE IF EXISTS #referring_provider_tbl
	CREATE TABLE #referring_provider_tbl (
		encounter_id VARCHAR(12),
		pt_id VARCHAR(12),
		ref_pract_no VARCHAR(12),
		ref_pract_name VARCHAR(255)
		)

INSERT INTO #referring_provider_tbl (
	encounter_id,
	pt_id,
	ref_pract_no,
	ref_pract_name
	)
SELECT vst.pt_id AS encounter_id,
	CONCAT (
		'0000',
		vst.pt_id
		) AS pt_id,
	VST.ref_pract_no,
	UPPER(PDV.pract_rpt_name) AS [pract_rpt_name]
FROM SMSMIR.hl7_vst AS VST
INNER JOIN #unique_visits_tbl AS UV ON VST.pt_id = SUBSTRING(UV.PT_ID, 5, 8)
LEFT OUTER JOIN smsdss.pract_dim_v AS PDV ON VST.ref_pract_no = PDV.src_pract_no
	AND VST.orgz_from = PDV.orgz_cd
GROUP BY VST.pt_id,
	CONCAT ('0000',	vst.pt_id),
	VST.ref_pract_no,
	UPPER(PDV.PRACT_RPT_name);

-- attending provider
DROP TABLE IF EXISTS #attending_provider_tbl
	CREATE TABLE #attending_provider_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		attending_code VARCHAR(12),
		attending_npi VARCHAR(24),
		attending_name VARCHAR(255),
		attending_service VARCHAR(255)
		)

INSERT INTO #attending_provider_tbl (
	encounter_id,
	unit_seq_no,
	attending_code,
	attending_npi,
	attending_name,
	attending_service
	)
SELECT PAV.PtNo_Num,
	BASE.unit_seq_no,
	PAV.Atn_Dr_No,
	PDV.npi_no,
	UPPER(PDV.pract_rpt_name) AS [pract_rpt_name],
	PDV.spclty_desc
FROM #unique_visits_tbl AS BASE
INNER JOIN SMSDSS.BMH_PLM_PtAcct_V AS PAV ON BASE.pt_id = PAV.Pt_No
	AND BASE.unit_seq_no = PAV.unit_seq_no
INNER JOIN SMSDSS.pract_dim_v AS PDV ON PAV.Atn_Dr_No = PDV.src_pract_no
	AND PAV.Regn_Hosp = PDV.orgz_cd;

-- Charge information
DROP TABLE IF EXISTS #charges_tbl
	CREATE TABLE #charges_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		operating_room_charges MONEY,
		recovery_room_charges MONEY,
		ancillary_charges MONEY
		)

INSERT INTO #charges_tbl (
	encounter_id,
	unit_seq_no,
	operating_room_charges,
	recovery_room_charges,
	ancillary_charges
	)
SELECT ACTV.pt_id,
	ACTV.unit_seq_no,
	[operating_room_charges] = (
		SELECT SUM(zzz.chg_tot_amt)
		FROM smsmir.actv AS ZZZ
		WHERE ZZZ.PT_ID = ACTV.pt_id
			AND ZZZ.unit_seq_no = ACTV.unit_seq_no
			AND LEFT(ZZZ.actv_cd, 3) = '008'
		),
	[recovery_room_charges] = (
		SELECT SUM(zzz.chg_tot_amt)
		FROM smsmir.actv AS ZZZ
		WHERE ZZZ.PT_ID = ACTV.pt_id
			AND ZZZ.unit_seq_no = ACTV.unit_seq_no
			AND LEFT(ZZZ.actv_cd, 3) = '009'
		),
	[ancillary_charges] = (
		SELECT SUM(zzz.chg_tot_amt)
		FROM smsmir.actv AS ZZZ
		WHERE ZZZ.PT_ID = ACTV.pt_id
			AND ZZZ.unit_seq_no = ACTV.unit_seq_no
			AND LEFT(ZZZ.actv_cd, 3) NOT IN ('008', '009')
		)
FROM smsmir.actv AS ACTV
INNER JOIN #unique_visits_tbl AS BASE ON ACTV.PT_ID = BASE.pt_id
	AND ACTV.unit_seq_no = BASE.unit_seq_no
GROUP BY ACTV.pt_id,
	ACTV.unit_seq_no;

-- Insurance policy numbers
DROP TABLE IF EXISTS #ins_policy_info_tbl
	CREATE TABLE #ins_policy_info_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		ins1_pol_no VARCHAR(255),
		ins2_pol_no VARCHAR(255),
		ins3_pol_no VARCHAR(255)
		)

INSERT INTO #ins_policy_info_tbl (
	encounter_id,
	unit_seq_no,
	ins1_pol_no,
	ins2_pol_no,
	ins3_pol_no
	)
SELECT VST.pt_id,
	VST.unit_seq_no,
	ins1_pol_no,
	ins2_pol_no,
	ins3_pol_no
FROM smsmir.vst_rpt AS VST
INNER JOIN #unique_visits_tbl AS BASE ON VST.pt_id = BASE.pt_id
	AND VST.unit_seq_no = BASE.unit_seq_no;

-- CHARGES BY REVENUE CODE
DROP TABLE IF EXISTS #rev_cd_charges_tbl
	CREATE TABLE #rev_cd_charges_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		rev_cd VARCHAR(5),
		tot_chg MONEY
		)

INSERT INTO #rev_cd_charges_tbl (
	encounter_id,
	unit_seq_no,
	rev_cd,
	tot_chg
	)
SELECT ACTV.pt_id,
	ACTV.unit_seq_no,
	XREF.rev_cd,
	SUM(chg_tot_amt) AS [tot_rev_cd_chg]
FROM SMSMIR.actv AS ACTV
INNER JOIN smsmir.mir_actv_proc_seg_xref AS XREF ON ACTV.actv_cd = XREF.actv_cd
	AND XREF.proc_pyr_ind = 'A'
INNER JOIN #unique_visits_tbl AS BASE ON ACTV.PT_ID = BASE.pt_id
	AND ACTV.unit_seq_no = BASE.unit_seq_no
WHERE XREF.rev_cd IN ('219', '170', '171', '172', '173', '174', '270', '272', '274', '275', '276', '278', '279', '387', '390', '391', '399', '636', '760', '761', '762', '769')
GROUP BY ACTV.pt_id,
	ACTV.unit_seq_no,
	XREF.rev_cd;

-- REV CODE PIVOT
DROP TABLE IF EXISTS #rev_cd_pvt_tbl
	CREATE TABLE #rev_cd_pvt_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		[219] VARCHAR(12),
		[170] VARCHAR(12),
		[171] VARCHAR(12),
		[172] VARCHAR(12),
		[173] VARCHAR(12),
		[174] VARCHAR(12),
		[270] VARCHAR(12),
		[272] VARCHAR(12),
		[274] VARCHAR(12),
		[275] VARCHAR(12),
		[276] VARCHAR(12),
		[278] VARCHAR(12),
		[279] VARCHAR(12),
		[387] VARCHAR(12),
		[390] VARCHAR(12),
		[391] VARCHAR(12),
		[399] VARCHAR(12),
		[636] VARCHAR(12),
		[760] VARCHAR(12),
		[761] VARCHAR(12),
		[762] VARCHAR(12),
		[769] VARCHAR(12)
		)

INSERT INTO #rev_cd_pvt_tbl (
	encounter_id,
	unit_seq_no,
	[219],
	[170],
	[171],
	[172],
	[173],
	[174],
	[270],
	[272],
	[274],
	[275],
	[276],
	[278],
	[279],
	[387],
	[390],
	[391],
	[399],
	[636],
	[760],
	[761],
	[762],
	[769]
	)
SELECT PVT.encounter_id,
	PVT.unit_seq_no,
	PVT.[219],
	PVT.[170],
	PVT.[171],
	PVT.[172],
	PVT.[173],
	PVT.[174],
	PVT.[270],
	PVT.[272],
	PVT.[274],
	PVT.[275],
	PVT.[276],
	PVT.[278],
	PVT.[279],
	PVT.[387],
	PVT.[390],
	PVT.[391],
	PVT.[399],
	PVT.[636],
	PVT.[760],
	PVT.[761],
	PVT.[762],
	PVT.[769]
FROM (
	SELECT ZZZ.encounter_id,
		ZZZ.unit_seq_no,
		ZZZ.rev_cd,
		ZZZ.tot_chg
	FROM #rev_cd_charges_tbl AS ZZZ
	) AS A
PIVOT(MAX(tot_chg) FOR rev_cd IN ("219", "170", "171", "172", "173", "174", "270", "272", "274", "275", "276", "278", "279", "387", "390", "391", "399", "636", "760", "761", "762", "769")) AS PVT

-- PATIENT BALANCE
DROP TABLE IF EXISTS #pt_bal_amt_tbl
CREATE TABLE #pt_bal_amt_tbl (
	encounter_id VARCHAR(12),
	unit_seq_no VARCHAR(12),
	pt_balance_amt money
)

INSERT INTO #pt_bal_amt_tbl (
	encounter_id,
	unit_seq_no,
	pt_balance_amt
)
SELECT ACCT.pt_id,
	ACCT.unit_seq_no,
	ACCT.pt_bal_amt
FROM SMSMIR.acct AS ACCT
INNER JOIN #unique_visits_tbl AS UV ON ACCT.pt_id = UV.pt_id
	AND ACCT.unit_seq_no = UV.unit_seq_no

-- PULL IT ALL TOGETHER
SELECT BASE.med_rec_no,
	BASE.encounter_id,
	BASE.pt_id,
	BASE.unit_seq_no,
	BASE.admit_date,
	BASE.discharge_date,
	BASE.admit_source,
	BASE.disposition,
	BASE.length_of_stay,
	BASE.payer_one_code,
	BASE.payer_one_name,
	BASE.payer_two_code,
	BASE.payer_two_name,
	BASE.payer_three_code,
	BASE.payer_three_name,
	BASE.payer_four_code,
	BASE.payer_four_name,
	BASE.payer_one_type,
	BASE.pt_name,
	PTDEMOS.pt_street_address,
	PTDEMOS.pt_city,
	PTDEMOS.pt_state,
	PTDEMOS.pt_zip_cd,
	BASE.pt_age,
	BASE.pt_dob,
	BASE.pt_sex,
	BASE.pt_ssn_last_four,
	BASE.department_id,
	BASE.department_name,
	BASE.billing_drg_no,
	BASE.billing_drg_weight,
	BASE.total_charges,
	BASE.total_payments,
	BASE.total_amount_due,
	PT_BAL.pt_balance_amt,
	ADM_DX.admitting_dx_code,
	DX_PVT.dx_cd_one,
	DX_PVT.dx_cd_two,
	DX_PVT.dx_cd_three,
	DX_PVT.dx_cd_four,
	DX_PVT.dx_cd_five,
	PROC_PVT.proc_cd_one,
	PROC_PVT.proc_cd_two,
	PROC_PVT.proc_cd_three,
	PROC_PVT.proc_cd_four,
	PROC_PVT.proc_cd_five,
	APR.apr_drg,
	APR.apr_severity,
	REF_PROV.ref_pract_name,
	ATN_PROV.attending_code,
	ATN_PROV.attending_npi,
	ATN_PROV.attending_name,
	ATN_PROV.attending_service,
	CHGS.operating_room_charges,
	CHGS.recovery_room_charges,
	CHGS.ancillary_charges,
	INS_POL.ins1_pol_no,
	INS_POL.ins2_pol_no,
	INS_POL.ins3_pol_no,
	REV_PVT.[170],
	REV_PVT.[171],
	REV_PVT.[172],
	REV_PVT.[173],
	REV_PVT.[174],
	REV_PVT.[219],
	REV_PVT.[270],
	REV_PVT.[272],
	REV_PVT.[274],
	REV_PVT.[275],
	REV_PVT.[276],
	REV_PVT.[278],
	REV_PVT.[279],
	REV_PVT.[387],
	REV_PVT.[390],
	REV_PVT.[391],
	REV_PVT.[399],
	REV_PVT.[636],
	REV_PVT.[760],
	REV_PVT.[761],
	REV_PVT.[762],
	REV_PVT.[769]
FROM #base_tbl AS BASE
LEFT OUTER JOIN #pt_bal_amt_tbl AS PT_BAL ON BASE.pt_id = PT_BAL.encounter_id
	AND BASE.unit_seq_no = PT_BAL.unit_seq_no
LEFT OUTER JOIN #pt_demos_tbl AS PTDEMOS ON BASE.pt_id = PTDEMOS.encounter_id
LEFT OUTER JOIN #admit_dx_tbl AS ADM_DX ON BASE.pt_id = ADM_DX.encounter_id
	AND BASE.unit_seq_no = ADM_DX.unit_seq_no
LEFT OUTER JOIN #dx_cd_pvt_tbl AS DX_PVT ON BASE.pt_id = DX_PVT.encounter_id
	AND BASE.unit_seq_no = DX_PVT.unit_seq_no
LEFT OUTER JOIN #proc_cd_tbl AS PROC_PVT ON BASE.pt_id = PROC_PVT.encounter_id
	AND BASE.unit_seq_no = PROC_PVT.unit_seq_no
LEFT OUTER JOIN #apr_drg_tbl AS APR ON BASE.encounter_id = APR.encounter_id
LEFT OUTER JOIN #referring_provider_tbl AS REF_PROV ON BASE.pt_id = REF_PROV.pt_id
LEFT OUTER JOIN #attending_provider_tbl AS ATN_PROV ON BASE.encounter_id = ATN_PROV.encounter_id
	AND BASE.unit_seq_no = ATN_PROV.unit_seq_no
LEFT OUTER JOIN #charges_tbl AS CHGS ON BASE.pt_id = CHGS.encounter_id
	AND BASE.unit_seq_no = CHGS.unit_seq_no
LEFT OUTER JOIN #ins_policy_info_tbl AS INS_POL ON BASE.pt_id = INS_POL.encounter_id
	AND BASE.unit_seq_no = INS_POL.unit_seq_no
LEFT OUTER JOIN #rev_cd_pvt_tbl AS REV_PVT ON BASE.pt_id = REV_PVT.encounter_id
	AND BASE.unit_seq_no = REV_PVT.unit_seq_no
ORDER BY BASE.med_rec_no,
 BASE.encounter_id;

 -- Outpatient --------------------------------------------------------
DECLARE @START DATE;
DECLARE @END DATE;

SET @START = '2019-01-01'
SET @END = '2022-01-01'

DROP TABLE IF EXISTS #base_tbl
	CREATE TABLE #base_tbl (
		med_rec_no VARCHAR(12),
		encounter_id VARCHAR(12),
		pt_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		admit_date DATE,
		payer_one_code CHAR(3),
		payer_one_name VARCHAR(255),
		payer_two_code CHAR(3),
		payer_two_name VARCHAR(255),
		payer_three_code CHAR(3),
		payer_three_name VARCHAR(255),
		payer_one_type VARCHAR(100),
		pt_name VARCHAR(255),
		pt_age INT,
		pt_dob DATE,
		pt_sex VARCHAR(5),
		pt_ssn_last_four VARCHAR(4),
		department_id VARCHAR(5),
		department_name VARCHAR(100),
		total_charges MONEY,
		total_payments MONEY,
		total_amount_due MONEY
		)

INSERT INTO #base_tbl (
	med_rec_no,
	encounter_id,
	pt_id,
	unit_seq_no,
	admit_date,
	payer_one_code,
	payer_one_name,
	payer_two_code,
	payer_two_name,
	payer_three_code,
	payer_three_name,
	payer_one_type,
	pt_name,
	pt_age,
	pt_dob,
	pt_sex,
	pt_ssn_last_four,
	department_id,
	department_name,
	total_charges,
	total_payments,
	total_amount_due
	)
SELECT PAV.Med_Rec_No,
	PAV.PtNo_Num,
	PAV.Pt_No,
	PAV.unit_seq_no,
	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
	[payer_one_code] = PAV.Pyr1_Co_Plan_Cd,
	[payer_one_name] = PDVA.pyr_name,
	[payer_two_code] = PAV.Pyr2_Co_Plan_Cd,
	[payer_two_name] = PDVB.pyr_name,
	[payer_three_code] = PAV.Pyr3_Co_Plan_Cd,
	[payer_three_name] = PDVC.pyr_name,
	[payer_one_type] = PDVA.pyr_group2,
	pav.Pt_Name,
	PAV.Pt_Age,
	PAV.Pt_Birthdate,
	PAV.Pt_Sex,
	[pt_ssn_last_four] = RIGHT(PAV.Pt_SSA_No, 4),
	PAV.hosp_svc,
	HSVC.hosp_svc_name,
	PAV.tot_chg_amt,
	PAV.tot_pay_amt,
	PAV.Tot_Amt_Due
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
LEFT OUTER JOIN SMSDSS.pyr_dim_v AS PDVA ON PAV.Pyr1_Co_Plan_Cd = PDVA.src_pyr_cd
	AND PAV.Regn_Hosp = PDVA.orgz_cd
LEFT OUTER JOIN SMSDSS.pyr_dim_v AS PDVB ON PAV.Pyr2_Co_Plan_Cd = PDVB.src_pyr_cd
	AND PAV.Regn_Hosp = PDVB.orgz_cd
LEFT OUTER JOIN SMSDSS.pyr_dim_v AS PDVC ON PAV.Pyr3_Co_Plan_Cd = PDVC.src_pyr_cd
	AND PAV.Regn_Hosp = PDVC.orgz_cd
LEFT OUTER JOIN SMSDSS.pyr_dim_v AS PDVD ON PAV.Pyr4_Co_Plan_Cd = PDVD.src_pyr_cd
	AND PAV.Regn_Hosp = PDVD.orgz_cd
LEFT OUTER JOIN SMSDSS.hosp_svc_dim_v AS HSVC ON PAV.hosp_svc = HSVC.src_hosp_svc
	AND PAV.Regn_Hosp = HSVC.orgz_cd
WHERE PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) != '2'
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.Plm_Pt_Acct_Type != 'I'
	AND PAV.adm_Date >= @START
	AND PAV.adm_Date < @END;

-- get unique visit numbers
DROP TABLE IF EXISTS #unique_visits_tbl
	CREATE TABLE #unique_visits_tbl (
		pt_id VARCHAR(12),
		unit_seq_no VARCHAR(12)
		)

INSERT INTO #unique_visits_tbl (
	pt_id,
	unit_seq_no
	)
SELECT pt_id,
	unit_seq_no
FROM #base_tbl
GROUP BY pt_id,
	unit_seq_no;

-- PT Demos address
DROP TABLE IF EXISTS #pt_demos_tbl
CREATE TABLE #pt_demos_tbl (
	encounter_id VARCHAR(12),
	pt_street_address VARCHAR(255),
	pt_city VARCHAR(255),
	pt_state VARCHAR(50),
	pt_zip_cd VARCHAR(10)
)

INSERT INTO #pt_demos_tbl (
	encounter_id,
	pt_street_address,
	pt_city,
	pt_state,
	pt_zip_cd
)
SELECT PTDEMOS.pt_id,
	PTDEMOS.addr_line1,
	PTDEMOS.Pt_Addr_City,
	PTDEMOS.Pt_Addr_State,
	PTDEMOS.Pt_Addr_Zip
FROM SMSDSS.c_patient_demos_v AS PTDEMOS
INNER JOIN #unique_visits_tbl AS UV ON PTDEMOS.pt_id = UV.pt_id
GROUP BY PTDEMOS.pt_id,
	PTDEMOS.addr_line1,
	PTDEMOS.Pt_Addr_City,
	PTDEMOS.Pt_Addr_State,
	PTDEMOS.Pt_Addr_Zip;

-- Dx codes 1-6
DROP TABLE IF EXISTS #dx_codes_tbl
	CREATE TABLE #dx_codes_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		dx_cd VARCHAR(12),
		dx_cd_prio VARCHAR(5)
		)

INSERT INTO #dx_codes_tbl (
	encounter_id,
	unit_seq_no,
	dx_cd,
	dx_cd_prio
	)
SELECT DX.pt_id,
	DX.unit_seq_no,
	DX.dx_cd,
	DX.dx_cd_prio
FROM smsmir.dx_grp AS DX
INNER JOIN #unique_visits_tbl AS PV ON DX.pt_id = PV.pt_id
	AND DX.unit_seq_no = PV.unit_seq_no
WHERE LEFT(DX.dx_cd_type, 2) = 'DF'
	AND DX.dx_cd_prio IN ('01', '02', '03', '04', '05', '06')

-- PIVOT THE TABLE
DROP TABLE IF EXISTS #dx_cd_pvt_tbl
	CREATE TABLE #dx_cd_pvt_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		dx_cd_one VARCHAR(12),
		dx_cd_two VARCHAR(12),
		dx_cd_three VARCHAR(12),
		dx_cd_four VARCHAR(12),
		dx_cd_five VARCHAR(12),
		dx_cd_six VARCHAR(12)
		)

INSERT INTO #dx_cd_pvt_tbl (
	encounter_id,
	unit_seq_no,
	dx_cd_one,
	dx_cd_two,
	dx_cd_three,
	dx_cd_four,
	dx_cd_five,
	dx_cd_six
	)
SELECT PVT.encounter_id,
	PVT.unit_seq_no,
	PVT.[01] AS [dx_cd_one],
	PVT.[02] AS [dx_cd_two],
	PVT.[03] AS [dx_cd_three],
	PVT.[04] AS [dx_cd_four],
	PVT.[05] AS [dx_cd_five],
	PVT.[06] AS [dx_cd_six]
FROM #dx_codes_tbl
PIVOT(MAX(DX_CD) FOR DX_CD_PRIO IN ("01", "02", "03", "04", "05", "06")) AS PVT

-- procedure codes
DROP TABLE IF EXISTS #proc_cd_tbl
	CREATE TABLE #proc_cd_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		principal_proc_cd VARCHAR(12),
		proc_cd_one VARCHAR(12),
		proc_cd_two VARCHAR(12),
		proc_cd_three VARCHAR(12),
		proc_cd_four VARCHAR(12),
		proc_cd_five VARCHAR(12),
		proc_cd_six VARCHAR(12)
		)

INSERT INTO #proc_cd_tbl (
	encounter_id,
	unit_seq_no,
	principal_proc_cd,
	proc_cd_one,
	proc_cd_two,
	proc_cd_three,
	proc_cd_four,
	proc_cd_five,
	proc_cd_six
	)
SELECT PVT.pt_id,
	PVT.unit_seq_no,
	PVT.[01] AS principal_proc_cd,
	pvt.[01],
	PVT.[02],
	PVT.[03],
	PVT.[04],
	PVT.[05],
	PVT.[06]
FROM (
	SELECT SPROC.pt_id,
		SPROC.unit_seq_no,
		SPROC.proc_cd,
		SPROC.proc_cd_prio
	FROM smsmir.sproc AS SPROC
	INNER JOIN #unique_visits_tbl PV ON SPROC.pt_id = PV.pt_id
		AND SPROC.unit_seq_no = PV.unit_seq_no
	WHERE proc_cd_prio IN ('01', '02', '03', '04', '05', '06')
		AND SPROC.proc_cd_type = 'PC'
	) AS A
PIVOT(MAX(PROC_CD) FOR PROC_CD_PRIO IN ("01", "02", "03", "04", "05", "06")) AS PVT

-- CPT table
DROP TABLE IF EXISTS #TEMPA
SELECT PVTB.pt_id,
	PVTB.unit_seq_no,
	PVTB.[01],
	PVTB.A01,
	PVTB.[02],
	PVTB.A02,
	PVTB.[03],
	PVTB.A03,
	PVTB.[04],
	PVTB.A04,
	PVTB.[05],
	PVTB.A05,
	PVTB.[06],
	PVTB.A06,
	PVTB.[07],
	PVTB.A07,
	PVTB.[08],
	PVTB.A08,
	PVTB.[09],
	PVTB.A09,
	PVTB.[10],
	PVTB.A10,
	PVTB.[11],
	PVTB.A11,
	PVTB.[12],
	PVTB.A12
INTO #TEMPA
FROM (
	SELECT SPROC.pt_id,
		SPROC.unit_seq_no,
		SPROC.proc_cd,
		SPROC.proc_cd_modf1,
		SPROC.proc_cd_modf2,
		SPROC.proc_cd_modf3,
		SPROC.proc_cd_prio,
		[proc_cd_prio_a] = 'A' + SPROC.proc_cd_prio
	FROM smsmir.sproc AS SPROC
	INNER JOIN #unique_visits_tbl PV ON SPROC.pt_id = PV.pt_id
		AND SPROC.unit_seq_no = PV.unit_seq_no
	WHERE proc_cd_prio IN (
			'01', '02', '03', '04', '05', '06',
			'07', '08', '09', '10', '11', '12' 			   
		)
		AND SPROC.proc_cd_type = 'PCH'
	) AS A
PIVOT(MAX(PROC_CD) FOR PROC_CD_PRIO IN ("01", "02", "03", "04", "05", "06",
										"07","08","09","10","11","12")) AS PVT
PIVOT(MAX(PROC_CD_MODF1) FOR PROC_CD_PRIO_A IN ("A01", "A02", "A03", "A04", "A05", "A06",
										"A07","A08","A09","A10","A11","A12")) AS PVTB;

DROP TABLE IF EXISTS #cpt_cd_tbl
SELECT pt_id,
	unit_seq_no,
	MAX([01]) AS CPT_01,
	MAX([02]) AS CPT_02,
	MAX([03]) AS CPT_03,
	MAX([04]) AS CPT_04,
	MAX([05]) AS CPT_05,
	MAX([06]) AS CPT_06,
	MAX([07]) AS CPT_07,
	MAX([08]) AS CPT_08,
	MAX([09]) AS CPT_09,
	MAX([10]) AS CPT_10,
	MAX([11]) AS CPT_11,
	MAX([12]) AS CPT_12,
	MAX([A01]) AS CPT_MODIFIER_01,
	MAX([A02]) AS CPT_MODIFIER_02,
	MAX([A03]) AS CPT_MODIFIER_03,
	MAX([A04]) AS CPT_MODIFIER_04,
	MAX([A05]) AS CPT_MODIFIER_05,
	MAX([A06]) AS CPT_MODIFIER_06,
	MAX([A07]) AS CPT_MODIFIER_07,
	MAX([A08]) AS CPT_MODIFIER_08,
	MAX([A09]) AS CPT_MODIFIER_09,
	MAX([A10]) AS CPT_MODIFIER_10,
	MAX([A11]) AS CPT_MODIFIER_11,
	MAX([A12]) AS CPT_MODIFIER_12
INTO #cpt_cd_tbl
FROM #TEMPA
GROUP BY pt_id, unit_seq_no;

-- Referring provider
DROP TABLE IF EXISTS #referring_provider_tbl
	CREATE TABLE #referring_provider_tbl (
		encounter_id VARCHAR(12),
		pt_id VARCHAR(12),
		ref_pract_no VARCHAR(12),
		ref_pract_name VARCHAR(255)
		)

INSERT INTO #referring_provider_tbl (
	encounter_id,
	pt_id,
	ref_pract_no,
	ref_pract_name
	)
SELECT vst.pt_id AS encounter_id,
	CONCAT (
		'0000',
		vst.pt_id
		) AS pt_id,
	VST.ref_pract_no,
	UPPER(PDV.pract_rpt_name) AS [pract_rpt_name]
FROM SMSMIR.hl7_vst AS VST
INNER JOIN #unique_visits_tbl AS UV ON VST.pt_id = SUBSTRING(UV.PT_ID, 5, 8)
LEFT OUTER JOIN smsdss.pract_dim_v AS PDV ON VST.ref_pract_no = PDV.src_pract_no
	AND VST.orgz_from = PDV.orgz_cd
GROUP BY VST.pt_id,
	CONCAT ('0000',	vst.pt_id),
	VST.ref_pract_no,
	UPPER(PDV.PRACT_RPT_name);

-- attending provider
DROP TABLE IF EXISTS #attending_provider_tbl
	CREATE TABLE #attending_provider_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		attending_code VARCHAR(12),
		attending_npi VARCHAR(24),
		attending_name VARCHAR(255),
		attending_service VARCHAR(255)
		)

INSERT INTO #attending_provider_tbl (
	encounter_id,
	unit_seq_no,
	attending_code,
	attending_npi,
	attending_name,
	attending_service
	)
SELECT PAV.PtNo_Num,
	BASE.unit_seq_no,
	PAV.Atn_Dr_No,
	PDV.npi_no,
	UPPER(PDV.pract_rpt_name) AS [pract_rpt_name],
	PDV.spclty_desc
FROM #unique_visits_tbl AS BASE
INNER JOIN SMSDSS.BMH_PLM_PtAcct_V AS PAV ON BASE.pt_id = PAV.Pt_No
	AND BASE.unit_seq_no = PAV.unit_seq_no
INNER JOIN SMSDSS.pract_dim_v AS PDV ON PAV.Atn_Dr_No = PDV.src_pract_no
	AND PAV.Regn_Hosp = PDV.orgz_cd;

-- Charge information
DROP TABLE IF EXISTS #charges_tbl
	CREATE TABLE #charges_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		operating_room_charges MONEY,
		recovery_room_charges MONEY,
		ancillary_charges MONEY
		)

INSERT INTO #charges_tbl (
	encounter_id,
	unit_seq_no,
	operating_room_charges,
	recovery_room_charges,
	ancillary_charges
	)
SELECT ACTV.pt_id,
	ACTV.unit_seq_no,
	[operating_room_charges] = (
		SELECT SUM(zzz.chg_tot_amt)
		FROM smsmir.actv AS ZZZ
		WHERE ZZZ.PT_ID = ACTV.pt_id
			AND ZZZ.unit_seq_no = ACTV.unit_seq_no
			AND LEFT(ZZZ.actv_cd, 3) = '008'
		),
	[recovery_room_charges] = (
		SELECT SUM(zzz.chg_tot_amt)
		FROM smsmir.actv AS ZZZ
		WHERE ZZZ.PT_ID = ACTV.pt_id
			AND ZZZ.unit_seq_no = ACTV.unit_seq_no
			AND LEFT(ZZZ.actv_cd, 3) = '009'
		),
	[ancillary_charges] = (
		SELECT SUM(zzz.chg_tot_amt)
		FROM smsmir.actv AS ZZZ
		WHERE ZZZ.PT_ID = ACTV.pt_id
			AND ZZZ.unit_seq_no = ACTV.unit_seq_no
			AND LEFT(ZZZ.actv_cd, 3) NOT IN ('008', '009')
		)
FROM smsmir.actv AS ACTV
INNER JOIN #unique_visits_tbl AS BASE ON ACTV.PT_ID = BASE.pt_id
	AND ACTV.unit_seq_no = BASE.unit_seq_no
GROUP BY ACTV.pt_id,
	ACTV.unit_seq_no;

-- Insurance policy numbers
DROP TABLE IF EXISTS #ins_policy_info_tbl
	CREATE TABLE #ins_policy_info_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		ins1_pol_no VARCHAR(255),
		ins2_pol_no VARCHAR(255),
		ins3_pol_no VARCHAR(255)
		)

INSERT INTO #ins_policy_info_tbl (
	encounter_id,
	unit_seq_no,
	ins1_pol_no,
	ins2_pol_no,
	ins3_pol_no
	)
SELECT VST.pt_id,
	VST.unit_seq_no,
	ins1_pol_no,
	ins2_pol_no,
	ins3_pol_no
FROM smsmir.vst_rpt AS VST
INNER JOIN #unique_visits_tbl AS BASE ON VST.pt_id = BASE.pt_id
	AND VST.unit_seq_no = BASE.unit_seq_no;

-- CHARGES BY REVENUE CODE
DROP TABLE IF EXISTS #rev_cd_charges_tbl
	CREATE TABLE #rev_cd_charges_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		rev_cd VARCHAR(5),
		tot_chg MONEY
		)

INSERT INTO #rev_cd_charges_tbl (
	encounter_id,
	unit_seq_no,
	rev_cd,
	tot_chg
	)
SELECT ACTV.pt_id,
	ACTV.unit_seq_no,
	XREF.rev_cd,
	SUM(chg_tot_amt) AS [tot_rev_cd_chg]
FROM SMSMIR.actv AS ACTV
INNER JOIN smsmir.mir_actv_proc_seg_xref AS XREF ON ACTV.actv_cd = XREF.actv_cd
	AND XREF.proc_pyr_ind = 'A'
INNER JOIN #unique_visits_tbl AS BASE ON ACTV.PT_ID = BASE.pt_id
	AND ACTV.unit_seq_no = BASE.unit_seq_no
WHERE XREF.rev_cd IN ('270', '272', '274', '275', '276', '278', '279', '387', '390', '391', '399', '636', '760', '761', '762', '769')
GROUP BY ACTV.pt_id,
	ACTV.unit_seq_no,
	XREF.rev_cd;

-- REV CODE PIVOT
DROP TABLE IF EXISTS #rev_cd_pvt_tbl
	CREATE TABLE #rev_cd_pvt_tbl (
		encounter_id VARCHAR(12),
		unit_seq_no VARCHAR(12),
		[219] VARCHAR(12),
		[170] VARCHAR(12),
		[171] VARCHAR(12),
		[172] VARCHAR(12),
		[173] VARCHAR(12),
		[174] VARCHAR(12),
		[270] VARCHAR(12),
		[272] VARCHAR(12),
		[274] VARCHAR(12),
		[275] VARCHAR(12),
		[276] VARCHAR(12),
		[278] VARCHAR(12),
		[279] VARCHAR(12),
		[387] VARCHAR(12),
		[390] VARCHAR(12),
		[391] VARCHAR(12),
		[399] VARCHAR(12),
		[636] VARCHAR(12),
		[760] VARCHAR(12),
		[761] VARCHAR(12),
		[762] VARCHAR(12),
		[769] VARCHAR(12)
		)

INSERT INTO #rev_cd_pvt_tbl (
	encounter_id,
	unit_seq_no,
	[219],
	[170],
	[171],
	[172],
	[173],
	[174],
	[270],
	[272],
	[274],
	[275],
	[276],
	[278],
	[279],
	[387],
	[390],
	[391],
	[399],
	[636],
	[760],
	[761],
	[762],
	[769]
	)
SELECT PVT.encounter_id,
	PVT.unit_seq_no,
	PVT.[219],
	PVT.[170],
	PVT.[171],
	PVT.[172],
	PVT.[173],
	PVT.[174],
	PVT.[270],
	PVT.[272],
	PVT.[274],
	PVT.[275],
	PVT.[276],
	PVT.[278],
	PVT.[279],
	PVT.[387],
	PVT.[390],
	PVT.[391],
	PVT.[399],
	PVT.[636],
	PVT.[760],
	PVT.[761],
	PVT.[762],
	PVT.[769]
FROM (
	SELECT ZZZ.encounter_id,
		ZZZ.unit_seq_no,
		ZZZ.rev_cd,
		ZZZ.tot_chg
	FROM #rev_cd_charges_tbl AS ZZZ
	) AS A
PIVOT(MAX(tot_chg) FOR rev_cd IN ("219", "170", "171", "172", "173", "174", "270", "272", "274", "275", "276", "278", "279", "387", "390", "391", "399", "636", "760", "761", "762", "769")) AS PVT

-- PATIENT BALANCE
DROP TABLE IF EXISTS #pt_bal_amt_tbl
CREATE TABLE #pt_bal_amt_tbl (
	encounter_id VARCHAR(12),
	unit_seq_no VARCHAR(12),
	pt_balance_amt money
)

INSERT INTO #pt_bal_amt_tbl (
	encounter_id,
	unit_seq_no,
	pt_balance_amt
)
SELECT ACCT.pt_id,
	ACCT.unit_seq_no,
	ACCT.pt_bal_amt
FROM SMSMIR.acct AS ACCT
INNER JOIN #unique_visits_tbl AS UV ON ACCT.pt_id = UV.pt_id
	AND ACCT.unit_seq_no = UV.unit_seq_no

-- PULL IT ALL TOGETHER
SELECT BASE.med_rec_no,
	BASE.encounter_id,
	BASE.pt_id,
	BASE.unit_seq_no,
	BASE.admit_date,
	BASE.payer_one_code,
	BASE.payer_one_name,
	BASE.payer_two_code,
	BASE.payer_two_name,
	BASE.payer_three_code,
	BASE.payer_three_name,
	BASE.payer_one_type,
	BASE.pt_name,
	PTDEMOS.pt_street_address,
	PTDEMOS.pt_city,
	PTDEMOS.pt_state,
	PTDEMOS.pt_zip_cd,
	BASE.pt_age,
	BASE.pt_dob,
	BASE.pt_sex,
	BASE.pt_ssn_last_four,
	BASE.department_id,
	BASE.department_name,
	BASE.total_charges,
	BASE.total_payments,
	BASE.total_amount_due,
	PT_BAL.pt_balance_amt,
	DX_PVT.dx_cd_one,
	DX_PVT.dx_cd_two,
	DX_PVT.dx_cd_three,
	DX_PVT.dx_cd_four,
	DX_PVT.dx_cd_five,
	DX_PVT.dx_cd_six,
	PROC_PVT.proc_cd_one,
	PROC_PVT.proc_cd_two,
	PROC_PVT.proc_cd_three,
	PROC_PVT.proc_cd_four,
	PROC_PVT.proc_cd_five,
	PROC_PVT.proc_cd_six,
	CPT.CPT_01,
	CPT.CPT_MODIFIER_01,
	CPT.CPT_02,
	CPT.CPT_MODIFIER_02,
	CPT.CPT_03,
	CPT.CPT_MODIFIER_03,
	CPT.CPT_04,
	CPT.CPT_MODIFIER_04,
	CPT.CPT_05,
	CPT.CPT_MODIFIER_05,
	CPT.CPT_06,
	CPT.CPT_MODIFIER_06,
	CPT.CPT_07,
	CPT.CPT_MODIFIER_07,
	CPT.CPT_08,
	CPT.CPT_MODIFIER_08,
	CPT.CPT_09,
	CPT.CPT_MODIFIER_09,
	CPT.CPT_10,
	CPT.CPT_MODIFIER_10,
	CPT.CPT_11,
	CPT.CPT_MODIFIER_11,
	CPT.CPT_12,
	CPT.CPT_MODIFIER_12,
	REF_PROV.ref_pract_name,
	ATN_PROV.attending_code,
	ATN_PROV.attending_npi,
	ATN_PROV.attending_name,
	ATN_PROV.attending_service,
	CHGS.operating_room_charges,
	CHGS.recovery_room_charges,
	CHGS.ancillary_charges,
	INS_POL.ins1_pol_no,
	INS_POL.ins2_pol_no,
	INS_POL.ins3_pol_no,
	REV_PVT.[170],
	REV_PVT.[171],
	REV_PVT.[172],
	REV_PVT.[173],
	REV_PVT.[174],
	REV_PVT.[219],
	REV_PVT.[270],
	REV_PVT.[272],
	REV_PVT.[274],
	REV_PVT.[275],
	REV_PVT.[276],
	REV_PVT.[278],
	REV_PVT.[279],
	REV_PVT.[387],
	REV_PVT.[390],
	REV_PVT.[391],
	REV_PVT.[399],
	REV_PVT.[636],
	REV_PVT.[760],
	REV_PVT.[761],
	REV_PVT.[762],
	REV_PVT.[769]
FROM #base_tbl AS BASE
LEFT OUTER JOIN #pt_bal_amt_tbl AS PT_BAL ON BASE.pt_id = PT_BAL.encounter_id
	AND BASE.unit_seq_no = PT_BAL.unit_seq_no
LEFT OUTER JOIN #pt_demos_tbl AS PTDEMOS ON BASE.pt_id = PTDEMOS.encounter_id
LEFT OUTER JOIN #dx_cd_pvt_tbl AS DX_PVT ON BASE.pt_id = DX_PVT.encounter_id
	AND BASE.unit_seq_no = DX_PVT.unit_seq_no
LEFT OUTER JOIN #proc_cd_tbl AS PROC_PVT ON BASE.pt_id = PROC_PVT.encounter_id
	AND BASE.unit_seq_no = PROC_PVT.unit_seq_no
LEFT OUTER JOIN #referring_provider_tbl AS REF_PROV ON BASE.pt_id = REF_PROV.pt_id
LEFT OUTER JOIN #attending_provider_tbl AS ATN_PROV ON BASE.encounter_id = ATN_PROV.encounter_id
	AND BASE.unit_seq_no = ATN_PROV.unit_seq_no
LEFT OUTER JOIN #charges_tbl AS CHGS ON BASE.pt_id = CHGS.encounter_id
	AND BASE.unit_seq_no = CHGS.unit_seq_no
LEFT OUTER JOIN #ins_policy_info_tbl AS INS_POL ON BASE.pt_id = INS_POL.encounter_id
	AND BASE.unit_seq_no = INS_POL.unit_seq_no
LEFT OUTER JOIN #rev_cd_pvt_tbl AS REV_PVT ON BASE.pt_id = REV_PVT.encounter_id
	AND BASE.unit_seq_no = REV_PVT.unit_seq_no
LEFT OUTER JOIN #cpt_cd_tbl AS CPT ON BASE.pt_id = CPT.pt_id
	AND BASE.unit_seq_no = CPT.unit_seq_no
ORDER BY BASE.med_rec_no,
 BASE.encounter_id;
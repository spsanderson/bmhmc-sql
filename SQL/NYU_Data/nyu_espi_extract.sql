/*
***********************************************************************
File: nyu_epsi_extract.sql

Input Parameters:
    None

Tables/Views:
    smsdss.dly_cen_occ_fct_v
    smsdss.bmh_plm_ptacct_v
    smsdss.pract_dim_v
    smsmir.pyr_plan
    Customer.Custom_DRG
    smsmir.dx_grp
    smsdss.adm-src_dim_v
    smsdss.pyr_dim_v
    smsmir.vst_rpt
    smsmir.sproc
    smsmir.actv
    smsdss.c_covid_extract_tbl

Creates Table:
    None

Functions:
    None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
    Get elements to help understand ED throughput

Revision History:

Date        Version     Description
----        ----        ----
2022-06-06  v1          Initial creation
***********************************************************************
*/

DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2020-09-01';
SET @END   = '2021-09-01';

SELECT PAV.Med_Rec_No,
	PAV.PtNo_Num,
	PAV.unit_seq_no,
	PAV.fc,
	PAV.Plm_Pt_Acct_Type,
	PAV.hosp_svc,
	HOSP_SVC.HOSP_SVC_NAME,
	PAV.tot_chg_amt,
	PAV.tot_adj_amt,
	PAV.Tot_Amt_Due,
	PAV.tot_pay_amt,
	[billed_drg] = PYR_PLAN.bl_drg_no,
	[drg_no] = PAV.drg_no,
	[drg_weight] = PAV.drg_cost_weight,
	APR_DRG.APRDRGNO,
	APR_DRG.SEVERITY_OF_ILLNESS,
	APR_DRG.RISK_OF_MORTALITY,
	[prin_cpt] = CASE 
		WHEN PAV.Plm_Pt_Acct_Type != 'I'
			THEN PAV.Prin_Hcpc_Proc_Cd
		ELSE PAV.Prin_Icd10_Proc_Cd
		END,
	PAV.vst_start_dtime AS [admit_date_time],
	pav.vst_end_dtime AS [discharge_date_time],
	pav.Days_Stay,
	PAV.prin_dx_cd,
	DX.dx_cd AS [secondary_dx],
	[location_of_service] = CASE 
		WHEN PAV.hosp_svc = 'DMS'
			THEN 'DIALYSIS_MAIN_STREET'
		WHEN PAV.hosp_svc = 'WCC'
			THEN 'WOUND_CARE_PATCHOGUE'
		WHEN PAV.hosp_svc = 'WCH'
			THEN 'WOUND_CARE_HAUPPAUGE'
		ELSE 'MAIN_CAMPUS'
		END,
	[ATTENDING_MD] = UPPER(ATTENDING.pract_rpt_name),
	[ATTENDING_NPI] = ATTENDING.npi_no,
	[ATTENDING_ID_NO] = PAV.ATN_DR_NO,
	[ATTENDING_SPECIALTY] = ATTENDING.spclty_desc,
	[ADMITTING_MD] = UPPER(ADMITTING.PRACT_RPT_NAME),
	[ADMIT_SOURCE] = ADM_SRC.adm_src_desc,
	PAV.Pt_Zip_Cd,
	PAV.Pt_Age,
	PAV.Pt_Sex,
	CASE 
		WHEN PAV.Pt_Race = 'W'
			THEN 'WHITE' -- 01
		WHEN PAV.Pt_Race = 'B'
			THEN 'BLACK OR AFRICAN AMERICAN' -- BLACK OR AFRICAN AMERICAN
		WHEN PAV.Pt_Race = 'I'
			THEN 'NATIVE AMERICAN OR ALASKAN NATIVE' -- NATIVE AMERICAN OR ALASKAN NATIVE
		WHEN PAV.Pt_Race = 'A'
			THEN 'ASIAN' -- ASIAN
		WHEN PAV.Pt_Race IN ('H', 'O')
			THEN 'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER' -- NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER
		WHEN PAV.Pt_Race IN ('?', 'U')
			THEN 'OTHER' -- OTHER RACE
		WHEN PAV.Pt_Race IS NULL
			THEN 'UNKNOWN' -- UNKNOWN
		END AS RACE,
	[PAYER_1] = PAV.Pyr1_Co_Plan_Cd,
	PAYER.pyr_name,
	PAYER.pyr_group2,
	[admit_status] = CASE 
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
	[DISPOSITION] = CASE 
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
	VST.ward_cd,
	SPROC.proc_cd,
	[PRINCIPAL_PROCEDURALIST] = UPPER(SPROC_DOC.pract_rpt_name),
	[PRINCIPAL_PROCEDURALIST_ID] = SPROC_DOC.src_pract_no,
	[PRINCIPAL_PROCEDURALIST_NPI] = SPROC_DOC.npi_no,
	[OR_INDICATOR] = CASE 
		WHEN OR_FLAG.PT_ID IS NULL
			THEN 0
		ELSE 1
		END,
	[icu_los] = ISNULL(ICU.LOS, 0),
	[ICU_ADMIT_DATE] = ICU_DATE.icu_adm_date,
	[has_pt_tested_covid_pos] = COVID_IND.Pos_MRN
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.hosp_svc_dim_v AS HOSP_SVC ON PAV.hosp_svc = HOSP_SVC.HOSP_SVC
	AND PAV.Regn_Hosp = HOSP_SVC.ORGZ_CD
INNER JOIN smsmir.pyr_plan AS PYR_PLAN ON PAV.PT_NO = PYR_PLAN.pt_id
	AND PAV.unit_seq_no = PYR_PLAN.unit_seq_no
	AND PAV.Pyr1_Co_Plan_Cd = PYR_PLAN.pyr_cd
LEFT OUTER JOIN Customer.Custom_DRG AS APR_DRG ON PAV.PtNo_Num = APR_DRG.PATIENT#
LEFT OUTER JOIN smsmir.dx_grp AS DX ON PAV.Pt_No = DX.pt_id
	AND PAV.unit_seq_no = DX.unit_seq_no
	AND LEFT(DX.dx_cd_type, 2) = 'DF'
	AND DX.dx_cd_prio = '02'
LEFT OUTER JOIN smsdss.pract_dim_v AS ATTENDING ON PAV.Atn_Dr_No = ATTENDING.src_pract_no
	AND PAV.Regn_Hosp = ATTENDING.orgz_cd
LEFT OUTER JOIN smsdss.pract_dim_v AS ADMITTING ON PAV.Adm_Dr_No = ADMITTING.src_pract_no
	AND PAV.Regn_Hosp = ADMITTING.orgz_cd
LEFT OUTER JOIN smsdss.adm_src_dim_v AS ADM_SRC ON PAV.Adm_Source = ADM_SRC.SRC_adm_src
	AND PAV.Regn_Hosp = ADM_SRC.orgz_cd
LEFT OUTER JOIN smsdss.pyr_dim_v AS PAYER ON PAV.Pyr1_Co_Plan_Cd = PAYER.src_pyr_cd
	AND PAV.Regn_Hosp = PAYER.orgz_cd
LEFT OUTER JOIN smsmir.vst_rpt AS VST ON CAST(PAV.PtNo_Num AS VARCHAR) = VST.acct_no
	AND PAV.unit_seq_no = VST.unit_seq_no
LEFT OUTER JOIN smsmir.sproc AS SPROC ON PAV.PT_NO = SPROC.pt_id
	AND PAV.unit_seq_no = SPROC.unit_seq_no
	AND SPROC.proc_cd_prio = '01'
	AND SPROC.proc_cd_type != 'C'
LEFT OUTER JOIN smsdss.pract_dim_v AS SPROC_DOC ON SPROC.resp_pty_cd = SPROC_DOC.src_pract_no
	AND SPROC.orgz_cd = SPROC_DOC.orgz_cd
LEFT OUTER JOIN (
	SELECT A.pt_id,
		A.unit_seq_no
	FROM smsmir.actv AS A
	WHERE A.actv_cd IN ('01800010', '00800011', '00800029', '00800037', '00800045', '00800052', '00800060', '00800078', '00800086', '00800094', '00800102', '00800110', '00800128', '00800136', '00800144', '00800151', '00800169', '00800177', '00800185', '00800193', '00800201', '00800219', '00800227', '00800235', '00800243', '00800250', '00800268', '00800276', '00800284', '00800292', '00800300', '00800318', '00800326')
	GROUP BY A.pt_id,
		A.unit_seq_no
	HAVING SUM(A.actv_tot_qty) > 0
	) AS OR_FLAG ON PAV.PT_NO = OR_FLAG.PT_ID
	AND PAV.unit_seq_no = OR_FLAG.UNIT_SEQ_NO
-- GET ICU TIME (MICU, SICU, CCU)
LEFT OUTER JOIN (
	SELECT pt_id,
		SUM(tot_cen) AS [LOS]
	FROM smsdss.dly_cen_occ_fct_v
	WHERE nurs_sta IN ('micu', 'sicu', 'ccu')
	GROUP BY pt_id
	) AS ICU ON PAV.Pt_No = ICU.pt_id
-- GET ICU ADMIT_DATE
LEFT OUTER JOIN (
	SELECT pt_id,
		MIN(cen_date) AS icu_adm_date
	FROM smsdss.dly_cen_occ_fct_v
	WHERE nurs_sta IN ('micu', 'sicu', 'ccu')
	GROUP BY pt_id
	) AS ICU_DATE ON PAV.Pt_No = ICU_DATE.pt_id
LEFT OUTER JOIN (
	SELECT PTNO_NUM,
		Pos_MRN
	FROM smsdss.c_covid_extract_tbl
	GROUP BY PTNO_NUM,
		Pos_MRN
	) AS COVID_IND ON PAV.PtNo_Num = COVID_IND.PTNO_NUM
WHERE PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) != '2'
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.prin_dx_cd IS NOT NULL
	AND PAV.Dsch_Date >= @START
	AND PAV.Dsch_Date < @END;

--AND PAV.PtNo_Num = '14930689';

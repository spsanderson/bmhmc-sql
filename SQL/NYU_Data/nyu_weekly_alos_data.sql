/*
***********************************************************************
File: nyu_weekly_alos_data.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
    smsdss.pract_dim_v
    smsdss.hosp_svc_dim_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Grab previous weeks discharges to get los data by provider and 
    hospital service line

Revision History:
Date		Version		Description
----		----		----
2021-10-27	v1			Initial Creation
2021-10-28	v2			Changes:
						1.	Running a weekly report rolling 12 months up to the date of the report (or day before)
							We will generally exclude the most recent two weeks on the front end but may be helpful 
							to have the data for some things
						2.	Adding a few fields: 
								Physician department, 
								service line, 
								DRG, 
								DRG Description,
								DRG Category
								ICD10 Primary diagnosis,
								pyr_group2,
								ward_cd,
								vst_end_dtime,
								vst_start_dtime
2021-11-30	v3			3. Add preadm_pt_id from smsmir.mir_pms_case
2021-12-02	v4			4. Fix discharge date time column for straight 
							OBV patients
2021-12-20	v5			5. Per discussion with Mike and Will, add CMI
2022-01-03	v6			6. Per discussion with Mike and Will, start_date is 2020-01-01
2022-01-14	v7			7. Add Admit Status Emergency, Truama, Newborn etc
2022-02-10	v8			8. Add column [is_readmit] binary
2022-04-28	v9			9. Add principal_procedure_code and description
2022-05-12	v10			10. Add patient age at admit and pt_birthdate per Matt G.
***********************************************************************
*/

DECLARE @THISDATE DATE;
DECLARE @START    DATE;
DECLARE @END      DATE;

SET @THISDATE = GETDATE();
SET @START    = DATEADD(WEEK, - 53, DATEADD(WEEK, DATEDIFF(WEEK, 0, @THISDATE), - 1));
SET @END      = DATEADD(WEEK, DATEDIFF(WEEK, 0, @THISDATE), - 1);

SELECT PAV.Med_Rec_No AS [mrn],
	PAV.PtNo_Num,
	PMS.preadm_pt_id,
	CAST(PAV.ADM_DATE AS DATE) AS [adm_date],
	CAST(PAV.DSCH_DATE AS DATE) AS [dsch_date],
	CAST(PAV.VST_START_DTIME AS smalldatetime) AS [vst_start_dtime],
	[vst_end_dtime] = CASE
		WHEN PAV.hosp_svc = 'OBV'
			THEN CAST(COALESCE(OBV.DSCH_STRT_DTIME, PAV.VST_START_DTIME) AS smalldatetime)
		ELSE CAST(PAV.VST_END_DTIME AS smalldatetime)
		END,
	PAV.Adm_Source,
	--CAST(PAV.VST_END_DTIME AS smalldatetime) AS [vst_end_dtime],
	CAST(PAV.DAYS_STAY AS INT) AS [LOS],
	PAV.dsch_disp,
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
	UPPER(PDV.pract_rpt_name) AS [Attending_Provider],
	UPPER(PDV.med_staff_dept) AS [Attending_Med_Staff_Dept],
	UPPER(pdv.spclty_desc) AS [Attending_Specialty],
	[hospitalist_private_flag] = CASE 
		WHEN PDV.src_spclty_cd = 'HOSIM'
			THEN 'Hospitalist'
		ELSE 'Private'
		END,
	PAV.hosp_svc,
	HS.hosp_svc_name,
	SVC_LINE.LIHN_Svc_Line AS [Service_Line],
	PAV.drg_no,
	DRG.drg_name,
	DRG.MDCVal,
	DRG.MDCDescText,
	PAV.prin_dx_cd,
	PYR.pyr_group2 AS [payor_grouping],
	VST.ward_cd AS [discharge_unit],
	PAV.drg_cost_weight,
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
	[is_readmit] = CASE
		WHEN RA.READMIT IS NOT NULL
			THEN 1
		ELSE 0
		END,
	[principal_proc_cd] = CASE
		WHEN PAV.Plm_Pt_Acct_Type = 'I'
			THEN PAV.Prin_Icd10_Proc_Cd
		ELSE PAV.Prin_Hcpc_Proc_Cd
		END,
	[principal_proc_cd_desc] = PROC_DESC.alt_clasf_desc,
	pav.pt_age,
	CAST(pav.pt_birthdate AS DATE) AS [pt_birthdate]
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
LEFT OUTER JOIN SMSDSS.pract_dim_v AS PDV ON PAV.Atn_Dr_No = PDV.src_pract_no
	AND PAV.Regn_Hosp = PDV.orgz_cd
LEFT OUTER JOIN SMSDSS.hosp_svc_dim_v AS HS ON PAV.hosp_svc = HS.hosp_svc
	AND PAV.Regn_Hosp = HS.orgz_cd
LEFT OUTER JOIN SMSDSS.c_LIHN_Svc_Line_Tbl AS SVC_LINE ON PAV.PtNo_Num = SVC_LINE.Encounter
LEFT OUTER JOIN SMSDSS.drg_dim_v AS DRG ON PAV.drg_no = DRG.drg_no
	AND DRG.drg_vers = 'MS-V25'
LEFT OUTER JOIN smsdss.pyr_dim_v AS PYR ON PAV.Pyr1_Co_Plan_Cd = PYR.src_pyr_cd
	AND PAV.Regn_Hosp = PYR.orgz_cd
LEFT OUTER JOIN smsmir.vst_rpt AS VST ON PAV.Pt_No = VST.pt_id
LEFT OUTER JOIN smsmir.mir_pms_case AS PMS ON CAST(PAV.PtNo_Num AS INT) = CAST(PMS.episode_no AS INT)
LEFT OUTER JOIN smsdss.c_obv_Comb_1 AS OBV ON PAV.PtNo_Num = OBV.pt_id
-- Get info on present accout, is it a readmit
LEFT OUTER JOIN [smsdss].[vReadmits] AS RA ON PAV.PtNo_Num = RA.READMIT
	AND RA.INTERIM IS NOT NULL
	AND RA.INTERIM <= 30
-- PROC_CD_DESC
LEFT OUTER JOIN smsdss.proc_dim_v AS PROC_DESC ON PAV.proc_cd = PROC_DESC.proc_cd
WHERE PAV.DSCH_DATE >= '2020-01-01' --@START
	AND PAV.Dsch_Date < @END
	AND LEFT(PAV.PTNO_NUM, 1) != '2'
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.tot_chg_amt > 0
	AND (
		PAV.Plm_Pt_Acct_Type = 'I'
		OR
		PAV.hosp_svc = 'OBV'
	)
ORDER BY PAV.Dsch_Date
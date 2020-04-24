USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[BMH_PLM_PtAcct_V]    Script Date: 7/27/2017 8:54:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [smsdss].[BMH_PLM_PtAcct_V]
AS
SELECT smsmir.pt.id_col AS Pt_Key,
	smsmir.vst.id_col AS Bl_Unit_Key,
	smsmir.vst.orgz_cd AS Regn_Hosp,
	smsmir.vst.vst_type_cd AS Plm_Pt_Acct_Type,
	smsmir.vst.pt_sts_cd AS Plm_Pt_Sub_Type,
	smsmir.vst.pt_id AS Pt_No,
	CAST(smsmir.vst.Pt_Id AS BIGINT) AS PtNo_Num,
	smsmir.pt.gender_cd AS Pt_Sex,
	smsmir.vst.infant_age,
	smsmir.vst.vst_postal_cd AS Pt_Zip_Cd,
	smsmir.pt.marital_sts AS Pt_Marital_Sts,
	LTRIM(RTRIM(smsmir.vst.vst_med_rec_no)) AS Med_Rec_No,
	smsmir.vst.fc,
	smsmir.vst.pt_type,
	smsmir.vst.hosp_svc,
	smsmir.vst.vst_start_date AS Adm_Date,
	smsmir.vst.vst_end_date AS Dsch_Date,
	smsmir.vst.vst_end_dtime AS Dsch_DTime,
	smsmir.pt.birth_date AS Pt_Birthdate,
	smsmir.vst.adm_pract_no AS Adm_Dr_No,
	smsmir.vst.prim_pract_no AS Atn_Dr_No,
	smsmir.pt.race_cd AS Pt_Race,
	smsmir.pt.religion_cd AS Pt_Religion,
	smsmir.vst_ext.acc_type,
	smsmir.vst.adm_prio,
	smsmir.vst.adm_src AS Adm_Source,
	smsmir.vst.dsch_disp,
	smsmir.vst.drg_no,
	smsmir.vst.mdc,
	smsmir.vst.prin_dx_cd_schm,
	smsmir.vst.prin_dx_cd,
	smsmir.vst.prin_dx_icd9_cd,
	smsmir.vst.prin_dx_icd10_cd,
	smsmir.vst.proc_cd,
	smsmir.vst.proc_icd9_cd AS Prin_Icd9_Proc_Cd,
	smsmir.vst.proc_icd10_cd AS Prin_Icd10_Proc_Cd,
	smsmir.vst.hcpcs_proc_cd AS Prin_Hcpc_Proc_Cd,
	smsmir.acct.pyr2_cd AS Pyr2_Co_Plan_Cd,
	smsmir.acct.pyr3_cd AS Pyr3_Co_Plan_Cd,
	smsmir.acct.pyr4_cd AS Pyr4_Co_Plan_Cd,
	smsmir.vst.no_of_consults,
	smsmir.vst.len_of_stay AS Days_Stay,
	smsmir.acct.tot_chg_amt,
	smsmir.acct.tot_pay_amt,
	smsmir.acct.tot_adj_amt,
	smsmir.acct.reimb_amt,
	smsmir.acct.tot_bal_amt AS Tot_Amt_Due,
	smsmir.vst_ext.tot_cost1,
	smsmir.vst_ext.tot_cost2,
	smsmir.vst.ref_pract_no AS Ref_Dr_No,
	smsmir.vst.from_file_ind,
	DATEDIFF(yyyy, smsmir.pt.birth_date, smsmir.vst.vst_start_date) AS Pt_Age,
	smsmir.pt.rpt_name AS Pt_Name,
	smsmir.pt.nhs_id_no AS Pt_SSA_No,
	smsmir.vst.vst_end_dtime,
	smsmir.vst.vst_start_dtime,
	smsmir.vst.drg_outl_ind,
	smsmir.vst.pt_id_start_dtime,
	smsmir.vst.unit_seq_no,
	smsmir.vst_ext.drg_cost_weight,
	smsmir.vst.preadm_dtime,
	smsmir.vst.vst_cre_dtime,
	ISNULL(smsmir.vst.prim_pyr_cd, '*') AS Pyr1_Co_Plan_Cd,
	--               smsmir.vst.prim_pyr_cd as Pyr1_Co_Plan_Cd,
	smsmir.acct.last_pay_date,
	smsmir.acct.bd_wo_date,
	smsmir.acct.Alt_Bd_WO_Amt,
	User_Pyr1_Cat = (
		SELECT CASE 
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'A'
					THEN 'AAA'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'B'
					THEN 'BBB'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'C'
					THEN 'CCC'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'D'
					THEN 'DDD'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'E'
					THEN 'EEE'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'I'
					THEN 'III'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'J'
					THEN 'JJJ'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'K'
					THEN 'KKK'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'L'
					THEN 'LLL'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'M'
					THEN 'BBB'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'N'
					THEN 'NNN'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'P'
					THEN 'MIS'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'S'
					THEN 'BBB'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'W'
					THEN 'WWW'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'X'
					THEN 'XXX'
				WHEN LTRIM(RTRIM(LEFT(smsmir.vst.prim_pyr_cd, 1))) = 'Z'
					THEN 'ZZZ'
				WHEN smsmir.vst.prim_pyr_cd IS NULL
					THEN 'MIS'
				ELSE '???'
				END
		),
	DschInPt = (
		CASE 
			WHEN LEFT(smsmir.vst.pt_id, 5) IN ('00001')
				THEN 1
			ELSE 0
			END
		),
	DschDay = DATEPART(dd, smsmir.vst.vst_end_date),
	DschMonth = MONTH(smsmir.vst.vst_end_date),
	smsmir.pt.race_cd,
	ED_Adm = (
		CASE 
			WHEN RIGHT(LTRIM(RTRIM(smsmir.vst.Pt_Id)), 8) IN (
					SELECT g.episode_no
					FROM smsdss.BMH_ED_Admitted_Pts_V g
					)
				THEN 1
			ELSE 0
			END
		),
	smsmir.Acct.Last_Ins_Bl_Dtime AS Last_Billed,
	smsmir.acct.Orig_Fc
FROM smsmir.vst
INNER JOIN smsmir.acct ON smsmir.vst.pt_id = smsmir.acct.pt_id
	AND smsmir.vst.pt_id_start_dtime = smsmir.acct.pt_id_start_dtime
	AND smsmir.vst.src_sys_id = smsmir.acct.src_sys_id
	AND smsmir.vst.from_file_ind = smsmir.acct.from_file_ind
	AND smsmir.vst.orgz_cd = smsmir.acct.orgz_cd
	AND smsmir.vst.acct_no = smsmir.acct.acct_no
	AND smsmir.vst.unit_seq_no = smsmir.acct.unit_seq_no
INNER JOIN smsmir.vst_ext ON smsmir.vst.episode_no = smsmir.vst_ext.episode_no
	AND smsmir.vst.from_file_ind = smsmir.vst_ext.from_file_ind
	AND smsmir.vst.orgz_cd = smsmir.vst_ext.orgz_cd
	AND smsmir.vst.pt_id = smsmir.vst_ext.pt_id
	AND smsmir.vst.pt_id_start_dtime = smsmir.vst_ext.pt_id_start_dtime
	AND smsmir.vst.src_sys_id = smsmir.vst_ext.src_sys_id
	AND smsmir.vst.unit_seq_no = smsmir.vst_ext.unit_seq_no
	AND smsmir.vst.vst_id = smsmir.vst_ext.vst_id
INNER JOIN smsmir.pt ON smsmir.vst.pt_id = smsmir.pt.pt_id
	AND smsmir.vst.pt_id_start_dtime = smsmir.pt.pt_id_start_dtime
	AND smsmir.vst.src_sys_id = smsmir.pt.src_sys_id
	AND smsmir.vst.from_file_ind = smsmir.pt.from_file_ind
GO





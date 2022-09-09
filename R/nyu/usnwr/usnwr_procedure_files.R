# Lib Load ----
library(DBI)
library(tidyverse)
library(LICHospitalR)
library(writexl)
library(lubridate)
library(odbc)

# DB Connection ----
db_con <- db_connect()

table_df <- dbGetQuery(
  conn = db_con,
  statement = paste0(
    "
    WITH CTE AS (
      SELECT schema_name(t.schema_id) AS schema_name,
      		t.name AS table_name,
      		[full_name] = cast(SCHEMA_NAME(t.schema_id) as varchar) + '.' + t.name
      	FROM sys.tables t
      	WHERE t.name LIKE 'c_nyu_usnwr_%'
      	and t.name not in (
          'c_nyu_usnwr_condition_accounts_tbl',
          'c_nyu_usnwr_readmits_tbl',
          'c_nyu_usnwr_accounts_tbl',
        	'c_nyu_usnwr_spinal_fusion_proc_exclusion_tbl'
        )
    )
    
    SELECT full_name AS usnwr_procedure_table
    FROM CTE 
    	ORDER BY table_name,
    		schema_name;
    "
  )
) %>%
  as_tibble()

db_disconnect(.connection = db_con)

# Build Query ----

query_tbl <- table_df %>%
  mutate(usnwr_procedure_table = as.factor(usnwr_procedure_table)) %>%
  mutate(
    q = paste0(
      "SELECT [usnwr_group] = BASE_POP.usnwr_group_name,
    [medicare_id] = '',
	[patient_id] = PAV.Med_Rec_No,
	[encounter_number] = PAV.PtNo_Num,
	[empi] = '',
	[admission_date] = CAST(PAV.Adm_Date AS DATE),
	[admission_day] = '',
	[emergency_room_patient] = '',
	[admission_status] = CASE 
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
	[discharge_date] = CAST(PAV.Dsch_Date AS DATE),
	[discharge_day] = '',
	[discharge_status] = CASE 
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
	[age] = PAV.Pt_Age,
	[norm_nb] = '',
	[sex] = PAV.Pt_Sex,
	[race] = CASE 
		WHEN LTRIM(RTRIM(PAV.race_cd)) = 'I'
			THEN 'AMERICAN_INDIAN_ALASKIAN'
		WHEN LTRIM(RTRIM(PAV.race_cd)) = 'A'
			THEN 'ASIAN'
		WHEN LTRIM(RTRIM(PAV.race_cd)) = 'S'
			THEN 'ASIAN_INDIAN'
		WHEN LTRIM(RTRIM(PAV.race_cd)) = 'B'
			THEN 'BLACK_AFRICAN_AMERICAN'
		WHEN LTRIM(RTRIM(PAV.race_cd)) = 'N'
			THEN 'HAWAIIAN_PACIFIC_ISLANDER'
		WHEN LTRIM(RTRIM(PAV.race_cd)) = 'W'
			THEN 'WHITE'
		WHEN LTRIM(RTRIM(PAV.race_cd)) = 'O'
			THEN 'OTHER'
		END,
	[ethnicity] = CASE 
		WHEN PAV.Pt_Race = 'H'
			THEN 'SPANISH_HISPANIC_ORIGIN'
		WHEN PAV.Pt_Race IN ('W', 'B', 'I', 'A')
			THEN 'NOR_SPANISH_HISPANIC'
		ELSE 'UKNOWN'
		END,
	[icu_days_obs_from_icu_file] = '',
	[early_death] = '',
	[base_ms_drg] = '',
	[ms_drg] = PAV.drg_no,
	[serviceline_msdrg] = '',
	[ms_drg_weight] = PAV.drg_cost_weight,
	[admit_apr_drg] = '',
	[vizient_service_line] = '',
	[vizient_sub_service_line] = '',
	[admit_severity_of_illness] = '',
	[admit_risk_of_mortality] = '',
	[prin_proc_md] = UPPER(PRIN_PROC_MD.pract_rpt_name),
	[discharge_md] = UPPER(DSCH_MD.pract_rpt_name),
	[discharge_md_specialty] = DSCH_MD.spclty_desc,
	[primary_payer_category] = PRIM_PYR.pyr_cd_desc,
	[secondary_payer_category] = SEC_PYR.pyr_cd_desc,
	ISNULL(REPLACE(DX_CDS.[01], '.', ''), '') AS [DX_CD_01],
	ISNULL(REPLACE(DX_CDS.[02], '.', ''), '') AS [DX_CD_02],
	ISNULL(REPLACE(DX_CDS.[03], '.', ''), '') AS [DX_CD_03],
	ISNULL(REPLACE(DX_CDS.[04], '.', ''), '') AS [DX_CD_04],
	ISNULL(REPLACE(DX_CDS.[05], '.', ''), '') AS [DX_CD_05],
	ISNULL(REPLACE(DX_CDS.[06], '.', ''), '') AS [DX_CD_06],
	ISNULL(REPLACE(DX_CDS.[07], '.', ''), '') AS [DX_CD_07],
	ISNULL(REPLACE(DX_CDS.[08], '.', ''), '') AS [DX_CD_08],
	ISNULL(REPLACE(DX_CDS.[09], '.', ''), '') AS [DX_CD_09],
	ISNULL(REPLACE(DX_CDS.[10], '.', ''), '') AS [DX_CD_10],
	ISNULL(REPLACE(DX_CDS.[11], '.', ''), '') AS [DX_CD_11],
	ISNULL(REPLACE(DX_CDS.[12], '.', ''), '') AS [DX_CD_12],
	ISNULL(REPLACE(DX_CDS.[13], '.', ''), '') AS [DX_CD_13],
	ISNULL(REPLACE(DX_CDS.[14], '.', ''), '') AS [DX_CD_14],
	ISNULL(REPLACE(DX_CDS.[15], '.', ''), '') AS [DX_CD_15],
	ISNULL(REPLACE(DX_CDS.[16], '.', ''), '') AS [DX_CD_16],
	ISNULL(REPLACE(DX_CDS.[17], '.', ''), '') AS [DX_CD_17],
	ISNULL(REPLACE(DX_CDS.[18], '.', ''), '') AS [DX_CD_18],
	ISNULL(REPLACE(DX_CDS.[19], '.', ''), '') AS [DX_CD_19],
	ISNULL(REPLACE(DX_CDS.[20], '.', ''), '') AS [DX_CD_20],
	ISNULL(REPLACE(DX_CDS.[21], '.', ''), '') AS [DX_CD_21],
	ISNULL(REPLACE(DX_CDS.[22], '.', ''), '') AS [DX_CD_22],
	ISNULL(REPLACE(DX_CDS.[23], '.', ''), '') AS [DX_CD_23],
	ISNULL(REPLACE(DX_CDS.[24], '.', ''), '') AS [DX_CD_24],
	ISNULL(REPLACE(DX_CDS.[25], '.', ''), '') AS [DX_CD_25],
	ISNULL(REPLACE(DX_CDS.[26], '.', ''), '') AS [DX_CD_26],
	ISNULL(REPLACE(DX_CDS.[27], '.', ''), '') AS [DX_CD_27],
	ISNULL(REPLACE(DX_CDS.[28], '.', ''), '') AS [DX_CD_28],
	ISNULL(REPLACE(DX_CDS.[29], '.', ''), '') AS [DX_CD_29],
	ISNULL(REPLACE(DX_CDS.[30], '.', ''), '') AS [DX_CD_30],
	ISNULL(REPLACE(DX_CDS.[31], '.', ''), '') AS [DX_CD_31],
	ISNULL(REPLACE(DX_CDS.[32], '.', ''), '') AS [DX_CD_32],
	ISNULL(REPLACE(DX_CDS.[33], '.', ''), '') AS [DX_CD_33],
	ISNULL(REPLACE(DX_CDS.[34], '.', ''), '') AS [DX_CD_34],
	ISNULL(REPLACE(DX_CDS.[35], '.', ''), '') AS [DX_CD_35],
	ISNULL(REPLACE(DX_CDS.[36], '.', ''), '') AS [DX_CD_36],
	ISNULL(REPLACE(DX_CDS.[37], '.', ''), '') AS [DX_CD_37],
	ISNULL(REPLACE(DX_CDS.[38], '.', ''), '') AS [DX_CD_38],
	ISNULL(REPLACE(DX_CDS.[39], '.', ''), '') AS [DX_CD_39],
	ISNULL(REPLACE(DX_CDS.[40], '.', ''), '') AS [DX_CD_40],
	ISNULL(REPLACE(DX_CDS.[41], '.', ''), '') AS [DX_CD_41],
	ISNULL(REPLACE(DX_CDS.[42], '.', ''), '') AS [DX_CD_42],
	ISNULL(REPLACE(DX_CDS.[43], '.', ''), '') AS [DX_CD_43],
	ISNULL(REPLACE(DX_CDS.[44], '.', ''), '') AS [DX_CD_44],
	ISNULL(REPLACE(DX_CDS.[45], '.', ''), '') AS [DX_CD_45],
	ISNULL(REPLACE(DX_CDS.[46], '.', ''), '') AS [DX_CD_46],
	ISNULL(REPLACE(DX_CDS.[47], '.', ''), '') AS [DX_CD_47],
	ISNULL(REPLACE(DX_CDS.[48], '.', ''), '') AS [DX_CD_48],
	ISNULL(REPLACE(DX_CDS.[49], '.', ''), '') AS [DX_CD_49],
	ISNULL(REPLACE(DX_CDS.[50], '.', ''), '') AS [DX_CD_50],
	ISNULL(REPLACE(DX_CDS.[51], '.', ''), '') AS [DX_CD_51],
	ISNULL(REPLACE(DX_CDS.[52], '.', ''), '') AS [DX_CD_52],
	ISNULL(REPLACE(DX_CDS.[53], '.', ''), '') AS [DX_CD_53],
	ISNULL(REPLACE(DX_CDS.[54], '.', ''), '') AS [DX_CD_54],
	ISNULL(REPLACE(DX_CDS.[55], '.', ''), '') AS [DX_CD_55],
	ISNULL(REPLACE(DX_CDS.[56], '.', ''), '') AS [DX_CD_56],
	ISNULL(REPLACE(DX_CDS.[57], '.', ''), '') AS [DX_CD_57],
	ISNULL(REPLACE(DX_CDS.[58], '.', ''), '') AS [DX_CD_58],
	ISNULL(REPLACE(DX_CDS.[59], '.', ''), '') AS [DX_CD_59],
	ISNULL(REPLACE(DX_CDS.[60], '.', ''), '') AS [DX_CD_60],
	ISNULL(REPLACE(DX_CDS.[61], '.', ''), '') AS [DX_CD_61],
	ISNULL(REPLACE(DX_CDS.[62], '.', ''), '') AS [DX_CD_62],
	ISNULL(REPLACE(DX_CDS.[63], '.', ''), '') AS [DX_CD_63],
	ISNULL(REPLACE(DX_CDS.[64], '.', ''), '') AS [DX_CD_64],
	ISNULL(REPLACE(DX_CDS.[65], '.', ''), '') AS [DX_CD_65],
	ISNULL(REPLACE(DX_CDS.[66], '.', ''), '') AS [DX_CD_66],
	ISNULL(REPLACE(DX_CDS.[67], '.', ''), '') AS [DX_CD_67],
	ISNULL(REPLACE(DX_CDS.[68], '.', ''), '') AS [DX_CD_68],
	ISNULL(REPLACE(DX_CDS.[69], '.', ''), '') AS [DX_CD_69],
	ISNULL(REPLACE(DX_CDS.[70], '.', ''), '') AS [DX_CD_70],
	ISNULL(REPLACE(DX_CDS.[71], '.', ''), '') AS [DX_CD_71],
	ISNULL(REPLACE(DX_CDS.[72], '.', ''), '') AS [DX_CD_72],
	ISNULL(REPLACE(DX_CDS.[73], '.', ''), '') AS [DX_CD_73],
	ISNULL(REPLACE(DX_CDS.[74], '.', ''), '') AS [DX_CD_74],
	ISNULL(REPLACE(DX_CDS.[75], '.', ''), '') AS [DX_CD_75],
	ISNULL(REPLACE(DX_CDS.[76], '.', ''), '') AS [DX_CD_76],
	ISNULL(REPLACE(DX_CDS.[77], '.', ''), '') AS [DX_CD_77],
	ISNULL(REPLACE(DX_CDS.[78], '.', ''), '') AS [DX_CD_78],
	ISNULL(REPLACE(DX_CDS.[79], '.', ''), '') AS [DX_CD_79],
	ISNULL(REPLACE(DX_CDS.[80], '.', ''), '') AS [DX_CD_80],
	ISNULL(REPLACE(DX_CDS.[81], '.', ''), '') AS [DX_CD_81],
	ISNULL(REPLACE(DX_CDS.[82], '.', ''), '') AS [DX_CD_82],
	ISNULL(REPLACE(DX_CDS.[83], '.', ''), '') AS [DX_CD_83],
	ISNULL(REPLACE(DX_CDS.[84], '.', ''), '') AS [DX_CD_84],
	ISNULL(REPLACE(DX_CDS.[85], '.', ''), '') AS [DX_CD_85],
	ISNULL(REPLACE(PROC_CDS.[01], '.', ''), '') AS [PROC_CD_01],
	ISNULL(REPLACE(PROC_CDS.[02], '.', ''), '') AS [PROC_CD_02],
	ISNULL(REPLACE(PROC_CDS.[03], '.', ''), '') AS [PROC_CD_03],
	ISNULL(REPLACE(PROC_CDS.[04], '.', ''), '') AS [PROC_CD_04],
	ISNULL(REPLACE(PROC_CDS.[05], '.', ''), '') AS [PROC_CD_05],
	ISNULL(REPLACE(PROC_CDS.[06], '.', ''), '') AS [PROC_CD_06],
	ISNULL(REPLACE(PROC_CDS.[07], '.', ''), '') AS [PROC_CD_07],
	ISNULL(REPLACE(PROC_CDS.[08], '.', ''), '') AS [PROC_CD_08],
	ISNULL(REPLACE(PROC_CDS.[09], '.', ''), '') AS [PROC_CD_09],
	ISNULL(REPLACE(PROC_CDS.[10], '.', ''), '') AS [PROC_CD_10],
	ISNULL(REPLACE(PROC_CDS.[11], '.', ''), '') AS [PROC_CD_11],
	ISNULL(REPLACE(PROC_CDS.[12], '.', ''), '') AS [PROC_CD_12],
	ISNULL(REPLACE(PROC_CDS.[13], '.', ''), '') AS [PROC_CD_13],
	ISNULL(REPLACE(PROC_CDS.[14], '.', ''), '') AS [PROC_CD_14],
	ISNULL(REPLACE(PROC_CDS.[15], '.', ''), '') AS [PROC_CD_15],
	ISNULL(REPLACE(PROC_CDS.[16], '.', ''), '') AS [PROC_CD_16],
	ISNULL(REPLACE(PROC_CDS.[17], '.', ''), '') AS [PROC_CD_17],
	ISNULL(REPLACE(PROC_CDS.[18], '.', ''), '') AS [PROC_CD_18],
	ISNULL(REPLACE(PROC_CDS.[19], '.', ''), '') AS [PROC_CD_19],
	ISNULL(REPLACE(PROC_CDS.[20], '.', ''), '') AS [PROC_CD_20],
	ISNULL(REPLACE(PROC_CDS.[21], '.', ''), '') AS [PROC_CD_21],
	ISNULL(REPLACE(PROC_CDS.[22], '.', ''), '') AS [PROC_CD_22],
	ISNULL(REPLACE(PROC_CDS.[23], '.', ''), '') AS [PROC_CD_23],
	ISNULL(REPLACE(PROC_CDS.[24], '.', ''), '') AS [PROC_CD_24],
	ISNULL(REPLACE(PROC_CDS.[25], '.', ''), '') AS [PROC_CD_25],
	ISNULL(REPLACE(PROC_CDS.[26], '.', ''), '') AS [PROC_CD_26],
	ISNULL(REPLACE(PROC_CDS.[27], '.', ''), '') AS [PROC_CD_27],
	ISNULL(REPLACE(PROC_CDS.[28], '.', ''), '') AS [PROC_CD_28],
	ISNULL(REPLACE(PROC_CDS.[29], '.', ''), '') AS [PROC_CD_29],
	ISNULL(REPLACE(PROC_CDS.[30], '.', ''), '') AS [PROC_CD_30],
	ISNULL(REPLACE(PROC_CDS.[31], '.', ''), '') AS [PROC_CD_31],
	ISNULL(REPLACE(PROC_CDS.[32], '.', ''), '') AS [PROC_CD_32],
	ISNULL(REPLACE(PROC_CDS.[33], '.', ''), '') AS [PROC_CD_33],
	ISNULL(REPLACE(PROC_CDS.[34], '.', ''), '') AS [PROC_CD_34],
	ISNULL(REPLACE(PROC_CDS.[35], '.', ''), '') AS [PROC_CD_35],
	ISNULL(REPLACE(PROC_CDS.[36], '.', ''), '') AS [PROC_CD_36],
	ISNULL(REPLACE(PROC_CDS.[37], '.', ''), '') AS [PROC_CD_37],
	ISNULL(REPLACE(PROC_CDS.[38], '.', ''), '') AS [PROC_CD_38],
	ISNULL(REPLACE(PROC_CDS.[39], '.', ''), '') AS [PROC_CD_39],
	ISNULL(REPLACE(PROC_CDS.[40], '.', ''), '') AS [PROC_CD_40],
	ISNULL(REPLACE(PROC_CDS.[41], '.', ''), '') AS [PROC_CD_41],
	ISNULL(REPLACE(PROC_CDS.[42], '.', ''), '') AS [PROC_CD_42],
	ISNULL(REPLACE(PROC_CDS.[43], '.', ''), '') AS [PROC_CD_43],
	ISNULL(REPLACE(PROC_CDS.[44], '.', ''), '') AS [PROC_CD_44],
	ISNULL(REPLACE(PROC_CDS.[45], '.', ''), '') AS [PROC_CD_45],
	ISNULL(REPLACE(PROC_CDS.[46], '.', ''), '') AS [PROC_CD_46],
	ISNULL(REPLACE(PROC_CDS.[47], '.', ''), '') AS [PROC_CD_47],
	ISNULL(REPLACE(PROC_CDS.[48], '.', ''), '') AS [PROC_CD_48],
	ISNULL(REPLACE(PROC_CDS.[49], '.', ''), '') AS [PROC_CD_49],
	ISNULL(REPLACE(PROC_CDS.[50], '.', ''), '') AS [PROC_CD_50],
	ISNULL(REPLACE(PROC_CDS.[51], '.', ''), '') AS [PROC_CD_51],
	ISNULL(REPLACE(PROC_CDS.[52], '.', ''), '') AS [PROC_CD_52],
	ISNULL(REPLACE(PROC_CDS.[53], '.', ''), '') AS [PROC_CD_53],
	ISNULL(REPLACE(PROC_CDS.[54], '.', ''), '') AS [PROC_CD_54],
	ISNULL(REPLACE(PROC_CDS.[55], '.', ''), '') AS [PROC_CD_55],
	ISNULL(REPLACE(PROC_CDS.[56], '.', ''), '') AS [PROC_CD_56],
	ISNULL(REPLACE(PROC_CDS.[57], '.', ''), '') AS [PROC_CD_57],
	ISNULL(REPLACE(PROC_CDS.[58], '.', ''), '') AS [PROC_CD_58],
	ISNULL(REPLACE(PROC_CDS.[59], '.', ''), '') AS [PROC_CD_59],
	ISNULL(REPLACE(PROC_CDS.[60], '.', ''), '') AS [PROC_CD_60],
	ISNULL(REPLACE(PROC_CDS.[61], '.', ''), '') AS [PROC_CD_61],
	ISNULL(REPLACE(PROC_CDS.[62], '.', ''), '') AS [PROC_CD_62],
	ISNULL(REPLACE(PROC_CDS.[63], '.', ''), '') AS [PROC_CD_63],
	ISNULL(REPLACE(PROC_CDS.[64], '.', ''), '') AS [PROC_CD_64],
	ISNULL(REPLACE(PROC_CDS.[65], '.', ''), '') AS [PROC_CD_65],
	ISNULL(REPLACE(PROC_CDS.[66], '.', ''), '') AS [PROC_CD_66],
	ISNULL(REPLACE(PROC_CDS.[67], '.', ''), '') AS [PROC_CD_67],
	ISNULL(REPLACE(PROC_CDS.[68], '.', ''), '') AS [PROC_CD_68],
	ISNULL(REPLACE(PROC_CDS.[69], '.', ''), '') AS [PROC_CD_69],
	ISNULL(REPLACE(PROC_CDS.[70], '.', ''), '') AS [PROC_CD_70],
	ISNULL(REPLACE(PROC_CDS.[71], '.', ''), '') AS [PROC_CD_71],
	ISNULL(REPLACE(PROC_CDS.[72], '.', ''), '') AS [PROC_CD_72],
	ISNULL(REPLACE(PROC_CDS.[73], '.', ''), '') AS [PROC_CD_73],
	ISNULL(REPLACE(PROC_CDS.[74], '.', ''), '') AS [PROC_CD_74],
	ISNULL(REPLACE(PROC_CDS.[75], '.', ''), '') AS [PROC_CD_75],
	ISNULL(REPLACE(PROC_CDS.[76], '.', ''), '') AS [PROC_CD_76],
	ISNULL(REPLACE(PROC_CDS.[77], '.', ''), '') AS [PROC_CD_77],
	ISNULL(REPLACE(PROC_CDS.[78], '.', ''), '') AS [PROC_CD_78],
	ISNULL(REPLACE(PROC_CDS.[79], '.', ''), '') AS [PROC_CD_79],
	ISNULL(REPLACE(PROC_CDS.[80], '.', ''), '') AS [PROC_CD_80],
	ISNULL(REPLACE(PROC_CDS.[81], '.', ''), '') AS [PROC_CD_81],
	ISNULL(REPLACE(PROC_CDS.[82], '.', ''), '') AS [PROC_CD_82],
	ISNULL(REPLACE(PROC_CDS.[83], '.', ''), '') AS [PROC_CD_83],
	ISNULL(REPLACE(PROC_CDS.[84], '.', ''), '') AS [PROC_CD_84],
	ISNULL(REPLACE(PROC_CDS.[85], '.', ''), '') AS [PROC_CD_85],
	[admit_source] = (
		SELECT ADMSRC.adm_src_desc
		FROM smsdss.adm_src_mstr AS ADMSRC
		WHERE ADMSRC.orgz_cd = PAV.Regn_Hosp
		AND LTRIM(RTRIM(ADMSRC.adm_src)) = LTRIM(RTRIM(PAV.Adm_Source))
		),
	BASE_POP.*
  FROM ",
  paste0(as.character(usnwr_procedure_table), " as BASE_POP"),
  "
  INNER JOIN smsdss.BMH_PLM_PtAcct_V AS PAV ON BASE_POP.MED_REC_NO = PAV.Med_Rec_No
	AND BASE_POP.ptno_num = PAV.PtNo_Num
LEFT OUTER JOIN smsdss.drg_dim_v AS DRG ON PAV.drg_no = DRG.DRG_NO
	AND DRG.drg_vers = 'MS-V25'
LEFT OUTER JOIN smsmir.sproc AS PRIN_PROC ON PAV.Pt_No = PRIN_PROC.pt_id
	AND PAV.unit_seq_no = PRIN_PROC.unit_seq_no
	AND PRIN_PROC.proc_cd_prio = '01'
	AND PRIN_PROC.proc_cd_type != 'C'
LEFT OUTER JOIN smsdss.pract_dim_v AS PRIN_PROC_MD ON PRIN_PROC.resp_pty_cd = PRIN_PROC_MD.src_pract_no
	AND PRIN_PROC.orgz_cd = PRIN_PROC_MD.orgz_cd
LEFT OUTER JOIN SMSDSS.pract_dim_v AS DSCH_MD ON PAV.Atn_Dr_No = DSCH_MD.src_pract_no
	AND PAV.Regn_Hosp = DSCH_MD.orgz_cd
LEFT OUTER JOIN SMSDSS.pyr_dim_v AS PRIM_PYR ON PAV.Pyr1_Co_Plan_Cd = PRIM_PYR.pyr_cd
	AND PAV.Regn_Hosp = PRIM_PYR.orgz_cd
LEFT OUTER JOIN smsdss.pyr_dim_v AS SEC_PYR ON PAV.Pyr2_Co_Plan_Cd = SEC_PYR.pyr_cd
	AND PAV.Regn_Hosp = SEC_PYR.orgz_cd
LEFT OUTER JOIN (
	SELECT PVT.*
	FROM (
		SELECT pt_id,
			unit_seq_no,
			dx_cd,
			dx_cd_prio
		FROM SMSMIR.dx_grp
		WHERE LEFT(DX_CD_TYPE, 2) = 'DF'
			AND dx_cd_prio < '85'
		) AS A
	PIVOT(MAX(DX_CD) FOR DX_CD_PRIO IN (\"01\",\"02\",\"03\",\"04\",\"05\",\"06\",\"07\",\"08\",\"09\",\"10\",\"11\",\"12\",\"13\",\"14\",\"15\",\"16\",\"17\",\"18\",\"19\",\"20\",\"21\",\"22\",\"23\",\"24\",\"25\",\"26\",\"27\",\"28\",\"29\",\"30\",\"31\",\"32\",\"33\",\"34\",\"35\",\"36\",\"37\",\"38\",\"39\",\"40\",\"41\",\"42\",\"43\",\"44\",\"45\",\"46\",\"47\",\"48\",\"49\",\"50\",\"51\",\"52\",\"53\",\"54\",\"55\",\"56\",\"57\",\"58\",\"59\",\"60\",\"61\",\"62\",\"63\",\"64\",\"65\",\"66\",\"67\",\"68\",\"69\",\"70\",\"71\",\"72\",\"73\",\"74\",\"75\",\"76\",\"77\",\"78\",\"79\",\"80\",\"81\",\"82\",\"83\",\"84\",\"85\")) AS PVT
	) AS DX_CDS ON PAV.Pt_No = DX_CDS.pt_id
	AND PAV.unit_seq_no = DX_CDS.unit_seq_no
LEFT OUTER JOIN (
	SELECT PVT.*
	FROM (
		SELECT pt_id,
			unit_seq_no,
			proc_cd,
			proc_cd_prio
		FROM SMSMIR.sproc
		WHERE proc_cd_type != 'C'
			AND proc_cd_prio < '85'
		) AS A
	PIVOT(MAX(PROC_CD) FOR PROC_CD_PRIO IN (\"01\",\"02\",\"03\",\"04\",\"05\",\"06\",\"07\",\"08\",\"09\",\"10\",\"11\",\"12\",\"13\",\"14\",\"15\",\"16\",\"17\",\"18\",\"19\",\"20\",\"21\",\"22\",\"23\",\"24\",\"25\",\"26\",\"27\",\"28\",\"29\",\"30\",\"31\",\"32\",\"33\",\"34\",\"35\",\"36\",\"37\",\"38\",\"39\",\"40\",\"41\",\"42\",\"43\",\"44\",\"45\",\"46\",\"47\",\"48\",\"49\",\"50\",\"51\",\"52\",\"53\",\"54\",\"55\",\"56\",\"57\",\"58\",\"59\",\"60\",\"61\",\"62\",\"63\",\"64\",\"65\",\"66\",\"67\",\"68\",\"69\",\"70\",\"71\",\"72\",\"73\",\"74\",\"75\",\"76\",\"77\",\"78\",\"79\",\"80\",\"81\",\"82\",\"83\",\"84\",\"85\")) AS PVT
	) AS PROC_CDS ON PAV.Pt_No = PROC_CDS.pt_id
	AND PAV.unit_seq_no = PROC_CDS.unit_seq_no"
    ) 
  )

query_list <- as.list(query_tbl$q)

res_list <- lapply(
  query_list,
  function(query_list){
    sqlStatement <- query_list
    dbGetQuery(db_con, sqlStatement)
  }
)

# DB Disconnect ----
db_disconnect(db_con)

# Clean File ----
res_list <- res_list %>%
  map(.f = ~ .x %>% mutate(across(.fns = as.character)) %>%
        mutate(across(.fns = str_squish)))

# Write File Out ----
## File Date ----
file_dtime <- Sys.time() %>%
  ymd_hms() %>%
  str_replace_all(
    pattern = "[- ]",
    replacement = "_"
  ) %>%
  str_replace_all(
    pattern = "[:]",
    replacement = ""
  )

## File Name ----
file_name <- paste0("usnwr_procedure_data_lich_rundate_", file_dtime, ".xlsx")

## File Path ----
file_path <- "P://NYU Requests//Revenue Cycle//Performance_Analytics//USNWR_SS//"

## File Path and Name ----
full_file_path <- paste0(file_path, file_name)

# Write File ----
res_list %>%
  map_df(as_tibble) %>% 
  select(-ends_with("_accounts_tblId")) %>%
  named_item_list(.grouping_var = usnwr_group) %>%
  write_xlsx(path = full_file_path)

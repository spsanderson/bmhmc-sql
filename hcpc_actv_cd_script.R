
# Lib load ----------------------------------------------------------------

pacman::p_load(
  "LICHospitalR"
  , "tidyverse"
  , "DBI"
  , "tidyquant"
  , "xlsx"
)


# CPT Data ----------------------------------------------------------------

db_con_obj <- db_connect()

query <- DBI::dbGetQuery(
  conn = db_con_obj
  , statement = paste0(
    "
    SELECT PAV.PtNo_Num,
        PAV.Prin_Hcpc_Proc_Cd,
    	PROC_CD.alt_clasf_desc,
        actv.actv_cd,
    	actv_dim.actv_name,
    	REV_CD.rev_cd, 
        actv.actv_tot_qty,
        actv.chg_tot_amt,
        actv_dim.actv_group,
        [distinct_flag] = CASE 
        	WHEN ROW_NUMBER() OVER (
        			PARTITION BY pav.ptno_num,
        			actv.actv_cd ORDER BY pav.ptno_num
        			) = 1
        		THEN 1
        	ELSE 0
        	END
    FROM smsdss.BMH_PLM_PtAcct_V AS pav
    LEFT OUTER JOIN smsmir.actv AS actv ON pav.pt_no = actv.pt_id
        AND pav.unit_seq_no = actv.unit_seq_no
        AND pav.from_file_ind = actv.from_file_ind
    INNER JOIN smsdss.actv_cd_dim_v AS actv_dim ON actv.actv_cd = actv_dim.actv_cd
        AND ACTV_DIM.actv_type_desc != 'STATISTIC'
    LEFT OUTER JOIN (
    	SELECT DISTINCT actv_cd
    	, rev_cd
    	FROM smsmir.mir_actv_proc_seg_xref
    	WHERE rev_cd IS NOT NULL
    ) AS REV_CD 
    ON ACTV.ACTV_CD = REV_CD.ACTV_cd
    LEFT OUTER JOIN SMSDSS.proc_dim_v AS PROC_CD
    ON PAV.Prin_Hcpc_Proc_Cd = PROC_CD.proc_cd
    WHERE DATEPART(YEAR, pav.Dsch_Date) = 2019
        AND pav.Plm_Pt_Acct_Type != 'I'
        AND pav.tot_chg_amt > 0
        AND LEFT(PAV.PTNO_NUM, 1) != '2'
        AND LEFT(PAV.PTNO_NUM, 4) != '1999'
        AND PAV.Prin_Hcpc_Proc_Cd IS NOT NULL
        AND PAV.Prin_Hcpc_Proc_Cd NOT IN (
        '19120',
        '29881',
        '43235',
        '43239',
        '45378',
        '45380',
        '45385',
        '47562',
        '49505',
        '55700',
        '62322',
        '64483',
        '66984',
        '70553',
        '72148',
        '76700',
        '62323'
        )
    ORDER BY pav.PtNo_Num
    "
  )
)

db_disconnect(.connection = db_con_obj)

# Manipulate - Clean ------------------------------------------------------

df_tbl <- query %>%
  as_tibble()

df_summary_tbl <- df_tbl %>%
  group_by(
    Prin_Hcpc_Proc_Cd
    , alt_clasf_desc
    , actv_cd
    , actv_name
    , rev_cd
  ) %>%
  summarise(
    visit_count    = sum(distinct_flag, na.rm = TRUE)
    , actv_tot_qty = sum(actv_tot_qty, na.rm = TRUE)
    , chg_tot_amt  = sum(chg_tot_amt, na.rm = TRUE)
    , unit_charge  = round(sum(chg_tot_amt / actv_tot_qty), 2)
  ) %>%
  ungroup() %>%
  filter(actv_tot_qty > 0) %>%
  set_names(
    "prin_hcpc_proc_cd"
    ,"hcpc_desc"
    ,"cdm_code"
    ,"cdm_desc"
    ,"rev_cd"
    ,"visit_count"
    ,"total_units"
    ,"total_charges"
    ,"unit_charge"
  )

list_of_dfs <- df_summary_tbl %>%
  group_by(prin_hcpc_proc_cd) %>%
  arrange(desc(visit_count)) %>%
  group_split(prin_hcpc_proc_cd)

names(list_of_dfs) <- list_of_dfs %>%
  map(~pull(.,prin_hcpc_proc_cd)) %>%
  map(~as.character(.)) %>%
  map(~unique(.))

list_of_dfs %>%
  writexl::write_xlsx(path = "S:/Global Finance/1 REVENUE CYCLE/CMS_PRICE_TRANSPARENCY/hcpcs_with_commonly_used_cmd_codes.xlsx")

df_summary_tbl %>%
  arrange(prin_hcpc_proc_cd, desc(visit_count)) %>%
  writexl::write_xlsx(path = "S:/Global Finance/1 REVENUE CYCLE/CMS_PRICE_TRANSPARENCY/all_other_hcpcs_with_commonly_used_cmd_codes.xlsx")


# DRG Data ----------------------------------------------------------------

db_con_obj <- db_connect()

drg <- DBI::dbGetQuery(
  conn = db_con_obj
  , statement = paste0(
    "
    SELECT PAV.PtNo_Num,
      PAV.drg_no,
    	DRG.drg_name,
        actv.actv_cd,
        actv_dim.actv_name,
        REV_CD.rev_cd, 
        actv.actv_tot_qty,
        actv.chg_tot_amt,
        actv_dim.actv_group,
        [distinct_flag] = CASE 
            WHEN ROW_NUMBER() OVER (
            		PARTITION BY pav.ptno_num,
            		actv.actv_cd ORDER BY pav.ptno_num
            		) = 1
            	THEN 1
            ELSE 0
            END
    FROM smsdss.BMH_PLM_PtAcct_V AS pav
    LEFT OUTER JOIN smsmir.actv AS actv ON pav.pt_no = actv.pt_id
        AND pav.unit_seq_no = actv.unit_seq_no
        AND pav.from_file_ind = actv.from_file_ind
    INNER JOIN smsdss.actv_cd_dim_v AS actv_dim ON actv.actv_cd = actv_dim.actv_cd
        AND ACTV_DIM.actv_type_desc != 'STATISTIC'
    LEFT OUTER JOIN (
        SELECT DISTINCT actv_cd
        , rev_cd
        FROM smsmir.mir_actv_proc_seg_xref
        WHERE rev_cd IS NOT NULL
    ) AS REV_CD 
    ON ACTV.ACTV_CD = REV_CD.ACTV_cd
    LEFT OUTER JOIN SMSDSS.drg_dim_v AS DRG
    ON PAV.drg_no = DRG.drg_no
    	AND DRG.drg_vers = 'MS-V25'
    WHERE DATEPART(YEAR, pav.Dsch_Date) = 2019
        AND pav.Plm_Pt_Acct_Type = 'I'
        AND pav.tot_chg_amt > 0
        AND LEFT(PAV.PTNO_NUM, 1) != '2'
        AND LEFT(PAV.PTNO_NUM, 4) != '1999'
        AND PAV.drg_no != '0'
    ORDER BY pav.PtNo_Num
    "
  )
)

db_disconnect(.connection = db_con_obj)

# DRG Manipulate ----------------------------------------------------------

drg_tbl <- drg %>%
  as_tibble()

drg_summary_tbl <- drg_tbl %>%
  group_by(
    drg_no
    , drg_name
    , actv_cd
    , actv_name
    , rev_cd
  ) %>%
  summarise(
    visit_count    = sum(distinct_flag, na.rm = TRUE)
    , actv_tot_qty = sum(actv_tot_qty, na.rm = TRUE)
    , chg_tot_amt  = sum(chg_tot_amt, na.rm = TRUE)
    , unit_charge  = round(sum(chg_tot_amt / actv_tot_qty), 2)
  ) %>%
  ungroup() %>%
  filter(actv_tot_qty > 0) %>%
  set_names(
    "drg_no"
    ,"drg_name"
    ,"cdm_code"
    ,"cdm_desc"
    ,"rev_cd"
    ,"visit_count"
    ,"total_units"
    ,"total_charges"
    ,"unit_charge"
  )

list_of_drg <- drg_summary_tbl %>%
  group_by(drg_no) %>%
  arrange(desc(visit_count)) %>%
  group_split(drg_no)

names(list_of_drg) <- list_of_drg %>%
  map(~pull(.,drg_no)) %>%
  map(~as.character(.)) %>%
  map(~unique(.))

drg_summary_tbl %>%
  arrange(drg_no, desc(visit_count)) %>%
  writexl::write_xlsx(path = "S:/Global Finance/1 REVENUE CYCLE/CMS_PRICE_TRANSPARENCY/drgs_with_commonly_used_cdm_codes.xlsx")


# Radiology Data ---------------------------------------------------------------


db_con_obj <- db_connect()

radiology <- DBI::dbGetQuery(
  conn = db_con_obj
  , statement = paste0(
    "
    SELECT SUBSTRING(a.pt_id, 5, 8) AS [pt_no],
  	SUBSTRING(a.Proc_Cd, 1, 5) as [proc_cd],
  	a.actv_cd,
  	a.actv_name,
  	a.Rev_Cd,
  	a.actv_tot_qty,
  	a.chg_tot_amt,
  	[distinct_flag] = CASE 
  		WHEN ROW_NUMBER() OVER (
  				PARTITION BY a.pt_id,
  				a.actv_cd ORDER BY a.pt_id
  				) = 1
  			THEN 1
  		ELSE 0
  		END
    FROM [smsdss].[c_ip_ub04_v_2] AS a
    INNER JOIN smsdss.bmh_plm_PTAcct_v AS b ON a.pt_id = b.pt_no
    	AND b.pt_type = 'u'
    	AND b.hosp_svc = 'opd'
    	AND b.tot_chg_amt > 0
    	AND left(b.ptno_num, 1) != '2'
    	AND left(b.ptno_num, 4) != '1999'
    	AND datepart(year, b.adm_date) = 2019
    ORDER BY a.pt_id
    "
  )
)

db_disconnect(.connection = db_con_obj)

# Radiology Manipulate ----------------------------------------------------


rad_tbl <- radiology %>%
  as_tibble() %>%
  janitor::clean_names()

rad_summary_tbl <- rad_tbl %>%
  group_by(
    proc_cd
    , actv_cd
    , actv_name
    , rev_cd
  ) %>%
  summarise(
    visit_count    = sum(distinct_flag, na.rm = TRUE)
    , actv_tot_qty = sum(actv_tot_qty, na.rm = TRUE)
    , chg_tot_amt  = sum(chg_tot_amt, na.rm = TRUE)
    , unit_charge  = round(sum(chg_tot_amt / actv_tot_qty), 2)
  ) %>%
  ungroup() %>%
  filter(actv_tot_qty > 0) %>%
  set_names(
    "proc_cd"
    ,"cdm_code"
    ,"cdm_desc"
    ,"rev_cd"
    ,"visit_count"
    ,"total_units"
    ,"total_charges"
    ,"unit_charge"
  ) 

list_of_rad <- rad_summary_tbl %>%
  filter(!is.na(proc_cd)) %>%
  group_by(proc_cd, .add = TRUE) %>%
  arrange(desc(visit_count)) %>%
  ungroup() %>%
  group_split(proc_cd)

names(list_of_rad) <- list_of_rad %>%
  map(~pull(.,proc_cd)) %>%
  map(~as.character(.)) %>%
  map(~unique(.))

rad_summary_tbl %>%
  arrange(proc_cd, desc(visit_count)) %>%
  writexl::write_xlsx(path = "S:/Global Finance/1 REVENUE CYCLE/CMS_PRICE_TRANSPARENCY/rad_with_commonly_used_cdm_codes.xlsx")

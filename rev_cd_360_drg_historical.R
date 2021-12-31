
# Lib load ----------------------------------------------------------------

pacman::p_load(
  "LICHospitalR"
  , "tidyverse"
  , "DBI"
  , "odbc"
  , "tidyquant"
  , "janitor"
)


# CPT Data ----------------------------------------------------------------

db_con_obj <- db_connect()

query <- DBI::dbGetQuery(
  conn = db_con_obj
  , statement = paste0(
    "
    SELECT SUM(1) OVER (
    		ORDER BY PTNO_NUM
    		) [RECORD],
    	PAV.PtNo_Num,
    	CASE 
    		WHEN PAV.Plm_Pt_Acct_Type = 'I'
    			THEN CAST(PAV.DRG_NO AS VARCHAR)
    		ELSE CAST(PAV.Prin_Hcpc_Proc_Cd AS VARCHAR)
    		END AS [DRG_OR_HCPC],
    	PAV.Plm_Pt_Acct_Type AS [IP_OP_Flag],
    	PAV.tot_chg_amt,
    	PDV.pyr_cd_desc,
    	CASE 
    		WHEN PAV.User_Pyr1_Cat IN ('AAA', 'ZZZ')
    			THEN PIP.tot_pymts_w_pip
    		ELSE PYRPLAN.tot_pay_amt
    		END AS [tot_primary_payor_payment],
    		ACTV.actv_cd,
    	ACTVDIM.actv_name,
    	ACTV.actv_tot_qty,
    	ACTV.chg_tot_amt
    FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
    LEFT OUTER JOIN SMSDSS.pyr_dim_v AS PDV ON PAV.PYR1_CO_PLAN_CD = PDV.SRC_PYR_CD
    	AND PAV.Regn_Hosp = PDV.ORGZ_cd
    LEFT OUTER JOIN SMSMIR.pyr_plan AS PYRPLAN ON PAV.PT_NO = PYRPLAN.pt_id
    	AND PAV.unit_seq_no = PYRPLAN.unit_seq_no
    	AND PAV.from_file_ind = PYRPLAN.from_file_ind
    	AND PAV.Pyr1_Co_Plan_Cd = PYRPLAN.pyr_cd
    LEFT OUTER JOIN SMSDSS.c_tot_pymts_w_pip_v AS PIP ON PAV.Pt_NO = PIP.pt_id
    	AND PAV.unit_seq_no = PIP.unit_seq_no
    	AND PAV.pt_id_start_dtime = PIP.pt_id_start_dtime
    INNER JOIN SMSMIR.actv AS ACTV
    ON PAV.PT_NO = ACTV.PT_ID
    	AND PAV.UNIT_SEQ_NO = ACTV.unit_seq_no
    	AND PAV.from_file_ind = ACTV.from_file_ind
    	AND ACTV.actv_cd IN (
    		SELECT DISTINCT actv_cd
    		FROM SMSMIR.mir_actv_proc_seg_xref
    		WHERE rev_cd = '360'
    	)
    LEFT OUTER JOIN SMSDSS.actv_cd_dim_v AS ACTVDIM
    ON ACTV.actv_cd = ACTVDIM.actv_cd
    WHERE DATEPART(YEAR, PAV.DSCH_DATE) = 2019
    	AND PAV.tot_chg_amt > 0
    	AND LEFT(PAV.PTNO_NUM, 1) != '2'
    	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
    "
  )
)

db_disconnect(.connection = db_con_obj)

# Manipulate - Clean ------------------------------------------------------

df_tbl <- query %>%
  as_tibble() %>%
  clean_names() %>%
  select(-pt_no_num)

df_summary_tbl <- df_tbl %>%
  group_by(
    record
    , drg_or_hcpc
    , ip_op_flag
    , tot_chg_amt
    , pyr_cd_desc
    , tot_primary_payor_payment
    , actv_cd
    , actv_name
  ) %>%
  summarise(
    actv_tot_qty  = sum(actv_tot_qty)
    , chg_tot_amt = sum(chg_tot_amt)
  ) %>%
  ungroup() %>%
  rename(
    "total_cdm_qty" = "actv_tot_qty"
    , "tot_cdm_chg" = "chg_tot_amt"
    ) %>%
  mutate(rev_cd = 360) %>%
  mutate_if(is.character, str_squish) %>%
  mutate(ip_op_flag = case_when(
    ip_op_flag == "I" ~ "Inpatient"
    , TRUE ~ "Outpatient"
  ))

list_of_dfs <- df_summary_tbl %>%
  group_split(ip_op_flag)

names(list_of_dfs) <- list_of_dfs %>%
  map(~pull(.,ip_op_flag)) %>%
  map(~as.character(.)) %>%
  map(~unique(.))

list_of_dfs %>%
  writexl::write_xlsx(path = "S:/Global Finance/1 REVENUE CYCLE/CMS_PRICE_TRANSPARENCY/rev_cd_360_historical_rundate_12222020.xlsx")


df_summary_tbl %>%
  writexl::write_xlsx(path = "S:/Global Finance/1 REVENUE CYCLE/CMS_PRICE_TRANSPARENCY/rev_cd_360_historical_rundate_12222020.xlsx")



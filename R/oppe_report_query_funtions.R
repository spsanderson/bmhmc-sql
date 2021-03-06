#' OPPE ALOS Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get the average length of stay data from DSS in order to run the OPPE report.
#' The data in this report goes back 18 months and the dates are set dynamically in
#' the sql.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has start and end dates set dynamically to look back on data to ensure it has
#' gone through the coding process.
#' - The fields that come back are:
#'   * pt_id
#'   * ptno_num
#'   * dsch_date
#'   * dsch_yr
#'   * dsch_month
#'   * atn_dr_no
#'   * atn_dr_name
#'   * drg_no
#'   * lihn_service_line
#'   * hosim
#'   * apr_drg
#'   * severity_of_illness
#'   * los
#'   * elos
#'   * threshold
#'   * outlier_flag
#'   * drg_cost_weight
#'   * pyr_grouping
#'   * case_var
#'   * case_index
#'   * index_threshold
#'   * z_score
#'   * med_staff_dept
#'   * ward_cd
#' - The tables that are used are:
#'   * smsdss.c_LIHN_Svc_Line_tbl
#'   * smsdss.BMH_PLM_PtAcct_V
#'   * Customer.Custom_DRG
#'   * smsdss.c_LIHN_SPARCS_BenchmarkRates
#'   * smsdss.pract_dim_v
#'   * smsdss.c_LIHN_APR_DRG_OutlierThresholds
#'   * smsdss.pyr_dim_v
#'   * SMSMIR.vst_rpt
#'
#' @examples
#' library(dplyr)
#'
#' oppe_alos_query() %>%
#' glimpse()
#'
#' @return
#' A tibble object
#'
#' @export
#'

oppe_alos_query <- function(){

  # * DB Connection ----
  #base::source("R/db_con.R")
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @TODAY DATE;
      DECLARE @START DATE;
      DECLARE @END   DATE;

      SET @TODAY = CAST(GETDATE() AS date);
      SET @START = DATEADD(MM, DATEDIFF(MM, 0, @TODAY) - 18, 0);
      SET @END   = dateadd(mm, datediff(mm, 0, @TODAY), 0);

      SELECT b.Pt_No AS [pt_no]
      , b.PtNo_Num AS [ptno_num]
      , CAST(b.Dsch_Date AS DATE) AS [dsch_date]
      , [dsch_month] = DATEPART(month, b.dsch_date)
      , [dsch_yr] = DATEPART(year, b.dsch_date)
      , CASE
      	WHEN b.Days_Stay = '0'
      		THEN '1'
      		ELSE b.Days_Stay
        END AS [los]
      , b.Atn_Dr_No AS [atn_dr_no]
      , e.pract_rpt_name
      , b.drg_no
      , a.LIHN_Svc_Line AS [lich_service_line]
      , CASE
      	WHEN e.src_spclty_cd = 'hosim'
      		THEN 'Hospitalist'
      		ELSE 'Private'
        END AS [hosim]
      , c.APRDRGNO AS [apr_drg_no]
      , c.SEVERITY_OF_ILLNESS AS [severity_of_illness]
      , CASE
      	WHEN d.Performance = '0'
      		THEN '1'
      	WHEN d.Performance IS null
      	AND b.Days_Stay = 0
      		THEN '1'
      	WHEN d.Performance IS null
      	AND b.days_stay != 0
      		THEN b.Days_Stay
      		ELSE d.Performance
        END AS [elos]
      , f.[Outlier Threshold] AS [threshold]
      , CASE
      	WHEN b.Days_Stay > f.[Outlier Threshold]
      		THEN 1
      		ELSE 0
        END AS [outlier_flag]
      , b.drg_cost_weight
      , G.pyr_group2 AS [pyr_grouping]
      , e.med_staff_dept
      , H.ward_cd

      FROM smsdss.c_LIHN_Svc_Line_tbl                   AS a
      LEFT JOIN smsdss.BMH_PLM_PtAcct_V                 AS b
      ON a.Encounter = b.Pt_No
      LEFT JOIN Customer.Custom_DRG                     AS c
      ON b.PtNo_Num = c.PATIENT#
      LEFT JOIN smsdss.c_LIHN_SPARCS_BenchmarkRates     AS d
      ON c.APRDRGNO = d.[APRDRG Code]
      	AND c.SEVERITY_OF_ILLNESS = d.SOI
      	AND d.[Measure ID] = 4
      	AND d.[Benchmark ID] = 3
      	AND a.LIHN_Svc_Line = d.[LIHN Service Line]
      LEFT JOIN smsdss.pract_dim_v                      AS e
      ON b.Atn_Dr_No = e.src_pract_no
      	AND e.orgz_cd = 's0x0'
      LEFT JOIN smsdss.c_LIHN_APR_DRG_OutlierThresholds AS f
      ON c.APRDRGNO = f.[apr-drgcode]
      LEFT JOIN smsdss.pyr_dim_v                        AS G
      ON B.Pyr1_Co_Plan_Cd = G.pyr_cd
      	AND b.Regn_Hosp = G.orgz_cd
      LEFT JOIN SMSMIR.vst_rpt                          AS H
      ON B.PT_NO = H.PT_ID

      WHERE b.Dsch_Date >= @start
      AND b.Dsch_Date < @end
      AND b.drg_no NOT IN (
      	'0','981','982','983','984','985',
      	'986','987','988','989','998','999'
      )
      AND b.Plm_Pt_Acct_Type = 'I'
      AND LEFT(B.PTNO_NUM, 1) != '2'
      AND LEFT(b.PtNo_Num, 4) != '1999'
      AND b.tot_chg_amt > 0
      AND e.med_staff_dept NOT IN ('?', 'Anesthesiology', 'Emergency Department')

      OPTION(FORCE ORDER)
      ;
      "
    )
  ) %>%
    tibble::as_tibble()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  data_tbl <- query %>%
    dplyr::mutate_if(is.character, stringr::str_squish) %>%
    dplyr::mutate(dsch_date = as.Date(dsch_date)) %>%
    dplyr::mutate(
      case_var          = round(los - elos, 4)
      , case_index      = round(los / elos, 4)
      , index_threshold = 1
      , z_score         = round((los - elos) / stats::sd(los), 4)
      , pract_name      = stringr::str_to_title(pract_rpt_name)
    ) %>%
    dplyr::select(-pract_rpt_name) %>%
    dplyr::rename("pract_rpt_name" = "pract_name")

  return(data_tbl)

}

#' OPPE Readmit Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get the readmit rate data from DSS in order to run the OPPE report.
#' The data in this report goes back 18 months and the dates are set dynamically in
#' the sql.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has start and end dates set dynamically to look back on data to ensure it has
#' gone through the coding process.
#' - The fields that come back are:
#'   * med_rec_no
#'   * ptno_num
#'   * adm_date
#'   * dsch_date
#'   * payor_category
#'   * atn_dr_no
#'   * med_staff_dept
#'   * lihn_svc_line
#'   * severity_of_illness
#'   * dsch_yr
#'   * dsch_qtr
#'   * dsch_month
#'   * dsch_week
#'   * dsch_day
#'   * dsch_day_name
#'   * rpt_month
#'   * rpt_qtr
#'   * dsch_disp
#'   * dsch_disp_desc
#'   * drg_no
#'   * drg_cost_weight
#'   * hospitalist_private
#'   * hospitalist_private_flag
#'   * los
#'   * interim
#'   * pt_count
#'   * readmit_count
#'   * bench_yr
#'   * readmit_rate_bench
#'   * ward_cd
#'   * z_score
#'   * pract_rpt_name
#' - The tables that are used are:
#'   * smsdss.c_readmit_dashboard_detail_tbl
#'   * smsdss.c_readmit_dashboard_bench_tbl
#'   * smsmir.vst_rpt
#'
#' @examples
#' library(dplyr)
#'
#' oppe_readmit_query() %>%
#' glimpse()
#'
#' @return
#' A tibble object
#'
#' @export
#'
oppe_readmit_query <- function(){

  # * DB Connection ----
  #base::source("R/db_con.R")
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      SELECT A.Med_Rec_No,
      	A.PtNo_Num,
      	A.Adm_Date,
      	A.Dsch_Date,
      	A.Payor_Category,
      	A.Atn_Dr_No,
      	A.pract_rpt_name,
      	A.med_staff_dept,
      	A.LIHN_Svc_Line,
      	A.SEVERITY_OF_ILLNESS,
      	A.Dsch_YR,
      	A.Dsch_Qtr,
      	A.Dsch_Month,
      	A.Dsch_Week,
      	A.Dsch_Day,
      	A.Dsch_Day_Name,
      	A.Rpt_Month,
      	A.Rpt_Qtr,
      	A.DSCH_DISP,
      	A.Dsch_Disp_Desc,
      	A.drg_no,
      	A.drg_cost_weight,
      	A.Hospitalist_Private,
      	A.Hospitaslit_Private_Flag,
      	A.LOS,
      	A.INTERIM,
      	1 AS [Pt_Count],
      	A.RA_Flag AS [Readmit_Count],
      	B.BENCH_YR,
      	B.READMIT_RATE AS [Readmit_Rate_Bench],
      	C.ward_cd
      FROM SMSDSS.C_READMIT_DASHBOARD_DETAIL_TBL AS A
      LEFT OUTER JOIN smsdss.c_Readmit_Dashboard_Bench_Tbl AS B ON A.LIHN_Svc_Line = B.LIHN_SVC_LINE
      	AND (A.Dsch_YR - 1) = B.BENCH_YR
      	AND A.SEVERITY_OF_ILLNESS = B.SOI
      LEFT OUTER JOIN SMSMIR.VST_RPT AS C ON A.PtNo_Num = SUBSTRING(C.PT_ID, 5, 8)
      WHERE B.SOI IS NOT NULL
      ORDER BY A.Dsch_YR,
      	A.Dsch_Qtr,
      	B.SOI
      "
    )
  ) %>%
    tibble::as_tibble()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  data_tbl <- query %>%
    dplyr::mutate_if(is.character, stringr::str_squish) %>%
    dplyr::mutate(Dsch_Date = as.Date(Dsch_Date)) %>%
    dplyr::mutate(Adm_Date = as.Date(Adm_Date)) %>%
    dplyr::mutate(
      z_score      = round((Readmit_Count - Readmit_Rate_Bench) / stats::sd(Readmit_Count), 4)
      , pract_name = stringr::str_to_title(pract_rpt_name)
    ) %>%
    dplyr::select(-pract_rpt_name) %>%
    dplyr::rename("pract_rpt_name" = "pract_name") %>%
    janitor::clean_names()

  return(data_tbl)
}

#' OPPE CPOE Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get the CPOE data from DSS in order to run the OPPE report.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has start and end dates set dynamically to look back on data to ensure it has
#' gone through the coding process.
#' - The fields that come back are:
#'   * ent_ate
#'   * req_pty_cd
#'   * pract_rpt_name
#'   * spclty_desc
#'   * hospitalist_np_pa_flag
#'   * ord_type_abbr
#'   * specimen_collect
#'   * written
#'   * verbal_order
#'   * communication
#'   * specimen_redraw
#'   * cpoe
#'   * nursing_order
#' - The tables that are used are:
#'   * smsdss.c_CPOE_Rpt_Tbl_Rollup_v
#'   * smsdss.pract_dim_v
#'
#' @examples
#' library(dplyr)
#'
#' oppe_cpoe_query() %>%
#' glimpse()
#'
#' @return
#' A tibble object
#'
#' @export
#'

oppe_cpoe_query <- function(){

  # * DB Connection ----
  #base::source("R/db_con.R")
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      SELECT A.ent_date,
      	A.req_pty_cd,
      	B.pract_rpt_name,
      	B.spclty_desc AS [spclty_desc],
      	Hospitalist_Np_Pa_Flag AS [hospitalist_np_pa_flag],
      	Ord_Type_Abbr AS [ord_type_abbr],
      	[Specimen Collect] AS [specimen_collect],
      	Written AS [written],
      	[Verbal Order] AS [verbal_order],
      	Communication AS [communication],
      	[Specimen Redraw] AS [specimen_redraw],
      	CPOE AS [cpoe],
      	[Nursing Order] AS [nursing_order],
      	Unknown AS [unknown],
      	Telephone AS [telephone],
      	[Per RT Protocol] AS [per_rt_protocol]
      FROM smsdss.c_CPOE_Rpt_Tbl_Rollup_v AS A
      LEFT OUTER JOIN smsdss.pract_dim_v AS B ON A.req_pty_cd = B.src_pract_no
      	AND B.orgz_cd = 'S0X0'
      WHERE A.req_pty_cd NOT IN ('000000','000059')
      "
    )
  ) %>%
    tibble::as_tibble()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  data_tbl <- query %>%
    dplyr::mutate(ent_date = as.Date(ent_date)) %>%
    dplyr::mutate(pract_name = stringr::str_to_title(pract_rpt_name)) %>%
    dplyr::select(-pract_rpt_name) %>%
    dplyr::rename("pract_rpt_name" = "pract_name")

  return(data_tbl)
}

#' OPPE Denials Detail Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get the Denials Detail data for a specified provider.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has start and end dates set dynamically to look back on data to ensure it has
#' gone through the coding process.
#' - The fields that come back are:
#'   *
#' - The tables that are used are:
#'   * smsdss.bmh_plm_ptacct_v
#'   * smsdss.pract_dim_v
#'   * smsdss.drg_dim_v
#'   * smsdss.c_lihn_svc_line_tbl
#'   * smsdss.c_lihn_op_svc_line_tbl
#'   * BMH-3MHIS-DB.MMM_COR_BMH_LIVE.dbo.visit_view
#'   * BMH-3MHIS-DB.MMM_COR_BMH_LIVE.dbo.CTC_VISIT
#'   * BMH-3MHIS-DB.MMM_COR_BMH_LIVE.dbo.CTC_INSURANCE
#'   * BMH-3MHIS-DB.MMM_COR_BMH_LIVE.dbo.CTC_UM_Denial
#'   * BMH-3MHIS-DB.MMM_COR_BMH_LIVE.dbo.CTC_UM_APPEAL
#'
#' @param .provider_id The id of the provider you want denial detial for
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' oppe_denials_detail_query(.provider_id = "005892") %>%
#' glimpse()
#'
#' # If provider id is not known you can do either of the following
#' # pract_dim_v_query(.name = "the providers name") and the pract_no will be
#' # returned to you, or you could do the following:
#'
#' oppe_denials_detail_query(
#'   .provider_id = pract_dim_v_query(.name = "name_here") %>%
#'     dplyr::pull(pract_no)
#' )
#'}
#'
#' @return
#' A tibble object
#'
#' @export
#'
oppe_denials_detail_query <- function(.provider_id){

  # * Tidyeval ----
  provider_id_var_expr <- rlang::enquo(.provider_id)

  # * Checks ----
  if(rlang::quo_is_missing(provider_id_var_expr)){
    stop(call. = FALSE,"(.provider_id) is missing. Please supply.")
  }

  # * DB Connection ----
  #base::source("R/db_con.R")
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @TODAY DATE;
      DECLARE @START DATE;
      DECLARE @END   DATE;

      SET @TODAY = CAST(GETDATE() AS date);
      SET @START = DATEADD(YY, DATEDIFF(YY, 0, @TODAY) - 5, 0);
      SET @END   = DATEADD(MM, DATEDIFF(MM, 0, @TODAY), 0);

      SELECT PAV.Med_Rec_No AS [med_rec_no],
    	PAV.PtNo_Num AS [ptno_num],
    	CAST(PAV.ADM_DATE AS DATE) AS [adm_date],
    	CAST(PAV.Dsch_Date AS DATE) AS [dsch_date],
    	CAST(PAV.DAYS_STAY AS INT) AS [days_stay],
    	PAV.drg_no,
    	DRG.drg_name,
    	PAV.drg_cost_weight,
    	PAV.Atn_Dr_No AS [atn_dr_no],
    	PDV.pract_rpt_name,
    	CASE
    		WHEN PAV.Plm_Pt_Acct_Type != 'I'
    			THEN LIHNOP.LIHN_Svc_Line
    		ELSE LIHNIP.LIHN_Svc_Line
    		END AS [svc_line],
    	CASE
    		WHEN DENIALS.pt_no IS NOT NULL
    			THEN 1
    		ELSE 0
    		END AS [denial_flag],
    	DENIALS.UM_Days_Denied AS [um_days_denied],
    	DENIALS.Dollars_Appealed AS [dollars_appealed],
    	DENIALS.Dollars_Recovered AS [dollars_recovered],
    	PAV.tot_chg_amt,
      PAV.Plm_Pt_Acct_Type AS [plm_pt_acct_type]
      FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
      INNER JOIN SMSDSS.pract_dim_v AS PDV ON PAV.Atn_Dr_No = PDV.src_pract_no
    	  AND PAV.Regn_Hosp = PDV.orgz_cd
      LEFT OUTER JOIN SMSDSS.drg_dim_v AS DRG ON PAV.DRG_NO = DRG.DRG_NO
    	  AND DRG.drg_vers = 'MS-V25'
      LEFT OUTER JOIN SMSDSS.c_LIHN_Svc_Line_Tbl AS LIHNIP ON PAV.PtNo_Num = LIHNIP.Encounter
      LEFT OUTER JOIN SMSDSS.c_LIHN_OP_Svc_Line_Tbl AS LIHNOP ON PAV.PtNo_Num = LIHNOP.Encounter
      LEFT OUTER JOIN (
    	  SELECT CAST(rtrim(ltrim('0000' + CAST(a.bill_no AS CHAR(13)))) AS CHAR(13)) COLLATE SQL_LATIN1_GENERAL_PREF_CP1_CI_AS AS [Pt_No],
    		e.appl_dollars_appealed AS [Dollars_Appealed],
    		e.appl_dollars_recovered AS [Dollars_Recovered],
    		d.rvw_Dys_dnd AS [UM_Days_Denied]
    	  FROM [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.visit_view AS a
    	  LEFT JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_VISIT AS b ON a.visit_id = b._fk_visit
    	  LEFT JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_INSURANCE AS c ON a.visit_id = c._fk_visit
    	  LEFT JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[CTC_UM_Denial] AS d ON c._pk = d._fk_insurance
    	  LEFT OUTER JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_UM_APPEAL AS e ON d._pk = e._fk_UM_Denial
    	  WHERE E.APPL_doLLARS_APPEALED IS NOT NULL
    	) AS DENIALS ON PAV.Pt_NO = DENIALS.Pt_No
      WHERE Adm_Date >= @START
    	AND Adm_Date < @END
    	AND PAV.tot_chg_amt > 0
    	AND LEFT(PAV.PTNO_NUM, 1) != '2'
    	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
    	AND (
    		(
    			PAV.Plm_Pt_Acct_Type = 'I'
    			AND PAV.drg_no IS NOT NULL
    			)
    		OR (
    			PAV.Plm_Pt_Acct_Type != 'I'
    			AND PAV.drg_no IS NULL
    			)
    		)
        ORDER BY PAV.Plm_Pt_Acct_Type,
    	PAV.Adm_Date
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    dplyr::filter(atn_dr_no == {{ provider_id_var_expr }}) %>%
    dplyr::mutate_if(is.character, stringr::str_squish) %>%
    dplyr::mutate(
      adm_date    = as.Date(adm_date)
      , dsch_date = as.Date(dsch_date)
      , plm_pt_acct_type = as.factor(plm_pt_acct_type)
    ) %>%
    dplyr::mutate(
      pract_rpt_name = stringr::str_to_title(pract_rpt_name)
    ) %>%
    dplyr::distinct(ptno_num, .keep_all = TRUE)

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  data_tbl <- query

  return(data_tbl)
}

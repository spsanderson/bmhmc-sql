#' Time Series - Readmission Excess Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query gets the data necessary to do a time series analysis on the excess
#' readmission rates.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - The start date is set to 2016-04-01
#' - The end date is set dynamically to the end of the previous month.
#' - It gets data from:
#' 1. smsdss.BMH_PLM_PtAcct_V
#' 2. smsdss.pract_dim_v
#' 3. Customer.Custom_DRG
#' 4. smsdss.c_LIHN_Svc_Line_Tbl
#' 5. smsdss.vReadmits
#' 6. smsdss.c_Readmit_Dashboard_Bench_Tbl
#' 7. smsdss.c_ppr_apr_drg_global_exclusions
#'
#' @examples
#' \dontrun{
#' ts_readmit_excess_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

ts_readmit_excess_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @START DATE;
      DECLARE @END   DATE;

      SET @START = '2016-04-01';
      SET @END   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0)

      SELECT CAST(A.DSCH_DATE AS date) AS [Dsch_Date]
      , A.PTNO_NUM
      , DATEPART(YEAR, A.DSCH_DATE) AS [Dsch_YR]
      , C.SEVERITY_OF_ILLNESS
      , D.LIHN_Svc_Line
      , 1 AS [DSCH]
      , CASE
      	WHEN E.[READMIT] IS NOT NULL
      		THEN 1
      		ELSE 0
      	END AS [RA_Flag]
      , F.READMIT_RATE AS [RR_Bench]
      , F.BENCH_YR

      FROM smsdss.BMH_PLM_PtAcct_V AS A
      LEFT OUTER JOIN smsdss.pract_dim_v AS B
      ON A.Atn_Dr_No = B.src_pract_no
      	AND A.Regn_Hosp = B.orgz_cd
      LEFT OUTER JOIN Customer.Custom_DRG AS C
      ON A.PtNo_Num = C.PATIENT#
      LEFT OUTER JOIN smsdss.c_LIHN_Svc_Line_Tbl AS D
      ON A.PtNo_Num = D.Encounter
      	AND A.prin_dx_cd_schm = D.prin_dx_cd_schme
      LEFT OUTER JOIN smsdss.vReadmits AS E
      ON A.PtNo_Num = E.[INDEX]
      	AND E.[INTERIM] < 31
      	AND E.[READMIT SOURCE DESC] != 'Scheduled Admission'
      LEFT OUTER JOIN smsdss.c_Readmit_Dashboard_Bench_Tbl AS F
      ON D.LIHN_Svc_Line = F.LIHN_SVC_LINE
      	AND (DATEPART(YEAR, A.DSCH_DATE) - 1) = F.BENCH_YR
      	AND C.SEVERITY_OF_ILLNESS = F.SOI

      WHERE A.DSCH_DATE >= @START
      AND A.Dsch_Date < @END
      AND A.tot_chg_amt > 0
      AND LEFT(A.PtNo_Num, 1) != '2'
      AND LEFT(A.PTNO_NUM, 4) != '1999'
      AND A.drg_no IS NOT NULL
      AND A.dsch_disp IN ('AHR','ATW')
      AND C.APRDRGNO NOT IN (
      	SELECT ZZZ.[APR-DRG]
      	FROM smsdss.c_ppr_apr_drg_global_exclusions AS ZZZ
      )
      AND B.med_staff_dept != 'Emergency Department'
      AND B.pract_rpt_name != 'TEST DOCTOR X'

      ORDER BY A.Dsch_Date
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names()

  data_tbl <- data_tbl %>%
    dplyr::mutate(dsch_date = lubridate::ymd(dsch_date)) %>%
    dplyr::mutate(dsch_yr   = forcats::as_factor(dsch_yr)) %>%
    dplyr::mutate(severity_of_illness = forcats::as_factor(severity_of_illness)) %>%
    dplyr::mutate(bench_yr  = forcats::as_factor(bench_yr))

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

#' Time Series - ALOS/ELOS Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query gets the data necessary to do a time series analysis on the excess
#' length of stay rates.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - The start date is set to 2014-04-01 which is when the Customer.Custom_DRG
#' table starts
#' - The end date is set dynamically to the end of the previous month.
#' - It gets data from:
#' 1. smsdss.BMH_PLM_PtAcct_V
#' 2. smsdss.c_LIHN_Svc_Line_tbl
#' 3. Customer.Custom_DRG
#' 4. smsdss.c_LIHN_SPARCS_BenchmarkRates
#' 5. smsdss.pract_dim_v
#' 6. smsdss.c_LIHN_APR_DRG_OutlierThresholds
#' 7. smsdss.pyr_dim_v
#'
#' @examples
#' \dontrun{
#' ts_alos_elos_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

ts_alos_elos_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  query <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @TODAY DATE;
      DECLARE @END   DATE;

      SET @TODAY = CAST(GETDATE() AS date);
      SET @END   = DATEADD(MM, DATEDIFF(MM, 0, @TODAY), 0);

      SELECT b.Pt_No
      , b.Dsch_Date
      , CASE
      	WHEN b.Days_Stay = '0'
      		THEN '1'
      		ELSE b.Days_Stay
        END AS [LOS]
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
        END AS [Performance]

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
      LEFT JOIN smsdss.pyr_dim_v AS G
      ON B.Pyr1_Co_Plan_Cd = G.pyr_cd
      	AND b.Regn_Hosp = G.orgz_cd

      WHERE b.Dsch_Date >= '2014-04-01'
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
      AND c.PATIENT# IS NOT NULL
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::select(
      dsch_date
      , los
      , performance
    )

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(query)

}


#' Time Series - Inpatient Discharges Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query gets the data necessary to do a time series analysis on the daily
#' inpatient discharges.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - The start date is set to 2001-01-01
#' - The end date is set dynamically to the end of the previous month.
#' - It gets data from smsdss.BMH_PLM_PtAcct_V
#' - The data comes back aggregated by day with columns date_col and value
#'
#' @examples
#' \dontrun{
#' ts_ip_discharges_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

ts_ip_discharges_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  query <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      SELECT CAST(Dsch_Date as date) AS [date_col]
      , COUNT(DISTINCT(PTNO_NUM)) AS [value]

      FROM smsdss.BMH_PLM_PtAcct_V

      WHERE Dsch_Date >= '2001-01-01'
      AND Dsch_Date < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
      AND tot_chg_amt > 0
      AND Plm_Pt_Acct_Type = 'I'
      AND LEFT(PTNO_NUM, 1) != '2'
      AND LEFT(PTNO_NUM, 4) != '1999'

      GROUP BY Dsch_Date

      ORDER BY Dsch_Date
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    dplyr::mutate(date_col = as.Date(date_col))

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(query)

}

#' Time Series - ER Arrivals Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query gets the data necessary to do a time series analysis on emergency
#' room arrivals.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - The start date is set to 2010-01-01
#' - The end date is set dynamically to the end of the previous month.
#' - It gets data from the WellSoft reporting server
#' - The data comes back aggregated by arrival which is granular to the minute.
#' The following columns come back:
#' * date_col - date is of datetime, so down to the second
#' * value - where value simply equals 1
#'
#' @examples
#' \dontrun{
#' ts_ed_arrivals_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

ts_ed_arrivals_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  query <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      SELECT Arrival AS [date_col]
      , COUNT(ACCOUNT) AS [value]

      FROM [SQL-WS\\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]

      WHERE ARRIVAL >= '2010-01-01'
      AND ARRIVAL < DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0)
      AND TIMELEFTED != '-- ::00'
      AND ARRIVAL != '-- ::00'

      GROUP BY ARRIVAL

      ORDER BY ARRIVAL
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    dplyr::mutate(date_col = lubridate::ymd_hms(date_col))

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(query)

}

#' Time Series - Outpatient Visits Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query gets the data necessary to do a time series analysis on outpatient visits.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - The start date is set to 2001-01-01
#' - The end date is set dynamically to the end of the previous month.
#' - It gets data from smsdss.BMH_PLM_PtAcct_V
#' - The data comes back aggregated by day, using the discharge date which is the same
#' as the arrival date. The columns that are returned are:
#' * date_col - date is of date
#' * value - where value count of visits that day
#' - This query excludes unitized and ED visits and those that start with 9
#'
#' @examples
#' \dontrun{
#' ts_op_visits_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

ts_op_visits_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  query <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      SELECT CAST(Dsch_Date as date) AS [date_col]
      , COUNT(DISTINCT(PTNO_NUM)) AS [value]

      FROM smsdss.BMH_PLM_PtAcct_V

      WHERE Dsch_Date >= '2001-01-01'
      AND Dsch_Date < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
      AND tot_chg_amt > 0
      AND Plm_Pt_Acct_Type != 'I'
      AND LEFT(PTNO_NUM, 1) NOT IN ('2','7','8','9')
      AND LEFT(PTNO_NUM, 4) != '1999'
      AND LEFT(HOSP_SVC, 1) != 'E'
      AND unit_seq_no = '0'
      AND tot_chg_amt > 0

      GROUP BY Dsch_Date

      ORDER BY Dsch_Date
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    dplyr::mutate(date_col = lubridate::ymd(date_col))

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(query)

}

#' Time Series - Inpatient Census/LOS by Day
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Sometimes it is important to know what the census was on any given day, or what
#' the average length of stay is on any given day, including for those patients
#' that are not yet discharged. This can be easily achieved.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - The start date is set to 2001-01-01
#' - The end date is not set in order to capture those that are still here.
#' - It gets data from smsdss.BMH_PLM_PtAcct_V
#'
#' @examples
#' \dontrun{
#' ts_ip_census_los_daily_query()
#' }
#'
#' @return
#' A tibble object
#'
#' @export
#'

ts_ip_census_los_daily_query <- function(){

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  query <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      SELECT CAST(Adm_Date AS DATE) AS [adm_date],
      CAST(Dsch_Date AS DATE) AS [dsch_date]
      FROM SMSDSS.BMH_PLM_PtAcct_V
      WHERE Plm_Pt_Acct_Type = 'I'
      AND LEFT(PTNO_NUM, 1) != '2'
      AND LEFT(PTNO_NUM, 4) != '1999'
      AND Adm_Date >= '2001-01-01'
      AND tot_chg_amt > 0
      ORDER BY CAST(Adm_Date AS DATE)
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    dplyr::mutate(dplyr::across(.fns = lubridate::ymd))

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(query)

}

#' Time Series - Monthly Readmission Excess Query
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
#' 1. FROM smsdss.BMH_PLM_PtAcct_V
#' 2. smsdss.pract_dim_v
#' 3. Customer.Custom_DRG
#' 4. smsdss.c_LIHN_Svc_Line_Tbl
#' 5. smsdss.vReadmits
#' 6. smsdss.c_Readmit_Dashboard_Bench_Tbl
#' 7. smsdss.c_ppr_apr_drg_global_exclusions
#'
#' @examples
#' \dontrun{
#' ts_monthly_readmit_excess_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

ts_monthly_readmit_excess_query <- function() {

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

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

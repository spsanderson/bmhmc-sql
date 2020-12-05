#' Get LOS and Readmit Index Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get the Length of Stay and Readmit data with expected performance
#'
#' @details
#' - Gets data from DSS query
#' - Uses [db_connect()] and [db_disconnect()] functions. See documentation.
#' - Gets
#'   1. Adm_Date
#'   2. Dsch_Date
#'   3. Encounter
#'   4. LIHN_Svc_Line
#'   5. ALOS
#'   6. ELOS
#'   7. Visit_Flag
#'   8. Readmit_Flag
#'   9. Readmit_Rate
#' - Data Tables
#'   1. smsdss.bmh_plm_ptacct_v
#'   2. smsdss.vReadmits
#'   3. smsdss.c_elos_bench_data
#'   4. smsdss.c_LIHN_Svc_Line_Tbl
#'   5. Customer.Custom (APR-DRG Data)
#'   6. smsdss.c_readmit_dashboard_bench_tbl
#' - Filters
#'   1. tot_chg_amt > 0
#'   2. Encounter does not start with 2 or 1999
#'   3. Dsch_Date >= '2001-01-01'
#'   4. Plm_Pt_Acct_Type = "I"
#'
#' @examples
#' library(DBI)
#' library(odbc)
#' library(dplyr)
#' library(tibble)
#' library(janitor)
#' df_tbl <- los_ra_index_query()
#'
#' @return
#' A tibble
#'
#' @export
#'

los_ra_index_query <- function() {

  # DB Connect ----
  db_con_obj <- LICHospitalR::db_connect()
  # Get Data ----
  query <- DBI::dbGetQuery(
    conn = db_con_obj,
    base::paste0(
      "
        SELECT CAST(A.ADM_DATE AS DATE) AS [Adm_Date]
        , CAST(A.DSCH_DATE AS DATE) AS [Dsch_Date]
        , A.PtNo_Num
        , D.LIHN_Svc_Line
        , CAST(A.Days_Stay AS INT) AS [LOS]
        , C.Performance AS [ELOS]
        , 1 AS [Visit_Flag]
        , CASE
        	WHEN B.READMIT IS NULL
        		THEN 0
        		ELSE 1
          END AS [READMIT_FLAG]
        , F.READMIT_RATE

        FROM SMSDSS.BMH_PLM_PTACCT_V AS A
        LEFT OUTER JOIN SMSDSS.vReadmits AS B
        ON A.PtNo_Num = B.[INDEX]
        	AND B.[INTERIM] < 31
        INNER MERGE JOIN SMSDSS.c_elos_bench_data AS C
        ON A.PtNo_Num = C.Encounter
        INNER JOIN SMSDSS.c_LIHN_Svc_Line_Tbl AS D
        ON A.PtNo_Num = D.Encounter
        INNER JOIN Customer.Custom_DRG AS E
        ON A.PtNo_Num = E.PATIENT#
        INNER JOIN SMSDSS.C_READMIT_DASHBOARD_BENCH_TBL AS F
        ON D.LIHN_Svc_Line = F.LIHN_SVC_LINE
        	AND (DATEPART(YEAR, A.DSCH_DATE) - 1) = F.BENCH_YR
        	AND E.SEVERITY_OF_ILLNESS = F.SOI

        WHERE A.tot_chg_amt > 0
        AND LEFT(A.PTNO_NUM, 1) != '2'
        AND LEFT(A.PTNO_NUM, 4) != '1999'
        AND A.Dsch_Date >= '2001-01-01'
        AND A.Plm_Pt_Acct_Type = 'I'
        "
    )
  )

  # DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # As Tibble ----
  query_tbl <- query %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::mutate(adm_date = lubridate::ymd(adm_date)) %>%
    dplyr::mutate(dsch_date = lubridate::ymd(dsch_date)) %>%
    dplyr::mutate(los = as.double(los)) %>%
    dplyr::mutate_if(is.character, stringr::str_squish)

  return(query_tbl)

}

#' Make LOS and Readmit Index Summary Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Create the length of stay and readmit index summary tibble
#'
#' @details
#' - Expects a tibble
#' - Adds a year column from the Admit Date and one from Discharge Date
#' - Uses all data to compute variance, if you want it for a particular time frame
#' you will have to filter the data from [los_ra_index_query()]
#'
#' @param .data The data you are going to analyze from [los_ra_index_query()]
#'
#' @examples
#' los_ra_index_summary_tbl(
#'   .data = los_ra_index_query()
#' )
#'
#' @return
#' A tibble
#'
#' @export
#'

los_ra_index_summary_tbl <- function(.data) {

  # Checks
  if (!is.data.frame(.data)) {
    stop(call. = FALSE, "(data) is not a data-frame/tibble. Please provide.")
  }

  # Summarize and Manipulate
  df_tbl <- tibble::as_tibble(.data)

  df_summary_tbl <- df_tbl %>%
    dplyr::mutate(
      los_group = dplyr::case_when(
        los > 15 ~ 15,
        TRUE ~ los
      )
    ) %>%
    dplyr::group_by(los_group) %>%
    dplyr::summarise(
      tot_visits = sum(visit_flag, na.rm = TRUE)
      , tot_los  = sum(los, na.rm = TRUE)
      , tot_elos = sum(elos, na.rm = TRUE)
      , tot_ra   = sum(readmit_flag, na.rm = TRUE)
      , tot_perf = base::round(base::mean(readmit_rate, na.rm = TRUE), digits = 2)
    ) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(tot_rar = dplyr::case_when(
      tot_ra != 0 ~ base::round((tot_ra / tot_visits), digits = 2),
      TRUE ~ 0
    )) %>%
    dplyr::mutate(los_index = dplyr::case_when(
      tot_elos != 0 ~ (tot_los / tot_elos),
      TRUE ~ 0
    )) %>%
    dplyr::mutate(rar_index = dplyr::case_when(
      (tot_rar != 0 & tot_perf != 0) ~ (tot_rar / tot_perf),
      TRUE ~ 0
    )) %>%
    dplyr::mutate(
      los_ra_var = base::abs(1 - los_index) + base::abs(1 - rar_index)
      ) %>%
    dplyr::select(los_group, los_index, rar_index, los_ra_var)

  return(df_summary_tbl)

}

#' Plot LOS and Readmit Index with Variance
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Plot the index of the length of stay and readmit rate against each other along
#' with the variance
#'
#' @details
#' - Expects a tibble
#' - Expects a Length of Stay and Readmit column, must be numeric
#' - Uses patchwork to stack plots
#'
#' @param .data The data supplied from [los_ra_index_summary_tbl()]
#'
#' @examples
#' library(dplyr)
#' library(ggplot2)
#' library(patchwork)
#' library(tidyquant)
#'
#' los_ra_index_query() %>%
#' los_ra_index_summary_tbl() %>%
#' los_ra_index_plt()
#'
#' @return
#' A patchwork ggplot2 plot
#'
#' @export
#'

los_ra_index_plt <- function(.data) {

  requireNamespace(package = "patchwork")

  # Checks
  if(!is.data.frame(.data)) {
    stop(call. = FALSE, "(.data) is not a data.frame/tibble. Please supply.")
  }

  # Set local df/tibble
  df_tbl <- tibble::as_tibble(.data)

  # Set local variables
  min_los_ra_var = tibble::as_tibble(df_tbl) %>%
    dplyr::filter(df_tbl[[4]] == base::min(df_tbl[[4]])) %>%
    dplyr::select(los_group) %>%
    dplyr::pull()

  min_var = tibble::as_tibble(df_tbl) %>%
    dplyr::filter(df_tbl[[1]] == min_los_ra_var) %>%
    dplyr::select(los_ra_var) %>%
    dplyr::pull()

  # Plot
  g <- tibble::as_tibble(df_tbl) %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = los_group,
        y = los_index
      )
    ) +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_line(
      mapping = ggplot2::aes(
        y = los_index
      )
    ) +
    ggplot2::geom_point(
      mapping = ggplot2::aes(
        y = rar_index
      )
      , color = "red"
      , size = 3
    ) +
    ggplot2::geom_line(
      mapping = ggplot2::aes(
        y = rar_index
      )
    ) +
    ggplot2::geom_hline(
      yintercept = 1
      , linetype = "dashed"
    ) +
    ggplot2::geom_vline(
      xintercept = min_los_ra_var
      , linetype = "dashed"
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent) +
    tidyquant::theme_tq() +
    tidyquant::scale_color_tq() +
    ggplot2::labs(
      title = "LOS Index vs. Readmit Index",
      subtitle = "Black dots are LOS and Red are Readmit",
      y = "LOS/Readmit Index",
      x = "LOS Group"
    )

  g2 <- tibble::as_tibble(df_tbl) %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = los_group,
        y = los_ra_var
      )
    ) +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_line() +
    ggplot2::geom_vline(
      xintercept = min_los_ra_var
      , linetype = "dashed"
    ) +
    ggplot2::geom_hline(
      yintercept = min_var,
      linetype = "dashed",
      color = "red"
    ) +
    ggplot2::scale_y_continuous(labels = scales::number) +
    tidyquant::theme_tq() +
    tidyquant::scale_color_tq() +
    ggplot2::labs(
      title = "LOS vs Readmit Rate Index Variance",
      subtitle = stringr::str_c(
        "Total LRIV = "
        , base::round(base::sqrt(base::mean(df_tbl$los_ra_var)), digits = 2)
        , "\n"
        , "Minimum Variance at LOS of "
        , min_los_ra_var
        , " Min Var = "
        , base::round(min_var, digits = 4)
        , sep = ""
      ),
      caption = "Encounters with a LOS >= 15 are grouped to LOS Group 15",
      y = "LOS/Readmit Index",
      x = "LOS Group"
    )

  g / g2

}

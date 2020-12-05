#' OPPE Coded Consults Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get the coded consults for a specified provider using their ID number or resp_pty cd.
#'
#' @details
#' - Get the coded consults for a specified consulting provider using their ID number/resp_pty cd.
#' - This gets data from DSS, you must have a connection file on your pc to use this function.
#' If you do not have one then submit a help desk ticket for one.
#' - Gets data from smsdss.c_Coded_Consults_v for the last 6 full months by discharge date.
#' - Uses timetk::tk_augment_timeseries_signature() to obtain a few different time components
#'
#' @param .resp_pty The providers six digit ID Number. This should be quoted like '123456'
#'
#' @examples
#' library(janitor)
#' library(dplyr)
#' library(tibble)
#' library(DBI)
#' library(odbc)
#' library(lubridate)
#' library(timetk)
#' library(tidyquant)
#' coded_consults_query(.resp_pty = '123456')
#'
#' @return
#' A tibble
#'
#' @export
#'
coded_consults_query <- function(.resp_pty) {

  # Tidyeval Setup
  resp_party_var_expr <- rlang::enquo(.resp_pty)

  # Check
  # Missing ID
  if(rlang::quo_is_missing(resp_party_var_expr)) {
    stop(call. = FALSE, "(.resp_pty) is missing. Please provide one.")
  }

  # Is length 6
  if(base::nchar(resp_party_var_expr)[[2]] != 6) {
    stop(call. = FALSE, "(.resp_pty) is not of length six. Check leading zero.")
  }

  # DB Connection
  db_con_obj <- LICHospitalR::db_connect()

  # Query
  coded_consults_tbl <- DBI::dbGetQuery(
    conn      = db_con_obj,
    statement = base::paste0(
      "
      SELECT *
      , [record_flag] = 1
      FROM smsdss.c_Coded_Consults_v
      WHERE Dsch_Date >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 6, 0)
      AND Dsch_Date < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
      ORDER BY Dsch_Date
      "
    )
  ) %>%
    dplyr::filter(RespParty == ({{resp_party_var_expr}})) %>%
    tibble::as_tibble()

  # DB Disconnect
  LICHospitalR::db_disconnect()

  # Data Clean / Manipulation
  coded_consults_ts_tbl <- tibble::as_tibble(coded_consults_tbl) %>%
    janitor::clean_names() %>%
    dplyr::mutate_if(base::is.character, stringr::str_squish) %>%
    dplyr::mutate_if(base::is.character, stringr::str_to_title) %>%
    dplyr::mutate(
      adm_date  = lubridate::ymd(adm_date),
      dsch_date = lubridate::ymd(dsch_date)
    ) %>%
    timetk::tk_augment_timeseries_signature(.date_var = dsch_date) %>%
    dplyr::select(
      adm_date,
      dsch_date,
      med_rec_no:pt_no,
      days_stay:clasf_cd,
      year,
      month,
      month.lbl,
      day,
      wday,
      wday.lbl,
      week.iso,
      record_flag
    ) %>%
    dplyr::mutate(
      end_of_month = tidyquant::EOMONTH(dsch_date),
      end_of_week  = tidyquant::CEILING_WEEK(dsch_date)
    )

  # Return tibble
  return(coded_consults_ts_tbl)
}

#' OPPE Coded Consults Top Attending
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Gets the top n attending providers who have consulted the consultant in question.
#'
#' @details
#' - Get the top n attending providers and counts of times they consulted the specialist
#' provider in question.
#' - This gets data from either DSS by using the [coded_consults_query()] or an
#' imported file.
#'
#' @param .data The data that you provided. There must be an Attending column and Consultant column
#' @param .top_n How many of the top attending providers do you want returned.
#' @param .attending_col The column that holds the name of the attending provider
#' @param .consultant_col The column that holds the name of the consulting provider(s)
#'
#' @examples
#' library(dplyr)
#' library(tibble)
#' coded_consults_top_providers_tbl(
#' .data = coded_consults_query(.resp_pty = "013128")
#' , .top_n = 10
#' , .attending_col = attending_md
#' , .consultant_col = consultant
#' )
#'
#' @export
#'

coded_consults_top_providers_tbl <- function(
  .data
  , .top_n
  , .attending_col
  , .consultant_col
) {

  # Tidyeval Setup
  top_n_var_expr      <- rlang::enquo(.top_n)
  attending_var_expr  <- rlang::enquo(.attending_col)
  consultant_var_expr <- rlang::enquo(.consultant_col)

  # Checks
  if (!is.data.frame(.data)) {
    stop(call. = FALSE, "(data) is not a data-frame/tibble. Please provide.")
  }

  if (rlang::quo_is_missing(top_n_var_expr)) {
    stop(call. = FALSE, "(top_n_var_expr) is missing. Please provide.")
  }

  if (rlang::quo_is_missing(attending_var_expr)) {
    stop(call. = FALSE, "(attending_var_expr) is missing. Please provide attending md column name")
  }

  if (rlang::quo_is_missing(consultant_var_expr)) {
    stop(call. = FALSE, "(consultant_var_expr) is missing. Please provide consultant column name.")
  }

  # Consultant
  consultant <- tibble::as_tibble(.data) %>%
    dplyr::distinct(!!consultant_var_expr) %>%
    dplyr::pull()

  # Get tp_n attending providers that asked consultant to consult
  top_n_tbl <- dplyr::count(.data, {{attending_var_expr}} ) %>%
    dplyr::arrange(dplyr::desc(n)) %>%
    dplyr::slice(1:( {{top_n_var_expr}} )) %>%
    dplyr::mutate(
      attending_md = forcats::as_factor( {{attending_var_expr}} ) %>%
        forcats::fct_reorder(n)
    ) %>%
    dplyr::select(attending_md, n) %>%
    dplyr::mutate(consultant = consultant)

  return(top_n_tbl)

}

#' OPPE Plot of top N Attending
#'
#' @author Steven P Sanderson II, MPH
#'
#' @description
#' Plot out the results from the coded_consults_top_providers function
#'
#' @details
#' - Gives a ggplot2 plot of the top_n attending providers from the coded_consults_top_providers
#' function
#'
#' @param .data The data provided the coded_consults_top_providers function
#'
#' @examples
#' library(janitor)
#' library(dplyr)
#' library(tibble)
#' library(DBI)
#' library(odbc)
#' library(lubridate)
#' library(timetk)
#' library(tidyquant)
#' library(ggplot2)
#' coded_consults_query(.resp_pty = "013128") %>%
#'   coded_consults_top_providers_tbl(
#'     .top_n          = 10,
#'     .attending_col  = attending_md,
#'     .consultant_col = consultant
#'   ) %>%
#'   coded_consults_top_plt()
#'
#' @return
#' A ggplot plot
#'
#' @export
#'

coded_consults_top_plt <- function(.data) {

  # check
  if (!is.data.frame(.data)) {
    stop(call. = FALSE, "(data) is not a data-frame/tibble. Please provide.")
  }

  consultant <- tibble::as_tibble(.data) %>%
    dplyr::select(3) %>%
    dplyr::distinct() %>%
    dplyr::pull()

  total_consults <- tibble::as_tibble(.data) %>%
    dplyr::select(n) %>%
    base::sum(na.rm = TRUE)

  # Plot
  g <- tibble::as_tibble(.data) %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = n,
        y = attending_md,
        fill = "blue"
      )
    ) +
    ggplot2::geom_col() +
    tidyquant::scale_fill_tq() +
    tidyquant::theme_tq() +
    ggplot2::labs(
      x = "",
      y = "",
      title = base::paste0(
        "Top Attending Providers that consulted ",
        consultant
      ),
      subtitle = base::paste0(
        "Total Consults for Top Attending Providers: ",
        total_consults
      )
    ) +
    ggplot2::theme(legend.position = "none")

  return(g)
}

#' OPPE Coded Consults Trend Plot
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get a plot of the trend for a spcified consultant
#'
#' @details
#' - Get the trend plot for a given consultant
#' - Data can come from the coded_consults_query function or data that is imported
#' - Must have a consultant column
#' - Groups data by month label, January, February, etc.
#' - See [coded_consults_query()]
#'
#'
#' @param .data The data that you want to trend
#' @param .consultant_col The column that holds the consultant name
#'
#' @examples
#' library(dplyr)
#' library(tibble)
#' library(ggplot2)
#' coded_consults_query(.resp_pty = "013128") %>%
#'   coded_consults_trend_plt(.consultant_col = consultant)
#'
#' @return
#' A ggplot2 plot
#'
#' @export
#'

coded_consults_trend_plt <- function(
  .data
  , .consultant_col
) {

  # Tidyeval Setup
  consultant_var_expr <- rlang::enquo(.consultant_col)

  # Checks
  if (!is.data.frame(.data)) {
    stop(call. = FALSE, "(data) is not a data-frame/tibble. Please provide.")
  }

  if (rlang::quo_is_missing(consultant_var_expr)) {
    stop(call. = FALSE, "(consultant_var_expr) is missing. Please provide column.")
  }

  # Data Manip
  df_tbl <- tibble::as_tibble(.data) %>%
    dplyr::select(
      dsch_date,
      month.lbl,
      week.iso,
      wday.lbl,
      end_of_month,
      end_of_week
    ) %>%
    dplyr::group_by(month.lbl) %>%
    dplyr::summarise(total_consults = n()) %>%
    dplyr::ungroup() %>%
    purrr::set_names("ts", "value")

  # Consultant
  consultant <- tibble::as_tibble(.data) %>%
    dplyr::distinct( {{consultant_var_expr}} ) %>%
    dplyr::pull()

  # Plot
  g <- df_tbl %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = ts,
        y = value,
        fill = "blue"
      )
    ) +
    ggplot2::geom_col() +
    tidyquant::scale_fill_tq() +
    tidyquant::theme_tq() +
    ggplot2::labs(
      x = "",
      y = "",
      title = base::paste0("Consult Trend For: ", consultant),
      subtitle = "Last Six Months"
    ) +
    ggplot2::theme(legend.position = "none")

  # Return plot
  return(g)

}


#' OPPE Coded Consults Seasonal Diagnostics
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get the seasonal diagnostics of the last 6 months consulant usage
#'
#' @details
#' - Must have data supplied either by import or by [coded_consults_query()] function
#' - Must have a date column (adm_date or dsch_date)
#' - Must have a value column (should just use record_flag from the query)
#'
#' @param .data The data you want to analyze
#' @param .date_col The column that has the date you want to use, typically dsch_date
#' @param .value_col The column that holds the value, can use record_flag from the query
#'
#' @examples
#' library(timetk)
#' library(dplyr)
#' library(tibble)
#' coded_consults_seasonal_diagnositcs_plt(
#'   .data = coded_consults_query(.resp_pty = "013128")
#'   , .date_col = dsch_date
#'   , .value_col = record_flag
#'   )
#'
#' @return
#' A plotly plot
#'
#' @export
#'

coded_consults_seasonal_diagnositcs_plt <- function(
  .data,
  .date_col,
  .value_col
  ) {

  # Tidyeval Setup
  date_col_var_expr <- rlang::enquo(.date_col)
  value_col_var_expr <- rlang::enquo(.value_col)

  # Checks
  if (!is.data.frame(.data)) {
    stop(call. = FALSE, "(data) is not a data-frame/tibble. Please provide.")
  }

  if (rlang::quo_is_missing(date_col_var_expr)) {
    stop(call. = FALSE, "(date_col_var_expr) is missing. Please provide.")
  }

  if (rlang::quo_is_missing(value_col_var_expr)) {
    stop(call. = FALSE, "(value_col_var_expr) is missing. Please provide.")
  }

  # Data Manip
  df_tbl <- tibble::as_tibble(.data) %>%
    dplyr::select(!!date_col_var_expr, !!value_col_var_expr) %>%
    dplyr::group_by(!!date_col_var_expr) %>%
    dplyr::summarise(value = base::sum(!!value_col_var_expr, na.rm = TRUE)) %>%
    dplyr::ungroup()

  # Pad by time
  df_tbl <- df_tbl %>%
    timetk::pad_by_time(.date_var = !!date_col_var_expr, .pad_value = 0)

  # Plot ts season dx
  g <- df_tbl %>%
    timetk::plot_seasonal_diagnostics(
      .date_var = !!date_col_var_expr,
      .value = value,
      .interactive = FALSE
    )

  return(g)
}

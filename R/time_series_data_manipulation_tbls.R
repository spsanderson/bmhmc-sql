#' Time Series - Monthly Readmission Excess Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes data from the [ts_monthly_readmit_excess_query()] and performs the necessary
#' calculations to see if a possible VAE has occurred.
#'
#' This function makes an internal summary table using `timetk::summarise_by_time`
#' with the following possible choices: "year", "month", "week", these are checked
#' inside of the function, if something else is chose an error will be thrown
#' and the function will exit. It defaults to "month".
#'
#' @details
#' - Returns a tibble
#' - Expects [ts_monthly_readmit_excess_query()] as the data argument
#' - Cleans the table names and selects the following columns
#' 1. dsch_date
#' 4. dsch (which just equals 1 as a record column)
#' 5. ra_flag
#' 6. rr_bench
#' - dsch_date gets mutated using `lubridate::ymd(dsch_date)`
#' - The output columns are:
#' 1. date_col
#' 2. value - the excess readmit rate.
#'
#' @param .data The data passed in from [ts_monthly_readmit_excess_query()]
#' @param .by_time The choices are "year", "month", "week", defaults to "month"
#'
#' @examples
#' \dontrun{
#' data <- ts_monthly_readmit_excess_query()
#'
#' data %>%
#'   ts_monthly_readmit_excess_tbl(.by_time = "year")
#'
#' data %>%
#'   ts_monthly_readmit_excess_tbl()
#'
#' data %>%
#'   ts_monthly_readmit_excess_tbl(.by_time = "week") %>%
#'   save_to_excel(.file_name = "weekly_readmit_excess")
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

ts_monthly_readmit_excess_tbl <- function(
  .data
  , .by_time = "month"
  , .date_col
  ) {

  # * Tideval ----
  by_time_var_expr  <- .by_time
  date_col_var_expr <- rlang::enquo(.date_col)

  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE,"(.data) is not a data.frame/tibble. Please supply.")
  }

  if(rlang::quo_is_missing(date_col_var_expr)) {
    stop(call. = FALSE, "(.date_col) was not provided. Please supply.")
  }

  if(!by_time_var_expr %in% c("year","month","week")) {
    stop(call. = FALSE,"(.by_time) must be either year, month or week")
  }

  # * Data ----
  data_tbl <- tibble::as_tibble(.data)

  # * Manipulate ----
  data_tbl <- data_tbl %>%
    dplyr::select(
      dsch_date
      , severity_of_illness
      , lihn_svc_line
      , dsch
      , ra_flag
      , rr_bench
    ) %>%
    dplyr::mutate(dsch_date = lubridate::ymd(dsch_date)) %>%
    dplyr::select(dsch_date, dsch, ra_flag, rr_bench)

  data_tbl <- data_tbl %>%
    timetk::summarise_by_time(
      .date_var       = {{ date_col_var_expr }}
      , .by           = by_time_var_expr
      # .date_var = dsch_date
      # , .by = "month"
      , dsch_count    = sum(dsch, na.rm = TRUE)
      , readmit_count = sum(ra_flag, na.rm = TRUE)
      , readmit_rate  = round(readmit_count / dsch_count, 4) * 100
      , readmit_bench = round(mean(rr_bench, na.rm = TRUE), 4)  * 100
      , value         = round((readmit_rate - readmit_bench), 2)
    ) %>%
    dplyr::rename(date_col = dsch_date)

  # * Return ----
  return(data_tbl)

}

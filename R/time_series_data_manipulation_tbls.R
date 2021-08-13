#' Time Series - Monthly Readmission Excess Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes data from the [ts_readmit_excess_query()] and makes an internal summary table using `timetk::summarise_by_time`
#' with the following possible choices: "year", "month", "week", these are checked
#' inside of the function, if something else is chose an error will be thrown
#' and the function will exit. It defaults to "month".
#'
#' @details
#' - Returns a tibble
#' - Expects [ts_readmit_excess_query()] as the data argument
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
#' @param .data The data passed in from [ts_readmit_excess_query()]
#' @param .date_col The column containing the date variable of interest
#' @param .by_time The choices are "year", "month", "week", defaults to "month"
#'
#' @examples
#' \dontrun{
#' library(healthyR)
#'
#' data <- ts_monthly_readmit_excess_query()
#'
#' data %>%
#'   ts_readmit_excess_tbl(.by_time = "year")
#'
#' data %>%
#'   ts_readmit_excess_tbl(.by_time = "month") %>%
#'   ts_plt(.date_col = dsch_date, .value_col = value)
#'
#' data %>%
#'   ts_readmit_excess_tbl()
#'
#' data %>%
#'   ts_readmit_excess_tbl(.by_time = "week") %>%
#'   save_to_excel(.file_name = "weekly_readmit_excess")
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

ts_readmit_excess_tbl <- function(
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

#' Time Series - ALOS/ELOS Excess Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes data from the [ts_alos_elos_query()] and makes an internal summary table using `timetk::summarise_by_time`
#' with the following possible choices: "year", "month", "week", these are checked
#' inside of the function, if something else is chose an error will be thrown
#' and the function will exit. It defaults to "month".
#'
#' @details
#' - Returns a tibble
#' - Expects [ts_alos_elos_query()] as the data argument
#'
#' @param .data The data passed in from [ts_alos_elos_query()]
#' @param .date_col The column containing the date variable of interest
#' @param .by_time The choices are "year", "month", "week", defaults to "month"
#'
#' @examples
#' \dontrun{
#' library(healthyR)
#'
#' data <- ts_alos_elos_query()
#'
#' data %>%
#'   ts_alos_elos_tbl(.by_time = "year")
#'
#' data %>%
#'   ts_alos_elos_tbl(.by_time = "month") %>%
#'   ts_plt(.date_col = dsch_date, .value_col = avg_excess)
#'
#' data %>%
#'   ts_alos_elos_tbl()
#'
#' data %>%
#'   ts_alos_elos_tbl(.by_time = "week") %>%
#'   save_to_excel(.file_name = "weekly_alos_excess")
#' }
#'
#' @return
#' A tibble with the following columns:
#' 1. date_col
#' 2. visit_count
#' 3. sum_days
#' 4. sum_exp_days
#' 5. alos
#' 6. elos
#' 7. excess_days
#' 8. avg_excess
#'
#'
#' @export
#'

ts_alos_elos_tbl <- function(
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
    timetk::summarise_by_time(
      .date_var       = {{ date_col_var_expr }}
      , .by           = by_time_var_expr
      , visit_count   = dplyr::n()
      , sum_days      = sum(los, na.rm = TRUE)
      , sum_exp_days  = sum(performance, na.rm = TRUE)
      , alos          = sum_days / visit_count
      , elos          = sum_exp_days / visit_count
      , excess_days   = sum_days - sum_exp_days
      , avg_excess    = alos - elos
    ) %>%
    dplyr::rename(date_col = dsch_date)

  # * Return ----
  return(data_tbl)

}

#' Time Series - Inpatient Discharges Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes data from the [ts_ip_discharges_query()] and makes an internal summary table using `timetk::summarise_by_time`
#' with the following possible choices: "year", "month", "week", and "day", these are checked
#' inside of the function, if something else is chose an error will be thrown
#' and the function will exit. It defaults to "month". This function also uses the
#' `timetk::pad_by_time` function with a value of 0 for time periods that have no data.
#'
#' @details
#' - Returns a tibble
#' - Expects [ts_ip_discharges_query()] as the data argument
#'
#' @param .data The data passed in from [ts_ip_discharges_query()]
#' @param .date_col The column containing the date variable of interest
#' @param .by_time The choices are "year", "month", "week", "day" defaults to "month"
#'
#' @examples
#' \dontrun{
#' library(healthyR)
#'
#' data <- ts_ip_discharges_query()
#'
#' data %>%
#'   ts_ip_discharges_tbl(.by_time = "year")
#'
#' data %>%
#'   ts_ip_discharges_tbl(.by_time = "month") %>%
#'   ts_plt(.date_col = dsch_date, .value_col = value)
#'
#' data %>%
#'   ts_ip_discharges_tbl()
#'
#' data %>%
#'   ts_ip_discharges_tbl(.by_time = "week") %>%
#'   save_to_excel(.file_name = "ip_discharges")
#' }
#'
#' @return
#' A tibble with the following columns:
#' 1. date_col
#' 2. value
#'
#' @export
#'

ts_ip_discharges_tbl <- function(
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

  if(!by_time_var_expr %in% c("year","month","week","day")) {
    stop(call. = FALSE,"(.by_time) must be either year, month, week, or day")
  }

  # * Data ----
  data_tbl <- tibble::as_tibble(.data)

  # * Manipulate ----
  data_tbl <- data_tbl %>%
    timetk::summarise_by_time(
      .date_var = {{ date_col_var_expr }}
      , .by     = by_time_var_expr
      , value   = sum(value, na.rm = TRUE)
    )  %>%
    timetk::pad_by_time(
      .date_var    = {{ date_col_var_expr }}
      , .by        = by_time_var_expr
      , .pad_value = 0
    ) %>%
    purrr::set_names("date_col", "value")

  # * Return ----
  return(data_tbl)

}

#' Time Series - ED Arrivals Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes data from the [ts_ed_arrivals_query()] and makes an internal summary table using `timetk::summarise_by_time`
#' with the following possible choices: "year", "month", "week", "day", and "min", these are checked
#' inside of the function, if something else is chose an error will be thrown
#' and the function will exit. It defaults to "month". This function also uses the
#' `timetk::pad_by_time` function with a value of 0 for time periods that have no data.
#'
#' @details
#' - Returns a tibble
#' - Expects [ts_ed_arrivals_query()] as the data argument
#'
#' @param .data The data passed in from [ts_ed_arrivals_query()]
#' @param .date_col The column containing the date variable of interest
#' @param .by_time The choices are "year", "month", "week", "day", "hour", "min" defaults to "month"
#'
#' @examples
#' \dontrun{
#' library(healthyR)
#'
#' data <- ts_ed_arrivals_query()
#'
#' data %>%
#'   ts_ed_arrivals_tbl(.by_time = "year")
#'
#' data %>%
#'   ts_ed_arrivals_tbl(.by_time = "month") %>%
#'   ts_plt(.date_col = dsch_date, .value_col = value)
#'
#' data %>%
#'   ts_ed_arrivals_tbl()
#'
#' data %>%
#'   ts_ed_arrivals_tbl(.by_time = "week") %>%
#'   save_to_excel(.file_name = "ed_arrivals")
#' }
#'
#' @return
#' A tibble with the following columns:
#' 1. date_col
#' 2. value
#'
#' @export
#'

ts_ed_arrivals_tbl <- function(
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

  if(!by_time_var_expr %in% c("year","month","week","day","hour","min")) {
    stop(call. = FALSE,"(.by_time) must be either year, month, week, day, hour, or minute")
  }

  # * Data ----
  data_tbl <- tibble::as_tibble(.data)

  # * Manipulate ----
  data_tbl <- data_tbl %>%
    timetk::summarise_by_time(
      .date_var = {{ date_col_var_expr }}
      , .by     = by_time_var_expr
      , value   = sum(value, na.rm = TRUE)
    ) %>%
    timetk::pad_by_time(
      .date_var    = {{ date_col_var_expr }}
      , .by        = by_time_var_expr
      , .pad_value = 0
    ) %>%
    purrr::set_names("date_col", "value")

  # * Return ----
  return(data_tbl)

}

#' Time Series - ED Arrivals Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes data from the [ts_op_visits_query()] and makes an internal summary table using `timetk::summarise_by_time`
#' with the following possible choices: "year", "month", "week", "day" these are checked
#' inside of the function, if something else is chose an error will be thrown
#' and the function will exit. It defaults to "month". This function also uses the
#' `timetk::pad_by_time` function with a value of 0 for time periods that have no data.
#'
#' @details
#' - Returns a tibble
#' - Expects [ts_op_visits_query()] as the data argument
#'
#' @param .data The data passed in from [ts_op_visits_query()]
#' @param .date_col The column containing the date variable of interest
#' @param .by_time The choices are "year", "month", "week", "day" defaults to "month"
#'
#' @examples
#' \dontrun{
#' library(healthyR)
#'
#' data <- ts_op_visits_query()
#'
#' data %>%
#'   ts_op_visits_tbl(.by_time = "year")
#'
#' data %>%
#'   ts_op_visits_tbl(.by_time = "month") %>%
#'   ts_plt(.date_col = dsch_date, .value_col = value)
#'
#' data %>%
#'   ts_op_visits_tbl()
#'
#' data %>%
#'   ts_op_visits_tbl(.by_time = "week") %>%
#'   save_to_excel(.file_name = "weekly_alos_excess")
#' }
#'
#' @return
#' A tibble with the following columns:
#' 1. date_col
#' 2. value
#'
#' @export
#'

ts_op_visits_tbl <- function(
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

  if(!by_time_var_expr %in% c("year","month","week","day","min")) {
    stop(call. = FALSE,"(.by_time) must be either year, month, week, day")
  }

  # * Data ----
  data_tbl <- tibble::as_tibble(.data)

  # * Manipulate ----
  data_tbl <- data_tbl %>%
    timetk::summarise_by_time(
      .date_var = {{ date_col_var_expr }}
      , .by     = by_time_var_expr
      , value   = sum(value, na.rm = TRUE)
    ) %>%
    timetk::pad_by_time(
      .date_var    = {{ date_col_var_expr }}
      , .by        = by_time_var_expr
      , .pad_value = 0
    ) %>%
    purrr::set_names("date_col", "value")

  # * Return ----
  return(data_tbl)

}

#' Time Series - Inpatient Census/LOS by Day Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Sometimes it is important to know what the census was on any given day, or what
#' the average length of stay is on any given day, including for those patients
#' that are not yet discharged. This can be easily achieved. This will return one
#' record for every account so the data will still need to be summarised.
#'
#' For those accounts that are not yet discharged the date column that returns will
#' be set to today (the day the function is run.)
#'
#' __This function can take a little bit of time to run while the join comparison runs.__
#'
#' @details
#' - Requires the data from the [ts_ip_census_los_daily_query()]
#' - Takes a single boolean parameter
#'
#' @param .data The data passed from from [ts_ip_census_los_daily_query()]
#' @param .keep_nulls_only A boolean that will keep only those records that have
#' a NULL discharge date, meaning the patient is currently admitted. The default
#' is FALSE which brings back all records.
#'
#' @examples
#' \dontrun{
#' ts_ip_census_los_daily_query() %>%
#'   ts_ip_census_los_daily_tbl()
#'
#' ts_ip_census_los_daily_query() %>%
#'   ts_ip_census_los_daily_tbl(.keep_nulls_only = TRUE)
#' }
#'
#' @return
#' A tibble object
#'
#' @export
#'
#'

ts_ip_census_los_daily_tbl <- function(.data, .keep_nulls_only = FALSE){

  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE,"(.data) is not a data.frame/tibble. Please supply.")
  }

  keep_nulls_only_bool <- .keep_nulls_only

  # * Data ----
  # Ensure a tibble
  data_tbl <- tibble::as_tibble(.data)

  # * Manipulate ----
  # Get start date and end date
  all_dates_tbl <- data_tbl %>%
    dplyr::filter(!is.na(data_tbl[[1]])) %>%
    dplyr::filter(!is.na(data_tbl[[2]]))

  start_date <- min(all_dates_tbl[[1]], all_dates_tbl[[2]])
  end_date   <- max(all_dates_tbl[[1]], all_dates_tbl[[2]])
  today      <- Sys.Date()

  ts_day_tbl <- timetk::tk_make_timeseries(
    start_date = start_date
    , end_date = end_date
    , by       = "day"
  ) %>%
    tibble::as_tibble() %>%
    dplyr::rename("date" = "value")

  res <- sqldf::sqldf(
    "
    SELECT *
    FROM ts_day_tbl AS A
    LEFT JOIN data_tbl AS B
    ON adm_date <= A.date
      AND (
        dsch_date >= A.date
        or dsch_date is null
      )
    "
  )

  res <- tibble::as_tibble(res) %>%
    dplyr::arrange(date)

  los_tbl <- res %>%
    dplyr::mutate(
      los = dplyr::case_when(
        !is.na(dsch_date) ~ difftime(
          dsch_date, adm_date, units = "days"
        ) %>% as.integer()
        , TRUE ~ difftime(
          today, adm_date, units = "days"
        ) %>% as.integer()
      )
    ) %>%
    dplyr::mutate(census = 1) %>%
    # dplyr::mutate(
    #   date = dplyr::case_when(
    #     is.na(dsch_date) ~ Sys.Date()
    #     , TRUE ~ dsch_date
    #   )
    # ) %>%
    dplyr::arrange(date)

  # Keep NA columns?
  if(!keep_nulls_only_bool) {
    data_final_tbl <- los_tbl
  } else {
    data_final_tbl <- los_tbl %>%
      dplyr::filter(is.na(dsch_date))
    }

  # * Return ----
  return(data_final_tbl)

}

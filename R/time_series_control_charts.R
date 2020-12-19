#' Time Series Range
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get the range of a given set of numbers.
#'
#' @details
#' - Expects a vector of numbers be supplied
#'
#' @param .value_col The time series value column, e.g. discharge counts
#'
#' @examples
#' y <- seq(-5:5)
#' ts_qc_range(y)
#'
#' @return
#' A number
#'
#' @export
#'

ts_qc_range <- function(.value_col) {

  # Tidyeval
  value_col_var_expr <- rlang::enquo(.value_col)

  # Checks
  if(rlang::quo_is_missing(value_col_var_expr)){
    stop(call. = FALSE, "(.value_col) is missing. Please supply.")
  }

  range    <- max(.value_col) - min(.value_col)

  # * Return ----
  return(range)
}

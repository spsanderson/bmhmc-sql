#' OPPE ALOS Plots
#' @author Steven P. Sanderson II, MPH
#'
#' @description Get plots for a single providers length of stay data.
#'
#' @details Takes data in from the [oppe_alos_tbl()] function.
#'
#' @param .data The data that you would pass from [oppe_alos_tbl()]
#' @param .date_col The column holding the date value
#' @param .value_col The column holding the value you want to plot
#' @param .by_time How you want the data time aggregated, the default is __"month"__
#'
#' @examples
#' oppe_alos_query() %>%
#'   oppe_alos_tbl(.provider_id = "017236") %>%
#'   oppe_alos_plt(.date_col = dsch_date, .value_col = excess)
#'
#' @return
#' A patchwork time series plot
#'
#' @export
#'
oppe_alos_plt <- function(.data, .date_col, .value_col, .by_time = "month"){

  requireNamespace(package = "patchwork")

  # * Tidyeval Setup ----
  by_time_var_expr     <- .by_time
  interactive_var_expr <- FALSE
  value_var_expr       <- rlang::enquo(.value_col)
  date_var_expr        <- rlang::enquo(.date_col)

  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is not a data.frame/tibble. Please supply.")
  }

  if(rlang::quo_is_missing(value_var_expr)){
    stop(call. = FALSE, "(.value_col) is missing. Please supply.")
  }

  if(rlang::quo_is_missing(date_var_expr)){
    stop(call. = FALSE, "(.date_col) is missing. Please supply.")
  }

  # * Data ----
  data_tbl <- tibble::as_tibble(.data)
  provider <- base::unique(data_tbl$pract_rpt_name)
  val_txt  <- rlang::quo_text(value_var_expr)

  # Check how many providers are in list
  if(base::length(base::unique(data_tbl$pract_rpt_name)) > 1){
    stop(call. = FALSE, "There is more than one provider name in the data.
         Please choose one and then run this function")
  }

  # * Manipulate ----
  data_tbl <- data_tbl %>%
    timetk::summarise_by_time(
      .date_var    = {{ date_var_expr }}
      , .by        = by_time_var_expr
      , sum_value  = sum({{ value_var_expr }})
      , mean_value = mean({{ value_var_expr }})
    ) %>%
    dplyr::rename(date_col = dsch_date)

  p1 <- timetk::plot_time_series(
        .data        = data_tbl
      , .date_var    = date_col
      , .value       = sum_value
      , .title       = base::paste0("Sum of ", val_txt, " for: ", provider)
      , .interactive = interactive_var_expr
      , .smooth      = FALSE
      , .legend_show = FALSE
    )

  p2 <- timetk::plot_time_series(
      .data          = data_tbl
      , .date_var    = date_col
      , .value       = mean_value
      , .title       = base::paste0("Mean of ", val_txt, " for: ", provider)
      , .interactive = interactive_var_expr
      , .smooth      = FALSE
      , .legend_show = FALSE
    )

  # * Return ----
  p1 / p2

}

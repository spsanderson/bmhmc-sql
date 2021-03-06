#' OPPE CPOE Detail Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get the CPOE Detail data for use in CPOE for a specified provider.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#'
#' @param .data The data to be passed into the tibble function, should be the results
#' from [oppe_cpoe_query()]
#' @param .provider_id The provider id number you are looking for
#' @param .provider_name If you do not know the providers id, then you can use their name
#' to get a match. You can also use the [pract_dim_v_query()] to find the id number
#' before using this function, or you can use it inside of the id number parameter. Be
#' careful with this approach as providers can have the same last name. It is better to
#' use the function on it's own and select the appropriate id number.
#' Uses [stringr::str_to_lower()] so that you can use all lower case letters to
#' describe the name you are looking for.
#'
#' @examples
#' \dontrun{
#' oppe_cpoe_query() %>%
#'   oppe_cpoe_tbl()
#'
#' oppe_cpoe_query() %>%
#'   oppe_cpoe_tbl(.provider_id = "009142")
#'
#' oppe_cpoe_query() %>%
#'   oppe_cpoe_tbl(.provider_name = "rakesh")
#'}
#'
#' @return
#' A tibble
#'
#' @export
#'

oppe_cpoe_tbl <- function(.data, .provider_id, .provider_name){

  # * Tidyeval Setup ----
  resp_party_var_expr <- rlang::enquo(.provider_id)
  name_var_expr       <- rlang::enquo(.provider_name)

  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is not a data.frame/tibble. Please supply.")
  }

  if(rlang::quo_is_missing(resp_party_var_expr)){
    resp_party_var_expr = NULL
  }

  if(rlang::quo_is_missing(name_var_expr)){
    name_var_expr = NULL
  }

  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data)

  # Get total orders
  data_tbl <- data_tbl %>%
    # reorder
    dplyr::select(
      ent_date, req_pty_cd, pract_rpt_name, spclty_desc:ord_type_abbr, dplyr::everything()
    ) %>%
    # filter out na names
    dplyr::filter(!is.na(pract_rpt_name))

  # Get total orders
  data_tbl$total_orders = data_tbl %>%
    dplyr::select(where(is.numeric)) %>%
    base::rowSums(.)

  # * Filter ---
  if(!is.null(resp_party_var_expr)){
    data_tbl <- data_tbl %>%
      dplyr::filter(req_pty_cd == {{ resp_party_var_expr }})

    return(data_tbl)
  }

  if(!is.null(name_var_expr)){
    data_tbl <- data_tbl %>%
      dplyr::mutate(pract_rpt_name = stringr::str_to_lower(pract_rpt_name)) %>%
      dplyr::filter(stringr::str_detect(pract_rpt_name, {{ name_var_expr }}))

    return(data_tbl)
  }

  # * Return ----
  return(data_tbl)

}

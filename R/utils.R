#' Save a file to Excel
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Save a tibble/data.frame to an excel `.xlsx` file. The file will automatically
#' with a save_dtime in the format of 20201109_132416 for November 11th, 2020
#' at 1:24:16PM.
#'
#' @details
#' - Requires a tibble/data.frame to be passed to it.
#'
#' @param .data The tibble/data.frame that you want to save as an `.xlsx` file.
#' @param .file_name the name you want to give to the file.
#'
#' @examples
#' \dontrun{
#' coded_consults_query(.resp_pty = "013789") %>%
#'   save_to_excel(.file_name = "coded_consults")
#'
#' coded_consults_query(.resp_pty = "013789") %>%
#'   coded_consults_top_providers_tbl(
#'   .top_n = 10
#'   , .attending_col = attending_md
#'   , .consultant_col = consultant
#'   ) %>%
#'   save_to_excel(.file_name = "coded_consults")
#'}
#' @return
#' A saved excel file
#'
#' @export
#'

save_to_excel <- function(.data, .file_name) {

  # Checks
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is not a data.frame/tibble. Please supply.")
  }

  if(is.na(.file_name)){
    stop(call. = FALSE, "(.file_name) was not provided. Please supply.")
  }

  data_tbl <- tibble::as_tibble(.data)

  # Save Dir
  file_path <- utils::choose.dir()

  # File Name
  file_name <- .file_name
  file_date <- base::Sys.Date() %>%
    stringr::str_replace_all("-","")
  file_time <- base::Sys.time() %>%
    LICHospitalR::sql_right(5) %>%
    stringr::str_replace_all(":","")
  file_name <- base::paste0(
    "\\"
    ,file_name
    ,"_save_dtime_"
    , file_date
    , "_"
    , file_time
    ,".xlsx"
  )

  f_pn <- base::paste0(
    file_path
    , file_name
  )

  # Save file
  writexl::write_xlsx(
    x = data_tbl
    , path = f_pn
  )

}

#' Named list from a grouped tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Takes in a data.frame/tibble and creates a named list that can be
#' used in conjunction with something like [save_to_excel()]
#'
#' @details
#' - Needs a grouped data.frame/tibble
#'
#' @param .data The grouped data.frame/tibble
#' @param .grouping_var The column that contains the grouping variable
#'
#' @examples
#' \dontrun{
#' named_item_list(.data = df, .grouping_var = service_line)
#' }
#'
#' @export
#'

named_item_list <- function(.data, .grouping_var){

  # Tidyeval
  group_var_expr <- rlang::enquo(.grouping_var)

  # Checks
  if(!is.data.frame(.data)) {
    stop(call. = FALSE,"(.data) is not a data.frame/tibble. Please supply")
  }

  if(rlang::quo_is_missing(group_var_expr)){
    stop(call. = FALSE,"(.grouping_var) is missing. Please supply.")
  }

  data_tbl <- tibble::as_tibble(.data)

  data_tbl_list <- data_tbl %>%
    dplyr::group_split({{group_var_expr}})

  names(data_tbl_list) <- data_tbl_list %>%
    purrr::map(~ dplyr::pull(., {{group_var_expr}})) %>%
    purrr::map(~ base::as.character(.)) %>%
    purrr::map(~ base::unique(.))

  # Return
  return(data_tbl_list)

}

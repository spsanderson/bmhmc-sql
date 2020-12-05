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

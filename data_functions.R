denials_tbl <- function() {
  
  # * Data ----
  data <- readxl::read_excel(
    path = "G:\\R Studio Projects\\Denials_Report\\denials_data.xlsx"
    , sheet = "denials"
  )
  
  # * Return ----
  return(data)
  
}

denials_tbl_formatter <- function(.data) {
  
  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) was not provided, please supply.")
  }
  
  # * Data ----
  data_tbl <- tibble::as_tibble(.data)
  
  # * Manipulate ----
  data_fmt_tbl <- data_tbl %>%
    dplyr::mutate(
      dplyr::across(
        .cols = where(is.character)
        , .fns = stringr::str_squish
      )
    ) %>%
    dplyr::mutate(
      dplyr::across(
        .cols = where(lubridate::is.Date)
        , .fns = lubridate::ymd_hms
      )
    ) %>%
    dplyr::mutate(admission_date = anytime::anydate(admission_date)) %>%
    dplyr::mutate(discharged = anytime::anydate(discharged)) %>%
    dplyr::mutate(
      dplyr::across(
        .cols = matches(
          "(_indicator)|(_ind)|(pending)|(finalized)|(patient_type)|(appl_)|(initial_denial)|(no_appeal)|(external_appeal)"
        )
        , .fns = as.factor
      )
    ) %>%
    dplyr::mutate(s_qm_subseq_appeal = as.factor(s_qm_subseq_appeal)) %>%
    dplyr::mutate(ptno_num = LICHospitalR::sql_right(tmbptbl_bill_no, 8)) %>%
    dplyr::select(ptno_num, dplyr::everything(), -tmbptbl_bill_no) %>%
    janitor::clean_names() %>%
    # Keep inpatients only
    dplyr::filter(LICHospitalR::sql_left(ptno_num, 1) == "1")
  
  # * Return ----
  return(data_fmt_tbl)
  
}

discharges_tbl_formatter <- function(.data) {
  
  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Data ----
  data_tbl <- tibble::as_tibble(.data)
  
  # * Manipulate ----
  data_fmt_tbl <- data_tbl %>%
    dplyr::mutate(dsch_date = lubridate::ymd(dsch_date)) %>%
    dplyr::mutate(in_or_out_threshold = stringr::str_replace(
        in_or_out_threshold
        , pattern = " "
        , replacement = "_"
      ) %>%
        stringr::str_to_lower()
    ) %>%
    dplyr::mutate(
      dplyr::across(
        where(is.character)
        , .fns = stringr::str_squish
      )
    ) %>%
    janitor::clean_names()
  
  # * Return ----
  return(data_tbl)

}
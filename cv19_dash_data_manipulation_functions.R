# Total Admitted Positive Tibble
tot_adm_pos_tbl <- function(.data) {
  
  # Checks
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing. Please supply.")
  }
  
  data_tbl <- tibble::as_tibble(.data) %>%
    janitor::clean_names()
  
  return(data_tbl)
  
}

# Total Admitted Suspect Tibble
tot_adm_suspect_tbl <- function(.data) {
  
  # Checks
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing. Please supply.")
  }
  
  data_tbl <- tibble::as_tibble(.data) %>%
    janitor::clean_names()
  
  return(data_tbl)
  
}

# Current Inpatients Grid
tot_adm_pos_sus_grid <- function(.data_pos, .data_sus) {
  
  # Checks
  if(!is.data.frame(.data_pos)) {
    stop(call. = FALSE, "(.data_pos) is missing. Please supply.")
  }
  
  if(!is.data.frame(.data_sus)) {
    stop(ccall. = FALSE, "(.data_sus) is missing. Please supply.")
  }
  
  data_pos <- tibble::as_tibble(.data_pos)
  data_sus <- tibble::as_tibble(.data_sus)
  
  tot_adm_pos_count <- data_pos %>% base::nrow()
  tot_adm_sus_count <- data_sus %>% base::nrow()
  
  data_tbl <- tibble::tribble(
    ~ "COVID Status", ~ "Patient Count"
    , "Positive", tot_adm_pos_count
    , "Suspect", tot_adm_sus_count
  ) %>%
    gt::gt() %>%
    gt::grand_summary_rows(
      columns = "Patient Count"
      , fns = list(
        Total = ~sum(.)
      )
    )
  
  return(data_tbl)
  
}

tot_adm_yesterday <- function(.data_pos, .data_sus){
  
  # Checks
  if(!is.data.frame(.data_pos)) {
    stop(call. = FALSE, "(.data_pos) is missing. Please supply.")
  }
  
  if(!is.data.frame(.data_sus)) {
    stop(ccall. = FALSE, "(.data_sus) is missing. Please supply.")
  }
  
  data_pos <- tibble::as_tibble(.data_pos) %>%
    janitor::clean_names() %>%
    dplyr::select(ptno_num, adm_dtime) %>%
    dplyr::arrange(adm_dtime) %>%
    dplyr::mutate(
      adm_dtime = lubridate::ymd_hms(adm_dtime) %>% 
        lubridate::floor_date(unit = "day")
    ) %>%
    dplyr::mutate(today = Sys.Date()) %>%
    dplyr::mutate(
      adm_days_ago = base::difftime(
          today, adm_dtime, units = "days"
        ) %>%
        as.integer()
    ) %>%
    dplyr::filter(adm_days_ago == 1) %>%
    base::nrow()
  
  data_sus <- tibble::as_tibble(.data_sus) %>%
    janitor::clean_names() %>%
    dplyr::select(ptno_num, adm_dtime) %>%
    dplyr::arrange(adm_dtime) %>%
    dplyr::mutate(
      adm_dtime = lubridate::ymd_hms(adm_dtime) %>% 
        lubridate::floor_date(unit = "day")
    ) %>%
    dplyr::mutate(today = Sys.Date()) %>%
    dplyr::mutate(
      adm_days_ago = base::difftime(
        today, adm_dtime, units = "days"
      ) %>%
        as.integer()
    ) %>%
    dplyr::filter(adm_days_ago == 1) %>%
    base::nrow()
  
  tay <- data_pos + data_sus
  
  return(tay)
  
}

tot_sus_group_a <- function(.data){
  
  # Check
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) was not supplied. Please supply.")
  }
  
  # Manip
  data_tbl <- tibble::as_tibble(.data)
  
  data_tbl <- data_tbl %>%
    dplyr::filter(Dx_Order_Abbr %>% 
                    stringr::str_to_lower() %>%
                    stringr::str_starts("c"))
  
  # Return
  return(data_tbl)
}

tot_sus_group_b <- function(.data){
  
  # Check
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) was not supplied. Please supply.")
  }
  
  # Manip
  data_tbl <- tibble::as_tibble(.data)
  
  data_tbl <- tot_adm_sus %>%
    dplyr::filter(
      Dx_Order_Abbr %>% 
        stringr::str_to_lower() %>%
        stringr::str_starts("n") |
      is.na(Dx_Order_Abbr)
    )
  
  # Return
  return(data_tbl)
}

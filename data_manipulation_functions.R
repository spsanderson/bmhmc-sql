# Real Time Staff and Census tibble
rt_staff_pt_tbl <- function(.data){
  
  # Checks
  if(!is.data.frame(.data)){
    stop(call. = FALSE,"(.data) is missing. Please supply.")
  }
  
  query <- tibble::as_tibble(.data)
  
  data_tbl <- query %>%
    select(-c(Staff_DateTime, Staff_Pt_Ratio)) %>%
    clean_names() %>%
    pivot_longer(
      census_count:staff_count
    ) %>%
    arrange(census_date_time)
  
  return(data_tbl)
}

# Real Time Staff and Census Ratio tibble
rt_staff_pt_ratio_tbl <- function(.data){
  
  # Checks
  if(!is.data.frame(.data)){
    stop(call. = FALSE,"(.data) is missing. Please supply.")
  }
  
  query <- tibble::as_tibble(.data)
  
  data_tbl <- query %>%
    clean_names() %>%
    select(census_date_time, staff_pt_ratio) %>%
    arrange(census_date_time)
  
  return(data_tbl)
  
}

# ESI Counts
esi_counts_tbl <- function(.data){
  
  # Checks
  if(!is.data.frame(.data)){
    stop(call. = FALSE,"(.data) is missing. Please supply.")
  }
  
  query <- tibble::as_tibble(.data)
  
  data_tbl <- query %>%
    clean_names() %>%
    select(census_date_time:esi_5) %>%
    pivot_longer(-census_date_time) %>%
    mutate(value = ifelse(is.na(value), 0, value))
  
  return(data_tbl)
}

# Staff Counts
staff_counts_tbl <- function(.data){
  
  # Checks
  if(!is.data.frame(.data)){
    stop(call. = FALSE,"(.data) is missing. Please supply.")
  }
  
  query <- tibble::as_tibble(.data)
  
  data_tbl <- query %>%
    clean_names() %>%
    select(!starts_with("esi")) %>%
    pivot_longer(-census_date_time) %>%
    mutate(value = ifelse(is.na(value), 0, value))
  
  return(data_tbl)
}

# Current ESI Counts and Staff Counts
current_esi_staff_counts_tbl <- function(.data){
  
  if(!is.data.frame(.data)) {
    stop(call. = FALSE,"(.data) is missing. Please supply.")
  }
  
  data <- tibble::as_tibble(.data)
  
  current_time <- max(data$Census_DateTime) %>% format("%A %B %d %Y at %I:%M %p")
  
  data_tbl <- data %>% 
    as_tibble() %>% 
    tail(1) %>% 
    clean_names() %>% 
    pivot_longer(-census_date_time) %>% 
    mutate(grouping = ifelse(str_starts(name, "esi"), "ESI","Staff")) %>%
    mutate(value = ifelse(is.na(value), 0, value)) %>%
    select(grouping, everything(), -census_date_time) %>%
    pivot_wider(id_cols = grouping) %>% 
    set_names(
      "Grouping",
      "ESI NULL","ESI 1","ESI 2","ESI 3","ESI 4","ESI 5"
      ,"Nurse Aide","Nurse Aide II","Registered Nurse") %>% 
    pivot_longer(-Grouping, values_drop_na = TRUE) %>% 
    rename("Count" = value) %>%
    gt(
      groupname_col = "Grouping"
      , rowname_col = "name"
    ) %>% 
    tab_header(
      title = "Current ESI and Staff Counts"
      , subtitle = paste(
        "As of: "
        , current_time
      )
    )
  
  return(data_tbl)
}

# Staff Need Tbl
staff_need_tbl <- function(.data) {
  
  if(!is.data.frame(.data)) {
    stop(call. = FALSE,"(.data) was not supplied. Please supply.")
  }
  
  data_tbl <- tibble::as_tibble(.data)
  
  data_tbl %>% 
    utils::tail(1) %>%
    janitor::clean_names() %>% 
    dplyr::rename(
      "ESI Null" = "esi_0"
      , "ESI 1" = "esi_1"
      , "ESI 2" = "esi_2"
      , "ESI 3" = "esi_3"
      , "ESI 4" = "esi_4"
      , "ESI 5" = "esi_5"
    ) %>%
    tidyr::pivot_longer(-census_date_time) %>%
    dplyr::mutate(name_test = stringr::str_detect(name, "nurse_")) %>%
    dplyr::filter(!name_test) %>%
    dplyr::select(-name_test) %>%
    dplyr::mutate(value = ifelse(is.na(value), 0, value)) %>%
    dplyr::mutate(
      staff_need = case_when(
        name == "esi_1" ~ (value * 1)
        , TRUE ~ round((value / 6), 2)
      )
    ) %>%
    dplyr::select(name:staff_need) %>%
    purrr::set_names("ESI Level","Patient Count","Staff Need") %>%
    gt::gt()  %>% 
    tab_header(
      title = "Current ESI Counts and Staff Needs"
    )
  
}

# Staff Title to Patient Ratio
staff_title_to_pt_ratio_tbl <- function(.data){
  
  if(!is.data.frame(.data)){
    stop(call. = FALSE,"(.data) is missing. Please supply.")
  }
  
  data_tbl <- tibble::as_tibble(.data)
  
  df_cleaned <- data_tbl %>%
    tibble::as_tibble() %>%
    replace(is.na(.), 0) %>%
    mutate(patients = rowSums(.[2:6])) %>%
    select(-starts_with("ESI_")) %>%
    clean_names() %>%
    select(census_date_time, patients, everything()) %>%
    mutate_if(is.numeric, replace_na, 0) %>%
    mutate(pt_to_na_ratio = ifelse(
      nurse_aide_count > 0
      , round(patients / nurse_aide_count, 3)
      , 0)) %>%
    mutate(pt_to_na_ii_ratio = ifelse(
      nurse_aide_ii_count > 0
      , round(patients / nurse_aide_ii_count, 3)
      , 0
    )) %>%
    mutate(pt_to_rn_ratio = ifelse(
      registered_nurse_count > 0
      , round(patients / registered_nurse_count, 3)
      , 0
    )) %>%
    select(census_date_time, ends_with("ratio")) %>%
    rename("Nurse Aide" = "pt_to_na_ratio"
           , "Nurse Aide II" = "pt_to_na_ii_ratio"
           , "RN" = "pt_to_rn_ratio") %>%
    pivot_longer(-census_date_time)
  
  return(df_cleaned)
}


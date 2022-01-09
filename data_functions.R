data_format_tbl <- function(.data) {
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Format ----
  data_tbl <- tibble::as_tibble(.data) %>%
    dplyr::mutate(val = stringr::str_replace(disp_val, "\r", "")) %>%
    dplyr::mutate(val = as.numeric(val)) %>%
    dplyr::filter(!is.na(val)) %>%
    dplyr::select(-disp_val) %>%
    dplyr::mutate(obsv_cd = dplyr::case_when(
      obsv_cd == "2012" ~ "INR",
      TRUE ~ "Glucose"
    ))
  
  # * Return ----
  return(data_tbl)
  
}

inr_data_tbl <- function(.data){
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply")
  }
  
  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data) %>%
    dplyr::filter(obsv_cd == "INR") %>%
    dplyr::mutate(gte_five = ifelse(val >= 5, 1, 0)) %>%
    timetk::summarise_by_time(
      .date_var          = coll_dtime
      , .by              = "month"
      , inr_observations = n()
      , inr_over_five    = sum(gte_five)
    ) %>%
    dplyr::mutate(
      inr_rate       = (inr_over_five / inr_observations)
      , inr_rate_txt = inr_rate %>% scales::percent(accuracy = 0.01)
    )
  
  # * Return ----
  return(data_tbl)
  
}

glucose_data_tbl <- function(.data){
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply")
  }
  
  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data) %>%
    dplyr::filter(obsv_cd == "Glucose") %>%
    dplyr::mutate(gte_200 = ifelse(val >= 200, 1, 0)) %>%
    dplyr::mutate(gte_300 = ifelse(val >= 300, 1, 0)) %>%
    dplyr::select(coll_dtime, dplyr::starts_with("gte_")) %>%
    tidyr::pivot_longer(-coll_dtime) %>%
    dplyr::group_by(coll_dtime, name) %>%
    timetk::summarise_by_time(
      .date_var              = coll_dtime
      , .by                  = "month"
      , glucose_observations = n()
      , over_threshold = sum(value)
    ) %>%
    dplyr::mutate(
      glucose_rate        = (over_threshold / glucose_observations)
      , glucose_rate_text = glucose_rate %>% scales::percent(accuracy = 0.01)
    ) %>%
    dplyr::ungroup()
  
  # * Return ----
  return(data_tbl)
  
}

inr_data_grid_tbl <- function(.data){
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Data Tbl ----
  data_tbl <- tibble::as_tibble(.data)
  
  data_grid <- data_tbl %>% 
    dplyr::select(-inr_rate) %>% 
    gt::gt() %>% 
    gt::tab_header(
      title = "INR Rates Over Time"
      , subtitle = "INR >= 5.0"
    ) %>% 
    gt::cols_label(
      coll_dtime         = "Collection Month"
      , inr_observations = "Observations"
      , inr_over_five    = "INR >= 5"
      , inr_rate_txt     = "Rate"
    ) %>% 
    gt::cols_align(
      align     = "center"
      , columns = c(inr_observations, inr_over_five)
    ) %>% 
    gt::tab_source_note(source_note = gt::md("**Source: DSS**"))
  
  # * Return ----
  return(data_grid)
  
}

glucose_data_grid_tbl <- function(
  .data, .value = c("gte_200", "gte_300")
  ){
  
  # * Tidyeval ----
  val_var_expr <- rlang::quo(.value)
  
  val_subtitle_var <- ifelse(
    rlang::quo_name(val_var_expr) == "gte_200", "200","300"
  )
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data)
  
  data_grid <- glucose_tbl %>%
    dplyr::filter(name == !! val_var_expr) %>%
    dplyr::select(-name, -glucose_rate) %>%
    gt::gt() %>% 
    gt::tab_header(
      title = "Glucose Rates Over Time"
      , subtitle = base::paste0("Glucose >= ", val_subtitle_var)
    ) %>% 
    gt::cols_label(
      coll_dtime             = "Collection Month"
      , glucose_observations = "Observations"
      , over_threshold       = base::paste0("Glucose >= ", val_subtitle_var)
      , glucose_rate_text     = "Rate"
    ) %>% 
    gt::cols_align(
      align     = "center"
      , columns = c(glucose_observations, over_threshold)
    ) %>% 
    gt::tab_source_note(source_note = gt::md("**Source: DSS**"))
  
  # * Return ----
  return(data_grid)
  
}

inr_over_threshold_accts <- function(.data) { 
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data)
  
  data_tbl <- data_tbl %>%
    dplyr::filter(obsv_cd == "INR") %>%
    dplyr::filter(val >= 5) %>%
    dplyr::select(episode_no) %>%
    dplyr::distinct() %>%
    dplyr::mutate(inr_over_threshold_flag = TRUE)
  
  # * Return ----
  return(data_tbl)
  
}

inr_under_threshold_accts <- function(.data) {
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data)
  
  data_tbl <- data_tbl %>%
    dplyr::filter(obsv_cd == "INR") %>%
    dplyr::filter(val <= 2.0) %>%
    dplyr::select(episode_no) %>%
    dplyr::distinct() %>%
    dplyr::mutate(inr_under_threshold_flag = TRUE)
  
  # * Return ----
  return(data_tbl)
  
}

inr_over_threshold_tbl <- function(.data){
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data)
  
  over_thresh_accts <- inr_over_threshold_accts(.data = data_tbl)
  
  data_tbl <- data_tbl %>%
    dplyr::filter(obsv_cd == "INR") %>%
    dplyr::left_join(
      over_thresh_accts
      , by = c("episode_no" = "episode_no")
    ) %>%
    dplyr::mutate(inr_over_threshold_flag = ifelse(
      is.na(inr_over_threshold_flag)
      , FALSE
      , TRUE)
    ) %>%
    dplyr::filter(inr_over_threshold_flag == TRUE) %>%
    dplyr::arrange(coll_dtime) %>%
    dplyr::group_by(episode_no) %>%
    dplyr::mutate(lab_number = row_number()) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(lab_number) %>%
    dplyr::mutate(
      median_val = stats::median(val, na.rm = TRUE),
      mean_val   = base::mean(val, na.rm = TRUE)
    ) %>%
    dplyr::ungroup()
  
  max_lab <- data_tbl %>%
    dplyr::count(lab_number) %>%
    dplyr::mutate(cum_lab = cumsum(n)) %>%
    dplyr::mutate(cum_pct = cum_lab/sum(n)) %>%
    dplyr::filter(cum_pct <= 0.965) %>%
    dplyr::filter(lab_number == max(lab_number)) %>%
    dplyr::pull(lab_number)
  
  data_tbl <- data_tbl %>%
    dplyr::filter(lab_number <= max_lab)
  
  # * Return ----
  return(data_tbl)
    
}

inr_under_threshold_tbl <- function(.data){
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data)
  
  under_thresh_accts <- inr_under_threshold_accts(.data = data_tbl)
  
  data_tbl <- data_tbl %>%
    dplyr::filter(obsv_cd == "INR") %>%
    dplyr::left_join(under_thresh_accts
                     , by = c("episode_no" = "episode_no")) %>%
    dplyr::mutate(inr_under_threshold_flag = ifelse(is.na(inr_under_threshold_flag)
                                                    , FALSE
                                                    , TRUE)) %>%
    dplyr::filter(inr_under_threshold_flag == TRUE) %>%
    dplyr::arrange(coll_dtime) %>%
    dplyr::group_by(episode_no) %>%
    dplyr::mutate(lab_number = row_number()) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(lab_number) %>%
    dplyr::mutate(
      median_val = stats::median(val, na.rm = TRUE),
      mean_val   = base::mean(val, na.rm = TRUE)
    ) %>%
    dplyr::ungroup()
  
  max_lab <- data_tbl %>%
    dplyr::count(lab_number) %>%
    dplyr::mutate(cum_lab = cumsum(n)) %>%
    dplyr::mutate(cum_pct = cum_lab/sum(n)) %>%
    dplyr::filter(cum_pct <= 0.965) %>%
    dplyr::filter(lab_number == max(lab_number)) %>%
    dplyr::pull(lab_number)
  
  data_tbl <- data_tbl %>%
    dplyr::filter(lab_number <= max_lab)
  
    # * Return ----
  return(data_tbl)
  
}

glucose_over_two_thresh_accts <- function(.data){
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data)
  
  data_tbl <- data_tbl %>%
    dplyr::filter(obsv_cd == "Glucose") %>%
    dplyr::filter(val >= 200) %>%
    dplyr::select(episode_no) %>%
    dplyr::distinct() %>%
    dplyr::mutate(gluc_over_two_threshold_flag = TRUE)
  
  # * Return ----
  return(data_tbl)
  
}

glucose_over_two_threshold_tbl <- function(.data, ...) {
  
  # * Tidyeval ----
  #group_var_exp <- rlang::quos(...)
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data)
  
  over_two_thresh_accts <- glucose_over_two_thresh_accts(data_tbl)
  
  data_tbl <- data_tbl %>%
    dplyr::filter(obsv_cd == "Glucose") %>%
    dplyr::left_join(over_two_thresh_accts
                     , by = c("episode_no" = "episode_no")) %>%
    dplyr::mutate(gluc_over_two_threshold_flag = ifelse(is.na(gluc_over_two_threshold_flag)
                                                    , FALSE
                                                    , TRUE)) %>%
    dplyr::filter(gluc_over_two_threshold_flag == TRUE) %>%
    dplyr::arrange(coll_dtime) %>%
    dplyr::group_by(episode_no) %>%
    dplyr::mutate(lab_number = row_number()) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(lab_number, ...) %>%
    dplyr::mutate(
      median_val = stats::median(val, na.rm = TRUE),
      mean_val   = base::mean(val, na.rm = TRUE)
    ) %>%
    dplyr::ungroup()
  
  # * Return ----
  return(data_tbl)
  
}

glucose_over_three_thresh_accts <- function(.data){
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data)
  
  data_tbl <- data_tbl %>%
    dplyr::filter(obsv_cd == "Glucose") %>%
    dplyr::filter(val >= 300) %>%
    dplyr::select(episode_no) %>%
    dplyr::distinct() %>%
    dplyr::mutate(gluc_over_three_threshold_flag = TRUE)
  
  # * Return ----
  return(data_tbl)
  
}

glucose_over_three_threshold_tbl <- function(.data, ...) {
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data)
  
  over_three_thresh_accts <- glucose_over_three_thresh_accts(data_tbl)
  
  data_tbl <- data_tbl %>%
    dplyr::filter(obsv_cd == "Glucose") %>%
    dplyr::left_join(over_three_thresh_accts
                     , by = c("episode_no" = "episode_no")) %>%
    dplyr::mutate(gluc_over_three_threshold_flag = ifelse(is.na(gluc_over_three_threshold_flag)
                                                        , FALSE
                                                        , TRUE)) %>%
    dplyr::filter(gluc_over_three_threshold_flag == TRUE) %>%
    dplyr::arrange(coll_dtime) %>%
    dplyr::group_by(episode_no) %>%
    dplyr::mutate(lab_number = row_number()) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(lab_number, ...) %>%
    dplyr::mutate(
      median_val = stats::median(val, na.rm = TRUE),
      mean_val   = base::mean(val, na.rm = TRUE)
    ) %>%
    dplyr::ungroup()
  
  # * Return ----
  return(data_tbl)
  
}

roll_mean_tbl <- function(.data, .obsv_cd = ""
                          , .roll_days = 5, .length_out = 7){
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Tidyeval ----
  obsv_cd_var_expr    <- rlang::as_string(.obsv_cd)
  roll_days_var_expr  <- .roll_days
  length_out_var_expr <- .length_out
  
  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data) %>%
    dplyr::filter(obsv_cd == {{ obsv_cd_var_expr }}) %>%
    dplyr::mutate(coll_date = as.Date(coll_dtime)) %>% 
    dplyr::select(-coll_dtime) %>% 
    dplyr::group_by(episode_no, coll_date) %>% 
    dplyr::arrange(coll_date) %>% 
    dplyr::mutate(mean_val = mean(val, na.rm = TRUE)) %>% 
    dplyr::ungroup() %>% 
    dplyr::group_by(episode_no) %>% 
    dplyr::mutate(
      roll_mean = rollmean(
        val
        , {{ roll_days_var_expr }}
        , "left"
        ,fill = 0
      )) %>% 
    dplyr::mutate(lab_number = dplyr::row_number()) %>%
    dplyr::ungroup() %>% 
    dplyr::filter(roll_mean > 0) %>%
    dplyr::distinct() %>%
    dplyr::filter(lab_number <= {{ length_out_var_expr }}) %>%
    dplyr::group_by(episode_no) %>%
    dplyr::mutate(
      lab_n = dplyr::row_number()
    ) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(lab_n) %>%
    dplyr::mutate(
      mean_val     = mean(mean_val, na.rm = TRUE)
      , mean_roll  = mean(roll_mean, na.rm = TRUE)
    ) %>%
    dplyr::ungroup()
  
  # * Return ----
  return(data_tbl)
  
}

diabetes_tbl <- function(.data) {
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data)
  
  data_tbl <- data_tbl %>% 
    tidyr::pivot_wider(
      id_cols = Med_Rec_No
      , names_from = diabetes_type_flag
      , values_from = diabetes_type_flag
    ) %>% 
    dplyr::mutate(diabetes_type_flag = dplyr::coalesce(TYPE_1, TYPE_2, OTHER)) %>% 
    dplyr::select(Med_Rec_No, diabetes_type_flag) %>% 
    dplyr::distinct(Med_Rec_No, diabetes_type_flag)
  
  # * Return ----
  return(data_tbl)
  
}

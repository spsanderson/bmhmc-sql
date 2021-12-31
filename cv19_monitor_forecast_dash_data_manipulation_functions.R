# Query Summary and Manipulation Functions ----
# Total Admitted Positive Tibble Functions
tot_ed_visits_daily_tbl <- function(.data) {
  
  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing. Please supply.")
  }
  
  # * Manipulation ----
  data_tbl <- tibble::as_tibble(.data) %>%
    janitor::clean_names() %>%
    dplyr::mutate(arrival_date = as.Date.character(arrival_date, format = c("%Y-%m-%d"))) %>%
    dplyr::mutate(date_col = arrival_date) %>%
    dplyr::select(-arrival_date) %>%
    dplyr::select( date_col, visit_count) %>%
    dplyr::rename("value" = "visit_count") %>%
    timetk::summarise_by_time(
      .date_var = date_col
      , .by = "day"
      , value = sum(value)
    )
  
  # * Return ----
  return(data_tbl)
  
}

tot_ed_covid_visits_daily_tbl <- function(.data) {
  
  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE,"(.data) is missing. Please supply.")
  }
  
  # * Manipulation ----
  data_tbl <- tibble::as_tibble(.data) %>%
    janitor::clean_names() %>%
    dplyr::mutate(date_col = lubridate::ymd(date_col)) %>%
    timetk::summarise_by_time(
      .date_var = date_col
      , .by = "day"
      , value = sum(value)
    ) %>%
    timetk::pad_by_time(
      .date_var = date_col
      , .pad_value = 0
    )
  
  # * Return ----
  return(data_tbl)
  
}

# Table Latest NYS CV-19 Testing Data
covid_daily_test_tbl <- function(){
  
  # * Get Data ----
  nys_cv_tbl <- read.csv("00_Data/nys_data/ny_covid_data.csv")
  
  # Get data by county Suffolk and Nassau
  suffolk_tbl <- nys_cv_tbl %>%
    tibble::as_tibble() %>%
    purrr::set_names(
      "test_date"
      , "county"
      , "new_pos"
      , "cum_pos"
      , "tot_tst"
      , "cum_tst"
    ) %>%
    dplyr::mutate(test_date = lubridate::mdy(test_date)) %>%
    dplyr::filter(county == "Suffolk") %>%
    dplyr::mutate(new_pos = stringr::str_remove_all(new_pos, ",") %>%
                    as.double()) %>%
    dplyr::mutate(cum_pos = stringr::str_remove_all(cum_pos, ",") %>%
                    as.double()) %>%
    dplyr::mutate(tot_tst = stringr::str_remove_all(tot_tst, ",") %>%
                    as.double()) %>%
    dplyr::mutate(cum_tst = stringr::str_remove_all(cum_tst, ",") %>%
                    as.double()) %>%
    utils::tail(1) %>%
    dplyr::mutate(
      pos_since_march     = round(cum_pos / cum_tst, 3)
      , pct_pos_yesterday = round(new_pos / tot_tst, 3)
    )
  
  nassau_tbl <- nys_cv_tbl %>%
    tibble::as_tibble() %>%
    purrr::set_names(
      "test_date"
      , "county"
      , "new_pos"
      , "cum_pos"
      , "tot_tst"
      , "cum_tst"
    ) %>%
    dplyr::mutate(test_date = lubridate::mdy(test_date)) %>%
    dplyr::filter(county == "Nassau") %>%
    dplyr::mutate(new_pos = stringr::str_remove_all(new_pos, ",") %>%
                    as.double()) %>%
    dplyr::mutate(cum_pos = stringr::str_remove_all(cum_pos, ",") %>%
                    as.double()) %>%
    dplyr::mutate(tot_tst = stringr::str_remove_all(tot_tst, ",") %>%
                    as.double()) %>%
    dplyr::mutate(cum_tst = stringr::str_remove_all(cum_tst, ",") %>%
                    as.double()) %>%
    utils::tail(1) %>%
    dplyr::mutate(
      pos_since_march     = round(cum_pos / cum_tst, 3)
      , pct_pos_yesterday = round(new_pos / tot_tst, 3)
    )
  
  long_island_tbl <- nys_cv_tbl %>%
    tibble::as_tibble() %>%
    purrr::set_names(
      "test_date"
      , "county"
      , "new_pos"
      , "cum_pos"
      , "tot_tst"
      , "cum_tst"
    ) %>%
    dplyr::mutate(test_date = lubridate::mdy(test_date)) %>%
    dplyr::filter(county %in% c("Suffolk","Nassau")) %>%
    dplyr::mutate(county = "Long Island") %>%
    dplyr::mutate(new_pos = stringr::str_remove_all(new_pos, ",") %>%
                    as.double()) %>%
    dplyr::mutate(cum_pos = stringr::str_remove_all(cum_pos, ",") %>%
                    as.double()) %>%
    dplyr::mutate(tot_tst = stringr::str_remove_all(tot_tst, ",") %>%
                    as.double()) %>%
    dplyr::mutate(cum_tst = stringr::str_remove_all(cum_tst, ",") %>%
                    as.double()) %>%
    dplyr::group_by(test_date, county) %>%
    dplyr::summarise(
      new_pos   = sum(new_pos)
      , cum_pos = sum(cum_pos)
      , tot_tst = sum(tot_tst)
      , cum_tst = sum(cum_tst)
    ) %>%
    utils::tail(1) %>%
    dplyr::mutate(
      pos_since_march     = round(cum_pos / cum_tst, 3)
      , pct_pos_yesterday = round(new_pos / tot_tst, 3)
    )
  
  data_tbl <- rbind(nassau_tbl, suffolk_tbl, long_island_tbl)
  
  test_date <- data_tbl %>% 
    dplyr::select(test_date) %>%
    utils::head(1) %>%
    dplyr::pull()
  
  subtitle_data_source <- "New York State Statewide COVID-19 Testing"
  subtitle_data_url    <- "https://healthy.data.ny.gov"
  
  dt <- data_tbl %>%
    dplyr::select(-test_date) %>%
    dplyr::mutate(pos_since_march = scales::percent(pos_since_march, accuracy = 0.1)) %>%
    dplyr::mutate(pct_pos_yesterday = scales::percent(pct_pos_yesterday, accuracy = 0.1)) %>%
    dplyr::mutate(new_pos = scales::number(new_pos, big.mark = ",")) %>%
    dplyr::mutate(cum_pos = scales::number(cum_pos, big.mark = ",")) %>%
    dplyr::mutate(tot_tst = scales::number(tot_tst, big.mark = ",")) %>%
    dplyr::mutate(cum_tst = scales::number(cum_tst, big.mark = ",")) %>%
    dplyr::mutate_all(as.character) %>%
    purrr::set_names(
      "County"
      , "New Positives"
      , "Cumulative Positives"
      , "Total Tested"
      , "Cumulative Tested"
      , "Positive Since March"
      , "Positive Yesterday"
    ) %>%
    tidyr::pivot_longer(
      cols = -County
    ) %>%
    tidyr::pivot_wider(
      names_from = County
      , values_from = value
    ) %>%
    dplyr::rename("County" = "name") %>%
    gt::gt() %>%
    gt::tab_header(title = "Long Island COVID-19 Testing Stats"
                   , subtitle = paste(subtitle_data_source)) %>%
    gt::tab_source_note("Data URL: https://health.data.ny.gov") %>%
    gt::tab_source_note(base::paste("Data as of: ", test_date))
  
  # * Return ----
  return(dt)
  
}

# Test Results Time Series Tbl
test_result_tbl <- function() {
  
  # * Get Data ----
  dss_test_results_tbl <- get_test_results_query() %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::rename("result_dtime" = "result_d_time") %>%
    dplyr::mutate(result_dtime = lubridate::ymd_hms(result_dtime))
  
  dss_tbl <- dss_test_results_tbl %>%
    dplyr::mutate(result_date = as.Date(result_dtime)) %>%
    dplyr::select(-result_dtime) %>%
    dplyr::select(result_date, everything()) %>%
    dplyr::group_by(result_clean) %>%
    timetk::summarise_by_time(
      .date_var = result_date
      , .by = "month"
      , value = dplyr::n()
      , .type = "floor"
    ) %>%
    dplyr::ungroup() %>%
    dplyr::select(result_date, result_clean, value) %>%
    tidyr::pivot_wider(names_from = result_clean, values_from = value) %>%
    dplyr::filter(!is.na(result_date)) %>%
    janitor::clean_names() %>%
    dplyr::mutate(
      total = detected + not_detected
      , pct_pos = round(detected / total, 3)
    ) %>%
    dplyr::select(-not_detected)  %>%
    purrr::set_names("result_date","detected","total","pct_pos")
  
  # NYS Data
  nys_cv_tbl <- read.csv("00_Data/nys_data/ny_covid_data.csv")
  
  # Suffolk Table
  suffolk_tbl <- nys_cv_tbl %>%
    tibble::as_tibble() %>%
    purrr::set_names(
      "test_date"
      , "county"
      , "new_pos"
      , "cum_pos"
      , "tot_tst"
      , "cum_tst"
    ) %>%
    dplyr::filter(county == "Suffolk") %>%
    dplyr::mutate(test_date = lubridate::mdy(test_date)) %>%
    dplyr::select(test_date, new_pos, tot_tst) %>%
    dplyr::mutate(new_pos = stringr::str_remove_all(new_pos, ",") %>%
                    as.double()) %>%
    dplyr::mutate(tot_tst = stringr::str_remove_all(tot_tst, ",") %>%
                    as.double()) %>%
    dplyr::group_by(test_date) %>%
    timetk::summarise_by_time(
      .date_var = test_date
      , .by = "month"
      , across(c(new_pos, tot_tst), sum)
    ) %>%
    dplyr::mutate(
      pct_pos = round(new_pos / tot_tst, 3)
    ) %>%
    purrr::set_names("result_date","detected","total","pct_pos")
  
  # Nassau Table
  nassau_tbl <- nys_cv_tbl %>%
    tibble::as_tibble() %>%
    purrr::set_names(
      "test_date"
      , "county"
      , "new_pos"
      , "cum_pos"
      , "tot_tst"
      , "cum_tst"
    ) %>%
    dplyr::filter(county == "Nassau") %>%
    dplyr::mutate(test_date = lubridate::mdy(test_date)) %>%
    dplyr::select(test_date, new_pos, tot_tst) %>%
    dplyr::mutate(new_pos = stringr::str_remove_all(new_pos, ",") %>%
                    as.double()) %>%
    dplyr::mutate(tot_tst = stringr::str_remove_all(tot_tst, ",") %>%
                    as.double()) %>%
    dplyr::group_by(test_date) %>%
    timetk::summarise_by_time(
      .date_var = test_date
      , .by = "month"
      , across(c(new_pos, tot_tst), sum)
    ) %>%
    dplyr::mutate(
      pct_pos = round(new_pos / tot_tst, 3)
    ) %>%
    purrr::set_names("result_date","detected","total","pct_pos")
  
  # * Column Bind Tables ----
  data_tbl <- bind_cols(
    dss_tbl
    , suffolk_tbl
    , nassau_tbl
    ) %>%
    dplyr::select(-5, -9) %>%
    dplyr::glimpse() %>%
    purrr::set_names(
      "Date", "Hosp Pos", "Hosp Total", "Hosp Pos %"
      , "Suffolk Pos", "Suffolk Total", "Suffolk Pos %"
      , "Nassau Pos", "Nassau Total", "Nassau Pos %"
    ) %>%
    dplyr::mutate(
      `Hosp Pos`        = scales::number(`Hosp Pos`, accuracy = 1, big.mark = ",")
      , `Hosp Total`    = scales::number(`Hosp Total`, accuracy = 1, big.mark = ",")
      , `Hosp Pos %`    = scales::percent(`Hosp Pos %`, accuracy = 0.1)
      , `Suffolk Pos`   = scales::number(`Suffolk Pos`, accuracy = 1, big.mark = ",")
      , `Suffolk Total` = scales::number(`Suffolk Total`, accuracy = 1, big.mark = ",")
      , `Suffolk Pos %` = scales::percent(`Suffolk Pos %`, accuracy = 0.1)
      , `Nassau Pos`    = scales::number(`Nassau Pos`, accuracy = 1, big.mark = ",")
      , `Nassau Total`  = scales::number(`Nassau Total`, accuracy = 1, big.mark = ",")
      , `Nassau Pos %`  = scales::percent(`Nassau Pos %`, accuracy = 0.1)
    )
  
  return(data_tbl)
  
}

test_result_gt_tbl <- function(.data) {
  
  # Check
  if(!is.data.frame(.data)){
    stop(call. = FALSE,"(.data) is missing. Please supply.")
  }
  
  data_tbl <- tibble::as_tibble(.data)
  
  dt <- data_tbl %>%
    gt::gt() %>%
    gt::tab_header(
      title = "Comparative Data"
      , subtitle = "Hospital compared to Nassau and Suffolk Counties"
    ) %>%
    gt::tab_source_note("Nassau Suffolk Data: https://health.data.ny.gov") %>%
    gt::tab_source_note("Hospital Data Source: DSS") %>%
    gt::tab_options(
      table.font.size = 14
      , 
    ) %>%
    gt::cols_align("center")
  
  # * Return ----
  return(dt)
  
}

# Total Admitted Positive TS Tibble
tot_adm_pos_ts_tbl <- function() {
  
  # * Get Data ----
  # Load RDS File
  tot_adm_pos_rds <- readr::read_rds(file = "00_Data/back_load_spreadsheet/tot_adm_pos_tbl.RDS") %>%
    purrr::set_names("date_col","value")
  
  tot_adm_pos_qry <- tot_adm_covid_pos_query()
  
  data_tbl <- rbind(tot_adm_pos_rds, tot_adm_pos_qry) %>%
    tibble::as_tibble() %>%
    dplyr::mutate(value = as.double(value))
  
  # * Return ----
  return(data_tbl)
  
}

# Total Admitted Suspect TS Tibble
tot_adm_sus_ts_tbl <- function() {
  
  # * Get Data ----
  # Load RDS File
  tot_adm_sus_rds <- readr::read_rds(file = "00_Data/back_load_spreadsheet/tot_adm_sus_tbl.RDS") %>%
    purrr::set_names("date_col","value")
  
  tot_adm_sus_qry <- tot_adm_covid_sus_query()
  
  data_tbl <- rbind(tot_adm_sus_rds, tot_adm_sus_qry) %>%
    tibble::as_tibble() %>%
    dplyr::mutate(value = as.double(value))
  
  # * Return ----
  return(data_tbl)
  
}

# ALOS COVID Positive Patients Discharged Yesterday Tibble
covid_pos_dsch_yday_alos_tbl <- function(.data){
  
  # Checks
  if(!is.data.frame(.data)){
    stop(call. = FALSE,"(.data) is missing. Please supply.")
  }
  
  # * Manipulation ----
  data_tbl <- tibble::as_tibble(.data) %>%
    dplyr::mutate(date_col = as.Date(date_col))
  
  start_date <- min(data_tbl$date_col) %>% as.Date()
  end_date   <- max(data_tbl$date_col) %>% as.Date()
  
  data_tbl <- data_tbl %>%
    timetk::pad_by_time(
      .date_var    = date_col
      , .by        = "day"
      , .pad_value = 0
      ) %>%
    timetk::summarise_by_time(
      .date_var = date_col
      , .by     = "day"
      , value   = round(mean(value), 2)
    )
  
  return(data_tbl)
  
}

# ALOS COVID Positive Patients In House Tibble
covid_pos_inhouse_alos_tbl <- function(.data){
  
  # Checks
  if(!is.data.frame(.data)){
    stop(call. = FALSE,"(.data) is missing. Please supply.")
  }
  
  # * Manipulation ----
  data_tbl <- tibble::as_tibble(.data) %>%
    dplyr::mutate(date_col = as.Date(date_col))
  
  start_date <- min(data_tbl$date_col) %>% as.Date()
  end_date   <- max(data_tbl$date_col) %>% as.Date()
  
  data_tbl <- data_tbl %>%
    timetk::pad_by_time(
      .date_var    = date_col
      , .by        = "day"
      , .pad_value = 0
    ) %>%
    timetk::summarise_by_time(
      .date_var = date_col
      , .by     = "day"
      , value   = round(mean(value), 2)
    )
  
  return(data_tbl)
  
}

# HHS Hospitalization Tibble
hhs_hospitalization_ts_tbl <- function() {
  
  # * Get Data ----
  data_tbl <- read.csv(file = "00_Data/hhs_data/hhs_hospital_data.csv") %>%
    dplyr::select(1, date, inpatient_beds_used_covid) %>%
    purrr::set_names("state","date","value") %>%
    dplyr::mutate(date_col = as.Date(date)) %>%
    dplyr::filter(state == "NY") %>%
    dplyr::arrange(date_col) %>%
    dplyr::select(date_col, value)
  
  # * Return ----
  return(data_tbl)
  
}

# Inpatient Table
inpatient_cv19_tbl <- function() {
  
  # * Get Data ----
  positive_value <- tot_adm_covid_pos_query() %>%
    utils::tail(1) %>%
    dplyr::pull(value)
  suspect_value <- tot_adm_covid_sus_query() %>%
    utils::tail(1) %>%
    dplyr::pull(value)
  total_value    <- positive_value + suspect_value
  
  # * Manipulation ----
  g_tbl <- tibble::tribble(
    ~"Inpatient Status", ~"Count"
    , "Positive", positive_value
    , "Suspect", suspect_value
    , "Total COVID related Inpatients", total_value
  ) %>%
    gt::gt() %>%
    gt::tab_header(
      title = "LI Community Hospital Daily COVID Report"
      , subtitle = "Current Inpatients - COVID Related"
    ) %>%
    gt::tab_footnote(
      footnote = "Data Source: DSS"
      , locations = gt::cells_column_labels(
        columns = gt::vars(Count)
      )
    )
  
  # * Return ----
  return(g_tbl)
  
}

# ALOS of CV+ patients who have never been in the ICU with los tibble
cv_pos_inhouse_no_icu_los_tbl <- function(){
  
  # * Run Initial Queries ----
  # Get patient base
  cv_pos_inhouse_no_icu_query()
  # Get los of each patient each day
  cv_pos_inhouse_no_icu_los_query()
  
  # * Connect DB ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = paste0(
      "
      SELECT CAST([Date] AS DATE) AS [Date_col],
      CAST([arrival] AS DATE) AS [arrival],
      CAST([departure] AS DATE) AS [departure],
      ptno_num,
      los,
      in_house
      FROM smsdss.c_covid_inhouse_los_final_tbl
      ORDER BY in_house, [Date]
      "
    )
  )
  
  db_disconnect(.connection = db_conn)
  
  # * Manipulate ----
  data <- tibble::as_tibble(query)
  
  data_tbl <- data %>%
    janitor::clean_names() %>%
    dplyr::mutate(
      date_col    = as.Date(date_col)
      , arrival   = as.Date(arrival)
      , departure = as.Date(departure)
    )
  
  data_summary_tbl <- data_tbl %>%
    timetk::summarise_by_time(
      .date_var = date_col
      , .by   = "day"
      , pts   = dplyr::n()
      , value = round(mean(los, na.rm = TRUE), 2)
    )
  
  # * Return ----
  return(data_summary_tbl)
}


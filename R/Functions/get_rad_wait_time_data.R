get_rad_wait_time_data <- function(data, months) {
  # get file
  file.to.load <- tryCatch(file.choose(new = T), error = function(e) "")
  
  # Months
  months = as.list(months)
  
  # read the file in and clean col names
  df <- read.csv(file.to.load) %>%
    clean_names()
  
  # clean file and mutate columns
  df_clean <- df %>%
    filter(!is.na(acc)) %>%
    select(
      mrn
      , step_start_time
      , step_end_time
      , step_from_to
      , wait_time
    ) %>%
    mutate(
      step_start_time_clean = mdy_hms(step_start_time)
      , step_end_time_clean = mdy_hms(step_end_time)
      , elapsed_time = difftime(step_end_time_clean, step_start_time_clean, units = "mins")
      , elapsed_time_int = as.integer(elapsed_time)
      , procedure_start_year = year(step_start_time_clean)
      , procedure_start_month = month(step_start_time_clean)
      , procedure_start_month_name = month(step_start_time_clean, label = T, abbr = T)
      , procedure_start_day = day(step_start_time_clean)
      , procedure_start_dow = wday(step_start_time_clean, label = T, abbr = T)
      , procedure_start_hour = hour(step_start_time_clean)
      , procedure_end_year = year(step_end_time_clean)
      , procedure_end_month = month(step_end_time_clean)
      , procedure_end_month_name = month(step_end_time_clean, label = T, abbr = T)
      , procedure_end_day = day(step_end_time_clean)
      , procedure_end_dow = wday(step_end_time_clean, label = T, abbr = T)
      , procedure_end_hour = hour(step_end_time_clean)
    ) %>%
    filter(procedure_start_month_name %in% months) %>%
    filter(elapsed_time_int >= 0)
  
  dt <- data.table(df_clean)
  dt[, mrn := na.locf(mrn, fromLast = T, na.rm = F)]
  df_clean <- setDF(dt)
  
  # Get avg time per proc
  df_summary <- df_clean %>%
    group_by(mrn, step_start_time_clean, step_end_time_clean) %>%
    mutate(
      proc_count = n()
      , avg_time_per_proc = round(elapsed_time_int / proc_count, 2)
    ) %>%
    as.data.frame(df_tt_a) %>%
    distinct()
  
  df_clean <- as.data.frame(df_summary)
}

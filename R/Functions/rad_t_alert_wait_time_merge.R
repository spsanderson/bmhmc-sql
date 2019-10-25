rad_t_alert_wait_time_merge <- function(df_clean, df_t_alert){
  
  t_alert <- tryCatch(file.choose(new = T), error = function(e) "")
  
  df_t_alert <- read.csv(t_alert) %>%
    clean_names() %>%
    filter(dsch_date != "NULL") %>%
    filter(dsch_date != "#N/A")
  
  df_t_alert$account <- as.factor(df_t_alert$account)
  df_t_alert$mrn <- as.integer(df_t_alert$mrn)
  df_t_alert$arrival <- lubridate::mdy_hm(df_t_alert$arrival)
  df_t_alert$time_left_ed <- lubridate::mdy_hm(df_t_alert$time_left_ed)
  df_t_alert$dsch_date <- lubridate::mdy(df_t_alert$dsch_date)
  
  df_t_alert <- df_t_alert %>%
    select(
      mrn
      , account
      , patient
      , arrival
      , time_left_ed
      , dsch_date
      , age
      , order
      , md_sig
    )
  
  df_merge_a <- merge(
    df_clean
    , df_t_alert
    , by = "mrn"
  )
  
  # flag step_start_time_clean >= arrival &
  #      step_end_time_clean <= time_left_ed
  df_merge_a$keep_flag <- ifelse(
    (
      (df_merge_a$step_start_time_clean >= df_merge_a$arrival) & 
        (
          (df_merge_a$step_end_time_clean <= df_merge_a$time_left_ed) | 
            (df_merge_a$step_end_time_clean <= df_merge_a$dsch_date)
        )
    )
    , 1
    , 0
  )
  
  df_merge_a <- as.data.frame(df_merge_a)
  
}
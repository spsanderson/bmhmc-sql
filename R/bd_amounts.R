library(tidyverse)

bd_encounters <- readxl::read_excel(
  path = "S:/Global Finance/ICR20/Medicare Audit S-10 Figliozzi/Files For Steve/encounters.xlsx",
  sheet = "bd_encounters"
) %>%
dplyr::mutate(ptno_num = as.character(ptno_num))

bd_filtered_tbl <- df_tbl %>%
  dplyr::select(1:10) %>%
  purrr::set_names(
    "POST_DATE","SERVICE_DATE","PT_NO","SOURCE","DR_ACCOUNT","DR_AMT","CR_ACCOUNT",
    "CR_AMT","TRANS_TYPE","IMPACT"
  ) %>%
  dplyr::select(1:5,10,7:9) %>%
  dplyr::filter(POST_DATE != "POST") %>%
  dplyr::filter(!is.na(SERVICE_DATE)) %>%
  dplyr::rename("DR_AMT" = IMPACT) %>%
  dplyr::mutate(DR_AMT = stringr::str_remove_all(DR_AMT, ",") %>% as.numeric()) %>%
  dplyr::mutate(POST_DATE = lubridate::mdy(POST_DATE)) %>%
  dplyr::mutate(SERVICE_DATE = lubridate::mdy(SERVICE_DATE)) %>%
  dplyr::arrange(POST_DATE) %>%
  dplyr::mutate(PTNO_NUM = substr(PT_NO, 5, 12)) %>%
  dplyr::inner_join(bd_encounters, by = c("PTNO_NUM"="ptno_num")) %>%
  dplyr::arrange(POST_DATE)

total_life_long_bd_tbl <- bd_filtered_tbl %>%
  dplyr::with_groups(
    .groups = PTNO_NUM,
    .f = summarise,
    total_bad_debt = round(sum(DR_AMT, na.rm = TRUE), 3)
  )

utils::write.csv(
  x = total_life_long_bd_tbl,
  file = "S:/Global Finance/ICR20/Medicare Audit S-10 Figliozzi/Files For Steve/bd_total_life_bd.csv"
)

total_bd_by_trans_type_tbl <- bd_filtered_tbl %>%
  dplyr::with_groups(
    .groups = c(PTNO_NUM, TRANS_TYPE),
    .f = summarise,
    total_bad_debt_amt = sum(DR_AMT, na.rm = TRUE)
  ) %>%
  tidyr::pivot_wider(
    names_from = TRANS_TYPE,
    values_from = total_bad_debt_amt
  )

utils::write.csv(
  x = total_bd_by_trans_type_tbl,
  file = "S:/Global Finance/ICR20/Medicare Audit S-10 Figliozzi/Files For Steve/bd_total_bd_by_trans_type.csv"
)

bd_filtered_tbl %>%
  timetk::filter_by_time(
    .date_var = POST_DATE,
    .end_date = "2019"
  ) %>%
  dplyr::filter(TRANS_TYPE == "BD_Recovery") %>%
  dplyr::select(PTNO_NUM, DR_AMT) %>%
  dplyr::mutate(DR_AMT = as.numeric(DR_AMT)) %>%
  dplyr::group_by(PTNO_NUM) %>%
  dplyr::summarise(prior_recovery = sum(DR_AMT, na.rm = TRUE)) %>%
  dplyr::ungroup() %>%
  utils::write.csv(
    file = "S:/Global Finance/ICR20/Medicare Audit S-10 Figliozzi/Files For Steve/bd_prior_recoveries_tbl.csv"
  )

bd_filtered_tbl %>%
  timetk::filter_by_time(
    .date_var = POST_DATE,
    .start_date = "2021"
  ) %>%
  dplyr::filter(TRANS_TYPE == "BD_Recovery") %>%
  dplyr::select(PTNO_NUM, DR_AMT) %>%
  dplyr::mutate(DR_AMT = as.numeric(DR_AMT)) %>%
  dplyr::group_by(PTNO_NUM) %>%
  dplyr::summarise(post_recovery = sum(DR_AMT, na.rm = TRUE)) %>%
  dplyr::ungroup() %>%
  utils::write.csv(
    file = "S:/Global Finance/ICR20/Medicare Audit S-10 Figliozzi/Files For Steve/bd_post_recoveries_tbl.csv"
  )

bd_filtered_tbl %>%
  # timetk::filter_by_time(
  #   .date_var = POST_DATE,
  #   .start_date = "2020",
  #   .end_date = "2020"
  # ) %>%
  dplyr::filter(TRANS_TYPE != "BD_Recovery") %>%
  dplyr::select(PTNO_NUM, POST_DATE) %>%
  dplyr:::group_by(PTNO_NUM) %>%
  dplyr::summarise(max_date = max(POST_DATE)) %>%
  dplyr::ungroup() %>%
  utils::write.csv(
    file = "S:/Global Finance/ICR20/Medicare Audit S-10 Figliozzi/Files For Steve/bd_max_wo_date.csv"
  )

bd_filtered_tbl %>%
  dplyr::filter(TRANS_TYPE != "BD_Recovery") %>%
  timetk::filter_by_time(
    .date_var = POST_DATE,
    .start_date = "2021"
  ) %>%
  dplyr::group_by(PTNO_NUM) %>%
  dplyr::summarise(post_wo_amt = sum(as.numeric(DR_AMT), na.rm = TRUE)) %>%
  dplyr::ungroup() %>%
  utils::write.csv(
    file = "S:/Global Finance/ICR20/Medicare Audit S-10 Figliozzi/Files For Steve/bd_post_wo_amt.csv"
  )

bd_filtered_tbl %>%
  dplyr::filter(TRANS_TYPE != "BD_Recovery") %>%
  timetk::filter_by_time(
    .date_var = POST_DATE,
    .end_date = "2019"
  ) %>%
  dplyr::group_by(PTNO_NUM) %>%
  dplyr::summarise(post_wo_amt = sum(as.numeric(DR_AMT), na.rm = TRUE)) %>%
  dplyr::ungroup() %>%
  utils::write.csv(
    file = "S:/Global Finance/ICR20/Medicare Audit S-10 Figliozzi/Files For Steve/bd_prior_wo_amt.csv"
  )

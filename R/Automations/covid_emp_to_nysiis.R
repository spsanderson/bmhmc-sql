nysiis_tbl <- readxl::read_excel(
    path = "C:/Users/bha485/Desktop/employee_nysiis_list.xlsx"
  ) %>%
  janitor::clean_names()

nysiis_final_tbl <- nysiis_tbl %>%
  dplyr::mutate(
    birth_date = as.Date(birth_date) %>% 
      stringr::str_replace_all(pattern = "-", replacement = "_")
  ) %>%
  dplyr::mutate(
    pt_key = stringr::str_c(
      stringr::str_to_lower(last_name) %>%
        stringr::str_replace_all("-","") %>%
        stringr::str_replace_all(" ","")
      , stringr::str_to_lower(first_name)
      , birth_date
      , sep = "_"
    )
  ) %>%
  dplyr::group_by(pt_key) %>%
  dplyr::mutate(
    dose_number = dplyr::row_number(vaccination_date)
  ) %>%
  dplyr::ungroup()

emp_a_tbl <- readxl::read_excel(
    path = "C:/Users/bha485/Desktop/employee_list.xlsx"
    , sheet = "COMPANY 1000"
  ) %>%
  janitor::clean_names() %>%
  dplyr::select(last_name, first_name, birthdate)

emp_b_tbl <- readxl::read_excel(
  path = "C:/Users/bha485/Desktop/employee_list.xlsx"
  , sheet = "COMPANY 5000"
) %>%
  janitor::clean_names() %>%
  dplyr::select(last_name, first_name, birthdate)

emp_tbl <- rbind(emp_a_tbl, emp_b_tbl)

emp_final_tbl <- emp_tbl %>%
  dplyr::mutate(
    birthdate = as.Date(birthdate) %>% 
      stringr::str_replace_all(pattern = "-", replacement = "_")
  ) %>%
  dplyr::mutate(
    pt_key = stringr::str_c(
      stringr::str_to_lower(last_name) %>%
        stringr::str_replace_all("-","") %>%
        stringr::str_replace_all(pattern = " ", replacement = "")
      , stringr::str_to_lower(first_name)
      , birthdate
      , sep = "_"
    )
  ) %>%
  dplyr::distinct(pt_key, .keep_all = TRUE)


no_vax_tbl <- emp_final_tbl %>%
  dplyr::left_join(
    nysiis_final_tbl
    , by = c("pt_key"="pt_key")
  ) %>%
  dplyr::filter(is.na(birth_date)) %>%
  dplyr::select(1:4) %>%
  purrr::set_names("last_name","first_name","birth_date","pt_key")

write.csv(x = no_vax_tbl, file = "C:/Users/bha485/Desktop/employee_list_no_vax.csv")

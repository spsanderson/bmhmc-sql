
# Lib Load ----------------------------------------------------------------


library(magrittr)
library(RDCOMClient)


# Read Files --------------------------------------------------------------


df_first <- readr::read_csv(
  "C:/Documents and Settings/bha485/Desktop/vaccine_first_round.csv"
)
df_second <- readr::read_csv(
  "C:/Documents and Settings/bha485/Desktop/vaccine_second_round.csv"
)
df_second_recieved <- readr::read_csv(
  "C:/Documents and Settings/bha485/Desktop/vaccine_second_round_recieved.csv"
)


# Data Manipulation -------------------------------------------------------

df_first <- df_first %>% 
  janitor::clean_names()

df_second <- df_second %>%
  janitor::clean_names()

df_second_recieved <- df_second_recieved %>%
  janitor::clean_names()

df_first_guid_tbl <- df_first %>%
  dplyr::mutate(
    lower_last    = stringr::str_to_lower(last_name) %>%
      stringr::str_replace_all("[^[:alnum:]]", "") %>%
      stringr::str_squish()
    , full_dob    = lubridate::mdy(date_of_birth) %>%
      stringr::str_replace_all(pattern = "-",replacement = "_")
    , guid        = stringr::str_c(lower_last, "_", full_dob)
    , dose_group  = "first_group"
    ) 

df_second_guid_tbl <- df_second %>%
  dplyr::mutate(
    lower_last    = stringr::str_to_lower(last_name) %>%
      stringr::str_replace_all("[^[:alnum:]]", "") %>%
      stringr::str_squish()
    , full_dob    = lubridate::mdy(date_of_birth) %>%
      stringr::str_replace_all(pattern = "-",replacement = "_")
    , guid        = stringr::str_c(lower_last, "_", full_dob)
    , dose_group  = "second_group"
  )

df_second_recieved_guid_tbl <- df_second_recieved %>%
  dplyr::mutate(
    lower_last    = stringr::str_to_lower(last_name) %>%
      stringr::str_replace_all("[^[:alnum:]]", "") %>%
      stringr::str_squish()
    , full_dob    = lubridate::mdy(date_of_birth) %>%
      stringr::str_replace_all(pattern = "-",replacement = "_")
    , guid        = stringr::str_c(lower_last, "_", full_dob)
    , dose_group  = "second_group_recieved"
  )

union_tbl <- dplyr::union(
  df_first_guid_tbl %>%
    dplyr::select(lower_last, full_dob, guid, dose_group)
  , df_second_guid_tbl %>%
    dplyr::select(lower_last, full_dob, guid, dose_group)
) %>%
  dplyr::union(
    df_second_recieved_guid_tbl %>%
      dplyr::select(lower_last, full_dob, guid, dose_group)
  )

dose_tbl <- union_tbl %>%
  tidyr::pivot_wider(
    -dose_group
    , names_from = dose_group
    , values_from = dose_group
  ) %>%
  dplyr::arrange(full_dob, lower_last) %>%
  dplyr::select(-lower_last, -full_dob) %>%
  dplyr::distinct(guid, .keep_all = TRUE)

dose_tbl <- dose_tbl %>%
  dplyr::mutate(
    vaccine_group = dplyr::case_when(
      (
        !is.na(first_group) & 
          ((!is.na(second_group) | (!is.na(second_group_recieved))))) ~ "discard"
      , is.na(first_group) ~ "keep"
      , TRUE ~ "keep"
    )
  ) %>% 
  purrr::set_names(
    "guid","group_a","group_b","group_c","vaccine_group"
  ) %>%
  dplyr::filter(vaccine_group == "keep")

dose_final_tbl <- dose_tbl %>%
  dplyr::left_join(
    y = df_first_guid_tbl
    , by = c("guid" = "guid")
  ) %>%
  dplyr::select(
    1:5, lower_last, full_dob, phone_number, email_address, visit_date
  ) %>%
  dplyr::left_join(
    y = df_second_guid_tbl
    , by = c("guid" = "guid")
  ) %>%
  dplyr::select(
    1:10, dplyr::contains(".y")
  ) %>%
  dplyr::left_join(
    y = df_second_recieved_guid_tbl
    , by = c("guid" = "guid")
  ) %>%
  dplyr::select(
    1:10, dplyr::contains(".y"), lower_last, full_dob, phone_number, email_address
  ) %>%
  dplyr::mutate(visit = dplyr::coalesce(visit_date.x, visit_date.y)) %>%
  dplyr::mutate(last = dplyr::coalesce(lower_last, lower_last.x, lower_last.y)) %>%
  dplyr::mutate(dob = dplyr::coalesce(full_dob, full_dob.x, full_dob.y)) %>%
  dplyr::mutate(phone = dplyr::coalesce(phone_number, phone_number.x, phone_number.y)) %>%
  dplyr::mutate(email = dplyr::coalesce(email_address, email_address.x, email_address.y)) %>%
  dplyr::select(1:4, last, dob, phone, email, visit)



first_round_tbl <- df_first_guid_tbl %>%
  dplyr::left_join(dose_tbl, by = c("guid"="guid")) %>%
  dplyr::select(-dose_group)

second_round_tbl <- df_second_guid_tbl %>%
  dplyr::left_join(dose_tbl, by = ("guid"="guid")) %>%
  dplyr::select(-dose_group)

second_round_recieved_tbl <- df_second_recieved_guid_tbl %>%
  dplyr::left_join(dose_tbl, by = c("guid"="guid")) %>%
  dplyr::select(-dose_group)


# Make Excel File ---------------------------------------------------------

# Make Workbook
wb <- xlsx::createWorkbook(type = "xlsx")

# Make data sheets
first_round_sheet  <- xlsx::createSheet(wb = wb, sheetName = "first_round")
second_round_sheet <- xlsx::createSheet(wb = wb, sheetName = "second_round")
second_round_recieved_sheet <- xlsx::createSheet(wb = wb, sheetName = "second_round_recieved")
dose_group_sheet   <- xlsx::createSheet(wb = wb, sheetName = "dose_group") 

# Add data.frames to sheets
xlsx::addDataFrame(x = first_round_tbl, sheet = first_round_sheet)
xlsx::addDataFrame(x = second_round_tbl, sheet = second_round_sheet)
xlsx::addDataFrame(x = second_round_recieved_tbl, sheet = second_round_recieved_sheet)
xlsx::addDataFrame(x = dose_final_tbl, sheet = dose_group_sheet)

# Save file
f_path <- "G:\\Emergency Room\\Michelle Miller\\Vaccine_Files\\"
f_date <- Sys.Date() %>% stringr::str_replace_all(pattern = "-", replacement = "_")
f_name <- base::paste0(f_path, "vaccine_groups_", f_date, ".xlsx")

# Save file
xlsx::saveWorkbook(wb = wb, file = f_name)

# * Compose Email ----
# Open Outlook
Outlook <- RDCOMClient::COMCreate("Outlook.Application")

# Create Email
Email <- Outlook$CreateItem(0)

# Set fields
Email[["to"]] <- ""
Email[["cc"]] <- ""
Email[["bcc"]] <- ""
Email[["subject"]] <- "COVID-19 Vaccine Groups"
Email[["body"]] <- "Please see the attached for the latest report - This is a test PLEASE REVIEW"
Email[["attachments"]]$Add(f_name)

# Send the email
Email$Send()

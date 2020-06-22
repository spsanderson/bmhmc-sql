
# Lib Load ----------------------------------------------------------------

if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse",
    "odbc",
    "DBI",
    "readxl",
    "janitor"
)


# Data --------------------------------------------------------------------

# File Vector
file_vector <- list.files(path = "G:/R Studio Projects/MyHealth_Referrals/00_Data_In/")

# Get Excel File List
excel_list <- file_vector[grepl(".xls*", file_vector)]
print(excel_list)

# File In Path
f_read_path <- paste0(
    "G:/R Studio Projects/MyHealth_Referrals/00_Data_In/"
    , excel_list
)

# Read File In
df_tbl <- read_excel(path = f_read_path) %>%
    clean_names() %>%
    select(
        from_facility_name
        , starts_with("referral")
        , speciality_name
        , starts_with("patient")
    ) %>%
    mutate_if(is.character, str_squish)

# Data Manip
df_rad_tbl <- df_tbl %>%
    select(-patient_race, -patient_ethnicity, -patient_account_number) %>%
    filter(
        referral_to_provider_name %in% c(
            "WOMEN'S IMAGIN CENTER, ."
            , "WOMENS IMAGING SERVICES, BMH"
            , "LICH OUTPATIENT RADIOLOGY, ."
            , "LICH RADIOLOGY"
        )
    ) %>%
    mutate(
        referral_grouping = case_when(
            referral_to_provider_name %in% c(
                "WOMEN'S IMAGIN CENTER, ."
                , "WOMENS IMAGING SERVICES, BMH"
            ) ~ "BWIS",
            TRUE ~ "OP_Radiology"
        )
    ) %>%
    mutate(
        patient_name = str_replace(
            string = patient_name
            , pattern = ", "
            , replacement = " ,"
        )
    ) %>%
    mutate(patient_gender = str_to_lower(patient_gender)) %>%
    mutate(pt_sex = case_when(
        patient_gender == "female" ~ "F",
        TRUE ~ "M"
    ))


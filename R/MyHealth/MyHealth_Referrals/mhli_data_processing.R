
# Lib Load ----------------------------------------------------------------

if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse",
    "odbc",
    "DBI",
    "readxl",
    "janitor",
    "lubridate"
)


# Data --------------------------------------------------------------------

t <- Sys.Date()
t_year <- year(t)
t_month <- month(t, label = TRUE, abbr = FALSE)

file_in_path <- paste0("G:\\R Studio Projects\\MyHealth_Referrals\\00_Data_In\\")

# Get Data
pt_registry_tbl <- read_excel(paste0(file_in_path,"mhli_pt_registry.xlsx")) %>%
    clean_names() %>%
    mutate_if(is.character, str_squish) %>%
    mutate(patient_name = str_to_upper(patient_name)) %>%
    mutate(dob = as.Date.character(x = dob, format = "%Y-%m-%d")) %>%
    mutate(sex = as_factor(sex)) %>%
    mutate(age = str_replace(
        string = age
        , pattern = " Y"
        , replacement = ""
    ) %>%
        as.integer()
    ) %>%
    select(-tel_no) %>%
    filter(!str_detect(patient_name, "TEST")) %>%
    distinct(.keep_all = TRUE) %>%
    mutate(full_name = str_replace(
        patient_name
        , ","
        , " ,"
    ))

referrals_tbl   <- read_excel(paste0(file_in_path,"mhli_referrals.xlsx")) %>%
    clean_names() %>%
    select(
        from_facility_name
        , starts_with("referral")
        , speciality_name
        , starts_with("patient")
    ) %>%
    mutate_if(is.character, str_squish) %>%
    mutate(full_name = str_replace(
        patient_name
        , ", "
        , " ,"
    )) %>%
    distinct(.keep_all = TRUE)


# Full Data History --------------------------------------------------
# pt registry
write_excel_csv(
    x = pt_registry_tbl
    , path = paste0(
        "G:/MyHealth/MyHealth_File_History/mhli_pt_registry_"
        , t_year
        , "_"
        , t_month
        , ".csv"
    )
)
# referrals
write_excel_csv2(
    x = referrals_tbl
    , path = paste0(
        "G:/MyHealth/MyHealth_File_History/mhli_referral_log_"
        , t_year
        , "_"
        , t_month
        , ".csv"
    )
)

# Data Manip --------------------------------------------------------------

df_rad_tbl <- referrals_tbl %>%
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


# Import to DSS -----------------------------------------------------------

db_con <- dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "BMH-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = T
)

dbWriteTable(
    conn = db_con
    , Id(
        schema = "smsdss"
        , table = "c_mhli_pt_registry_tbl"
    )
    , pt_registry_tbl
    , overwrite = TRUE
)

dbWriteTable(
    conn = db_con
    , Id(
        schema = "smsdss"
        , table = "c_mhli_referrals_tbl"
    )
    , referrals_tbl
    , overwrite = TRUE
)

dbWriteTable(
    conn = db_con
    , Id(
        schema = "smsdss"
        , table = "c_mhli_rad_referrals_tbl"
    )
    , df_rad_tbl
    , overwrite = TRUE
)

dbDisconnect(db_con)

# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse"
    , "tidyquant"
    , "readxl"
    , "xlsx"
    , "tidycells"
    , "fs"
    , "janitor"
)

# Get FS Path ----
excel_paths_tbl <- fs::dir_info("Data/")
paths_chr <- excel_paths_tbl %>%
    pull(path)

# Read files ----
data_tbl <- excel_paths_tbl %>%
    select(path) %>%
    mutate(data = path %>% map(read_cells)) %>%
    unnest(cols = c(data))

df <- data_tbl %>%
    select(data) %>%
    map_df(~ plyr::ldply(., data.frame)) %>%
    as_tibble() %>%
    rowid_to_column()

tele_data_tbl <- df %>%
    filter(!is.na(V1)) %>%
    filter(rowid >= 7) %>%
    select(
        rowid,V1,V3,V5,V6,V7,V8,V16,V17,V19,V20,V21
    ) %>%
    set_names(
        "row_id"
        , "visit_info"
        , "assigned_bed"
        , "occupied_bed"
        , "request_date"
        , "request_time"
        , "assigned_time"
        , "clean_time"
        , "transport_req_time"
        , "transport_comp_time"
        , "occupied_time"
        , "elapsed_time"
    ) %>%
    filter(!str_starts(visit_info, "Assigned Bed")) %>%
    mutate(
        name_col = case_when(
            str_starts(
                string = visit_info
                , pattern = "MRN:"
            ) ~ "med_rec_no"
            , str_starts(
                string = visit_info
                , pattern = "Visit #:"
            ) ~ "encounter"
            , TRUE ~ "pt_name"
        )
    ) %>%
    pivot_wider(
        names_from = name_col
        , values_from = visit_info
    ) %>%
    mutate(
        med_rec_no = lead(med_rec_no, n = 1)
        , encounter = lead(encounter, n = 2)
    ) %>%
    mutate(
        med_rec_no = str_sub(med_rec_no, start = 6, end = -1)
        , encounter = str_sub(encounter, start = 9, end = -1)
    ) %>%
    select(
        row_id
        , pt_name
        , med_rec_no
        , encounter
        , everything()
    ) %>%
    filter(!is.na(pt_name)) %>%
    filter(!is.na(med_rec_no))

# Write to csv ----
tele_data_tbl %>%
    write_csv("Data/data_tbl.csv")

rm(list = ls())

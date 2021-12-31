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
    , "lubridate"
    , "tibbletime"
    , "anomalize"
)

# Get Data ----
telemetry_data_tbl <- read_csv("Data/data_tbl.csv")

# Clean up ----
vars_mutate_at = c(
    "request_time"
    , "assigned_time"
    , "clean_time"
    , "transport_req_time"
    , "transport_comp_time"
    , "occupied_time"
)

tele_tbl <- telemetry_data_tbl %>%
    filter(!is.na(med_rec_no)) %>%
    filter(
        !is.na(med_rec_no),
        !is.na(assigned_bed),
        !str_starts(assigned_bed, "Assigned")
    ) %>%
    select(-row_id) %>%
    mutate_at(
        .vars = c("med_rec_no","encounter")
        , .funs = as.character
    ) %>%
    mutate_at(
        .vars = c("assigned_bed", "occupied_bed")
        , .funs = as_factor
    ) %>%
    mutate_at(.vars = vars_mutate_at, .funs = hm) %>%
    mutate(
        elapsed_time_minutes = hm(elapsed_time) %>%
            minutes() %>%
            as.duration() %>%
            as.integer() / 3600
    ) %>% 
    mutate(request_dtime = request_date %>% as_datetime()) %>%
    mutate(request_date = request_date %>% as_datetime()) %>%
    mutate(request_dt = request_date %>% as_date()) %>%
    filter(!is.na(elapsed_time_minutes))

# Add Features ----
tele_tbl <- tele_tbl %>%
    # Request Hour
    mutate(request_hr = hour(request_dtime)) %>%
    # Request DOW
    mutate(request_dow = request_dt %>% WDAY(label = TRUE)) %>%
    # Nursing Station of occupied bed
    mutate(
        nurs_sta = case_when(
            str_starts(occupied_bed, "3") ~ "Third_Floor",
            str_starts(occupied_bed, "4") ~ "Fourth_Floor",
            str_starts(occupied_bed, "C") ~ "CCU",
            str_starts(occupied_bed, "M") ~ "MICU",
            str_starts(occupied_bed, "SC") ~ "SICU"
        )
    ) %>%
    mutate(nurs_sta = nurs_sta %>% as_factor()) %>%

# Stats ----
# Pvt Tbl Beds
occ_bed_pvt_tbl <- tele_tbl %>%
    pivot_table(
        .rows = ~ occupied_bed
        , .columns = ~ request_dow
        , .values = ~ COUNT(occupied_bed)
        , fill_na = 0
    ) %>%
    pivot_longer(
        cols = c(-occupied_bed)
        , names_to = "dow"
        , values_to = "value"
        , names_ptypes = list(dow = factor())
    )

nurs_sta_pvt_tbl <- tele_tbl %>%
    pivot_table(
        .rows = ~ nurs_sta
        , .columns = ~ request_dow
        , .values = ~ COUNT(nurs_sta)
        , fill_na = 0
    ) %>%
    pivot_longer(
        cols = c(-nurs_sta)
        , names_to = "dow"
        , values_to = "value"
        , names_ptypes = list(dow = factor())
    )

nurs_sta_hr_pvt_tbl <- tele_tbl %>%
    pivot_table(
        .rows = ~ nurs_sta
        , .columns = ~ request_hr
        , .values = ~ COUNT(nurs_sta)
        , fill_na = 0
    ) %>%
    pivot_longer(
        cols = c(-nurs_sta)
        , names_to = "hr"
        , values_to = "value"
        , names_ptypes = list(hr = factor())
    )

# Anomalies
nurs_sta_anomalies_tbl <- tele_tbl %>%
    # arrange by date_time column asc
    arrange(request_date) %>%
    as_tbl_time(index = request_dt, keep = TRUE) %>%
    collapse_by("daily") %>%
    select(
        request_dt,
        elapsed_time_minutes,
        nurs_sta
    ) %>%
    group_by(request_dt, nurs_sta, add = TRUE) %>%
    # need mean minutes by nurs sta by day
    summarise(
        mean_minutes = mean(elapsed_time_minutes, na.rm = TRUE)
    ) %>%
    ungroup() %>%
    as_tibble() %>%
    # coerce to tsibble in order to use fill_gaps
    fable::as_tsibble(index = request_dt, key = nurs_sta) %>%
    tsibble::fill_gaps(mean_minutes = 0) %>%
    # return to tibbletime object to use anomalize
    as_tbl_time(index = request_dt, keep = TRUE) %>%
    # want anomalies by nursing station
    group_by(nurs_sta) %>%
    time_decompose(
        target = mean_minutes,
        method = "twitter",
        merge = TRUE
    ) %>%
    anomalize(remainder, method = "gesd") %>%
    clean_anomalies() %>%
    time_recompose()

daily_anomalies_tbl <- tele_tbl %>%
    # arrange by date_time column asc
    arrange(request_date) %>%
    as_tbl_time(index = request_dt, keep = TRUE) %>%
    collapse_by("daily") %>%
    select(
        request_dt,
        elapsed_time_minutes
    ) %>%
    group_by(request_dt, add = TRUE) %>%
    # need mean minutes by day
    summarise(
        mean_minutes = mean(elapsed_time_minutes, na.rm = TRUE)
    ) %>%
    ungroup() %>%
    as_tibble() %>%
    # coerce to tsibble in order to use fill_gaps
    fable::as_tsibble(index = request_dt) %>%
    tsibble::fill_gaps(mean_minutes = 0) %>%
    # return to tibbletime object to use anomalize
    as_tbl_time(index = request_dt, keep = TRUE) %>%
    time_decompose(
        mean_minutes,
        method = "twitter",
        merge = TRUE
    ) %>%
    anomalize(remainder, method = "gesd") %>%
    clean_anomalies() %>%
    time_recompose()

dow_anomalies_tbl <- tele_tbl %>%
    # arrange by date_time column asc
    arrange(request_date) %>%
    as_tbl_time(index = request_dt, keep = TRUE) %>%
    collapse_by("daily") %>%
    select(
        request_dt,
        request_dow, 
        elapsed_time_minutes
    ) %>%
    group_by(request_dt, request_dow, add = TRUE) %>%
    # need mean minutes by dow
    summarise(
        mean_minutes = mean(elapsed_time_minutes, na.rm = TRUE)
    ) %>%
    ungroup() %>%
    as_tibble() %>%
    # coerce to tsibble in order to use fill_gaps
    fable::as_tsibble(index = request_dt, key = request_dow) %>%
    # return to tibbletime object to use anomalize
    as_tbl_time(index = request_dt) %>%
    # want anomalies by nursing station
    group_by(request_dow) %>%
    time_decompose(
        mean_minutes,
        method = "twitter", 
        merge = TRUE
    ) %>%
    anomalize(remainder, method = "gesd") %>%
    clean_anomalies() %>%
    time_recompose()


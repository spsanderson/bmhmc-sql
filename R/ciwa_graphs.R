pacman::p_load(
    "tidyverse"
    , "readxl"
)

# Source functions ----
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\clean_names.R")

# Get data ----
df_file_path <- file.choose(new = T)
df <- readxl::read_excel(path = df_file_path, sheet = "agg_data") %>%
    clean_names()

# Summary Data ----
# By CIWA Flag
visit_count_plt <- df %>%
    filter(
        adm_month >= 6
        , ip_op == "I"
    ) %>%
    select(
        adm_month
        , ciwa_flag
        , visit_count
    ) %>%
    mutate(
        ciwa_flag = ciwa_flag %>% as_factor()
        , ciwa_flag = case_when(
            ciwa_flag == 0 ~ "No"
            , TRUE ~ "Yes"
        )
        ) %>%
    group_by(
        adm_month
        , ciwa_flag
    ) %>%
    summarize(
        Visits = sum(visit_count, na.rm = T)
    ) %>%
    ungroup() %>%
    ggplot(
        mapping = aes(
            x = adm_month
            , y = Visits
            , group = ciwa_flag
            , color = ciwa_flag
        )
    ) +
    geom_point() +
    geom_line() +
    labs(
       title = "Visit Count by CIWA Usage"
       , subtitle = "Inpatients Only"
       , x = "Admit Month"
       , y = "Visit Count"
       , color = "CIWA Flag"
    ) +
    tidyquant::theme_tq() +
    tidyquant::scale_color_tq()

# ALOS
alos_plt <- df %>%
    filter(
        adm_month >= 6
        , ip_op == "I"
    ) %>%
    select(
        adm_month
        , ciwa_flag
        , visit_count
        , total_days
    ) %>%
    mutate(
        ciwa_flag = ciwa_flag %>% as_factor()
        , ciwa_flag = case_when(
            ciwa_flag == 0 ~ "No"
            , TRUE ~ "Yes"
        )
    ) %>%
    group_by(
        adm_month
        , ciwa_flag
    ) %>%
    summarize(
        alos = sum(total_days, na.rm = T) / sum(visit_count, na.rm = T)
    ) %>%
    mutate(
        alos = case_when(
            is.infinite(alos) ~ 0
            , TRUE ~ alos
        )
    ) %>%
    ungroup() %>%
    ggplot(
        mapping = aes(
            x = adm_month
            , y = alos
            , group = ciwa_flag
            , color = ciwa_flag
        )
    ) +
    geom_point() +
    geom_line() +
    labs(
        title = "ALOS by CIWA Usage"
        , subtitle = "Inpatients Only"
        , x = "Admit Month"
        , y = "ALOS"
        , color = "CIWA Flag"
    ) +
    tidyquant::theme_tq() +
    tidyquant::scale_color_tq()

# avg mg/pt
avg_mg_pt_plt <- df %>%
    filter(
        adm_month >= 6
        , ip_op == "I"
    ) %>%
    select(
        adm_month
        , ciwa_flag
        , visit_count
        , total_mg
    ) %>%
    mutate(
        ciwa_flag = ciwa_flag %>% as_factor()
        , ciwa_flag = case_when(
            ciwa_flag == 0 ~ "No"
            , TRUE ~ "Yes"
        )
    ) %>%
    group_by(
        adm_month
        , ciwa_flag
    ) %>%
    summarize(
        avg_mg_pt = sum(total_mg, na.rm = T) / sum(visit_count, na.rm = T)
    ) %>%
    mutate(
        avg_mg_pt = case_when(
            is.infinite(avg_mg_pt) ~ 0
            , TRUE ~ avg_mg_pt
        )
    ) %>%
    ungroup() %>%
    ggplot(
        mapping = aes(
            x = adm_month
            , y = avg_mg_pt
            , group = ciwa_flag
            , color = ciwa_flag
        )
    ) +
    geom_point() +
    geom_line() +
    labs(
        title = "Average mg/Pt by CIWA Usage"
        , subtitle = "Inpatients Only"
        , x = "Admit Month"
        , y = "Avg mg/Pt"
        , color = "CIWA Flag"
    ) +
    tidyquant::theme_tq() +
    tidyquant::scale_color_tq()

# avg mg/pt_day
avg_mg_ptdays_plt <- df %>%
    filter(
        adm_month >= 6
        , ip_op == "I"
    ) %>%
    select(
        adm_month
        , ciwa_flag
        , total_days
        , total_mg
    ) %>%
    mutate(
        ciwa_flag = ciwa_flag %>% as_factor()
        , ciwa_flag = case_when(
            ciwa_flag == 0 ~ "No"
            , TRUE ~ "Yes"
        )
    ) %>%
    group_by(
        adm_month
        , ciwa_flag
    ) %>%
    summarize(
        avg_mg_ptdays = sum(total_mg, na.rm = T) / sum(total_days, na.rm = T)
    ) %>%
    mutate(
        avg_mg_ptdays = case_when(
            is.infinite(avg_mg_ptdays) ~ 0
            , TRUE ~ avg_mg_ptdays
        )
    ) %>%
    ungroup() %>%
    ggplot(
        mapping = aes(
            x = adm_month
            , y = avg_mg_ptdays
            , group = ciwa_flag
            , color = ciwa_flag
        )
    ) +
    geom_point() +
    geom_line() +
    labs(
        title = "Average mg/Pt/Day by CIWA Usage"
        , subtitle = "Inpatients Only"
        , x = "Admit Month"
        , y = "Avg mg/Pt/Day"
        , color = "CIWA Flag"
    ) +
    tidyquant::theme_tq() +
    tidyquant::scale_color_tq()

# icu alos
icu_alos_plt <- df %>%
    filter(
        adm_month >= 6
        , ip_op == "I"
    ) %>%
    select(
        adm_month
        , ciwa_flag
        , icu_pts
        , total_icu_days
    ) %>%
    mutate(
        ciwa_flag = ciwa_flag %>% as_factor()
        , ciwa_flag = case_when(
            ciwa_flag == 0 ~ "No"
            , TRUE ~ "Yes"
        )
    ) %>%
    group_by(
        adm_month
        , ciwa_flag
    ) %>%
    summarize(
        icu_alos = sum(total_icu_days, na.rm = T) / sum(icu_pts, na.rm = T)
    ) %>%
    mutate(
        icu_alos = case_when(
            is.na(icu_alos) ~ 0
            , TRUE ~ icu_alos
        )
    ) %>%
    ungroup() %>%
    ggplot(
        mapping = aes(
            x = adm_month
            , y = icu_alos
            , group = ciwa_flag
            , color = ciwa_flag
        )
    ) +
    geom_point() +
    geom_line() +
    labs(
        title = "ICU ALOS by CIWA Usage"
        , subtitle = "Inpatients Only"
        , x = "Admit Month"
        , y = "ICU ALOS"
        , color = "CIWA Flag"
    ) +
    tidyquant::theme_tq() +
    tidyquant::scale_color_tq()

# mean_soi
mean_soi_plt <- df %>%
    filter(
        adm_month >= 6
        , ip_op == "I"
    ) %>%
    select(
        adm_month
        , ciwa_flag
        , visit_count
        , total_soi
    ) %>%
    mutate(
        ciwa_flag = ciwa_flag %>% as_factor()
        , ciwa_flag = case_when(
            ciwa_flag == 0 ~ "No"
            , TRUE ~ "Yes"
        )
    ) %>%
    group_by(
        adm_month
        , ciwa_flag
    ) %>%
    summarize(
        avg_soi = sum(total_soi) / sum(visit_count)
    ) %>%
    ungroup() %>%
    ggplot(
        mapping = aes(
            x = adm_month
            , y = avg_soi
            , group = ciwa_flag
            , color = ciwa_flag
        )
    ) +
    geom_point() +
    geom_line() +
    labs(
        title = "Mean SOI by CIWA Usage"
        , subtitle = "Inpatients Only"
        , x = "Admit Month"
        , y = "Avg SOI"
        , color = "CIWA Flag"
    ) +
    tidyquant::theme_tq() +
    tidyquant::scale_color_tq()

gridExtra::grid.arrange(
    visit_count_plt
    , alos_plt
    , avg_mg_pt_plt
    , avg_mg_ptdays_plt
    , icu_alos_plt
    , mean_soi_plt
    , nrow = 3
    , ncol = 2
)

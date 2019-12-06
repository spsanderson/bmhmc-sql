# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse"
    , "tidyquant"
    , "readxl"
    , "R.utils"
    , "tibbletime"
    , "knitr"
    , "kableExtra"
    , "anomalize"
)

# Source Functions ----
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\clean_names.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\oppe_cpoe_plot.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\oppe_readmit_plot.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\oppe_alos_plot.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\oppe_gartner_magic_plot.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\oppe_denials_plot.R")


# Data load ----
df_time_tbl <- read_xlsx("cpoe.xlsx", sheet = "DATA") %>%
    clean_names() %>%
    mutate(ent_date = lubridate::as_date(ent_date)) %>%
    as_tbl_time(index = ent_date) %>%
    arrange(ent_date)

drg_exclude <- read_xlsx("drg_exclude.xlsx") %>%
    clean_names()

apr_drg_thresholds_tbl <- read_xlsx("apr_drg_thresholds.xlsx") %>%
    clean_names()

alos_tbl <- read_xlsx("alos_data.xlsx") %>%
    clean_names() %>%
    as_tbl_time(alos_tbl, index = dsch_date)

readmit_tbl <- read_xlsx("readmit_data.xlsx") %>%
    clean_names() %>%
    as_tbl_time(readmit_tbl, index = dsch_date)

apr_drg_exclude <- read_xlsx("ra_apr_drg_exclude.xlsx") %>%
    clean_names()

denials_tbl <- read_xlsx("denials_data.xlsx", sheet = "data") %>%
    clean_names() %>%
    as_tbl_time(index = adm_date)

# Viz ----
oppe_cpoe_plot(df_time_tbl)
oppe_readmit_plot(readmit_tbl)
oppe_alos_plot(alos_tbl)
oppe_gartner_magic_plot()
oppe_denials_plot()

denials_tbl %>%
    mutate(adm_date = ymd(adm_date)) %>%
    arrange(adm_date) %>%
    collapse_by("yearly") %>%
    group_by(adm_date, add = T) %>%
    summarize(
        admits = n()
        , tot_chgs = sum(tot_chg_amt)
        , denials = sum(denial_flag)
        , denied_dollars = sum(dollars_appealed, na.rm = T)
        , recovered_dollars = sum(dollars_recovered, na.rm = T)
    ) %>%
    ungroup() %>%
    mutate(
        denial_lag_1 = lag(denied_dollars, n = 1)
        , denial_lag_1 = case_when(
            is.na(denial_lag_1) ~ denied_dollars
            , TRUE ~ denial_lag_1
        )
        , diff_1 = denied_dollars
        , pct_diff_1 = if_else(
            is.infinite(diff_1 / denial_lag_1)
            , 0
            , diff_1 /denial_lag_1
        )
        , pct_diff_1_chr = pct_diff_1 %>% scales::percent()
        , cum_denied_dollars = cumsum(denied_dollars)
        , cum_recovered_dollars = cumsum(recovered_dollars)
    ) %>%
    select(
        adm_date
        , admits
        , denials
        , denied_dollars
        , recovered_dollars
        , pct_diff_1
        , pct_diff_1_chr
        , cum_denied_dollars
        , cum_recovered_dollars
    ) %>% #View()
    ggplot(
        mapping = aes(
            x = year(adm_date)
            , y = cum_denied_dollars
        )
    ) +
    geom_col(
        fill = palette_light()[[1]]
    ) +
    theme_tq() +
    scale_y_continuous(
        labels = scales::dollar
    ) +
    labs(
        title = "Cumulative Dollars Denied by Year"
        , x = "Admit Year"
        , y = "Dollars Denied"
    )

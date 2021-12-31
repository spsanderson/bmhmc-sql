# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse",
    "janitor",
    "tidyquant",
    "patchwork"
)

# Import Data ----
df_tbl <- read_csv("01_data/data.csv") %>%
    filter(dsch_date < '2020-02-01')

# Manipulate ----
# Get Totals
df_summary_tbl <- df_tbl %>%
    mutate(
        los_group = case_when(
            los > 15 ~ 15,
            TRUE ~ los
        )
    ) %>%
    group_by(los_group) %>%
    summarise(
        tot_visits = n(),
        tot_los    = sum(los, na.rm = TRUE),
        tot_elos   = sum(elos, na.rm = TRUE),
        tot_ra     = sum(readmit_flag, na.rm = TRUE),
        tot_perf   = round(mean(readmit_rate, na.rm = TRUE), digits = 2)
    ) %>%
    ungroup() %>%
    mutate(
        tot_rar = case_when(
            tot_ra != 0 ~ round((tot_ra / tot_visits), digits = 2),
            TRUE ~ 0
        )
    ) %>%
    mutate(
        los_index = case_when(
            tot_elos != 0 ~ (tot_los / tot_elos),
            TRUE ~ 0
        ),
        rar_index = case_when(
            (tot_rar != 0 & tot_perf != 0) ~ (tot_rar / tot_perf),
            TRUE ~ 0
        )
    ) %>%
    mutate(
        los_ra_var = case_when(
            (abs(los_index) >= abs(rar_index)) ~ abs(los_index) - abs(rar_index)
            , TRUE ~ abs(rar_index) - abs(los_index)
        )
    ) %>%
    select(los_group, los_index, rar_index, los_ra_var)

# Viz ----
min_los_ra_var = df_summary_tbl %>%
    filter(los_ra_var == min(los_ra_var)) %>%
    select(los_group) %>%
    pull()

min_var <- df_summary_tbl %>%
    filter(los_group == min_los_ra_var) %>%
    select(los_ra_var) %>%
    pull()

min_date = min(df_tbl$dsch_date)
max_date = max(df_tbl$dsch_date)

los_ra_index_plt <- df_summary_tbl %>%
    ggplot(
        mapping = aes(
            x = los_group,
            y = los_index
        )
    ) +
    geom_point(size = 3) +
    geom_line(
        mapping = aes(
            y = los_index
        )
    ) +
    geom_point(
        mapping = aes(
            y = rar_index
        )
        , color = "red"
        , size = 3
    ) +
    geom_line(
        mapping = aes(
            y = rar_index
        )
    ) +
    geom_hline(
        yintercept = 1,
        linetype = "dashed"
    ) +
    geom_vline(
        xintercept = min_los_ra_var,
        linetype = "dashed"
    ) +
    scale_y_continuous(labels = scales::percent) +
    theme_tq() +
    labs(
        title = "LOS Index vs. Readmit Index",
        subtitle = "Black dots are LOS and Red are Readmit",
        y = "LOS/Readmit Index",
        x = "LOS Group"
    )
    
los_ra_var_plt <- df_summary_tbl %>%
    ggplot(
        mapping = aes(
            x = los_group,
            y = los_ra_var
        )
    ) +
    geom_point(size = 3) +
    geom_line() +
    geom_vline(
        xintercept = min_los_ra_var
        , linetype = "dashed"
    ) +
    geom_hline(
        yintercept = min_var,
        linetype = "dashed",
        color = "red"
    ) +
    scale_y_continuous(labels = scales::number) +
    theme_tq() +
    labs(
        title = "LOS vs Readmit Rate Index Variance",
        subtitle = str_c(
            "Total LRIV = "
            , round(sqrt(mean(df_summary_tbl$los_ra_var)), digits = 2)
            , "\n"
            , "Minimum Variance at LOS of "
            , min_los_ra_var
            , " Min Var = "
            , round(min_var, digits = 4)
            , sep = ""
        ),
        caption = str_c(
            "Encounters with a LOS >= 15 are grouped to LOS Group 15",
            "\n",
            "Discharges from ",
            min_date,
            " to ",
            max_date
        ) ,
        y = "LOS/Readmit Index",
        x = "LOS Group"
    )

los_ra_index_plt / los_ra_var_plt

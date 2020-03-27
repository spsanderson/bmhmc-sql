pacman::p_load(
    "tidyverse",
    "patchwork",
    "tidyquant"
)

n <- 1000
los_grp <- rep(x = c(1,2,3,4,5,6,7,8,9,10), times = n/10)
x <- rnorm(n = n, mean = 0, sd = 1)
y <- rnorm(n = n, mean = 0, sd = 1)
x <- sort(x)
y <- sort(y, decreasing = TRUE)

df <- tibble(los_grp,x,y) %>%
    mutate(los_grp = as_factor(los_grp))

df_summary_tbl <- df %>%
    group_by(los_grp) %>%
    summarise(
        avg_los_index = round(mean(x, na.rm = TRUE), digits = 4),
        avg_rar_index = round(mean(y, na.rm = TRUE), digits = 4),
        avg_var       = abs(avg_los_index - avg_rar_index)
    ) %>%
    ungroup()

min_var <- df_summary_tbl %>%
    filter(avg_var == min(avg_var)) %>%
    pull(avg_var)
min_var_los <- df_summary_tbl %>%
    filter(avg_var == min(avg_var)) %>%
    pull(los_grp)

plt1 <- df_summary_tbl %>%
    ggplot(
        mapping = aes(
            x = los_grp
        )
    ) +
    geom_point(
        mapping = aes(
            y = avg_los_index
        )
        , color = "red"
        , size = 3
    ) +
    geom_point(
        mapping = aes(
            y = avg_rar_index
        )
        , color = "black"
        , size = 3
    ) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    geom_vline(xintercept = min_var_los, linetype = "dashed") +
    theme_tq() +
    labs(
        title = "LOS Index vs Readmit Index",
        subtitle = "Black dots LOS, Red dots Readmit",
        x = "",
        y = "LOS/Readmit Index"
    )

plt2 <- df_summary_tbl %>%
    ggplot(
        mapping = aes(
            x = los_grp,
            y = avg_var
        )
    ) +
    geom_point(
        mapping = aes(
            y = avg_var
        )
        , color = "black"
        , size = 3
    ) +
    geom_vline(xintercept = min_var_los, linetype = "dashed") +
    labs(
        title = "Los Readmit Index Variance",
        x = "Length Of Stay",
        y = "Variance"
    ) +
    theme_tq()

plt1 / plt2

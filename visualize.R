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
)

# Heat Maps ----
# Bed Heatmap
occ_bed_pvt_tbl %>%
    ggplot(
        mapping = aes(
            x = dow
            , y = occupied_bed
        )
    ) +
    geom_tile(
        mapping = aes(
            fill = value
        )
    ) +
    scale_fill_gradient(
        low = "white"
        , high = palette_light()[1]
    ) +
    theme_tq() +
    theme(
        legend.position = "none"
    ) +
    labs(
        title = "Heatmap of Tele Bed Usage by Day of Week"
        , subtitle = "Room and Bed"
        , x = ""
        , y = ""
    )

# Nurs Sta Heatmap
nurs_sta_pvt_tbl %>%
    ggplot(
        mapping = aes(
            x = dow
            , y = nurs_sta
        )
    ) +
    geom_tile(
        mapping = aes(
            fill = value
        )
    ) +
    geom_text(
        mapping = aes(
            label = scales::number(x = value)
        )
    ) +
    scale_fill_gradient(
        low = "white"
        , high = palette_light()[1]
    ) +
    theme_tq() +
    theme(
        legend.position = "none"
    ) +
    labs(
        title = "Heatmap of Tele Bed Usage by Day of Week"
        , subtitle = "Nursing Station"
        , x = ""
        , y = ""
    )

# Nurs Sta Hour
nurs_sta_hr_pvt_tbl %>%
    ggplot(
        mapping = aes(
            x = hr,
            y = nurs_sta
        )
    ) +
    geom_tile(
        mapping = aes(
            fill = value
        )
    ) +
    scale_fill_gradient(
        low = "white"
        , high = palette_light()[1]
    ) +
    theme_tq() +
    theme(
        legend.position = "none"
    ) +
    labs(
        title = "Heatmap of Tele Bed Usage Request Hr"
        , subtitle = "Nursing Station"
        , x = ""
        , y = ""
    )

# Anomalies ----
nurs_sta_anomalies_tbl %>%
    plot_anomalies() +
    labs(
        x = "",
        y = "",
        title = "Mean Minutes by Nurse Station",
        subtitle = "Methods = Twitter + GESD"
    )

daily_anomalies_tbl %>%
    plot_anomaly_decomposition() +
    labs(
        x = "",
        y = "",
        title = "Mean Minutes by Request Date",
        subtitle = "Methods = Twitter + GESD"
    )

dow_anomalies_tbl %>%
    plot_anomalies() +
    labs(
        x = "",
        y = "",
        title = "Mean Minutes by Request Day of Week",
        subtitle = "Methods = Twitter + GESD"
    ) +
    facet_wrap(~ request_dow, scales = "free_y")

tele_tbl %>%
    select(
        elapsed_time_minutes,
        nurs_sta
    ) %>%
    ggplot(
        mapping = aes(
            x = elapsed_time_minutes
        )
    ) +
    geom_histogram(
        binwidth = 30,
        color = "black"
    ) +
    facet_wrap(~ nurs_sta, scales = "free_x") +
    theme_tq() +
    scale_color_tq() +
    labs(
        title = "Histogram of Elapsed Time in Minutes",
        subtitle = "Faceted by Nursing Station", 
        x = "",
        y = ""
    )

tele_tbl %>%
    ggplot(
        mapping = aes(
            x = elapsed_time_minutes,
            y = nurs_sta,
            fill = nurs_sta
        )
    ) +
    ggridges::stat_density_ridges(
        quantile_lines = TRUE,
        alpha = 0.618
    ) +
    ggridges::geom_density_ridges(
        jittered_points = TRUE,
        position = ggridges::position_points_jitter(
            width = 0.5, height = 0
            ),
        point_shape = "|", 
        point_size = 3, 
        point_alpha = 1, 
        alpha = 0.5
    ) +
    theme_tq() +
    scale_fill_tq() +
    labs(
        title = "Stacked Histogram of Elapsed Time in Minutes",
        subtitle = "Faceted by Nursing Station",
        x = "",
        y = "",
        fill = "Nursing Station"
    )

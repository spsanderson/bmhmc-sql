oppe_gartner_magic_plot <- function(){
    
    # Make df ----
    alos_data <- alos_tbl %>%
        mutate(dsch_date = ymd(dsch_date)) %>%
        select(
            dsch_date
            , pt_no_num
            , case_var
        )
    
    rr_data <- readmit_tbl %>%
        mutate(dsch_date = ymd(dsch_date)) %>%
        select(
            pt_no_num
            , pt_count
            , readmit_count
            , readmit_rate_bench
        )
    
    data_joined <- alos_data %>%
        inner_join(rr_data, by = c("pt_no_num" = "pt_no_num"))
    
    df <- data_joined %>%
        collapse_by("weekly") %>%
        group_by(dsch_date, add = T) %>%
        summarize(
            alos_var = round(mean(case_var), 2)
            , rr = round(mean(readmit_count), 2)
            , bench = round(mean(readmit_rate_bench), 2)
            , rr_var = (rr - bench)
        ) %>%
        ungroup() %>%
        select(
            alos_var
            , rr_var
        ) %>%
        set_names(
            "x"
            , "y"
        )
    
    # Plot ----
    plt <- df %>%
        ggplot(
            mapping = aes(
                x = x
                , y = y
            )
        ) + 
        scale_x_continuous(
            expand = c(0, 0)
            , limits = c(
                min(df$x)
                , max(df$x)
            )
        ) +
        scale_y_continuous(
            expand = c(0, 0)
            , limits = c(
                min(df$y)
                , max(df$y)
            )
        ) +
        ylab("Excess Readmit Rate") +
        xlab("Excess LOS") +
        labs(
            title = "Gartner Magic Quadrant - Excess LOS vs Excess Readmit Rate"
            , subtitle = "Red Dot Indicates Zero Variance"
        ) +
        theme(
            legend.position = "none"
            , axis.title.x = element_text(
                hjust = 0
                , vjust = 4
                , colour = "darkgrey"
                , size = 10
                , face = "bold"
            )
            , axis.title.y = element_text(
                hjust = 0
                , vjust = 0
                , color = "darkgrey"
                , size = 10
                , face = "bold"
            )
            , axis.ticks = element_blank()
            , panel.border = element_rect(
                colour = "lightgrey"
                , fill = NA
                , size = 4
            )
        ) +
        annotate(
            "rect"
            , xmin = 0
            , xmax = max(df$x)
            , ymin = 0
            , ymax = max(df$y)
            , fill = "#F8F9F9"
        ) + 
        annotate(
            "rect"
            , xmin = 0
            , xmax = min(df$x)
            , ymin = 0
            , ymax = min(df$y)
            , fill = "#F8F9F9"
        ) + 
        annotate(
            "rect"
            , xmin = 0
            , xmax = min(df$x)
            , ymin = 0
            , ymax = max(df$y)
            , fill = "white"
        ) + 
        annotate(
            "rect"
            , xmin = 0
            , xmax = max(df$x)
            , ymin = 0
            , ymax = min(df$y)
            , fill = "white"
        ) +
        geom_hline(
            yintercept = 0
            , color = "lightgrey"
            , size = 1.5
        ) +
        geom_vline(
            xintercept = 0
            , color = "lightgrey"
            , size = 1.5
        ) +
        geom_label(
            aes(
                x = 0.75 * min(df$x)
                , y = 0.90 * max(df$y)
                , label = "High RA"
            )
            , label.padding = unit(2, "mm")
            , fill = "lightgrey"
            , color="black"
        ) +
        geom_label(
            aes(
                x = 0.75 * max(df$x)
                , y = 0.90 * max(df$y)
                , label = "High RA/LOS"
            )
            , label.padding = unit(2, "mm")
            , fill = "lightgrey"
            , color = "black"
        ) +
        geom_label(
            aes(
                x = 0.75 * min(df$x)
                , y = 0.90 * min(df$y)
                , label = "Leader"
            )
            , label.padding = unit(2, "mm")
            , fill = "lightgrey"
            , color = "black"
        ) +
        geom_label(
            aes(
                x = 0.75 * max(df$x)
                , y = 0.9 * min(df$y)
                , label = "High LOS"
            )
            , label.padding = unit(2, "mm")
            , fill = "lightgrey"
            , color = "black"
        ) +
        geom_point(
            color = "#2896BA"
            , size = 2
        ) +
        # where you want to be
        geom_point(
            data = data.frame(x = 0, y = 0)
            , aes(color = 'red')
            , size = 3
        )
    
    # Print ----
    print(plt)
    
}
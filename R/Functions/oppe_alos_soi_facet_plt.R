oppe_alos_soi_facet_plt <- function(data){
    
    # Length of Stay Plots for OPPE
    if(!nrow(alos_tbl) >= 10){
        return(NA)
    } else {
        # Facets by SOI
        # ALOS by SOI ----
        # Make data tbl
        alos_soi_tbl <- alos_tbl %>%
            filter(outlier_flag == 0) %>%
            mutate(dsch_date = ymd(dsch_date)) %>%
            collapse_by("monthly") %>%
            group_by(
                severity_of_illness
                , dsch_date
                , add = T
            ) %>%
            select(
                dsch_date
                , los
                , performance
                , severity_of_illness
                , drg_cost_weight
            ) %>%
            summarize(
                Total_Discharges = n()
                , alos = round(mean(los), 2)
                , perf = round(mean(performance), 2)
                , excess = (alos - perf)
                , cmi = round(mean(drg_cost_weight), 2)
            ) %>%
            ungroup()
        
        # Print Data
        plt <- alos_soi_tbl %>%
            ggplot(
                mapping = aes(
                    x = dsch_date
                )
            ) +
            # Actual
            geom_point(
                mapping = aes(
                    y = alos
                )
                , size = 2
            ) +
            geom_line(
                mapping = aes(
                    y = alos
                )
            ) +
            # Expected
            geom_point(
                mapping = aes(
                    y = perf
                )
                , size = 2
                , color = "red"
            ) +
            geom_line(
                mapping = aes(
                    y = perf
                )
                , color = "red"
            ) +
            labs(
                x = "Discharge Month"
                , y = "ALOS / ELOS"
                , title = "ALOS vs. ELOS by SOI"
                , subtitle = "Red line indicates ELOS"
            ) +
            # linear trend actual
            geom_smooth(
                mapping = aes(
                    y = alos
                )
                , method = "lm"
                , se = F
                , color = "black"
                , linetype = "dashed"
            ) +
            geom_smooth(
                mapping = aes(
                    y = perf
                )
                , method = "lm"
                , se = F
                , color = "red"
                , linetype = "dashed"
            ) +
            facet_wrap(~ severity_of_illness, scales = "free_y") +
            scale_y_continuous(
                labels = scales::number_format(accuracy = 0.1)
                , expand = c(0,0)
            ) +
            theme_tq()
        
        print(plt)
    }
}
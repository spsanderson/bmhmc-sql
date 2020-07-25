oppe_alos_excess_soi_facet <- function(data){
    
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
            select(
                dsch_date
                , los
                , performance
                , severity_of_illness
                , drg_cost_weight
            ) %>%
            group_by(
                severity_of_illness
                , dsch_date
                , add = T
            ) %>%
            summarize(
                Total_Discharges = n()
                , alos = round(mean(los), 2)
                , perf = round(mean(performance), 2)
                , excess = (alos - perf)
                , cmi = round(mean(drg_cost_weight), 2)
            ) %>%
            ungroup()
        
        # Excess by SOI ----
        plt <- alos_soi_tbl %>%
            ggplot(
                mapping = aes(
                    x = dsch_date
                    , y = excess
                )
            ) +
            # Excess Rate
            geom_point(size = 2) +
            geom_line() +
            labs(
                x = "Discharge Month"
                , y = "Excess Days"
                , title = "Excess Days Trend by SOI"
            ) +
            # linear trend excess days
            geom_smooth(
                method = "lm"
                , se = F
                , color = "black"
                , linetype = "dashed"
            ) +
            facet_wrap(~ severity_of_illness) +
            scale_y_continuous(labels = scales::number_format(accuracy = 0.1)) +
            theme_tq()
        
        print(plt)
    }
}
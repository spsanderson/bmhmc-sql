oppe_alos_soi_cmi_plt <- function(data){
    
    # Length of Stay Plots for OPPE
    if(!nrow(alos_tbl) >= 10){
        return(NA)
    } else {
        # Alos Trends, Actual, Exp, SOI, CMI ----
        # Make Table
        alos_trend_tbl <- alos_tbl %>%
            filter(outlier_flag == 0) %>%
            mutate(dsch_date = ymd(dsch_date)) %>%
            collapse_by("monthly") %>%
            group_by(
                dsch_date
                , add = T
            ) %>%
            select(
                dsch_date
                , los
                , performance
                , severity_of_illness
                , drg_cost_weight
                , case_var
                , z_minus_score
            ) %>%
            summarize(
                Total_Discharges = n()
                , alos = round(mean(los, na.rm = TRUE), 2)
                , perf = round(mean(performance, na.rm = TRUE), 2)
                , avg_var = (alos - perf)
                , tot_excess_days = (avg_var * Total_Discharges)
                , cmi = round(mean(drg_cost_weight, na.rm = TRUE), 2)
                , soi = round(mean(severity_of_illness, na.rm = TRUE), 2)
                , z_score = round(mean(z_minus_score, na.rm = TRUE), 2)
            ) %>%
            ungroup()
        
        # SOI/CMI ----
        plt <- alos_trend_tbl %>%
            ggplot(
                mapping = aes(
                    x = dsch_date
                )
            ) +
            # Actual Rate
            geom_point(
                mapping = aes(
                    y = soi
                )
                , size = 2
            ) +
            geom_line(
                mapping = aes(
                    y = soi
                )
            ) +
            # Expected Rate
            geom_point(
                mapping = aes(
                    y = cmi
                )
                , size = 2
                , color = "red"
            ) +
            geom_line(
                mapping = aes(
                    y = cmi
                )
                , color = "red"
            ) +
            labs(
                x = "Discharge Month"
                , y = "SOI/CMI"
                , title = "Severity of Illness and CMI"
                , subtitle = "Red line indicates CMI"
            ) +
            # linear trend mean_soi
            geom_smooth(
                mapping = aes(
                    y = soi
                )
                , method = "lm"
                , se = F
                , color = "black"
                , linetype = "dashed"
            ) +
            # linear trend mean cmi
            geom_smooth(
                mapping = aes(
                    y = cmi
                )
                , method = "lm"
                , se = F
                , color = "red"
                , linetype = "dashed"
            ) +
            scale_y_continuous(labels = scales::number_format(accuracy = 0.1)) +
            theme_tq()
        
        print(plt)
        
    }
}
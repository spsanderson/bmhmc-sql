oppe_alos_elos_trend_plot <- function(data){
    
    # Length of Stay Plots for OPPE
    if(!nrow(alos_tbl) >= 10){
        return(NA)
    } else {
        # Alos Trends, Actual, Exp, SOI, CMI ----
        # Make Table
        alos_trend_tbl <- alos_tbl %>%
            filter(outlier_flag == 0) %>%
            mutate(dsch_date = ymd(dsch_date)) %>%
            mutate(enc_flag = 1) %>%
            collapse_by("monthly") %>%
            select(
                dsch_date
                , los
                , performance
                , severity_of_illness
                , drg_cost_weight
                , case_var
                , z_minus_score
                , enc_flag
            ) %>%
            group_by(
                dsch_date
                , add = T
            ) %>% 
            summarise(
                Total_Discharges = sum(enc_flag, na.rm = TRUE)
                , alos = round(mean(los, na.rm = TRUE), 2)
                , perf = round(mean(performance, na.rm = TRUE), 2)
                , avg_var = (alos - perf)
                , tot_excess_days = (avg_var * Total_Discharges)
                , cmi = round(mean(drg_cost_weight, na.rm = TRUE), 2)
                , soi = round(mean(severity_of_illness, na.rm = TRUE), 2)
                , z_score = round(mean(z_minus_score, na.rm = TRUE), 2)
            ) %>%
            ungroup()
        
        # Print Data
        plt <- alos_trend_tbl %>%
            ggplot(
                mapping = aes(
                    x = dsch_date
                )
            ) +
            # Actual Rate
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
            # Expected Rate
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
                , y = "ALOS/ELOS"
                , title = "ALOS vs. ELOS"
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
            scale_y_continuous(labels = scales::number_format(accuracy = 0.01)) +
            theme_tq()
        
        print(plt)
    }
}
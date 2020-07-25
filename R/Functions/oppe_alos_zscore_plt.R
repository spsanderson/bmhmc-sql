 oppe_alos_zscore_plt <- function(data){
    
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

            select(
                dsch_date
                , los
                , performance
                , severity_of_illness
                , drg_cost_weight
                , case_var
                , z_minus_score
            ) %>%
            group_by(
                dsch_date
                , add = T
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
     
        # Z-Score ----
        plt <- alos_trend_tbl %>%
            ggplot(
                mapping = aes(
                    x = dsch_date
                    , y = z_score
                )
            ) +
            # Z-Score
            geom_point(size = 2) +
            geom_line() +
            labs(
                x = "Discharge Month"
                , y = "Z-Score"
                , title = "ALOS Z-Score"
            ) +
            # linear trend z-score
            geom_smooth(
                method = "lm"
                , se = F
                , color = "black"
                , linetype = "dashed"
            ) +
            geom_hline(
                yintercept = 0
                , color = "green"
                , size = 1
                , linetype = "dashed"
            ) +
            scale_y_continuous(labels = scales::number_format(accuracy = 0.1)) +
            theme_tq()
        
        print(plt)
           
    }
}
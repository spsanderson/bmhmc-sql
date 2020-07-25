oppe_readmit_zscore_plt <- function(data){
    
    # Readmit Plots for OPPE
    if(!nrow(readmit_tbl) >= 10){
        return(NA)
    } else {
        # Readmit Trends - Expected, Actual, CMI, SOI ----
        # Make tbl
        readmit_trend_tbl <- readmit_tbl %>%
            mutate(dsch_date = ymd(dsch_date)) %>%
            collapse_by("monthly") %>%

            select(
                dsch_date
                , pt_count
                , readmit_count
                , readmit_rate_bench
                , severity_of_illness
                , drg_cost_weight
                , z_minus_score
            ) %>%
            group_by(dsch_date, add = T) %>%
            summarize(
                Total_Discharges = sum(pt_count, na.rm = TRUE)
                , rr = round((sum(readmit_count, na.rm = TRUE) / Total_Discharges), 2)
                , perf = round(mean(readmit_rate_bench, na.rm = TRUE), 2)
                , Excess = (rr - perf)
                , mean_soi = round(mean(severity_of_illness, na.rm = TRUE), 2)
                , cmi = round(mean(drg_cost_weight, na.rm = TRUE), 2)
                , z_score = round(mean(z_minus_score, na.rm = TRUE), 2)
            ) %>%
            ungroup()
        
        # Z-Score ----
        plt <- readmit_trend_tbl %>%
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
                , title = "Readmit Rate Z-Score"
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
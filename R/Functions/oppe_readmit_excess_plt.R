oppe_readmit_excess_plt <- function(data){
    
    # Readmit Plots for OPPE
    if(!nrow(readmit_tbl) >= 10){
        return(NA)
    } else {
        # Readmit Trends - Expected, Actual, CMI, SOI ----
        # Make tbl
        readmit_trend_tbl <- readmit_tbl %>%
            mutate(dsch_date = ymd(dsch_date)) %>%
            collapse_by("monthly") %>%
            group_by(dsch_date, add = T) %>%
            select(
                dsch_date
                , pt_count
                , readmit_count
                , readmit_rate_bench
                , severity_of_illness
                , drg_cost_weight
                , z_minus_score
            ) %>%
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
        
        # Excess Rate ----
        plt <- readmit_trend_tbl %>%
            ggplot(
                mapping = aes(
                    x = dsch_date
                    , y = Excess
                )
            ) +
            # Excess Rate
            geom_point(size = 2) +
            geom_line() +
            labs(
                x = "Discharge Month"
                , y = "Excess Rate"
                , title = "Excess Readmit Rate Trend"
            ) +
            # linear trend mean_soi
            geom_smooth(
                method = "lm"
                , se = F
                , color = "black"
                , linetype = "dashed"
            ) +
            scale_y_continuous(labels = scales::percent) +
            theme_tq()
        
        print(plt)
        
    }
}
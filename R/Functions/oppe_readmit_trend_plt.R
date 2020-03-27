oppe_readmit_trend_plt <- function(data){
    
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
        
        # Print Data
        plt <- readmit_trend_tbl %>%
            ggplot(
                mapping = aes(
                    x = dsch_date
                )
            ) +
            # Actual Rate
            geom_point(
                mapping = aes(
                    y = rr
                )
                , size = 2
            ) +
            geom_line(
                mapping = aes(
                    y = rr
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
                , y = "Readmit Rate"
                , title = "Readmit Rate vs. Expected Rate"
                , subtitle = "Red line indicates Expected Rate"
            ) +
            # linear trend actual
            geom_smooth(
                mapping = aes(
                    y = rr
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
            scale_y_continuous(labels = scales::percent) +
            theme_tq()
        
        print(plt)
    }
}
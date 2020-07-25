oppe_readmit_excess_soi_plt <- function(data){
    
    # Readmit Plots for OPPE
    if(!nrow(readmit_tbl) >= 10){
        return(NA)
    } else {
        # Facets by SOI
        # RR by SOI ----
        # Make data tbl
        readmit_soi_tbl <- readmit_tbl %>%
            mutate(dsch_date = ymd(dsch_date)) %>%
            collapse_by("monthly") %>%
            select(
                dsch_date
                , pt_count
                , readmit_count
                , readmit_rate_bench
                , severity_of_illness
                , drg_cost_weight
            ) %>%
            group_by(
                severity_of_illness
                , dsch_date
                , add = T
            ) %>%
            summarize(
                Total_Discharges = sum(pt_count)
                , rr = round((sum(readmit_count) / Total_Discharges), 2)
                , perf = round(mean(readmit_rate_bench), 2)
                , Excess = (rr - perf)
                , cmi = round(mean(drg_cost_weight), 2)
            ) %>%
            ungroup()
        
        # Excess by SOI ----
        plt <- readmit_soi_tbl %>%
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
                , title = "Excess Readmit Rate Trend by SOI"
            ) +
            # linear trend excess rate
            geom_smooth(
                method = "lm"
                , se = F
                , color = "black"
                , linetype = "dashed"
            ) +
            facet_wrap(~ severity_of_illness, scales = "free_y") +
            scale_y_continuous(labels = scales::percent) +
            theme_tq()
        
        print(plt)
        
    }
}
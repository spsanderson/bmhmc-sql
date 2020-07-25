oppe_readmit_soi_facet_plt <- function(data){
    
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
        
        # Print Data
        plt <- readmit_soi_tbl %>%
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
                , y = "Rate"
                , title = "Actual Readmit Rate vs. Expected Rate by SOI"
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
            facet_wrap(~ severity_of_illness, scales = "free_y") +
            scale_y_continuous(
                labels = scales::percent
                , expand = c(0,0)
            ) +
            theme_tq()
        
        print(plt)
    }
}
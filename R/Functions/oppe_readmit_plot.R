oppe_readmit_plot <- function(data) {
    
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
    
    # SOI/CMI ----
    plt <- readmit_trend_tbl %>%
        ggplot(
            mapping = aes(
                x = dsch_date
            )
        ) +
        # Actual Rate
        geom_point(
            mapping = aes(
                y = mean_soi
            )
            , size = 2
        ) +
        geom_line(
            mapping = aes(
                y = mean_soi
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
                y = mean_soi
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
    
    # Facets by SOI
    # RR by SOI ----
    # Make data tbl
    readmit_soi_tbl <- readmit_tbl %>%
        mutate(dsch_date = ymd(dsch_date)) %>%
        collapse_by("monthly") %>%
        group_by(
            severity_of_illness
            , dsch_date
            , add = T
        ) %>%
        select(
            dsch_date
            , pt_count
            , readmit_count
            , readmit_rate_bench
            , severity_of_illness
            , drg_cost_weight
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
        facet_wrap(~ severity_of_illness) +
        scale_y_continuous(labels = scales::percent) +
        theme_tq()
    
    print(plt)
    
    # Anomaly detection and decomposition ----
    # Monthly Excess Days
    plt <- readmit_trend_tbl %>%
        time_decompose(Excess, frequency = 2) %>%
        anomalize(remainder, method = "gesd") %>%
        clean_anomalies() %>%
        plot_anomaly_decomposition() +
        labs(
            x = "Discharge Date"
            , y = "Value"
            , title = "Excess Readmit Rate Anomaly Decomposition"
        )
    
    print(plt)
    }

}

oppe_alos_plot <- function(data){
    
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
    
    # Excess Days ----
    plt <- alos_trend_tbl %>%
        ggplot(
            mapping = aes(
                x = dsch_date
                , y = tot_excess_days
            )
        ) +
        # Excess Rate
        geom_point(size = 2) +
        geom_line() +
        labs(
            x = "Discharge Month"
            , y = "Excess Days"
            , title = "Total Excess Days Trend"
        ) +
        # linear trend mean_soi
        geom_smooth(
            method = "lm"
            , se = F
            , color = "black"
            , linetype = "dashed"
        ) +
        scale_y_continuous(labels = scales::number_format(accuracy = 0.01)) +
        theme_tq()
    
    print(plt)
    
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
    
    # Facets by SOI
    # ALOS by SOI ----
    # Make data tbl
    alos_soi_tbl <- alos_tbl %>%
        filter(outlier_flag == 0) %>%
        mutate(dsch_date = ymd(dsch_date)) %>%
        collapse_by("monthly") %>%
        group_by(
            severity_of_illness
            , dsch_date
            , add = T
        ) %>%
        select(
            dsch_date
            , los
            , performance
            , severity_of_illness
            , drg_cost_weight
        ) %>%
        summarize(
            Total_Discharges = n()
            , alos = round(mean(los), 2)
            , perf = round(mean(performance), 2)
            , excess = (alos - perf)
            , cmi = round(mean(drg_cost_weight), 2)
        ) %>%
        ungroup()
    
    # Print Data
    plt <- alos_soi_tbl %>%
        ggplot(
            mapping = aes(
                x = dsch_date
            )
        ) +
        # Actual
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
        # Expected
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
            , y = "ALOS / ELOS"
            , title = "ALOS vs. ELOS by SOI"
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
        facet_wrap(~ severity_of_illness, scales = "free_y") +
        scale_y_continuous(
            labels = scales::number_format(accuracy = 0.1)
            , expand = c(0,0)
        ) +
        theme_tq()
    
    print(plt)
    
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
    
    # Anomaly detection and decomposition ----
    # Monthly Excess Days
    plt <- alos_trend_tbl %>%
        time_decompose(tot_excess_days, frequency = 2) %>%
        anomalize(remainder, method = "gesd") %>%
        clean_anomalies() %>%
        plot_anomaly_decomposition() +
        labs(
            x = "Discharge Date"
            , y = "Value"
            , title = "Excess Days Anomaly Decomposition"
        )
    
    print(plt)
    }
    
}

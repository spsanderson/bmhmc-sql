oppe_alos_anomaly_plt <- function(data){
    
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
        
        # Anomaly detection and decomposition ----
        # Monthly Excess Days
        if(nrow(alos_trend_tbl) < 12) {
            return(NA)
        } else {
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
}
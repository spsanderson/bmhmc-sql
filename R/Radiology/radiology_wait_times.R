# Lib Load ####
install.load::install_load(
  "tidyverse"
  , "esquisse"
  , "DataExplorer"
  , "funModeling"
  , "tibbletime"
  , "anomalize"
  , "zoo"
  , "data.table"
  , "lubridate"
)

# Source functions
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\get_rad_wait_time_data.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\clean_names.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\optimal_bin_size.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\rad_t_alert_wait_time_merge.R")

# Parameters
yr_qtr_a <- "2019q1"
yr_qtr_b <- "2019q2"

# Get Rad Files ####
# load clean_names function and run it
df_clean_a <- get_rad_wait_time_data(months = c("Jan","Feb","Mar"))
df_clean_b <- get_rad_wait_time_data(months = c("Apr","May","Jun"))

df_clean_a$yr_qtr <- as.factor(yr_qtr_a)
df_clean_b$yr_qtr <- as.factor(yr_qtr_b)

summary(df_clean_a)
summary(df_clean_b)

glimpse(df_clean_a)
glimpse(df_clean_b)

plot_missing(df_clean_a)
plot_missing(df_clean_b)

freq(df_clean_a, input = c("procedure_start_month_name"))
freq(df_clean_b, input = c("procedure_start_month_name"))

# Get T-Alert File ####
df_clean_merged_a <- rad_t_alert_wait_time_merge(df_clean_a, t_alert)
df_clean_merged_b <- rad_t_alert_wait_time_merge(df_clean_b, t_alert)

# Initial Viz ####
# df_clean_a
df_clean_merged_a %>%
  ggplot(
    mapping = aes(
      x = procedure_start_month_name
      , y = elapsed_time_int
    )
  ) +
  geom_boxplot(
    outlier.colour = "red"
    , fill = "lightblue"
  ) +
  xlab("Procedure Start Month") +
  ylab("Elapsed Time in Minutes") +
  labs(
    title = "Boxplot of Elapsed Time from Start to End"
    , subtitle = "Step: Ordered to End Procedure"
    , fill = ""
  ) +
  theme_light()

df_clean_merged_b %>%
  ggplot(
    mapping = aes(
      x = procedure_start_month_name
      , y = elapsed_time_int
    )
  ) +
  geom_boxplot(
    outlier.colour = "red"
    , fill = "lightblue"
  ) +
  xlab("Procedure Start Month") +
  ylab("Elapsed Time in Minutes") +
  labs(
    title = "Boxplot of Elapsed Time from Start to End"
    , subtitle = "Step: Ordered to End Procedure"
    , fill = ""
  ) +
  theme_light()

# Hist Elapsed Wait Times use opt bin function
df_clean_merged_a %>%
  ggplot(
    mapping = aes(
      x = elapsed_time_int
    )
  ) +
  geom_histogram(
    breaks = optBin(df_clean_a$elapsed_time_int)
    , color = "black"
    , fill = "lightblue"
    ) +
  xlab("Elapsed Time in Minutes") +
  ylab("Count") +
  labs(
    title = "Histogram of Elapsed Time in Minutes"
    , subtitle = paste("Data for:", yr_qtr_a)
  ) +
  theme_light()

df_clean_merged_b %>%
  ggplot(
    mapping = aes(
      x = elapsed_time_int
    )
  ) +
  geom_histogram(
    breaks = optBin(df_clean_b$elapsed_time_int)
    , color = "black"
    , fill = "lightblue"
  ) +
  xlab("Elapsed Time in Minutes") +
  ylab("Count") +
  labs(
    title = "Histogram of Elapsed Time in Minutes"
    , subtitle = paste("Data for:", yr_qtr_b)
  ) +
  theme_light()

# Anomaly Viz ####
# Elapsed Time ----
# df_clean_a
dfa_tsa <- df_clean_merged_a %>%
  as_tbl_time(index = step_start_time_clean) %>%
  arrange(step_start_time_clean) %>%
  time_decompose(elapsed_time_int, method = "stl") %>%
  anomalize(remainder, method = "gesd") %>%
  time_recompose()

dfa_tsa %>%
  plot_anomalies(
    ncol = 3
    , alpha_dots = 0.25
  ) +
  xlab("Order Date Time") +
  ylab("Observed") +
  labs(
    title = paste(
      "Anomaly Detection for"
      , yr_qtr_a
      , "Elapsed Time in Minutes"
      )
    , subtitle = "Method: GESD"
  )

dfa_tsa %>%
  plot_anomaly_decomposition() + 
  xlab("Order Date Time") + 
  ylab("Value") +
  labs(
    title = paste(
      "Anomaly Detection for"
      , yr_qtr_a
      , "- Freq/Trend = auto - Elapsed Time in Minutes")
    , subtitle = "Method: GESD"
  )

# Avg time per proc ----
dfa_tsap <- df_clean_merged_a %>%
  as_tbl_time(index = step_start_time_clean) %>%
  arrange(step_start_time_clean) %>%
  time_decompose(avg_time_per_proc, method = "stl") %>%
  anomalize(remainder, method = "gesd") %>%
  time_recompose()

dfa_tsap %>%
  plot_anomalies(
    ncol = 3
    , alpha_dots = 0.25
  ) +
  xlab("Order Date Time") +
  ylab("Observed") +
  labs(
    title = paste(
      "Anomaly Detection on Average Time/Procedure"
      , yr_qtr_a
    )
    , subtitle = "Method: GESD"
  )
  
dfa_tsap %>%
  plot_anomaly_decomposition() +
  xlab("Order Start Time") +
  ylab("Value") +
  labs(
    title = paste(
      "Anomaly Detection for"
      , yr_qtr_a
      , "- Freq/Trend = auto"
    )
    , subtitle = "Method: GESD"
  )

# df_clean_b
dfa_tsb <- df_clean_merged_b %>%
  as_tbl_time(index = step_start_time_clean) %>%
  arrange(step_start_time_clean) %>%
  time_decompose(elapsed_time_int, method = "stl") %>%
  anomalize(remainder, method = "gesd") %>%
  time_recompose()

dfa_tsb %>%
  plot_anomalies(
    ncol = 3
    , alpha_dots = 0.25
  ) +
  xlab("Order Date Time") +
  ylab("Observed") +
  labs(
    title = paste(
      "Anomaly Detection for"
      , yr_qtr_b
      , "Elapsed Time in Minutes"
      )
    , subtitle = "Method: GESD"
  )

dfa_tsb %>%
  plot_anomaly_decomposition() + 
  xlab("Order Date Time") + 
  ylab("Value") +
  labs(
    title = paste(
      "Anomaly Detection for"
      , yr_qtr_b
      , "- Freq/Trend = auto - Elapsed Time in Minutes"
      )
    , subtitle = "Method: GESD"
  )

# Avg time per proc
dfa_tsbp <- df_clean_merged_b %>%
  as_tbl_time(index = step_start_time_clean) %>%
  arrange(step_start_time_clean) %>%
  time_decompose(avg_time_per_proc, method = "stl") %>%
  anomalize(remainder, method = "gesd") %>%
  time_recompose()

dfa_tsbp %>%
  plot_anomalies(
    ncol = 3
    , alpha_dots = 0.25
  ) +
  xlab("Order Date Time") +
  ylab("Observed") +
  labs(
    title = paste(
      "Anomaly Detection on Average Time/Procedure"
      , yr_qtr_b
    )
    , subtitle = "Method: GESD"
  )

dfa_tsbp %>%
  plot_anomaly_decomposition() +
  xlab("Procedure Start Time") +
  ylab("Value") +
  labs(
    title = paste(
      "Anomaly Detection for"
      , yr_qtr_b
      , "- Freq/Trend = auto"
    )
    , subtitle = "Method: GESD"
  )

# Anomaly Detection ####
# Add anomaly indicator to df's
# Make df_clean_a and b into as_tbl_time
df_tt_a <- as_tbl_time(
  df_clean_merged_a
  , index = step_start_time_clean
  ) %>%
  anomalize(
    target = elapsed_time_int
    , method = "gesd"
    , alpha = 0.05
  )

df_tt_ap <- as_tbl_time(
  df_clean_merged_a
  , index = step_start_time_clean
  ) %>%
  anomalize(
    target = avg_time_per_proc
    , method = "gesd"
    , alpha = 0.05
  )

df_tt_b <- as_tbl_time(
  df_clean_merged_b
  , index = step_start_time_clean
  ) %>%
  anomalize(
    target = elapsed_time_int
    , method = "gesd"
    , alpha = 0.05
  )

df_tt_bp <- as_tbl_time(
  df_clean_merged_b
  , index = step_start_time_clean
) %>%
  anomalize(
    target = avg_time_per_proc
    , method = "gesd"
    , alpha = 0.05
  )

# Viz No Outliers ####
df_tt_a %>%
  filter(anomaly == "No") %>%
  ggplot(
    mapping = aes(
      x = procedure_start_month_name
      , y = elapsed_time_int
    )
  ) +
  geom_boxplot(
    outlier.colour = "red"
    , fill = "lightblue"
  ) +
  xlab("Procedure Start Month") +
  ylab("Elapsed Time in Minutes") +
  labs(
    title = paste("Boxplot of Elapsed Time from Start to End -", yr_qtr_a)
    , subtitle = "Step: Ordered to End Procedure"
    , caption = "Anomalies removed with GESD"
    , fill = ""
  ) +
  theme_light()

df_tt_ap %>%
  filter(anomaly == "No") %>%
  ggplot(
    mapping = aes(
      x = procedure_start_month_name
      , y = avg_time_per_proc
    )
  ) +
  geom_boxplot(
    outlier.colour = "red"
    , fill = "lightblue"
  ) +
  xlab("Procedure Start Month") +
  ylab("Elapsed Time in Minutes") +
  labs(
    title = paste("Boxplot of Avg Time Per Procedure -", yr_qtr_a)
    , subtitle = "Step: Ordered to End Procedure"
    , caption = "Anomalies removed with GESD"
    , fill = ""
  ) +
  theme_light()

df_tt_b %>%
  filter(anomaly == "No") %>%
  ggplot(
    mapping = aes(
      x = procedure_start_month_name
      , y = elapsed_time_int
    )
  ) +
  geom_boxplot(
    outlier.colour = "red"
    , fill = "lightblue"
  ) +
  xlab("Procedure Start Month") +
  ylab("Elapsed Time in Minutes") +
  labs(
    title = paste("Boxplot of Elapsed Time from Start to End -", yr_qtr_b)
    , subtitle = "Step: Ordered to End Procedure"
    , caption = "Anomalies removed with GESD"
    , fill = ""
  ) +
  theme_light()

df_tt_bp %>%
  filter(anomaly == "No") %>%
  ggplot(
    mapping = aes(
      x = procedure_start_month_name
      , y = avg_time_per_proc
    )
  ) +
  geom_boxplot(
    outlier.colour = "red"
    , fill = "lightblue"
  ) +
  xlab("Procedure Start Month") +
  ylab("Elapsed Time in Minutes") +
  labs(
    title = paste("Boxplot of Avg Time Per Procedure -", yr_qtr_b)
    , subtitle = "Step: Ordered to End Procedure"
    , caption = "Anomalies removed with GESD"
    , fill = ""
  ) +
  theme_light()

# Hist Elapsed Wait Times use opt bin function
df_tt_a %>%
  filter(anomaly == "No") %>%
  ggplot(
    mapping = aes(
      x = elapsed_time_int
    )
  ) +
  geom_histogram(
    breaks = optBin(df_clean_a$elapsed_time_int)
    , color = "black"
    , fill = "lightblue"
  ) +
  xlab("Elapsed Time in Minutes") +
  ylab("Count") +
  labs(
    title = "Histogram of Elapsed Time in Minutes"
    , subtitle = paste0(
      "Data for: "
      , yr_qtr_a
      ,"- Mean Time in Minutes: "
      , round(mean(df_clean_a$elapsed_time_int), 2)
    )
    , caption = "Anomalies removed with GESD"
  ) +
  theme_light()

df_tt_ap %>%
  filter(anomaly == "No") %>%
  ggplot(
    mapping = aes(
      x = elapsed_time_int
    )
  ) +
  geom_histogram(
    breaks = optBin(df_clean_a$avg_time_per_proc)
    , color = "black"
    , fill = "lightblue"
  ) +
  xlab("Elapsed Time in Minutes") +
  ylab("Count") +
  labs(
    title = "Histogram of Avg Time Per Procedure"
    , subtitle = paste0(
      "Data for: "
      , yr_qtr_a
      ,"- Mean Time in Minutes: "
      , round(mean(df_clean_a$avg_time_per_proc), 2)
    )
    , caption = "Anomalies removed with GESD"
  ) +
  theme_light()

df_tt_b %>%
  filter(anomaly == "No") %>%
  ggplot(
    mapping = aes(
      x = elapsed_time_int
    )
  ) +
  geom_histogram(
    breaks = optBin(df_clean_b$elapsed_time_int)
    , color = "black"
    , fill = "lightblue"
  ) +
  xlab("Elapsed Time in Minutes") +
  ylab("Count") +
  labs(
    title = "Histogram of Elapsed Time in Minutes"
    , subtitle = paste0(
      "Data for: "
      , yr_qtr_b
      ,"- Mean Time in Minutes: "
      , round(mean(df_clean_b$elapsed_time_int), 2)
    )
    , caption = "Anomalies removed with GESD"
  ) +
  theme_light()

df_tt_b %>%
  filter(anomaly == "No") %>%
  ggplot(
    mapping = aes(
      x = elapsed_time_int
    )
  ) +
  geom_histogram(
    breaks = optBin(df_clean_b$avg_time_per_proc)
    , color = "black"
    , fill = "lightblue"
  ) +
  xlab("Elapsed Time in Minutes") +
  ylab("Count") +
  labs(
    title = "Histogram of Avg Time Per Procedure"
    , subtitle = paste0(
      "Data for: "
      , yr_qtr_b
      ,"- Mean Time in Minutes: "
      , round(mean(df_clean_b$avg_time_per_proc), 2)
    )
    , caption = "Anomalies removed with GESD"
  ) +
  theme_light()

# ECDF
df_tt_a %>%
  filter(anomaly == "No") %>%
  ggplot(
    mapping = aes(
      x = elapsed_time_int
    )
  ) +
  xlab("Elapsed Time in Minutes") +
  ylab("Empirical Cumulative Distribution") +
  labs(
    title = "ECD of Elapsed Time in Minutes"
    , subtitle = paste("Data for", yr_qtr_a)
    , caption = "Anomalies removed with GESD"
  ) +
  theme_light() +
  stat_ecdf()

df_tt_ap %>%
  filter(anomaly == "No") %>%
  ggplot(
    mapping = aes(
      x = elapsed_time_int
    )
  ) +
  xlab("Avg Time Per Procedure") +
  ylab("Empirical Cumulative Distribution") +
  labs(
    title = "ECD of Elapsed Time in Minutes"
    , subtitle = paste("Data for", yr_qtr_a)
    , caption = "Anomalies removed with GESD"
  ) +
  theme_light() +
  stat_ecdf()

df_tt_b %>%
  filter(anomaly == "No") %>%
  ggplot(
    mapping = aes(
      x = elapsed_time_int
    )
  ) +
  xlab("Elapsed Time in Minutes") +
  ylab("Empirical Cumulative Distribution") +
  labs(
    title = "ECD of Elapsed Time in Minutes"
    , subtitle = paste("Data for", yr_qtr_b)
    , caption = "Anomalies removed with GESD"
  ) +
  theme_light() +
  stat_ecdf()

df_tt_bp %>%
  filter(anomaly == "No") %>%
  ggplot(
    mapping = aes(
      x = elapsed_time_int
    )
  ) +
  xlab("Avg Time Per Procedure") +
  ylab("Empirical Cumulative Distribution") +
  labs(
    title = "ECD of Elapsed Time in Minutes"
    , subtitle = paste("Data for", yr_qtr_b)
    , caption = "Anomalies removed with GESD"
  ) +
  theme_light() +
  stat_ecdf()

# Stat Tests ####
# T-Test on mean times
ttadf <- subset(df_tt_a, anomaly == "No")
ttapdf <- subset(df_tt_ap, anomaly == "No")
ttbdf <- subset(df_tt_b, anomaly == "No")
ttbpdf <- subset(df_tt_bp, anomaly == "No")
t.test(
  ttadf$elapsed_time_int
  , ttbdf$elapsed_time_int
  )
t.test(
  ttadf$elapsed_time_int
  , ttbdf$elapsed_time_int
  , alternative = "less"
  )
t.test(
  ttadf$elapsed_time_int
  , ttbdf$elapsed_time_int
  , alternative = "greater"
  )

t.test(
  ttapdf$avg_time_per_proc
  , ttbpdf$avg_time_per_proc
  )

t.test(
  ttapdf$avg_time_per_proc
  , ttbpdf$avg_time_per_proc
  , alternative = "less"
)

t.test(
  ttapdf$avg_time_per_proc
  , ttbpdf$avg_time_per_proc
  , alternative = "greater"
)

# Join Data sets ####
df_et <- rbind(df_tt_a, df_tt_b)

df_et %>%
  filter(anomaly == "No") %>%
  ggplot(
    mapping = aes(
      x = procedure_start_month_name
      , y = elapsed_time_int
      , fill = yr_qtr
    )
  ) +
  geom_boxplot(
    outlier.colour = "red"
  ) +
  xlab("Procedure Start Month") +
  ylab("Elapsed Time in Minutes") +
  labs(
    title = "Boxplot of Elapsed Time from Start to End"
    , subtitle = paste0(
      "Step: Ordered to End Procedure"
      , "\n"
      , yr_qtr_a
      , " - "
      , df_et %>%
        filter(yr_qtr == as.character(yr_qtr_a)) %>%
        dplyr::select(elapsed_time_int) %>%
        dplyr::summarize(round(mean(elapsed_time_int), 2))
      , "\n"
      , yr_qtr_b
      , " - "
      , df_et %>%
        filter(yr_qtr == as.character(yr_qtr_b)) %>%
        dplyr::select(elapsed_time_int) %>%
        dplyr::summarize(round(mean(elapsed_time_int), 2))
    )
    , fill = "Quarter"
  ) +
  theme_light()

df_et %>% 
  filter(anomaly == "No") %>%
  ggplot(
    mapping = aes(
      x = procedure_start_month_name
      , y = avg_time_per_proc
      , fill = yr_qtr
    )
  ) +
  geom_boxplot(
    outlier.colour = "red"
    #, fill = "lightblue"
  ) +
  xlab("Procedure Start Month") +
  ylab("Elapsed Time in Minutes") +
  labs(
    title = "Boxplot of Average Time Per Procedure from Start to End"
    , subtitle = paste0(
      "Step: Ordered to End Procedure"
      , "\n"
      , yr_qtr_a
      , " - "
      , df_et %>%
        filter(yr_qtr == as.character(yr_qtr_a)) %>%
        dplyr::select(avg_time_per_proc) %>%
        dplyr::summarize(round(mean(avg_time_per_proc), 2))
      , "\n"
      , yr_qtr_b
      , " - "
      , df_et %>%
        filter(yr_qtr == as.character(yr_qtr_b)) %>%
        dplyr::select(avg_time_per_proc) %>%
        dplyr::summarize(round(mean(avg_time_per_proc), 2))
    )
    , fill = "Quarter"
  ) +
  theme_light()

# Merged Anomaly Viz
df_tsa <- df_et %>%
  as_tbl_time(index = step_start_time_clean) %>%
  arrange(step_start_time_clean) %>%
  time_decompose(elapsed_time_int, method = "stl") %>%
  anomalize(remainder, method = "gesd") %>%
  time_recompose()

df_tsa %>%
  plot_anomalies(
    ncol = 3
    , alpha_dots = 0.25
  ) +
  xlab("Procedure Start Time") +
  ylab("Observed") +
  labs(
    title = paste("Anomaly Detection on Elapsed Procedure Time in Minutes")
    , subtitle = "Method: GESD"
  )

df_tsa %>%
  plot_anomaly_decomposition() + 
  xlab("Procedure Start Time") + 
  ylab("Value") +
  labs(
    title = "Anomaly Detection - Freq/Trend = auto - Elapsed Procedure Time in Minutes"
    , subtitle = "Method: GESD"
  )

df_tsap <- df_et %>%
  as_tbl_time(index = step_start_time_clean) %>%
  arrange(step_start_time_clean) %>%
  time_decompose(avg_time_per_proc, method = "stl") %>%
  anomalize(remainder, method = "gesd") %>%
  time_recompose()

df_tsap %>%
  plot_anomalies(
    ncol = 3
    , alpha_dots = 0.25
  ) +
  xlab("Procedure Start Time") +
  ylab("Observed") +
  labs(
    title = "Anomaly Detection on Average Procedure Time"
    , subtitle = "Method: GESD"
  )

df_tsap %>%
  plot_anomaly_decomposition() +
  xlab("Procedure Start Time") +
  ylab("Value") +
  labs(
    title = "Anomaly Detection - Freq/Trend = auto - Average Procedure Time"
    , subtitle = "Method: GESD"
  )

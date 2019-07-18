# Lib Load ####
install.load::install_load(
  "tidyverse"
  , "lubridate"
  , "esquisse"
  , "DataExplorer"
  , "funModeling"
  , "tibbletime"
  , "anomalize"
)

# Get File ####
# load clean_names function and run it
file.to.load <- tryCatch(file.choose(new = T), error = function(e) "")
dfa <- read.csv(file.to.load) %>%
  clean_names()

# Clean files ####
# create df_clean_a and df_clean_b
df_clean_a <- dfa %>%
  filter(!is.na(acc)) %>%
  select(
    acc
    , procedure_information
    , reading_doctor
    , step_start_time
    , step_end_time
    , step_from_to
    , wait_time
  ) %>%
  mutate(
    step_start_time_clean = mdy_hms(step_start_time)
    , step_end_time_clean = mdy_hms(step_end_time)
    , elapsed_time = difftime(step_end_time_clean, step_start_time_clean, units = "mins")
    , elapsed_time_int = as.integer(elapsed_time)
    , procedure_start_year = year(step_start_time_clean)
    , procedure_start_month = month(step_start_time_clean)
    , procedure_start_month_name = month(step_start_time_clean, label = T, abbr = T)
    , procedure_start_day = day(step_start_time_clean)
    , procedure_start_dow = wday(step_start_time_clean, label = T, abbr = T)
    , procedure_start_hour = hour(step_start_time_clean)
    , procedure_end_year = year(step_end_time_clean)
    , procedure_end_month = month(step_end_time_clean)
    , procedure_end_month_name = month(step_end_time_clean, label = T, abbr = T)
    , procedure_end_day = day(step_end_time_clean)
    , procedure_end_dow = wday(step_end_time_clean, label = T, abbr = T)
    , procedure_end_hour = hour(step_end_time_clean)
  ) %>%
  filter(procedure_start_month_name %in% c("Oct","Nov","Dec")) %>%
  filter(elapsed_time_int >= 0)

# get file b
file.to.load <- tryCatch(file.choose(new = T), error = function(e) "")
dfb <- read.csv(file.to.load) %>%
  clean_names()

df_clean_b <- dfb %>%
  filter(!is.na(acc)) %>%
  select(
    acc
    , procedure_information
    , reading_doctor
    , step_start_time
    , step_end_time
    , step_from_to
    , wait_time
  ) %>%
  mutate(
    step_start_time_clean = mdy_hms(step_start_time)
    , step_end_time_clean = mdy_hms(step_end_time)
    , elapsed_time = difftime(step_end_time_clean, step_start_time_clean, units = "mins")
    , elapsed_time_int = as.integer(elapsed_time)
    , procedure_start_year = year(step_start_time_clean)
    , procedure_start_month = month(step_start_time_clean)
    , procedure_start_month_name = month(step_start_time_clean, label = T, abbr = T)
    , procedure_start_day = day(step_start_time_clean)
    , procedure_start_dow = wday(step_start_time_clean, label = T, abbr = T)
    , procedure_start_hour = hour(step_start_time_clean)
    , procedure_end_year = year(step_end_time_clean)
    , procedure_end_month = month(step_end_time_clean)
    , procedure_end_month_name = month(step_end_time_clean, label = T, abbr = T)
    , procedure_end_day = day(step_end_time_clean)
    , procedure_end_dow = wday(step_end_time_clean, label = T, abbr = T)
    , procedure_end_hour = hour(step_end_time_clean)
  ) %>%
  filter(procedure_start_month_name %in% c("Jan", "Feb","Mar")) %>%
  filter(elapsed_time_int >= 0)

summary(df_clean_a)
summary(df_clean_b)

glimpse(df_clean_a)
glimpse(df_clean_b)

plot_missing(df_clean_a)
plot_missing(df_clean_b)

freq(df_clean_a, input = c("procedure_start_month_name"))
freq(df_clean_b, input = c("procedure_start_month_name"))

# Initial Viz ####
# df_clean_a
df_clean_a %>%
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

df_clean_b %>%
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
df_clean_a %>%
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
    , subtitle = "Data for: 2018q4"
  ) +
  theme_light()

df_clean_b %>%
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
    , subtitle = "Data for: 2019q1"
  ) +
  theme_light()

# Anomaly Viz ####
# df_clean_a
dfa_tsa <- df_clean_a %>%
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
  xlab("Procedure Start Time") +
  ylab("Observed") +
  labs(
    title = "Anomaly Detection for 2018q4"
    , subtitle = "Method: GESD"
  )

dfa_tsa %>%
  plot_anomaly_decomposition() + 
  xlab("Procedure Start Time") + 
  ylab("Value") +
  labs(
    title = "Anomaly Detection for 2018q4 - Freq/Trend = auto"
    , subtitle = "Method: GESD"
  )

# df_clean_b
dfa_tsb <- df_clean_b %>%
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
  xlab("Procedure Start Time") +
  ylab("Observed") +
  labs(
    title = "Anomaly Detection for 2019q1"
    , subtitle = "Method: GESD"
  )

dfa_tsb %>%
  plot_anomaly_decomposition() + 
  xlab("Procedure Start Time") + 
  ylab("Value") +
  labs(
    title = "Anomaly Detection for 2019q1 - Freq/Trend = auto"
    , subtitle = "Method: GESD"
  )

# Anomalize ####
# Add anomaly indicator to df's
# Make df_clean_a and b into as_tbl_time
df_tt_a <- as_tbl_time(
  df_clean_a
  , index = step_start_time_clean
  ) %>%
  anomalize(
    target = elapsed_time_int
    , method = "gesd"
    , alpha = 0.05
  )

df_tt_b <- as_tbl_time(
  df_clean_b
  , index = step_start_time_clean
  ) %>%
  anomalize(
    target = elapsed_time_int
    , method = "gesd"
    , alpha = 0.05
  )

# df a and b wo anomalies
df_tt_ac <- df_tt_a %>%
  filter(anomaly == "No")

df_tt_bc <- df_tt_b %>%
  filter(anomaly == "No")

# Clean Viz ####
df_tt_ac %>%
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
    , caption = "Anomalies removed with GESD"
    , fill = ""
  ) +
  theme_light()

df_tt_bc %>%
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
    , caption = "Anomalies removed with GESD"
    , fill = ""
  ) +
  theme_light()

# Hist Elapsed Wait Times use opt bin function
df_tt_ac %>%
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
      "Data for: 2018q4 - Mean Time in Minutes: "
      , round(mean(df_clean_a$elapsed_time_int), 2)
    )
    , caption = "Anomalies removed with GESD"
  ) +
  theme_light()

df_tt_bc %>%
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
      "Data for: 2019q1 - Mean Time in Minutes: "
      , round(mean(df_clean_b$elapsed_time_int), 2)
    )
    , caption = "Anomalies removed with GESD"
  ) +
  theme_light()

# ECDF
df_tt_ac %>%
  ggplot(
    mapping = aes(
      x = elapsed_time_int
    )
  ) +
  xlab("Elapsed Time in Minutes") +
  ylab("Empirical Cumulative Distribution") +
  labs(
    title = "ECD of Elapsed Time in Minutes"
    , subtitle = "Data for 2018q4"
    , caption = "Anomalies removed with GESD"
  ) +
  theme_light() +
  stat_ecdf()

df_tt_bc %>%
  ggplot(
    mapping = aes(
      x = elapsed_time_int
    )
  ) +
  xlab("Elapsed Time in Minutes") +
  ylab("Empirical Cumulative Distribution") +
  labs(
    title = "ECD of Elapsed Time in Minutes"
    , subtitle = "Data for 2019q1"
    , caption = "Anomalies removed with GESD"
  ) +
  theme_light() +
  stat_ecdf()

# Stat Tests ####
# T-Test on mean times
t.test(df_tt_ac$elapsed_time_int, df_tt_bc$elapsed_time_int)
t.test(df_tt_ac$elapsed_time_int, df_tt_bc$elapsed_time_int, alternative = "less")
t.test(df_tt_ac$elapsed_time_int, df_tt_bc$elapsed_time_int, alternative = "greater")

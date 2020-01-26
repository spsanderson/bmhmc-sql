# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
  "tidyverse"
  , "lubridate"
  , "tidyquant"
  , "tibbletime"
  , "anomalize"
  , "sweep"
  , "readxl"
  , "writexl"
  , "knitr"
  , "kableExtra"
)

# Source Functions ----
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\clean_names.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\optimal_bin_size.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\optimal_hist_bin_size.R")

# Get File ----
file.to.load <- tryCatch(file.choose(new = T), error = function(e)"")

# Read Data and Clean column names
df <- read_xlsx(file.to.load, sheet = "DATA") %>%
  clean_names()

# Data with missing info
df[!complete.cases(df),] %>% glimpse()

# Drop data with missing info
df_tbl <- df[complete.cases(df),]

# Clean columns and column types
df_tbl <- df_tbl %>%
  as_tibble() %>%
  mutate_if(is.character, str_squish) %>%
  mutate(account = account %>% as.character() %>% str_squish()) %>%
  # Title case names
  mutate(
    admittingmd = admittingmd %>% str_to_title()
  ) %>%
  # Lubridate arrival dow, hour and weekday name
  mutate(
    arr_day = arrival %>% mday()
    , arr_dow_name = arrival %>% 
      wday(
        label = TRUE
        , abbr = TRUE
        , week_start = getOption("lubridate.week.start", 7)
      )
    , arr_hr = arrival %>% hour()
  ) %>%
  as_tbl_time(index = arrival, keep = TRUE) %>%
  arrange(arrival) %>%
  # get rid of diff < -120 minutes
  filter(diff >= -120)

# Anomalize Diff ----
df_tbl %>%
  time_decompose(
    target = diff
    , method = "twitter"
    , message = FALSE
  ) %>%
  anomalize(
    remainder
    , method = "gesd"
  ) %>%
  clean_anomalies() %>% 
  time_recompose() %>%
  plot_anomalies(
    time_recomposed = TRUE
    , alpha_dots = 0.25
  ) +
  labs(
    x = ""
    , y = ""
    , title = "Anomaly Detection"
    , subtitle = "GESD + Twitter Methods"
  )

df_tbl %>%
  time_decompose(
    target = diff
    , method = "twitter"
    , message = FALSE
  ) %>%
  anomalize(
    remainder
    , method = 'gesd'
  ) %>%
  plot_anomaly_decomposition() +
  labs(
    x = ""
    , y = ""
    , title = "Anomaly Detection"
    , subtitle = "GESD + Twitter Methods"
  )

df_tbl %>%
  time_decompose(
    target = diff
    , method = "twitter"
    , message = FALSE
  ) %>%
  anomalize(
    target = remainder
    , method = "gesd"
  ) %>%
  clean_anomalies() %>%
  time_recompose() %>%
  select(arrival, anomaly, observed, observed_cleaned) %>%
  mutate(
    arr_dow_name = wday(
      arrival
      , label = TRUE
      , abbr = FALSE
      , week_start = 7
    )
  ) %>%
  mutate(arr_dow_fct = arr_dow_name %>% as_factor()) %>%
  plot_anomalies() +
  facet_wrap(~ arr_dow_fct, scales = "free_y") +
  labs(
    title = "Anomalies by Day of Week"
    , subtitle = "GESD + Twitter Methods"
  )

# Set benchmark ----
anomaly_obj <- df_tbl %>%
  time_decompose(
    target = diff
    , method = "twitter"
    , message = FALSE
  ) %>%
  anomalize(
    target = remainder
    , method = "gesd"
  ) %>%
  clean_anomalies() %>%
  time_recompose()

df_anomalized_tbl <- bind_cols(df_tbl, anomaly_obj)
df_anomalized_tbl <- df_anomalized_tbl %>%
  mutate(
    ou_ind = ifelse(
      observed > 75
      , "Over_Bench"
      , "Under_Bench"
    )
  )
df_anomalized_tbl

# Aggregate Tbl ----
agg_tbl <- df_anomalized_tbl %>%
  select(
    admittingmd
    , account
    , observed
  ) %>%
  group_by(
    admittingmd
  ) %>%
  summarise(
    pt_count = n()
    , avg_time = round(mean(observed, na.rm = TRUE), 2)
    , pt_count_lbl = str_glue("Admits: {pt_count}")
    , avg_time_lbl = str_glue("Avg Minutes: {avg_time}")
    , lbl_txt = str_glue("Avg Minutes: {avg_time} - Admits: {pt_count}")
  ) %>%
  ungroup() %>%
  filter(pt_count >= 10) %>%
  mutate(ou_ind = ifelse(avg_time > 75, "Over","Under"))
 
agg_tbl %>%
  ggplot(
    mapping = aes(
      x = avg_time
      , y = reorder(admittingmd, avg_time)
      , color = ou_ind
    )
  ) +
  geom_point(size = 3) +
  geom_segment(
    mapping = aes(
      yend = admittingmd
    )
    , xend = 0
    , color = "black"
  ) +
  geom_vline(xintercept = 75, linetype = "dashed") +
  geom_label(
    mapping = aes(
      label = lbl_txt
    )
    , hjust = "inward"
    , size = 3
    , color = palette_light()[1]
  ) +
  theme_tq() +
  scale_color_tq() +
  labs(
    x = "Average Time"
    , y = "Provider"
    , title = "Average Time from Decision to Admit to Admit Order Entry"
    , subtitle = "Providers must have 10 or more admits to be displayed"
    , caption = "Benchmark is 75 Minutes"
    , color = ""
  )

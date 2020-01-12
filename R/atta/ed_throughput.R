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
df <- read_xlsx(file.to.load, sheet = "data") %>%
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
  # Make sure edmdid and adm_dr_no are 6 chr long
  mutate(
    edmdid = edmdid %>% as.character()
    , edmdid = if_else(
      str_length(edmdid) < 6
      , str_c(0, edmdid)
      , edmdid
    )
    , adm_dr_no = adm_dr_no %>% as.character()
    , adm_dr_no = if_else(
      str_length(adm_dr_no) < 6
      , str_c(0, adm_dr_no)
      , adm_dr_no
    )
  ) %>%
  # Title case names
  mutate(
    ed_md = ed_md %>% str_to_title()
    , adm_dr = adm_dr %>% str_to_title()
  ) %>%
  # Make Factors
  mutate(
    hospitalist_flag = hospitalist_flag %>% as_factor()
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
  select(-arr_dow) %>%
  as_tbl_time(index = arrival, keep = TRUE)

# Diff Times ----
df_tbl <- df_tbl %>%
  mutate(
    t_arr_to_dta_minutes = difftime(
        decision_to_admit
        , arrival
        , units = "mins"
      ) %>% as.integer()
    , TimeSegment_1 = t_arr_to_dta_minutes
    , t_dta_to_adm_ord_entry_minutes = difftime(
        admit_order_entry_d_time
        , decision_to_admit
        , units = "mins"
      ) %>% as.integer()
    , TimeSegment_2 = t_dta_to_adm_ord_entry_minutes
    , t_adm_ord_to_adm_confirm_minutes = difftime(
        admit_confirm
        , admit_order_entry_d_time
        , units = "mins"
      ) %>% as.integer()
    , TimeSegment_3 = t_adm_ord_to_adm_confirm_minutes
    , t_adm_confirm_to_tack_minutes = difftime(
        added_toad_missions_track
        , admit_confirm
        , units = "mins"
      ) %>% as.integer()
    , TimeSegment_4 = t_adm_confirm_to_tack_minutes
    , t_track_to_adm_bed_minutes = difftime(
        bed_occupied_time
        , added_toad_missions_track
        , units = "mins"
      ) %>% as.integer()
    , TimeSegmenet_5 = t_track_to_adm_bed_minutes
    , t_adm_bed_to_leave_ed_minutes = difftime(
        time_lefted
        , bed_occupied_time
        , units = "mins"
      ) %>% as.integer()
    , TimeSegment_6 = t_adm_bed_to_leave_ed_minutes
    , t_first_non_er_bed_minutes = difftime(
        non_er_bed_occupied_time
        , time_lefted
        , units = "mins"
      ) %>% as.integer()
    , TimeSegment_7 = t_first_non_er_bed_minutes
    , t_arrival_to_leave_ed_minutes = difftime(
        time_lefted
        , arrival
        , units = "mins"
      ) %>% as.integer()
    , TimeSegment_8 = t_arrival_to_leave_ed_minutes
    , t_arr_to_first_non_er_bed_minutes = difftime(
        non_er_bed_occupied_time
        , arrival
        , unit = "mins"
      ) %>% as.integer()
    , TimeSegment_9 = t_arr_to_first_non_er_bed_minutes
    , t_dsch_ord_to_dsch_minutes = difftime(
      dsch_dt
      , last_dsch_ord_dt
      , unit = "mins"
    ) %>% as.integer()
    , TimeSegment_10 = t_dsch_ord_to_dsch_minutes
    )

# View Times ----
cols_to_anomalize <- df_tbl %>% 
  select(
    starts_with("t_")
  ) %>% 
  colnames() %>%
  enframe() %>%
  mutate(value = value %>% as_factor()) %>%
  mutate(value_char = value %>% as.character())

par(mfrow = c(4,3))
for(i in 1:nrow(cols_to_anomalize)){
  c <- cols_to_anomalize[10,]$value
  title <- str_c(
    "Hist for: "
    , as.character(c) 
  )
  title <- title %>% 
    str_to_title() %>%
    str_replace_all(
      pattern = "_"
      , replacement = " "
    )
  df_tmp <- df_tbl %>%
    select(contains(as.character(c)), -contains("anomaly_")) %>%
    pull() %>%
    enframe()
  
  tryCatch(
    sshist(
      df_tmp$value
      , main = title
    )
    , error = function(e) hist(df_tmp$value, main = title)
  )
  rm(c)
  rm(title)
  rm(df_tmp)
}
par(mfrow = c(1,1))

# Drop Bad Times ----
# Drop records with bad time deltas / confirmed with IS
df_tbl <- df_tbl %>%
  filter(
    t_arr_to_dta_minutes >= 0
    , t_dta_to_adm_ord_entry_minutes >= -120
    , t_adm_ord_to_adm_confirm_minutes >= 0
    , t_adm_confirm_to_tack_minutes >= 0
    , t_track_to_adm_bed_minutes >= 0
    , t_adm_bed_to_leave_ed_minutes >= 0
    , t_first_non_er_bed_minutes >= -120
    , t_arrival_to_leave_ed_minutes >= 0
    , t_arr_to_first_non_er_bed_minutes >= 0
    , t_dsch_ord_to_dsch_minutes >= 0
  )

# Get anomalies ----
# Explore Data first
# Create table to get anomlized data
anomalize_tbl <- df_tbl %>%
  select(
    arrival
    , starts_with("t_")
  )

anomalize_long_tbl <- anomalize_tbl %>%
  pivot_longer(
    cols = cols_to_anomalize$value_char
    , names_to = "time_segment"
  ) %>%
  mutate(arrival = floor_date(arrival, unit = "days")) %>%
  mutate(time_segment = time_segment %>% as_factor()) %>%
  as_tbl_time(index = arrival, add = TRUE) %>%
  collapse_by("daily") %>%
  group_by(
    time_segment
    , add = TRUE
  ) %>%
  select(
    arrival
    , value
    , time_segment
  )

# View Anomalies
anomalize_long_tbl %>%
  time_decompose(
    target = value
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
  facet_wrap(~ time_segment, scales = "free_y") +
  labs(
    x = ""
    , y = ""
    , title = "Anomaly Detection"
    , subtitle = "GESD + Twitter Methods"
  )

# Add anomaly column to df_tbl
for(i in 1:nrow(cols_to_anomalize)){
  c <- cols_to_anomalize[i,]$value
  new_name <- str_c("anomaly_", as.character(c))
  print(paste("Anomalizing:", as.character(c)))
  df_tmp <- df_tbl %>%
    select(
      account
      , contains(as.character(c))
      , -contains("anomaly)")
    ) %>%
    anomalize(
      target = as.character(c)
      , method = "gesd"
      , alpha = 0.05
    ) 
  df_tmp <- df_tmp %>% select(account, anomaly)
  names(df_tmp)[ncol(df_tmp)] <- new_name
  df_tbl <- df_tbl %>%
    left_join(
      df_tmp
      , by = c("account" = "account")
    )
  rm(df_tmp)
  rm(c)
  rm(new_name)
  rm(i)
}

# Histograms ----
# Anomalies Kept In
par(mfrow = c(4,3))
for(i in 1:nrow(cols_to_anomalize)){
  c <- cols_to_anomalize[i,]$value
  title <- str_c(
    "Hist for: "
    , as.character(c) 
    , " with anomalies"
  )
  title <- title %>% 
    str_to_title() %>%
    str_replace_all(
      pattern = "_"
      , replacement = " "
    )
  df_tmp <- df_tbl %>%
    select(contains(as.character(c)), -contains("anomaly_")) %>%
    pull() %>%
    enframe()
  
  tryCatch(
    sshist(
      df_tmp$value
      , main = title
    )
    , error = function(e) hist(df_tmp$value, main = title)
  )
}
par(mfrow = c(1,1))

# Anomalies removed
par(mfrow = c(4,3))
for(i in 1:nrow(cols_to_anomalize)){
  c <- cols_to_anomalize[i,]$value
  title <- str_c(
    "Hist for: "
    , as.character(c) 
    , " without anomalies"
  )
  title <- title %>% 
    str_to_title() %>%
    str_replace_all(
      pattern = "_"
      , replacement = " "
    )
  filt_col <- str_c("anomaly_", as.character(c))
  df_tmp <- df_tbl %>%
    filter(!!sym(filt_col) == "No") %>%
    select(contains(as.character(c)), -contains("anomaly_")) %>%
    pull() %>%
    enframe()

  tryCatch(
    sshist(
      df_tmp$value
      , main = title
      )
    , error = function(e) hist(df_tmp$value, main = title)
    )
  
  rm(c)
  rm(title)
  rm(df_tmp)
  rm(i)
}
par(mfrow = c(1,1))

# Time Delta (Not)Anomaly ----
# Anomaly Columns
anomaly_cols <- df_tbl %>% 
  select(
    starts_with("anomaly_")
  ) %>% 
  colnames() %>%
  enframe() %>%
  mutate(value = value %>% as_factor()) %>%
  mutate(value_char = value %>% as.character())

anomaly_tbl <- anomalize_long_tbl %>%
  time_decompose(
    target = value
    , method = "twitter"
    , message = FALSE
  ) %>%
  anomalize(
    remainder
    , method = "gesd"
  ) %>%
  clean_anomalies() %>% 
  time_recompose()

avg_time_anomaly_tbl <- anomaly_tbl %>%
  select(
    time_segment
    , observed
    , observed_cleaned
    , anomaly
  ) %>%
  group_by(time_segment, anomaly) %>%
  summarise(
    avg_observed = round(mean(observed, na.rm = TRUE), 2)
  ) %>%
  ungroup() %>%
  pivot_wider(
    names_from = anomaly
    , values_from = avg_observed
  ) %>%
  mutate(
    avg_difference = (Yes - No)
    , time_segment_char = time_segment %>% as.character()
  ) 

avg_time_tbl <- df_tbl %>%
  pivot_longer(
    cols = cols_to_anomalize$value_char
    , names_to = "time_segment"
    , values_to = "step_time"
  ) %>%
  select(time_segment, step_time) %>%
  group_by(time_segment) %>%
  summarise(
    avg_time = round(mean(step_time, na.rm = TRUE), 2)
  ) %>%
  ungroup() %>%
  left_join(
    cols_to_anomalize
    , by = c("time_segment" = "value_char")
  ) %>% # new
  select(
    time_segment
    , name
    , avg_time
  ) %>%
  select(time_segment, avg_time)

avg_time_tbl %>%
  left_join(
    avg_time_anomaly_tbl
    , by = c("time_segment"="time_segment_char")
  ) %>%
  select(
    time_segment.y
    , avg_time
    , No
    , Yes
    , avg_difference
  ) %>%
  arrange(time_segment.y) %>%
  set_names(
    "Time_Segment"
    , "Avg_Time"
    , "Avg_Time_Anomalies_N"
    , "Avg_Time_Anomalies_Y"
    , "Avg_Diff_Anomaly_Y/N"
  ) %>%
  mutate(
    Time_Segment = Time_Segment %>% 
      as.character() %>%
      str_replace_all("_"," ") %>%
      str_to_title()
  ) %>%
  mutate(
    Time_Segment = case_when(
      str_starts(Time_Segment, "T ") ~ str_replace(Time_Segment, "T ", replacement = "")
    )
  ) %>%
  mutate(
    Avg_Shift = Avg_Time - Avg_Time_Anomalies_N
  ) %>%
  kable() %>%
  kable_styling(bootstrap_options = c(
    "striped"
    , "hover"
    , "condensed"
    , "responsive"
  )
  , font_size = 12
  , full_width = F
  )

anomaly_tbl %>%
  ungroup() %>%
  left_join(
    avg_time_anomaly_tbl
    , by = c("time_segment"="time_segment")
  ) %>%
  select(
    time_segment
    , observed
    , anomaly
  ) %>%
  arrange(time_segment) %>%
  mutate(
    time_segment = time_segment %>% 
      as.character() %>%
      str_replace_all("_"," ") %>%
      str_to_title()
  ) %>%
  mutate(
    time_segment = case_when(
      str_starts(time_segment, "T ") ~ str_replace(time_segment, "T ", replacement = "")
    )
  ) %>%
  mutate(
    time_segment = time_segment %>% as_factor()
  ) %>%
  ggplot(
    mapping = aes(
      x = time_segment
      , y = observed
      , fill = anomaly
    )
  ) +
  geom_boxplot() +
  theme_tq() +
  scale_fill_tq() +
  labs(
    title = "Boxplot of Times for Anomalies vs Non-Anomalies"
    , x = ""
    , y = ""
  ) +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1)
  )

# Dsch Ord HR ----
dsch_ord_by_hr_tbl <- df_tbl %>%
  select(last_dsch_ord_dt) %>%
  mutate(dsch_hr = hour(last_dsch_ord_dt)) %>%
  group_by(dsch_hr) %>%
  summarise(
    orders_by_hr = n()
  ) %>%
  ungroup() %>%
  mutate(
    total_orders = sum(orders_by_hr)
  ) %>%
  mutate(
    run_tot = cumsum(orders_by_hr)
    , pct   = round(orders_by_hr / total_orders, 3)
    , run_pct = round(run_tot / total_orders, 3)
    , orders_by_hr_txt = as.character(orders_by_hr)
    , run_tot_txt = as.character(run_tot)
    , pct_txt = scales::percent(pct, accuracy = 0.01)
    , run_pct_txt = scales::percent(run_pct, accuracy = 0.01)
  ) %>%
  mutate(
    label_text = str_glue(
      "Dsch Hr: {dsch_hr}\nOrders: {orders_by_hr}\nCumPct: {run_pct_txt}"
    )
  ) %>%
  as_tibble()

dsch_ord_by_hr_tbl %>%
  ggplot(
    mapping = aes(
      x = dsch_hr
      , y = orders_by_hr
    )
  ) +
  geom_col(
    color = "black"
  ) +
  geom_label(
    mapping = aes(
      label = label_text
    )
    , hjust = "inward"
    , data = dsch_ord_by_hr_tbl %>% filter(dsch_hr == 11)
    , size = 3
  ) +
  theme_tq() +
  scale_fill_tq() +
  labs(
    x = ""
    , y = ""
    , title = "Distribution of Last Discharge Order Entry Hour"
  )

# Discharge Hr ----
dsch_by_hr_tbl <- df_tbl %>%
  select(dsch_dt) %>%
  mutate(dsch_hr = hour(dsch_dt)) %>%
  group_by(dsch_hr) %>%
  summarise(
    discharges_by_hr = n()
  ) %>%
  ungroup() %>%
  mutate(
    total_discharges = sum(discharges_by_hr)
  ) %>%
  mutate(
    run_tot = cumsum(discharges_by_hr)
    , pct   = round(discharges_by_hr / total_discharges, 3)
    , run_pct = round(run_tot / total_discharges, 3)
    , orders_by_hr_txt = as.character(discharges_by_hr)
    , run_tot_txt = as.character(run_tot)
    , pct_txt = scales::percent(pct, accuracy = 0.01)
    , run_pct_txt = scales::percent(run_pct, accuracy = 0.01)
  ) %>%
  mutate(
    label_text = str_glue(
      "Dsch Hr: {dsch_hr}\nDischarges: {discharges_by_hr}\nCumPct: {run_pct_txt}"
    )
  ) %>%
  as_tibble()

dsch_by_hr_tbl %>%
  ggplot(
    mapping = aes(
      x = dsch_hr
      , y = discharges_by_hr
    )
  ) +
  geom_col(
    color = "black"
  ) +
  geom_label(
    mapping = aes(
      label = label_text
    )
    , hjust = "inward"
    , data = dsch_by_hr_tbl %>% filter(dsch_hr == 11)
    , size = 3
  ) +
  theme_tq() +
  scale_fill_tq() +
  labs(
    x = ""
    , y = ""
    , title = "Distribution of Discharges by hour"
  )

# Table Data
process_hr_tbl <- tibble(
  process_hr = seq(from = 0, to = 23, by = 1)
  , discharge = 1
  , discharge_ord = 1
  )

dschord_dsch_tbl <- process_hr_tbl %>%
  left_join(
    dsch_ord_by_hr_tbl
    , by = c("process_hr" = "dsch_hr")
  ) %>%
  select(
    process_hr
    , orders_by_hr
    , total_orders
    , run_tot
    , pct
    , run_pct
  ) %>% 
  set_names(
    "process_hr"
    , "orders_by_hr"
    , "total_orders"
    , "run_total_orders"
    , "pct_total_orders"
    , "run_total_pct_orders"
  ) %>%
  mutate(
    orders_by_hr = ifelse(
      is.na(orders_by_hr)
      , 0
      , orders_by_hr
    )
    , total_orders = zoo::na.locf(total_orders)
    , run_total_orders = ifelse(
      is.na(run_total_orders)
      , 0
      , run_total_orders
    )
    , pct_total_orders = ifelse(
      is.na(pct_total_orders)
      , 0
      , pct_total_orders
    )
    , run_total_pct_orders = ifelse(
      is.na(run_total_pct_orders)
      , zoo::na.locf(run_total_pct_orders)
      , run_total_pct_orders
    )
  ) %>%
  left_join(
    dsch_by_hr_tbl
    , by = c("process_hr" = "dsch_hr")
  ) %>%
  select(
    process_hr
    , orders_by_hr
    , total_orders
    , run_total_orders
    , pct_total_orders
    , run_total_pct_orders
    , discharges_by_hr
    , total_discharges
    , run_tot
    , pct
    , run_pct
  ) %>%
  rename(
    "run_total_discharges" = run_tot
    , "pct_total_discharges" = pct
    , "run_total_pct_discharges" = run_pct
  )

dschord_dsch_tbl %>%
  select(
    process_hr
    , run_total_pct_orders
    , run_total_pct_discharges
    , 
  ) %>%
  mutate(
    run_total_pct_orders = scales::percent(
      run_total_pct_orders
      , accuracy = 0.01
      )
    , run_total_pct_discharges = scales::percent(
      run_total_pct_discharges
      , accuracy = 0.01
    )
  ) %>%
  set_names(
    "Process Hour"
    , "Running Total % Discharge Orders"
    , "Running Total % Discharges"
  ) %>%
  kable() %>%
  kable_styling(bootstrap_options = c(
    "striped"
    , "hover"
    , "condensed"
    , "responsive"
  )
  , font_size = 12
  , full_width = F
  )

dschord_dsch_tbl %>% 
  ggplot(
    mapping = aes(
      x = process_hr
      )
    ) + 
  geom_col(
    mapping = aes(
      y = orders_by_hr
      )
    , fill = palette_light()[[1]]
    , alpha = 0.618
    ) + 
  geom_col(
    mapping = aes(
      y = discharges_by_hr
      )
    , fill = palette_light()[[2]]
    , alpha = 0.618
    ) +
  labs(
    title = "Distribution of Discharge Orders and Discharges by Process Hr"
    , subtitle = "Blue = Discharge Orders, Red = Discharges"
    , x = ""
    , y = ""
  ) +
  theme_tq() +
  scale_fill_tq()

# Forecast ----
# Forecast Arrival to...
library(timetk)
library(forecast)
model_data_grouped_tbl <- anomaly_tbl %>%
  select(
    time_segment
    , arrival
    , observed_cleaned
  ) %>% 
  mutate(process_month = as_date(as.yearmon(arrival))) %>%
  group_by(time_segment, process_month) %>%
  summarise(avg_minutes = mean(observed_cleaned, na.rm = TRUE))
model_data_grouped_tbl

model_data_grouped_nest_tbl <- model_data_grouped_tbl %>%
  group_by(time_segment) %>%
  nest()
model_data_grouped_nest_tbl

model_data_grouped_ts <- model_data_grouped_nest_tbl %>%
  mutate(
    data.ts = map(
      .x = data,
      .f = tk_ts,
      select = -process_month,
      start = 2019,
      freq = 12
    )
  )

model_data_grouped_fit <- model_data_grouped_ts %>%
  mutate(fit.ets = map(data.ts, ets))
model_data_grouped_fit

model_data_grouped_fit %>%
  mutate(tidy = map(fit.ets, sw_tidy)) %>%
  unnest(tidy) %>%
  spread(key = time_segment, value = estimate)

model_data_grouped_fit %>%
  mutate(glance = map(fit.ets, sw_glance)) %>%
  unnest(glance)

augment_fit_ets <- model_data_grouped_fit %>%
  mutate(
    augment = map(
      fit.ets
      , sw_augment
      , timetk_idx = TRUE
      , rename_index = "date"
      )
    ) %>%
  unnest(augment)
augment_fit_ets

augment_fit_ets %>%
  ggplot(
    mapping = aes(
      x = date
      , y = .resid
      , group = time_segment
    )
  ) +
  geom_hline(
    yintercept = 0
    , color = "grey40"
  ) +
  geom_line(
    color = palette_light()[[2]]
  ) +
  geom_smooth(
    method = "loess"
  ) +
  theme_tq() +
  facet_wrap(~ time_segment, scale = "free_y", ncol = 3) +
  scale_x_date(date_labels = "%B") +
  labs(
    x = ""
    , y = ""
    , title = "Average Minutes by Time Segment"
    , subtitle = "ETS Model Residuals"
  )

model_data_grouped_fit %>%
  mutate(
    decomp = map(
      fit.ets, 
      sw_tidy_decomp, 
      timetk_idk = TRUE,
      rename_index ="date"
      )
    ) %>%
  unnest(decomp)

model_fcast <- model_data_grouped_fit %>%
  mutate(fcast.ets = map(fit.ets, forecast, h = 3))
model_fcast

model_fcast_tidy <- model_fcast %>%
  mutate(
    sweep = map(
      fcast.ets,
      sw_sweep,
      fitted = FALSE,
      timetk_idx = TRUE
    )
  ) %>%
  unnest(sweep)
model_fcast_tidy  

model_fcast_tidy %>%
  ggplot(
    mapping = aes(
      x = index
      , y = avg_minutes
      , group = time_segment
    )
  ) +
  geom_ribbon(
    mapping = aes(
      ymin = lo.95
      , ymax = hi.95
    )
    , fill = "#D5DBFF"
    , color = NA
    , size = 0
  ) +
  geom_ribbon(
    mapping = aes(
      ymin = lo.80
      , ymax = hi.80
      , fill = key
    )
    , fill = "#596DD5"
    , color = NA
    , size = 0
    , alpha = 0.8
  ) +
  geom_line() +
  scale_x_date(date_breaks = "1 month", date_labels = "%B") +
  scale_color_tq() +
  scale_fill_tq() +
  facet_wrap(~ time_segment, scale = "free_y", ncol = 3) +
  theme_tq() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(
    x = ""
    , y = ""
    , title = "Average Minutes by Time Segment"
    , subtitle = "ETS Model Forecasts"
  )

# Teletracking ED ----
tele_file <- tryCatch(file.choose(new = T), error = function(e)"")
Tracking_ED_only <- read_csv(
  tele_file
  , col_types = cols(
    `Assn Time` = col_time(format = "%H:%M"),
    `Assn- Clean` = col_time(format = "%H:%M"), 
    `Assn- Occpd` = col_time(format = "%H:%M"), 
    `Assn- RTM` = col_skip(), 
    `Clean Time` = col_time(format = "%H:%M"), 
    `Clean&RTM - Occpd` = col_skip(), 
    `Clean- Occpd` = col_time(format = "%H:%M"), 
    `Creation Date` = col_date(format = "%m/%d/%Y"), 
    MRN = col_character(), 
    `Occpd Time` = col_time(format = "%H:%M"), 
    `RTM - Assn` = col_skip(), 
    `RTM Time` = col_skip(), 
    `RTM- Occpd` = col_skip(), 
    `Req - Assn` = col_time(format = "%H:%M"), 
    `Req -RTM` = col_skip(), 
    `Req. Date Time` = col_datetime(format = "%m/%d/%Y %H:%M"), 
    `Total Time` = col_time(format = "%H:%M")
    )
  ) %>%
  clean_names() %>%
  mutate(req_date = as.Date(req_date_time))
summary(Tracking_ED_only)

Tracking_ED_only %>% glimpse()

ed_tbl <- Tracking_ED_only %>% 
  select(
    -contains("RTM")
  ) %>%
  mutate(
    assn_time_int    = as.integer(assn_time) / 60
    , clean_time_int = as.integer(clean_time) / 60
    , occpd_time_int = as.integer(occpd_time) / 60
  ) %>%
  mutate(
    assn_dt = req_date_time + dminutes(assn_time_int)
    , clean_dt = req_date_time + dminutes(clean_time_int)
    , occpd_dt = req_date_time + dminutes(occpd_time_int)
  ) %>%
  mutate(
    total_time_mins = difftime(occpd_dt, req_date_time, units = "mins")
  ) %>%
  mutate(
    total_time_int = as.integer(total_time_mins)
  ) %>%
  as_tibble() %>%
  select(
    assn_bed
    , origin_bed
    , occpd_bed
    , mrn
    , creation_date
    , req_date_time
    , req_date
    , assn_dt
    , clean_dt
    , occpd_dt
    , total_time_mins
    , total_time_int
  )

ed_tbl <- ed_tbl %>%
  mutate(
    occpd_unit = case_when(
      str_sub(occpd_bed, 1, 1) == '1' ~ "1st Floor"
      , str_sub(occpd_bed, 1, 1) == '2' ~ "2nd Floor"
      , str_sub(occpd_bed, 1, 1) == '3' ~ "3rd Floor"
      , str_sub(occpd_bed, 1, 1) == '4' ~ "4th Floor"
      , str_sub(occpd_bed, 1, 1) == 'M' ~ "MICU"
      , str_sub(occpd_bed, 1, 1) == 'C' ~ "CCU"
      , TRUE ~ str_sub(occpd_bed, 1, 3)
    )
  )

# ED Track Anom ----
ed_anom_tbl <- ed_tbl %>%
  select(req_date_time, occpd_unit, total_time_int) %>%
  mutate(req_date_time = as.Date(req_date_time)) %>%
  as_tbl_time(index = req_date_time, add = TRUE) %>%
  arrange(req_date_time)

ed_long_tbl <- ed_anom_tbl %>% 
  pivot_longer(
    cols = occpd_unit
    , values_to = "occpd_unit"
  ) %>%
  mutate(req_date_time = floor_date(req_date_time, unit = "days")) %>%
  mutate(occpd_unit = occpd_unit %>% as_factor()) %>%
  as_tbl_time(index = req_date_time, add = TRUE) %>%
  collapse_by("daily") %>%
  group_by(req_date_time, occpd_unit) %>%
  select(
    req_date_time
    , total_time_int
    , occpd_unit
  ) %>%
  summarise(
    avg_time = round(mean(total_time_int, na.rm = TRUE), 2)
  ) %>%
  ungroup()

ed_long_tbl %>%
  ggplot(
    mapping = aes(
      x = req_date_time
      , y = avg_time
      , color = occpd_unit
    )
  ) +
  geom_point() +
  geom_line() +
  geom_hline(
    yintercept = mean(ed_long_tbl$avg_time, na.rm = TRUE)
    , linetype = "dashed"
  ) +
  facet_wrap(~ occpd_unit, scales = "free_y") +
  theme_tq() +
  labs(
    x = "Request Date"
    , y = "Avg Time in Minutes"
    , title = "Average Time in Minutes from Request Date Time to Occupied Unit Time"
    , subtitle = "Dashed line is Avg of Daily Time in Minutes"
  )

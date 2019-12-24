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
    , t_dta_to_adm_ord_entry_minutes = difftime(
        admit_order_entry_d_time
        , decision_to_admit
        , units = "mins"
      ) %>% as.integer()
    , t_adm_ord_to_adm_confirm_minutes = difftime(
        admit_confirm
        , admit_order_entry_d_time
        , units = "mins"
      ) %>% as.integer()
    , t_adm_confirm_to_tack_minutes = difftime(
        added_toad_missions_track
        , admit_confirm
        , units = "mins"
      ) %>% as.integer()
    , t_track_to_adm_bed_minutes = difftime(
        bed_occupied_time
        , added_toad_missions_track
        , units = "mins"
      ) %>% as.integer()
    , t_adm_bed_to_leave_ed_minutes = difftime(
        time_lefted
        , bed_occupied_time
        , units = "mins"
      ) %>% as.integer()
    , t_first_non_er_bed_minutes = difftime(
        non_er_bed_occupied_time
        , time_lefted
        , units = "mins"
      ) %>% as.integer()
    , t_arrival_to_leave_ed_minutes = difftime(
        time_lefted
        , arrival
        , units = "mins"
      ) %>% as.integer()
    , t_arr_to_first_non_er_bed_minutes = difftime(
        non_er_bed_occupied_time
        , arrival
        , unit = "mins"
      ) %>% as.integer()
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

par(mfrow = c(3,3))
for(i in 1:nrow(cols_to_anomalize)){
  c <- cols_to_anomalize[i,]$value
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
  )

# Get anomalies ----
# Explore Data first
# Create table to get anomlized data
anomalize_tbl <- df_tbl %>%
  select(
    arrival
    , starts_with("t_")
    , -contains("anomaly_")
  )

anomalize_long_tbl <- anomalize_tbl %>%
  pivot_longer(
    cols = cols_to_anomalize$value %>% as.character()
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
par(mfrow = c(3,3))
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
par(mfrow = c(3,3))
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

df_tbl %>%
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
  ) %>%
  select(
    time_segment
    , name
    , avg_time
  ) %>%
  arrange(name) %>%
  select(time_segment, avg_time)

df_tbl %>% 
  select(anomaly_t_arr_to_dta_minutes, t_arr_to_dta_minutes) %>% 
  pivot_longer(cols = anomaly_t_arr_to_dta_minutes) %>% 
  group_by(name, value) %>% 
  summarise(
    avg_time = round(mean(t_arr_to_dta_minutes, na.rm = TRUE), 2)
  ) %>% 
  ungroup() %>%
  select(name, value, avg_time)

test <- df_tbl %>% 
  select(
    starts_with("anomaly_")
    , starts_with("t_")
  ) %>% 
  pivot_longer(
    cols = anomaly_cols$value_char
  ) %>% 
  group_by(name, value) %>% 
  select(name, value, everything()) %>%
  ungroup()

test %>%
  select(-name) %>%
  pivot_longer(
    cols = cols_to_anomalize$value_char
  )
  summarise(
    avg_time = round(mean(t_arr_to_dta_minutes, na.rm = TRUE), 2)
    ) %>% 
  ungroup() %>%
  select(name, value, avg_time)

df_tbl %>%
  select(
    anomaly_cols$value_char
    , starts_with("t_")
  ) %>%
  pivot_longer(
    cols = anomaly_cols$value_char, cols_to_anomalize$value_char
    , names_to = c("time_segment","anomaly")
    , names_pattern = "(t_)(anomaly_)"
  ) %>% glimpse()
  group_by(name, value) %>%
  summarise(
    avg_time = mean(df_tbl %>% select(starts_with("t_")))
  )

# Dep Here Down ----
# Make a binwidth table for ggplots
bw_tbl <- data.frame(stringsAsFactors = FALSE)
for(i in 1:length(cols_to_anomalize)){
  c <- cols_to_anomalize[i]
  filt_col <- str_c("anomaly_", c)
  df_tmp <- df_tbl %>%
    filter(!!sym(filt_col) == "No") %>%
    select(contains(c), -contains("anomaly_")) %>%
    pull() %>%
    enframe()
  bw <- optBin(df_tmp$value)
  bw <- bw %>%
    enframe() %>%
    mutate(lag_1 = lag(value, n = 1)) %>%
    mutate(lag_1 = case_when(
      is.na(lag_1) ~ value
      , TRUE ~ lag_1
    )) %>%
    mutate(lag_1_delta = value - lag_1) %>%
    select(lag_1_delta) %>%
    tail(1) %>%
    pull() %>%
    as.data.frame()
  df_bw_tmp <- data.frame(stringsAsFactors = FALSE)
  df_bw_tmp <- data.frame(c, bw, stringsAsFactors = FALSE)
  bw_tbl <- rbind(bw_tbl, df_bw_tmp)
}
colnames(bw_tbl) <- c("time_segment", "bw_value")

anomalize_long_facet_tbl <- anomalize_long_tbl %>%
  left_join(bw_tbl, by = c("time_segment" = "time_segment"))

ggplot(
  data = anomalize_long_facet_tbl
  , mapping = aes(
      x = value
      , fill = time_segment
      , group = time_segment
    )
  ) +
  facet_wrap(~ time_segment) +
  geom_histogram(binwidth = ) +
  theme_tq()

# Facet times with ggplot
k <- anomalize_long_facet_tbl %>%
  select(value, time_segment, bw_value) %>%
  group_by(time_segment) %>%
  mutate(bin = round(mean(bw_value), 2)) %>%
  select(value, time_segment, bin) %>%
  set_names("data","group","bin")

bins <- unique(k$bin)

lp_hist <- plyr::llply(bins, function(b) {
  geom_histogram(
    data = k %>%
      filter(bin == b)
    , mapping = aes(x = data, fill=group)
    , binwidth = b
    )
  }
)

p_hist <- Reduce("+", lp_hist, init = ggplot())
p_hist + facet_wrap(. ~ group, scales = "free_y") + theme_tq()

# Bootstrap Viz ----
# Get bootstrap estimtes for more "normal" looking plots
# Anomalies left in
par(mfrow = c(3,3))
for(i in 1:length(cols_to_anomalize)){
  c <- cols_to_anomalize[i]
  title <- str_c("Bootstrp for: ", c %>% str_to_title())
  df_tmp <- df_tbl %>%
    select(contains(c), -contains("anomaly_")) %>%
    pull() %>%
    enframe()
  bw <- optBin(df_tmp$value)
  
  n = 5000
  mean_time = rep(NA, n)
  # sd_time   = rep(NA, n)
  # var_time  = rep(NA, n)
  for (i in 1:n){
    samp <- sample(
      df_tmp$value
      , 500
      , replace = TRUE
    )
    mean_time[i] <- mean(samp)
    # sd_time[i]   <- sd(samp)
    # var_time[i]  <- var(samp)
  }
  tryCatch(
    sshist(
      df_tmp$value
      , main = title
    )
    , error = function(e) hist(df_tmp$value, main = title)
  )
}
par(mfrow = c(1,1))

# Anomalies left out
par(mfrow = c(3,3))
for(i in 1:length(cols_to_anomalize)){
  c <- cols_to_anomalize[i]
  title <- str_c("Bootstrp for: ", c %>% str_to_title())
  filt_col <- str_c("anomaly_", c)
  df_tmp <- df_tbl %>%
    filter(!!sym(filt_col) == "No") %>%
    select(contains(c), -contains("anomaly_")) %>%
    pull() %>%
    enframe()
  bw <- optBin(df_tmp$value)
  
  n = 5000
  mean_time = rep(NA, n)
  # sd_time   = rep(NA, n)
  # var_time  = rep(NA, n)
  for (i in 1:n){
    samp <- sample(
      df_tmp$value
      , 500
      , replace = TRUE
    )
    mean_time[i] <- mean(samp)
    # sd_time[i]   <- sd(samp)
    # var_time[i]  <- var(samp)
  }
  tryCatch(
    sshist(
      df_tmp$value
      , main = title
    )
    , error = function(e) hist(df_tmp$value, main = title)
  )
}
par(mfrow = c(1,1))
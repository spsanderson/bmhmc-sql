# Lib Load ####
# Core Tidyverse
library(tidyverse)
library(glue)
library(forcats)
library(lubridate)

# Time Series
library(timetk)
library(tidyquant)
library(tibbletime)

# Visualization
library(cowplot)

# Preprocessing
library(recipes)

# Sampling / Accuracy
library(rsample)
library(yardstick) 

# Modeling
library(keras)

# Get file ####
file.to.choose <- file.choose(new = T)

# TA Tibble ####
df <- read.csv(file.to.choose)
df$Arrival_Date <- mdy_hm(df$Arrival_Date)

hourly.arrivals <- df %>%
  mutate(processed.hour = floor_date(Arrival_Date, "hour")) %>%
  group_by(processed.hour) %>%
  summarise(Arrival_Count = sum(Arrival_Count)) %>%
  as_tbl_time(index = processed.hour)
head(df)

# Get missing hours if they exist
min.date <- min(hourly.arrivals$processed.hour)
min.year <- year(min.date)
min.month <- month(min.date)
max.date <- max(hourly.arrivals$processed.hour)
max.year <- year(max.date)
max.month <- month(max.date)

# Make a time.frame data.frame for missing hours if they exist
time.frame <- as_datetime(c(min.date, max.date))
all.hours <- data.frame(
  processed.hour = seq(time.frame[1], time.frame[2], by = "hour")
)

# Make the full hourly.arrivals tibble
hourly.arrivals <- hourly.arrivals %>%
  right_join(all.hours, by = "processed.hour") %>%
  mutate(
    Arrival_Count = ifelse(
      test = is.na(Arrival_Count)
      , yes = 0
      , no = Arrival_Count
    )
  )
head(hourly.arrivals, 5)

# Plot Data
p1 <- hourly.arrivals %>%
  ggplot(
    aes(
      processed.hour
      , Arrival_Count
    )
  ) +
  geom_point(
    color = palette_light()[[1]]
    , alpha = 0.5
  ) +
  theme_tq() +
  labs(
    title = paste0(
      "From "
      , min.date
      , " to "
      , max.date
    )
  )
print(p1)

filter.date.value <- "2019-03-01"

p2 <- hourly.arrivals %>%
  filter_time(
    filter.date.value ~ "end"
  ) %>%
  ggplot(
    aes(
      processed.hour
      , Arrival_Count
    )
  ) +
  geom_line(
    color = palette_light()[[1]]
    , alpha = 0.5
  ) +
  geom_point(
    color = palette_light()[[1]]
  ) +
  geom_smooth(
    method = "loess"
    , span = 0.2
    , se = F
  ) +
  theme_tq() +
  labs(
    title = paste0(
      "From "
      , filter.date.value
      , " to "
      , max.date
    )
    , caption = "ED Arrivals by Hour"
  )
print(p2)

p.title <- ggdraw() +
  draw_label(
    "ED Arrivals by Hour"
    , size = 18
    , fontface = "bold"
    , colour = palette_light()[[1]]
    )
plot_grid(p.title, p1, p2, ncol = 1, rel_heights = c(0.1,1,1))

# is lstm good?
tidy.acf <- function(data, Arrival_Count, lags = 0:20){
  value.expr <- enquo(Arrival_Count)
  
  acf.values <- data %>%
    pull(Arrival_Count) %>%
    acf(lag.max = tail(lags, 1), plot = F) %>%
    .$acf %>%
    .[,,1]
  
  ret <- tibble(acf = acf.values) %>%
    rowid_to_column(var = "lag") %>%
    mutate(lag = lag - 1) %>%
    filter(lag %in% lags)
  
  return(ret)
}

max.lag <- 24 * 7

hourly.arrivals %>%
  tidy.acf(
    Arrival_Count
    , lags = 0:max.lag
  )

hourly.arrivals %>%
  tidy.acf(Arrival_Count, lags = 0:max.lag) %>%
  ggplot(aes(lag, acf)) +
  geom_segment(aes(xend = lag, yend = 0), color = palette_light()[[1]]) +
  geom_vline(xintercept = 24, size = 3, color = palette_light()[[2]])

hourly.arrivals %>%
  tidy.acf(excess.rate, lags = 12:36) %>%
  ggplot(aes(lag, acf)) +
  geom_vline(xintercept = 24, size = 3, color = palette_light()[[2]]) +
  geom_segment(aes(xend = lag, yend = 0), color = palette_light()[[1]]) +
  geom_point(color = palette_light()[[1]], size = 2) +
  geom_label(aes(label = acf %>% round(2)), vjust = -1, color = palette_light()[[1]])

optimal.lag.setting <- hourly.arrivals %>%
  tidy.acf(excess.rate, lags = 12:36) %>%
  filter(acf == max(acf)) %>%
  pull(lag)

print(optimal.lag.setting)

periods.train <- 24 * 90
periods.test <- 24 * 7
#skip.span <- 24 * 7
skip.span <- round( (nrow(hourly.arrivals) / 12), 0 )

rolling_origin_resamples <- rolling_origin(
  hourly.arrivals
  , initial = periods.train
  , assess = periods.test
  , cumulative = F
  , skip = skip.span
)
rolling_origin_resamples

# Viz Backtest Strat ####
plot.split <- function(
  split
  , expand_y_axis = T
  , alpha = 1
  , size = 1
  , base_size = 14) {
  # Manipulate Data
  train.tbl <- training(split) %>%
    add_column(key = "training")
  
  test.tbl <- testing(split) %>%
    add_column(key = "testing")
  
  data.manipulated <- bind_rows(
    train.tbl
    , test.tbl
  ) %>%
    as_tbl_time(index = processed.hour) %>%
    mutate(key = fct_relevel(key, "training", "testing"))
  
  # Collect attributes
  train.time.summary <- train.tbl %>%
    tk_index() %>%
    tk_get_timeseries_summary()
  
  test.time.summary <- test.tbl %>%
    tk_index() %>%
    tk_get_timeseries_summary()
  
  # Viz
  g <- data.manipulated %>%
    ggplot(
      aes(
        x = processed.hour
        , y = Arrival_Count
        , color = key
      )
    ) +
    geom_line(
      size = size
      , alpha = alpha
    ) +
    theme_tq(
      base_size = base_size
    ) +
    scale_color_tq() +
    labs(
      title = glue("Split: {split$id}")
      , subtitle = glue(
        "{train.time.summary$start} to {test.time.summary$end}"
        )
      , y = ""
      , x = ""
    ) +
    theme(legend.position = "none")
  
  if(expand_y_axis){
    hourly.arrivals.time.summary <- hourly.arrivals %>%
      tk_index() %>%
      tk_get_timeseries_summary()
    
    g <- g +
      scale_x_datetime(
        limits = c(
          hourly.arrivals.time.summary$start
          , hourly.arrivals.time.summary$end
        )
      )
  }
  return(g)
}

rolling_origin_resamples$splits[[1]] %>%
  plot.split(expand_y_axis = T) +
  theme(legend.position = "bottom")

# Plotting function that scales to all splits 
plot_sampling_plan <- function(
  sampling_tbl
  , expand_y_axis = TRUE
  , ncol = 3
  , alpha = 1
  , size = 1
  , base_size = 14
  , title = "Sampling Plan") {
  
  # Map plot_split() to sampling_tbl
  sampling_tbl_with_plots <- sampling_tbl %>%
    mutate(gg_plots = map(splits, plot.split, 
                          expand_y_axis = expand_y_axis,
                          alpha = alpha, base_size = base_size))
  
  # Make plots with cowplot
  plot_list <- sampling_tbl_with_plots$gg_plots 
  
  p_temp <- plot_list[[1]] + theme(legend.position = "bottom")
  legend <- get_legend(p_temp)
  
  p_body  <- plot_grid(plotlist = plot_list, ncol = ncol)
  
  p_title <- ggdraw() + 
    draw_label(title, size = 18, fontface = "bold", colour = palette_light()[[1]])
  
  g <- plot_grid(p_title, p_body, legend, ncol = 1, rel_heights = c(0.05, 1, 0.05))
  
  return(g)
  
}

rolling_origin_resamples %>%
  plot_sampling_plan(
    expand_y_axis = F
    , ncol = 3
    , alpha = 1
    , size = 1
    , base_size = 10
    , title = "Backtesting Strategy: Rolling Origin Sampling Plan"
    )

split <- rolling_origin_resamples$splits[[11]]
split_id <- rolling_origin_resamples$id[[11]]

plot.split(split, expand_y_axis = F, size = 0.5) +
  theme(legend.position = "bottom") +
  ggtitle(glue("Split: {split_id}"))

df_trn <- training(split)
df_tst <- testing(split)

df.su <- bind_rows(
  df_trn %>% add_column(key = "training")
  , df_tst %>% add_column(key = "testing")
) %>%
  as_tbl_time(index = processed.hour)

rec_obj <- recipe(
  Arrival_Count ~ ., df.su
) %>%
  step_sqrt(Arrival_Count) %>%
  step_center(Arrival_Count) %>%
  step_scale(Arrival_Count) %>%
  prep()

df_processed_tbl <- bake(rec_obj, df.su)
head(df_processed_tbl)

center_history <- rec_obj$steps[[2]]$means
scale_history <- rec_obj$steps[[3]]$sds
c("center"=center_history, "scale"=scale_history)

# LSTM Model ####
# Model Inputs
lag.setting <- nrow(df_tst)
batch.size <- 12
train.length <- nrow(df_trn)
tsteps <- 1
epochs <- 300

# Training Set
lag.train.tbl <- df_processed_tbl %>%
  mutate(value_lag = lag(Arrival_Count, n = lag.setting)) %>%
  filter(!is.na(value_lag)) %>%
  filter(key == "training") %>%
  tail(train.length)

x.train.vec <- lag.train.tbl$value_lag
x.train.arr <- array(data = x.train.vec, dim = c(length(x.train.vec), 1, 1))

y.train.vec <- lag.train.tbl$value_lag
y.train.arr <- array(data = y.train.vec, dim = c(length(y.train.vec), 1))

# Testing Set
lag.test.tbl <- df_processed_tbl %>%
  mutate(value_lag = Arrival_Count, n = lag.setting) %>%
  filter(!is.na(value_lag)) %>%
  filter(key == "testing")

x.test.vec <- lag.test.tbl$value_lag
x.test.arr <- array(data = x.test.vec, dim = c(length(x.test.vec), 1, 1))

y.test.vec <- lag.test.tbl$value_lag
y.test.arr <- array(data = y.test.vec, dim = c(length(y.test.vec), 1))

model <- keras::keras_model_sequential()

model %>%
  layer_lstm(
    units = 50
    , input_shape = c(tsteps, 1)
    , batch_size =batch.size
    , return_sequences = TRUE
    , stateful = TRUE
  ) %>%
  layer_lstm(
    units = 50
    , return_sequences = FALSE
    , stateful = TRUE
  ) %>%
  layer_dense(
    units = 1
  )

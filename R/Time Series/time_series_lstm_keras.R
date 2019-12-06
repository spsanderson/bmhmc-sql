# Lib Load ####
install.load::install_load(
  # Core Tidyverse
  "tidyverse"
  , "glue"
  , "forcats"
  , "lubridate"

  # Time Series
  , "timetk"
  , "tidyquant"
  , "tibbletime"
  
  # Visualization
  , "cowplot"
  
  # Preprocessing
  , "recipes"
  
  # Sampling / Accuracy
  , "rsample"
  , "yardstick"
  
  # Modeling
  , "keras"
)

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

filter.date.value <- "2019-10-01"

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
plot_split <- function(
  split
  , expand_y_axis = T
  , alpha = 1
  , size = 1
  , base_size = 14) {
  
  # Manipulate Data
  train_tbl <- training(split) %>%
    add_column(key = "training")
  
  test_tbl <- testing(split) %>%
    add_column(key = "testing")
  
  data_manipulated <- bind_rows(
    train_tbl
    , test_tbl
  ) %>%
    as_tbl_time(index = processed.hour) %>%
    mutate(key = fct_relevel(key, "training", "testing"))
  
  # Collect attributes
  train_time_summary <- train_tbl %>%
    tk_index() %>%
    tk_get_timeseries_summary()
  
  test_time_summary <- test_tbl %>%
    tk_index() %>%
    tk_get_timeseries_summary()
  
  # Viz
  g <- data_manipulated %>%
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
        "{train_time_summary$start} to {test_time_summary$end}"
        )
      , y = ""
      , x = ""
    ) +
    theme(legend.position = "none")
  
  if(expand_y_axis){
    hourly_arrivals_time_summary <- hourly.arrivals %>%
      tk_index() %>%
      tk_get_timeseries_summary()
    
    g <- g +
      scale_x_datetime(
        limits = c(
          hourly_arrivals_time_summary$start
          , hourly_arrivals_time_summary$end
        )
      )
  }
  return(g)
}

rolling_origin_resamples$splits[[1]] %>%
  plot_split(expand_y_axis = T) +
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
    mutate(
      gg_plots = map(
        splits
        , plot_split
        , expand_y_axis = expand_y_axis
        , alpha = alpha
        , base_size = base_size
        )
      )
  
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

plot_split(split, expand_y_axis = F, size = 0.5) +
  theme(legend.position = "bottom") +
  ggtitle(glue("Split: {split_id}"))

df_trn <- training(split)
df_tst <- testing(split)

df <- bind_rows(
  df_trn %>% add_column(key = "training")
  , df_tst %>% add_column(key = "testing")
) %>%
  as_tbl_time(index = processed.hour)
df

rec_obj <- recipe(
  Arrival_Count ~ ., df
  ) %>%
  step_sqrt(Arrival_Count) %>%
  step_center(Arrival_Count) %>%
  step_scale(Arrival_Count) %>%
  prep()

df_processed_tbl <- bake(rec_obj, df)
head(df_processed_tbl)

center_history <- rec_obj$steps[[2]]$means
scale_history <- rec_obj$steps[[3]]$sds
c("center" = center_history, "scale" = scale_history)

# LSTM Plan ####
# Model Inputs
lag_setting <- nrow(df_tst)
batch_size <- 12
train_length <- nrow(df_trn)
tsteps <- 1
epochs <- 300

# Train Test Arrays 2d and 3d
# Training Set
lag_train_tbl <- df_processed_tbl %>%
  mutate(value_lag = lag(Arrival_Count, n = lag_setting)) %>%
  filter(!is.na(value_lag)) %>%
  filter(key == "training") %>%
  tail(train_length)

x_train_vec <- lag_train_tbl$value_lag
x_train_arr <- array(data = x_train_vec, dim = c(length(x_train_vec), 1, 1))

y_train_vec <- lag_train_tbl$value_lag
y_train_arr <- array(data = y_train_vec, dim = c(length(y_train_vec), 1))

# Testing Set
lag_test_tbl <- df_processed_tbl %>%
  mutate(value_lag = Arrival_Count, n = lag_setting) %>%
  filter(!is.na(value_lag)) %>%
  filter(key == "testing")

x_test_vec <- lag_test_tbl$value_lag
x_test_arr <- array(data = x_test_vec, dim = c(length(x_test_vec), 1, 1))

y_test_vec <- lag_test_tbl$value_lag
y_test_arr <- array(data = y_test_vec, dim = c(length(y_test_vec), 1))

model <- keras::keras_model_sequential()

# Build the model
model %>%
  layer_lstm(
    units = 50
    , input_shape = c(tsteps, 1)
    , batch_size =batch_size
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

model %>%
  compile(
    loss = 'mae'
    , optimizer = 'adam'
  )

model

# Fit the model
for(i in 1:epochs){
  model %>% fit(
    x = x_train_arr
    , y = y_train_arr
    , batch_size = batch_size
    , epochs = 1
    , verbose = 1
    , shuffle = F
  )
  model %>% reset_states()
  cat("Epoch: ", i)
}

# Make predictions ####
pred_out <- model %>%
  predict(
    x_test_arr
    , batch_size = batch_size
  ) %>%
  .[, 1]

pred_tbl <- tibble(
  processed.hour = lag_test_tbl$processed.hour
  , Arrival_Count = (
    pred_out * scale_history + center_history
    )^2
)

# combine actual data with predictions
tbl_1 <- df_trn %>%
  add_column(key = "actual")

tbl_2 <- df_tst %>%
  add_column(key = "actual")

tbl_3 <- pred_tbl %>%
  add_column(key = "predict")

# create time_bind_rows() to solve dplyr issue
time_bind_rows <- function(data_1, data_2, index){
  index_expr <- enquo(index)
  bind_rows(data_1, data_2) %>%
    as_tbl_time(index = !! index_expr)
}

ret <- list(tbl_1, tbl_2, tbl_3) %>%
  reduce(time_bind_rows, index = processed.hour) %>%
  arrange(key, processed.hour) %>%
  mutate(key = as_factor(key))

ret

calc_rmse <- function(prediction_tbl) {
  
  rmse_calculation <- function(data) {
  result <- data %>%
    spread(key = key, value = Arrival_Count) %>%
    select(-processed.hour) %>%
    filter(!is.na(predict)) %>%
    rename(
      truth    = actual,
      estimate = predict
    ) %>%
    rmse(truth, estimate)
  
  result <- result$.estimate
  return(result)
  }
  
  safe_rmse <- possibly(rmse_calculation, otherwise = NA)
  
  safe_rmse(prediction_tbl)
  
}
calc_rmse(ret)

# view RMSE ####
plot_prediction <- function(data, id, alpha = 1, size = 2, base_size = 14){
  
  rmse_val <- calc_rmse(data)
  
  g <- data %>%
    ggplot(
      aes(
        x = processed.hour
        , y = Arrival_Count
        , color = key
        )
      ) +
    geom_point(
      alpha = alpha
      , size = size
      , position = position_jitterdodge()
      ) +
    theme_tq() +
    scale_color_tq() +
    theme(legend.position = "none") +
    labs(
      title = glue("{id}, RMSE: {round(rmse_val, digits = 4)}")
      , x = ""
      , y = ""
    )
  
  return(g)
}

ret %>%
  plot_prediction(id = split_id, alpha = 0.65) +
  theme(legend.position = "bottom")

# Create LSTM prediction function
predict_keras_lstm <- function(split, epochs = 300, ...){
  
  lstm_prediction <- function(split, epochs, ...){
    
    # Data setup
    df_trn <- training(split)
    df_tst <- testing(split)
    
    df <- bind_rows(
      df_trn %>% add_column(key = "training")
      , df_tst %>% add_column(key = "testing")
    ) %>%
      as_tbl_time(index = processed.hour)
    
    # Preprocessing
    rec_obj <- recipe(
      Arrival_Count ~ ., df
    ) %>%
      step_sqrt(Arrival_Count) %>%
      step_center(Arrival_Count) %>%
      step_scale(Arrival_Count) %>%
      prep()
    
    df_processed_tbl <- bake(rec_obj, df)
    
    center_history <- rec_obj$steps[[2]]$means["Arrival_Count"]
    scale_history <- rec_obj$steps[[3]]$sds["Arrival_Count"]
    
    # LSTM Plan
    lag_setting <- nrow(df_tst)
    batch_size <- 12
    train_length <- nrow(df_trn)
    tsteps <- 1
    epochs <- epochs
    
    # Train / Test setup
    lag_train_tbl <- df_processed_tbl %>%
      mutate(value_lag = lag(Arrival_Count, n = lag_setting)) %>%
      filter(!is.na(value_lag)) %>%
      filter(key == "training") %>%
      tail(train_length)
    
    x_train_vec <- lag_train_tbl$value_lag
    x_train_arr <- array(data = x_train_vec, dim = c(length(x_train_vec), 1, 1))
    
    y_train_vec <- lag_train_tbl$value_lag
    y_train_arr <- array(data = y_train_vec, dim = c(length(y_train_vec), 1))
    
    # Testing Set
    lag_test_tbl <- df_processed_tbl %>%
      mutate(value_lag = Arrival_Count, n = lag_setting) %>%
      filter(!is.na(value_lag)) %>%
      filter(key == "testing")
    
    x_test_vec <- lag_test_tbl$value_lag
    x_test_arr <- array(data = x_test_vec, dim = c(length(x_test_vec), 1, 1))
    
    y_test_vec <- lag_test_tbl$value_lag
    y_test_arr <- array(data = y_test_vec, dim = c(length(y_test_vec), 1))
    
    # LSTM Model
    model <- keras::keras_model_sequential()
    
    # Build model
    model %>%
      layer_lstm(
        units = 50
        , input_shape = c(tsteps, 1)
        , batch_size =batch_size
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
    
    model %>%
      compile(
        loss = 'mae'
        , optimizer = 'adam'
      )
    
    # Fit the model
    for(i in 1:epochs){
      model %>% fit(
        x = x_train_arr
        , y = y_train_arr
        , batch_size = batch_size
        , epochs = 1
        , verbose = 1
        , shuffle = F
      )
      model %>% reset_states()
      cat("Epoch: ", i)
    }
  
  # Predict and Return Tidy Data
  # Make Predictions
    pred_out <- model %>%
      predict(
        x_test_arr
        , batch_size = batch_size
      ) %>%
      .[, 1]
  
  # Retransform values
    pred_tbl <- tibble(
      processed.hour = lag_test_tbl$processed.hour
      , Arrival_Count = (
        pred_out * scale_history + center_history
      )^2
    )
  
  # Combine actual data with predictions
    tbl_1 <- df_trn %>%
      add_column(key = "actual")
    
    tbl_2 <- df_tst %>%
      add_column(key = "actual")
    
    tbl_3 <- pred_tbl %>%
      add_column(key = "predict")
  
  # Create time_bind_rows() to solve dplyr issue
    time_bind_rows <- function(data_1, data_2, index){
      index_expr <- enquo(index)
      bind_rows(data_1, data_2) %>%
        as_tbl_time(index = !! index_expr)
    }
    
    ret <- list(tbl_1, tbl_2, tbl_3) %>%
      reduce(time_bind_rows, index = processed.hour) %>%
      arrange(key, processed.hour) %>%
      mutate(key = as_factor(key))
    
    return(ret)
    
  }
  safe_lstm <- possibly(lstm_prediction, otherwise = NA)

  safe_lstm(split, epochs, ...)
}

predict_keras_lstm(split, epochs = 10)

sample_predictions_lstm_tbl <- rolling_origin_resamples %>%
  mutate(
    predict = map(
      splits
      , predict_keras_lstm
      , epochs = 300
    )
  )

# Assess backtest performance
sample_rmse_tbl <- sample_predictions_lstm_tbl %>%
  mutate(
    rmse = map_dbl(
      predict
      , calc_rmse
    )
  ) %>%
  select(id, rmse)

sample_rmse_tbl

sample_rmse_tbl %>%
  ggplot(
    aes(
      rmse
    )
  ) +
  geom_histogram(
    aes(
      y = ..density..
    )
    , fill = palette_light()[[1]]
    , bins = 16
  ) +
  geom_density(
    fill = palette_light()[[1]]
    , alpha = 0.5
  ) +
  theme_tq() +
  labs(
    title = "Histogram of RMSE"
  )

sample_rmse_tbl %>%
  summarize(
    mean_rmse = mean(rmse)
    , sd_rmse = sd(rmse)
  )

# Viz Backtest Results ####
plot_predictions <- function(
  sampling_tbl
  , predictions_col
  , ncol = 3
  , alpha = 1
  , size = 2
  , base_size = 14
  , title = "Backtested Predictions") {
  
  predictions_col_expr <- enquo(predictions_col)
  
  # Map plot_split() to sampling_tbl
  sampling_tbl_with_plots <- sampling_tbl %>%
    mutate(
      gg_plots = map2(
        !! predictions_col_expr
        , id
        , .f = plot_prediction
        , alpha     = alpha
        , size      = size
        , base_size = base_size
        )
      ) 
  
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

sample_predictions_lstm_tbl %>%
  plot_predictions(
    predictions_col = predict
    , alpha = 0.5
    , size = 1
    , base_size = 10
    , title = "Keras Stateful LSTM: Backtested Predictions"
  )

# Predict future ####
# next 7 days or lag_setting = 168 = 7 days * 24 hours
predict_keras_lstm_future <- function(data, epochs = 300, ...){
  
  lstm_prediction <- function(data, epochs, ...){
    
    # Data set up slightly modified
    df <- data
    
    # Preporocess
    rec_obj <- recipe(Arrival_Count ~ ., df) %>%
      step_sqrt(Arrival_Count) %>%
      step_center(Arrival_Count) %>%
      step_scale(Arrival_Count) %>%
      prep()
    
    df_processed_tbl <- bake(rec_obj, df)
    
    center_history <- rec_obj$steps[[2]]$means#["Arrival_Count"]
    scale_history <- rec_obj$steps[[3]]$sds#["Arrival_Count"]
    
    # LSTM Plan
    lag_setting <- 7 * 24 # 7days * 24hours / day
    batch_size <- 12
    train_length <- 90 * 24 # 90 days * 24hours / day
    tsteps <- 1
    epochs <- epochs
    
    # Train Setup
    lag_train_tbl <- df_processed_tbl %>%
      mutate(value_lag = lag(Arrival_Count, n = lag_setting)) %>%
      filter(!is.na(value_lag)) %>%
      tail(train_length)
    
    x_train_vec <- lag_train_tbl$value_lag
    x_train_arr <- array(data = x_train_vec, dim = c(length(x_train_vec), 1, 1))
    
    y_train_vec <- lag_train_tbl$Arrival_Count
    y_train_arr <- array(data = y_train_vec, dim = c(length(y_train_vec), 1))
    
    x_test_vec <- y_train_vec %>% tail(lag_setting)
    x_test_arr <- array(data = x_test_vec, dim = c(length(x_test_vec), 1, 1))
    
    # LSTM Model
    model <- keras::keras_model_sequential()
    
    model %>%
      layer_lstm(
        units = 64
        , input_shape = c(tsteps, 1)
        , batch_size = batch_size
        , return_sequences = T
        , stateful = T
      ) %>%
      layer_lstm(
        units = 64
        , return_sequences = F
        , stateful = T
      ) %>%
      layer_dense(units = 1)
    
    model %>%
      compile(
        loss = 'mae'
        , optimizer = 'adam'
        #, optimizer = optimizer_rmsprop()
        , metrics = c('accuracy')
        )
    
    # Fit LSTM
    for(i in 1:epochs){
      model %>%
        fit(
          x = x_train_arr
          , y = y_train_arr
          , batch_size = batch_size
          , epochs = 1
          , verbose = 1
          , shuffle = F
        )
      
      model %>% reset_states()
      print(paste("Epoch: ", i))
    }
    
    # Predict and return tidy data
    # Make predictions
    pred_out <- model %>%
      predict(
        x_test_arr
        , batch_size = batch_size
      ) %>%
      .[,1]
    
    # Make Future index using tk_make_futre_timeseries()
    idx <- data %>%
      tk_index() %>%
      tk_make_future_timeseries(n_future = lag_setting)
    
    # Retransform values
    pred_tbl <- tibble(
      processed.hour = idx
      , Arrival_Count = round(
        (pred_out * scale_history + center_history)^2, 0
      )
    )
    
    # Combine actual data with predictions
    tbl_1 <- df %>%
      add_column(key = "actual")
    
    tbl_3 <- pred_tbl %>%
      add_column(key = "predict")
    
    # Create time_bind_rows() to solve dplyr issue
    # time_bind_rows <- function(data_1, data_2, index){
    #   index_expr <- enquo(index)
    #   bind_rows(data_1, data_2) %>%
    #     as_tbl_time(index = !! index_expr)
    # }
    # 
    # ret <- list(tbl_1, tbl_3) %>%
    #   reduce(time_bind_rows, index = processed.hour) %>%
    #   arrange(key = processed.hour) %>%
    #   mutate(key = as_factor(key))
    ret <- bind_rows(tbl_1, tbl_3) %>%
      as_tbl_time(index = processed.hour) %>%
      arrange(key = processed.hour) %>%
      mutate(key = as_factor(key))
    
    return(ret)
  }
  
  safe_lstm <- possibly(lstm_prediction, otherwise = NA)
  
  safe_lstm(data, epochs, ...)
}

future_ed_arrivals_tbl <- predict_keras_lstm_future(
  hourly.arrivals, epochs = 500
)

tail(future_ed_arrivals_tbl, 5)

future_ed_arrivals_tbl %>%
  filter_time("2019-11-10" ~ "2019-11-17") %>%
  plot_prediction(id = NULL, alpha = 0.4, size = 1.5) +
  geom_line(size = 1, alpha = 0.618) +
  theme(legend.position = "bottom") +
  labs(
    title = "ED Arrivals Weekend Forecast"
    , subtitle = "Model - Keras Stateful LSTM"
  )

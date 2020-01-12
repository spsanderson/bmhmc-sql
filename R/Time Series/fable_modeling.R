# Lib Load ####
install.load::install_load(
  "tidyquant"
  , "fable"
  , "fabletools"
  , "feasts"
  , "tsibble"
  , "timetk"
  , "sweep"
  , "anomalize"
  , "xts"
  # , "fpp"
  # , "forecast"
  , "lubridate"
  , "dplyr"
  , "urca"
  # , "prophet"
  , "ggplot2"
  , "tidyverse"
)

# Get File ####
fileToLoad <- file.choose(new = TRUE)
arrivals <- read.csv(fileToLoad)

arrivals$Time <- mdy(arrivals$Time)

# Coerce to tsibble ----
df_tsbl <- arrivals %>%
  as_tsibble(index = Time)

df_tsbl
interval(df_tsbl)
count_gaps(df_tsbl)

# Make Monthly ----
df_monthly_tsbl <- df_tsbl %>%
  index_by(Year_Month = ~ yearmonth(.)) %>%
  summarise(Count = sum(DSCH_COUNT, na.rm = TRUE))

df_monthly_tsbl           

min.date  <- min(df_monthly_tsbl$Year_Month)
min.year  <- year(min.date)
min.month <- month(min.date)
max.date  <- max(df_monthly_tsbl$Year_Month)
max.year  <- year(max.date)
max.month <- month(max.date)

# Plot Initial Data
df_monthly_tsbl %>%
  ggplot(
    mapping = aes(
      x = Year_Month
      , y = Count
    )
  )  +
  geom_point(
    alpha = 0.5
    , color = palette_light()[[1]]
  ) +
  geom_line(
    alpha = 0.5
  ) +
  geom_smooth(
    se = F
    , method = 'loess'
    , color = 'red'
    , span = 1/12
  ) +
  labs(
    title = "ED Discharges: Monthly Scale"
    , subtitle = "Source: DSS"
    , caption = paste0(
      "Based on discharges from: "
      , min.date
      , " through "
      , max.date
    )
    , y = "Count"
    , x = ""
  ) +
  theme_tq()

# Anomalize ----
# anomalize does not yet work on tsibble convert to tibble
# make a simple IQR outlier function to use
detect_outliers <- function(x) {

  # Body ----
  if(missing(x)) stop("No data supplied, x needs a vector of values", call. = FALSE)
  if(!is.numeric(x)) stop("x must be numeric", call. = FALSE)
  
  data_tbl <- tibble(data = x)
  
  limits_tbl <- data_tbl %>%
    summarise(
      q_low = quantile(data, probs = 0.25, na.rm = TRUE)
      , q_high = quantile(data, probs = 0.75, na.rm = TRUE)
      , iqr = IQR(data, na.rm = TRUE)
      , ll = q_low - 1.5  * iqr
      , ul = q_high + 1.5 * iqr
    )
  
  output_tbl <- data_tbl %>%
    mutate(
      outlier = case_when(
        data < limits_tbl$ll ~ TRUE
        , data > limits_tbl$ul ~ TRUE
        , TRUE ~ FALSE
      )
    )
  
  return(output_tbl$outlier)
    
}

df_monthly_tsbl <- df_monthly_tsbl %>%
  mutate(outlier = detect_outliers(Count))
table(df_monthly_tsbl$outlier)

# df_monthly_tsbl %>%
#   time_decompose(Count, method = "twitter") %>%
#   anomalize(remainder, method = "gesd") %>%
#   clean_anomalies() %>%
#   time_recompose()

# Visualize ----
df_monthly_tsbl %>% gg_tsdisplay(y = Count)

df_monthly_tsbl %>% 
  STL(Count ~ season(window = Inf)) %>% 
  autoplot()

df_monthly_tsbl %>%
  gg_subseries(y = Count)

df_monthly_tsbl %>%
  features(Count, feat_stl) %>%
  pivot_longer(cols = everything(), names_to = "Metric")

# Model ----
models <- df_monthly_tsbl %>%
  model(
    ets          = ETS(Count)
    , ets_boxcox = ETS(box_cox(Count, 0.3))
    , arima      = ARIMA(Count)
    , arima_log  = ARIMA(log(Count))
    , snaive     = SNAIVE(Count)
    , nnetar     = NNETAR(Count, n_nodes = 10)
    , var        = VAR(Count)
  )
models_acc <- accuracy(models) %>% arrange(MAE)
models_tidy <- augment(models) %>%
  mutate(key = "actual") %>%
  set_names(
    "Model"
    ,"Year_Month"
    ,"Count"
    ,"Fitted"
    ,"Residuals"
    , "key"
    ) %>%
  as_tibble()
models_fcast <- models %>% 
  forecast(h = "12 months") %>%
  as_tibble() %>%
  select(.model, Year_Month, Count) %>%
  mutate(key = "forecast") %>%
  set_names("Model", "Year_Month","Count", "key")

# df_monthly_tsbl %>%
models_tidy %>%
  filter(year(Year_Month) > 2016) %>%
  ggplot(
    mapping = aes(
      x = Year_Month
      , y = Count
      , group = Model
    )
  ) +
  geom_point(    
    alpha = 0.5
    , color = palette_light()[[1]]
  ) +
  geom_line(
    alpha = 0.5
    , size = 1
  ) +
  geom_point(
    data = models_fcast
    , mapping = aes(
      x = Year_Month
      , y = Count
      , group = Model
      , color = Model
    )
  ) +
  geom_line(
    data = models_fcast
    , mapping = aes(
      x = Year_Month
      , y = Count
      , group = Model
      , color = Model
    )
    , size = 1
  ) +
  theme_tq() +
  scale_color_tq() +
  labs(
    title = "IP Discharges: Monthly Scale"
    , subtitle = "Source: DSS - 12 Month Forecast"
    , caption = paste0(
      "Based on discharges from: "
      , min.date
      , " through "
      , max.date
    )
    , y = "Count"
    , x = ""
  )

df_monthly_tsbl %>%
  model(
    ets = ETS(box_cox(Count, 0.3))
    , arima = ARIMA(log(Count))
    , snaive = SNAIVE(Count)
    , nnetar = NNETAR(Count, n_nodes = 10)
  ) %>%
  forecast(h = "12 months") %>%
  autoplot(
    filter(
      df_monthly_tsbl
      , year(Year_Month) > 2016)
    , level = NULL
    , size = 1
    ) +
  geom_point(    
    alpha = 0.5
    , color = palette_light()[[1]]
  ) +
  geom_line(
    alpha = 0.5
    , size = 1
  ) +
  theme_tq() +
  labs(
    title = "IP Discharges: Monthly Scale"
    , subtitle = "Source: DSS - 12 Month Forecast"
    , caption = paste0(
      "Based on discharges from: "
      , min.date
      , " through "
      , max.date
    )
    , y = "Count"
    , x = ""
  )

# Lib Load ####
# Time Series analysis on Daily Discharge Data - Inpatients
install.load::install_load(
  "tidyquant"
  , "broom"
  , "timetk"
  , "sweep"
  , "tibbletime"
  , "anomalize"
  , "xts"
  , "fpp"
  , "forecast"
  , "lubridate"
  , "dplyr"
  , "urca"
  , "prophet"
)

# Get File ####
fileToLoad <- file.choose(new = TRUE)
arrivals <- read.csv(fileToLoad)
rm(fileToLoad)

# Time Aware Tibble ####
# Format Arrival_Date and make time aware tibble
arrivals$Arrival_Date <- lubridate::mdy_hm(arrivals$Arrival_Date)
hourly.orders <- arrivals %>%
  mutate(processed_hour = floor_date(Arrival_Date, "hour")) %>%
  group_by(processed_hour) %>%
  summarise(Arrival_Count = sum(Arrival_Count))
head(hourly.orders, 5)

ta.arrivals <- as_tbl_time(hourly.orders, index = processed_hour)
head(ta.arrivals)

min.date  <- min(ta.arrivals$processed_hour)
min.year  <- year(min.date)
min.month <- month(min.date)
max.date  <- max(ta.arrivals$processed_hour)
max.year  <- year(max.date)
max.month <- month(max.date)

# Make a time.frame data.frame for missing hours if exists
time.frame <- as_datetime(c(min.date, max.date))
all.hours <- data.frame(
  processed_hour = seq(time.frame[1], time.frame[2], by = "hour")
)

hourly.orders <- hourly.orders %>%
  right_join(all.hours, by = "processed_hour") %>%
  mutate(
    Arrival_Count = ifelse(
      test = is.na(Arrival_Count)
      , yes = 0
      , no = Arrival_Count
    )
  )
head(hourly.orders, 5)

colnames(hourly.orders) <- c("ds","y")
head(hourly.orders, 5)

# FB Prophet Model ####
# may have trouble getting forecast model due to vector create size
# shrink data down
# hourly.orders <- hourly.arrivals %>% 
#   filter(ds >= '2018-01-01')

m <- prophet(hourly.orders)

future <- make_future_dataframe(
  m
  , periods = 96
  , freq = 3600
  )
tail(future, 96)

m.forecast <- predict(m, future)
tail(m.forecast[c('ds','yhat','yhat_lower','yhat_upper')], 96)

m.forecast.cut <- tail(
  m.forecast[c('ds','yhat','yhat_lower','yhat_upper')]
  , 48
  )
plt.date <- min(m.forecast.cut$ds)

ggplot(
  data = m.forecast.cut
  , aes(
    x = ds
    , y = yhat
    , size = yhat
    )
  ) +
  geom_ribbon(
    aes(
      ymin = yhat_lower
      , ymax = yhat_upper
    )
    , fill = "#D5DBFF"
    , color = NA
    , size = 0
    , alpha = 0.618
  ) +
  geom_point(
    alpha = 0.5
    , color = "red"
    , fill = "red"
  ) +
  geom_line(
     size = 1
     , alpha = 0.8
  ) +
  labs( 
    title = paste0(
      "Arrivals by Hour to ED: 48 Hours Prediction starting on "
      , plt.date
      ) 
    , subtitle = "Source: DSS - Model fbProphet" 
    , y = "Arrivals by Hour" 
    , x = "Hour of Arrival" 
    , size = "Predicted Arrivals"
    ) + 
  scale_fill_tq() +
  scale_color_tq() + 
  theme_tq() 

prophet_plot_components(m, m.forecast)

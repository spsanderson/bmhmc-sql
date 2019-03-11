# Lib Load ####
# Time Series analysis on Daily Discharge Data - Inpatients
library(tidyquant)
library(broom)
library(timetk)
library(sweep)
library(tibbletime)
library(anomalize)
library(xts)
library(fpp)
library(forecast)
library(lubridate)
library(dplyr)
library(urca)
library(prophet)

# Get File ####
fileToLoad <- file.choose(new = TRUE)
discharges <- read.csv(fileToLoad)
rm(fileToLoad)

# Time Aware Tibble ####
# Format Arrival_Date and make time aware tibble
discharges$Arrival_Date <- lubridate::mdy_hm(discharges$Arrival_Date)
hourly.orders <- discharges %>%
  mutate(processed_hour = floor_date(Arrival_Date, "hour")) %>%
  group_by(processed_hour) %>%
  summarise(Arrival_Count = sum(Arrival_Count))
head(hourly.orders, 5)

ta.discharges <- as_tbl_time(hourly.orders, index = processed_hour)
head(ta.discharges)

min.date  <- min(ta.discharges$processed_hour)
min.year  <- year(min.date)
min.month <- month(min.date)
max.date  <- max(ta.discharges$processed_hour)
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

# Plot Initial Data ####
hourly.orders %>%
  filter(ds >= "2019-02-24") %>%
  ggplot(
    aes(
      x = ds
      , y = y
    )
  ) +
  geom_point(
    alpha = 0.5
    , color = palette_light()[[1]]
  ) +
  geom_line(
    alpha = 0.5
  ) +
  geom_smooth(
    se = F
    , method = 'auto'
    , color = 'red'
  )

# FBProphet Model ####
m <- prophet(hourly.orders)

future <- make_future_dataframe(m, periods = 24, freq = 3600)
tail(future)

forecast <- predict(m, future)
tail(forecast[c('ds', 'yhat', 'yhat_lower', 'yhat_upper')],24)
forecast.cut <- tail(forecast[c('ds', 'yhat', 'yhat_lower', 'yhat_upper')],24)
# forecast.cut <- forecast %>%
#   filter(ds >= '2019-03-01') %>%
#   select(ds, yhat, yhat_lower, yhat_upper)

# plot(m, forecast)
plot(forecast.cut$yhat)
plt.date <- min(forecast.cut$ds)

ggplot(
  data = forecast.cut
  , aes(
    x = ds
   , y = yhat
  )
) +
  geom_point(
    alpha = 0.5
    , color = palette_light()[[1]]
) +
  geom_line(
    alpha = 0.5
) +
  labs(
    title = paste0("Arrivals by Hour to ED: 24 Hours Prediction for ", plt.date)
    , subtitle = "Source: DSS"
    , y = "Arrivals by Hour"
    , x = "Hour of Arrival"
  ) +
  scale_color_tq() +
  theme_tq()

prophet_plot_components(m, forecast)

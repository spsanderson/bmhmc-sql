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

# Plot Initial Data ####
hourly.orders %>%
  ggplot(
    aes(
      x = processed_hour
      , y = Arrival_Count
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

# Make XTS object ####
hourly.ts <- ts(
  hourly.orders$Arrival_Count
  , frequency = 24*365
  , start = c(min.year, min.month)
  , end = c(max.year, max.month)
)
plot.ts(hourly.ts)
class(hourly.ts)
head(hourly.ts)
hourly.xts <- window(
  hourly.ts
  , start = c(min.year, min.month)
  , end = c(max.year, max.month)
)
hourly.xts

# TS Componenets ####
hourly.componenets <- decompose(hourly.xts)
names(hourly.componenets)
hourly.componenets$seasonal
plot(hourly.componenets)

# Get STL object ####
hourly.compl <- stl(hourly.xts, s.window = "periodic")
plot(hourly.compl)

# HW Model ####
hour.fit.hw <- HoltWinters(hourly.xts)
hour.fit.hw
hour.hw.est.params <- sw_tidy(hour.fit.hw)
plot(hour.fit.hw)
plot.ts(hour.fit.hw$fitted)

# Forecast HW ####
hour.hw.fcast <- hw(
  hourly.xts
  , h = 1
  # , alpha = hour.fit.hw$alpha
  # , gamma = hour.fit.hw$gamma
  # , beta = hour.fit.hw$beta
)
summary(hour.hw.fcast)

# HW Errors
hour.hw.perf <- sw_glance(hour.fit.hw)
mape.hw <- hour.hw.perf$MAPE
model.desc.hw <- hour.hw.perf$model.desc

# Hour HW Predictions
hour.hw.pred <- sw_sweep(hour.hw.fcast) %>%
  filter(sw_sweep(hour.hw.fcast)$key == 'forecast')
print(hour.hw.pred)
hw.pred <- head(hour.hw.pred$value, 1)

# Vis HW predict ####
hour.hw.fcast.plt <- sw_sweep(hour.hw.fcast) %>%
  ggplot(
    aes(
      x = index
      , y = value
      , color = key
    )
  ) +
  geom_ribbon(
    aes(
      ymin = lo.95
      , ymax = hi.95
    )
    , fill = "#D5DBFF"
    , color = NA
    , size = 0
  ) +
  geom_ribbon(
    aes(
      ymin = lo.80
      , ymax = hi.80
      , fill = key
    )
    , fill = "#596DD5"
    , color = NA
    , size = 0
    , alpha = 0.8
  ) +
  geom_line(
    size = 1
  ) +
  labs(
    title = "Forecast for ED Arrivals: 24-Hour Forecast"
    , x = ""
    , y = ""
    , subtitle = paste0(
      "Model Desc - "
      , model.desc.hw
      , " - MAPE = "
      , round(mape.hw, 2)
      , " - Forecast = "
      , round(hw.pred, 0)
    )
  ) +
  scale_x_yearmon(n = 12, format = "%Y") +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq()
print(hour.hw.fcast.plt)

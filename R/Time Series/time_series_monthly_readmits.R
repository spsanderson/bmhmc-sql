# Readmit TS Analysis
# Lib Load ####
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

# Get File ####
fileToLoad <- file.choose(new = TRUE)
readmits <- read.csv(fileToLoad)
rm(fileToLoad)

# Time Aware Tibble ####
# Make a time aware tibble
readmits$Time <- lubridate::mdy(readmits$Time)
ta.readmits <- as_tbl_time(readmits, index = Time)
head(ta.readmits)

min.date  <- min(ta.readmits$Time)
min.year  <- year(min.date)
min.month <- month(min.date)
max.date  <- max(ta.readmits$Time)
max.year  <- year(max.date)
max.month <- month(max.date)

ta.readmits.ts <- tk_ts(
  ta.readmits
  , start = c(min.year, min.month)
  , end = c(max.year, max.month)
  , frequency = 365
  )
has_timetk_idx(ta.readmits.ts)

# Make Monthly objects
tk.monthly <- ta.readmits %>%
  collapse_by("monthly") %>%
  group_by(Time, add = T) %>%
  summarize(
    readmit.rate = round( (sum(READMIT_COUNT) / sum(DSCH_COUNT)), 4) * 100
  )
head(tk.monthly, 5)
tail(tk.monthly, 5)

# Get Parameters ####
max.readmitrate.monthly <- max(tk.monthly$readmit.rate)
min.readmitrate.monthly <- min(tk.monthly$readmit.rate)

start.date.monthly <- min(tk.monthly$Time)
end.date.monthly <- max(tk.monthly$Time)

training.region.monthly <- round(nrow(tk.monthly) * 0.7, 0)
test.region.monthly <- nrow(tk.monthly) - training.region.monthly
training.stop.date.monthly <- as.Date(max(tk.monthly$Time)) %m-% 
  months(as.numeric(test.region.monthly), abbreviate = F)

# Plot initial data ####
# Monthly
tk.monthly %>%
  ggplot(
    aes(
      x = Time
      , y = readmit.rate
    )
  ) + 
  geom_rect(
    xmin = as.numeric(ymd(training.stop.date.monthly))
    , xmax = as.numeric(ymd(end.date.monthly))
    , ymin = (0.9 * min.readmitrate.monthly)
    , ymax = (1.1 * max.readmitrate.monthly)
    , fill = palette_light()[[4]]
    , alpha = 0.01
  ) +
  annotate(
    "text"
    , x = ymd("2015-01-01")
    , y = min.readmitrate.monthly
    , color = palette_light()[[1]]
    , label = "Training Region"
  ) +
  annotate(
    "text"
    , x = ymd("2018-01-01")
    , y = max.readmitrate.monthly
    , color = palette_light()[[1]]
    , label = "Testing Region"
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
  ) +
  labs(
    title = "Readmit Rate: Monthly Scale"
    , subtitle = "Source: DSS"
    , caption = paste0(
      "Based on discharges from: "
      , start.date.monthly
      , " through "
      , end.date.monthly
    )
    , y = "Readmit Rate"
    , x = ""
  ) +
  theme_tq()

# Train / Test Data Sets ####
# Monthly train/test
train.monthly <- tk.monthly %>%
  filter(Time < training.stop.date.monthly)
head(train.monthly, 1)

test.monthly <- tk.monthly %>%
  filter(Time >= training.stop.date.monthly)
head(test.monthly, 1)

# Monthly
train.monthly.augmented <- train.monthly %>%
  tk_augment_timeseries_signature()
head(train.monthly.augmented, 1)

test.monthly.augmented <- test.monthly %>%
  tk_augment_timeseries_signature()
head(test.monthly.augmented, 1)

# Make XTS object ####
# Forecast with FPP, will need to convert data to an xts/ts object
monthly.rr.ts <- ts(
  tk.monthly$readmit.rate
  , frequency = 12
  , start = c(min.year, min.month)
  , end = c(max.year, max.month)
)
plot.ts(monthly.rr.ts)
class(monthly.rr.ts)
monthly.rr.xts <- as.xts(monthly.rr.ts)
head(monthly.rr.xts)
monthly.rr.sub.xts <- window(
	monthly.rr.ts
	, start = c(min.year, min.month)
  , end = c(max.year, max.month)
)
monthly.rr.sub.xts

# TS components ####
monthly.components <- decompose(monthly.rr.sub.xts)
names(monthly.components)
monthly.components$seasonal
plot(monthly.components)

# Get stl object ####
monthly.compl <- stl(monthly.rr.sub.xts, s.window = "periodic")
plot(monthly.compl)

# HW Model ####
monthly.fit.hw <- HoltWinters(monthly.rr.sub.xts)
monthly.fit.hw
monthly.hw.est.params <- sw_tidy(monthly.fit.hw)
plot(monthly.fit.hw)
plot.ts(monthly.fit.hw$fitted)

# Forecast HW ####
monthly.hw.fcast <- hw(
  monthly.rr.sub.xts
  , h = 12
  , alpha = monthly.fit.hw$alpha
  , gamma = monthly.fit.hw$gamma
)
summary(monthly.hw.fcast)

# HW Errors
monthly.hw.perf <- sw_glance(monthly.fit.hw)
mape.hw <- monthly.hw.perf$MAPE

# Monthly HW predictions
monthly.hw.pred <- sw_sweep(monthly.hw.fcast) %>%
  filter(sw_sweep(monthly.hw.fcast)$key == 'forecast')
print(monthly.hw.pred)
hw.pred <- head(monthly.hw.pred$value, 1)

# Vis HW predict ####
monthly.hw.fcast.plt <- sw_sweep(monthly.hw.fcast) %>%
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
    title = "IP Readmit Rate Forecast - HW"
    , x = ""
    , y = ""
    , subtitle = paste0(
      "HoltWinters Model - 12 Month forecast - MAPE = "
      , round(mape.hw, 2)
      , " - Forecast = "
      , round(hw.pred, 2)
    )
  ) +
  scale_x_yearmon(n = 12, format = "%Y") +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq()
print(monthly.hw.fcast.plt)

# S-Naive Model ####
monthly.snaive.fit <- snaive(monthly.rr.sub.xts, h = 12)
monthly.sn.pred <- sw_sweep(monthly.snaive.fit) %>%
  filter(sw_sweep(monthly.snaive.fit)$key == 'forecast')
print(monthly.sn.pred)

sn.pred <- head(monthly.sn.pred$value, 1)

# Calculate Errors
test.residuals.snaive <- monthly.snaive.fit$residuals
pct.err.snaive <- (test.residuals.snaive / monthly.snaive.fit$fitted) * 100
mape.snaive <- mean(abs(pct.err.snaive), na.rm = TRUE)

monthly.snaive.plt <- sw_sweep(monthly.snaive.fit) %>%
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
    title = "IP Readmit Rate Forecast - S-Naive"
    , x = ""
    , y = ""
    , subtitle = paste0(
     "S-Naive Model - 12 Month forecast - MAPE = "
     , round(mape.snaive, 2)
     , " - Forecast = "
     , round(sn.pred, 2)
    )
  ) +
  scale_x_yearmon(n = 12, format = "%Y") +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq() 
print(monthly.snaive.plt)

# ETS Model #####
monthly.ets.fit <- monthly.rr.sub.xts %>%
  ets()
summary(monthly.ets.fit)

monthly.ets.train.params   <- sw_tidy(monthly.ets.fit)
monthly.ets.train.accuracy <- sw_glance(monthly.ets.fit)
monthly.ets.train.augment  <- sw_augment(monthly.ets.fit)
monthly.ets.train.decomp   <- sw_tidy_decomp(monthly.ets.fit)
monthly.ets.alpha.train    <- monthly.ets.fit$par[["alpha"]]

monthly.ets.ref <- monthly.rr.sub.xts %>%
  ets(
    ic = "bic"
    , alpha = monthly.ets.alpha.train
  )
monthly.ets.ref.params   <- sw_tidy(monthly.ets.ref)
monthly.ets.ref.accuracy <- sw_glance(monthly.ets.ref)
monthly.ets.ref.augment  <- sw_augment(monthly.ets.ref)
monthly.ets.ref.decomop  <- sw_tidy_decomp(monthly.ets.ref)

# Caclulate errors
test.residuals.ets <- monthly.ets.ref$residuals
pct.err.ets <- (test.residuals.ets / monthly.ets.ref$fitted) * 100
mape.ets <- mean(abs(pct.err.ets), na.rm = TRUE)

# Forecast ets model
monthly.ets.fcast <- monthly.ets.ref %>%
  forecast(h = 12)

# Tidy Forecast Object
monthly.ets.pred <- sw_sweep(monthly.ets.fcast) %>%
  filter(sw_sweep(monthly.ets.fcast)$key == 'forecast')

ets.pred <- head(monthly.ets.pred$value, 1)

# Visualize
monthly.ets.fcast.plt <- sw_sweep(monthly.ets.fcast) %>%
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
    title = "IP Readmit Rate Forecast - ETS"
    , x = ""
    , y = ""
    , subtitle = paste0(
      "ETS Model - 12 Month forecast - MAPE = "
      , round(mape.ets, 2)
      , " - Forecast = "
      , round(ets.pred, 2)
    )
  ) +
  scale_x_yearmon(
    n = 12
    , format = "%Y"
  ) +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq()
print(monthly.ets.fcast.plt)

# Auto Arima ####
# Is the data stationary?
monthly.rr.ts %>% ur.kpss() %>% summary()
# Is the data stationary after differencing
monthly.rr.ts %>% diff() %>% ur.kpss() %>% summary()
# How many differences make it stationary
ndiffs(monthly.rr.ts)
rr.diffs <- ndiffs(monthly.rr.ts)
# Seasonal differencing?
nsdiffs(monthly.rr.ts)
# Re-plot
monthly.rr.ts.diff <- diff(monthly.rr.ts, differences = rr.diffs)
plot.ts(monthly.rr.ts.diff)
acf(monthly.rr.ts.diff, lag.max = 20)
acf(monthly.rr.ts.diff, plot = F)

# Auto Arima
monthly.aa.fit <- auto.arima(monthly.rr.ts)
sw_glance(monthly.aa.fit)
monthly.aa.fcast <- forecast(monthly.aa.fit, h = 12)
tail(sw_sweep(monthly.aa.fcast), 12)

# Monthly AA predictions
monthly.aa.pred <- sw_sweep(monthly.aa.fcast) %>%
  filter(sw_sweep(monthly.aa.fcast)$key == 'forecast')
print(monthly.aa.pred)

aa.pred <- head(monthly.aa.pred$value, 1)

# AA Errors
monthly.aa.perf <- sw_glance(monthly.aa.fit)
mape.aa <- monthly.aa.perf$MAPE

# Plot fitted aa model
monthly.aa.fcast.plt <- sw_sweep(monthly.aa.fcast) %>%
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
    title = "IP Readmit Rate Forecast - Auto Arima"
    , x = ""
    , y = ""
    , subtitle = paste0(
      "Auto Arima Model - 12 Month forecast - MAPE = "
      , round(mape.aa, 2)
      , " - Forecast = "
      , round(aa.pred, 2)
    )
  ) +
  scale_x_yearmon(n = 12, format = "%Y") +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq()
print(monthly.aa.fcast.plt)

# Compare models ####
qqnorm(monthly.hw.fcast$residuals)
qqline(monthly.hw.fcast$residuals)

qqnorm(monthly.snaive.fit$residuals)
qqline(monthly.snaive.fit$residuals)

qqnorm(monthly.ets.fcast$residuals)
qqline(monthly.ets.fcast$residuals)

qqnorm(monthly.aa.fcast$residuals)
qqline(monthly.aa.fcast$residuals)

checkresiduals(monthly.hw.fcast)
checkresiduals(monthly.snaive.fit)
checkresiduals(monthly.ets.fcast)
checkresiduals(monthly.aa.fcast)

# Pick Model ####
gridExtra::grid.arrange(
  monthly.hw.fcast.plt
  , monthly.snaive.plt
  , monthly.ets.fcast.plt
  , monthly.aa.fcast.plt
  , nrow = 2
  , ncol = 2
)

# 1 Month Pred
hw.pred <- head(monthly.hw.pred$value, 1)
hw.pred.lo.95 <- head(monthly.hw.pred$lo.95, 1)
hw.pred.hi.95 <- head(monthly.hw.pred$hi.95, 1)

sn.pred <- head(monthly.sn.pred$value, 1)
sn.pred.lo.95 <- head(monthly.sn.pred$lo.95, 1)
sn.pred.hi.95 <- head(monthly.sn.pred$hi.95, 1)

ets.pred <- head(monthly.ets.pred$value, 1)
ets.pred.lo.95 <- head(monthly.ets.pred$lo.95, 1)
ets.pred.hi.95 <- head(monthly.ets.pred$hi.95, 1)

aa.pred <- head(monthly.aa.pred$value, 1)
aa.pred.lo.95 <- head(monthly.aa.pred$lo.95, 1)
aa.pred.hi.95 <- head(monthly.aa.pred$hi.95, 1)

mod.pred <- c(hw.pred, sn.pred, ets.pred, aa.pred)
mod.pred.lo.95 <- c(
  hw.pred.lo.95
  , sn.pred.lo.95
  , ets.pred.lo.95
  , aa.pred.lo.95
  )
mod.pred.hi.95 <- c(
  hw.pred.hi.95
  , sn.pred.hi.95
  , ets.pred.hi.95
  , aa.pred.hi.95
  )
err.mape <- c(
  mape.hw
  , mape.snaive
  , mape.ets
  , mape.aa
  )

pred.tbl.row.names <- c(
  "HoltWinters"
  , "Seasonal Naive"
  , "ETS"
  , "Auto ARIMA"
)
pred.tbl <- data.frame(
  mod.pred
  , mod.pred.lo.95
  , mod.pred.hi.95
  , err.mape
  )
rownames(pred.tbl) <- pred.tbl.row.names
pred.tbl <- tibble::rownames_to_column(pred.tbl)
pred.tbl <- arrange(pred.tbl, pred.tbl$err.mape)
print(pred.tbl)

# h2o ####
library(h2o)
tk.monthly %>% glimpse()
tk.monthly.aug <- tk.monthly %>%
  tk_augment_timeseries_signature()
tk.monthly.aug %>% glimpse()

tk.monthly.tbl.clean <- tk.monthly.aug %>%
  select_if(~ !is.Date(.)) %>%
  select_if(~ !any(is.na(.))) %>%
  mutate_if(is.ordered, ~ as.character(.) %>% as.factor)

tk.monthly.tbl.clean %>% glimpse()

train.tbl <- tk.monthly.tbl.clean %>% filter(year < 2017)
valid.tbl <- tk.monthly.tbl.clean %>% filter(year == 2017)
test.tbl  <- tk.monthly.tbl.clean %>% filter(year == 2018)

h2o.init()

train.h2o <- as.h2o(train.tbl)
valid.h2o <- as.h2o(valid.tbl)
test.h2o <- as.h2o(test.tbl)

y <- "readmit.rate"
x <- setdiff(names(train.h2o), y)

automl.models.h2o <- h2o.automl(
  x = x
  , y = y
  , training_frame = train.h2o
  , validation_frame = valid.h2o
  , leaderboard_frame = test.h2o
  , max_runtime_secs = 60
  , stopping_metric = "deviance"
)

automl.leader <- automl.models.h2o@leader

pred.h2o <- h2o.predict(
  automl.leader
  , newdata = test.h2o
)

h2o.performance(
  automl.leader
  , newdata = test.h2o
)

# get mape
automl.error.tbl <- tk.monthly %>%
  filter(lubridate::year(Time) == 2018) %>%
  add_column(
    pred = pred.h2o %>%
      as.tibble() %>%
      pull(predict)
    ) %>%
  rename(actual = readmit.rate) %>%
  mutate(
    error = actual - pred
    , error.pct = error / actual
  )
print(automl.error.tbl)

automl.error.tbl %>%
  summarize(
    me = mean(error)
    , rmse = mean(error^2)^0.5
    , mae = mean(abs(error))
    , mape = mean(abs(error))
    , mpe = mean(error.pct)
  ) %>%
  glimpse()
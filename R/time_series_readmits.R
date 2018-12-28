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

# Get File ####
fileToLoad <- file.choose(new = TRUE)
readmits <- read.csv(fileToLoad)
rm(fileToLoad)

# Time Aware Tibble ####
# Make a time aware tibble
readmits$Time <- lubridate::mdy(readmits$Time)
ta.readmits <- as_tbl_time(readmits, index = Time)
head(ta.readmits)

ta.readmits.ts <- tk_ts(
  ta.readmits
  , start = c(2001,1)
  , end = c(2018,10)
  , frequency = 365
  )
has_timetk_idx(ta.readmits.ts)

# Make Weekly, Monthly objects
tk.weekly <- ta.readmits %>%
  collapse_by("weekly") %>%
  group_by(Time, add = T) %>%
  summarize(
    readmit.rate = round( (sum(READMIT_COUNT) / sum(DSCH_COUNT)), 4) * 100
  )
head(tk.weekly, 5)
tail(tk.weekly, 5)


tk.monthly <- ta.readmits %>%
  collapse_by("monthly") %>%
  group_by(Time, add = T) %>%
  summarize(
    readmit.rate = round( (sum(READMIT_COUNT) / sum(DSCH_COUNT)), 4) * 100
  )
head(tk.monthly, 5)
tail(tk.monthly, 5)

# Get Parameters ####
max.readmitrate.weekly <- max(tk.weekly$readmit.rate)
min.readmitrate.weekly <- min(tk.weekly$readmit.rate)

max.readmitrate.monthly <- max(tk.monthly$readmit.rate)
min.readmitrate.monthly <- min(tk.monthly$readmit.rate)

start.date.weekly <- min(tk.weekly$Time)
start.date.monthly <- min(tk.monthly$Time)

end.date.weekly  <- max(tk.weekly$Time)
end.date.monthly <- max(tk.monthly$Time)

training.region.weekly <- round(nrow(tk.weekly) * 0.7, 0)
training.region.monthly <- round(nrow(tk.monthly) * 0.7, 0)

test.region.weekly <- nrow(tk.weekly) - training.region.weekly
test.region.monthly <- nrow(tk.monthly) - training.region.monthly

training.stop.date.weekly <- ymd(end.date.weekly) - weeks(test.region.weekly)
training.stop.date.monthly <- as.Date(max(tk.monthly$Time)) %m-% 
  months(as.numeric(test.region.monthly), abbreviate = F)

# Plot initial data ####
# Weekly
tk.weekly %>%
  ggplot(
    aes(
      x = Time
      , y = readmit.rate
    )
  ) + 
  geom_rect(
    xmin = as.numeric(ymd(training.stop.date.weekly))
    , xmax = as.numeric(ymd(end.date.weekly))
    , ymin = (0.9 * min.readmitrate.weekly)
    , ymax = (1.1 * max.readmitrate.weekly)
    , fill = palette_light()[[4]]
    , alpha = 0.01
  ) +
  annotate(
    "text"
    , x = ymd("2005-01-01")
    , y = min.readmitrate.weekly
    , color = palette_light()[[1]]
    , label = "Training Region"
  ) +
  annotate(
    "text"
    , x = ymd("2016-01-01")
    , y = max.readmitrate.weekly
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
    title = "Readmit Rate: Weekly Scale"
    , subtitle = "Source: DSS"
    , caption = paste0(
      "Based on discharges from: "
      , start.date.weekly
      , " through "
      , end.date.weekly
    )
    , y = "Readmit Rate"
    , x = ""
  ) +
  theme_tq()

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
    , x = ymd("2005-01-01")
    , y = min.readmitrate.monthly
    , color = palette_light()[[1]]
    , label = "Training Region"
  ) +
  annotate(
    "text"
    , x = ymd("2016-01-01")
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
# Weekly train/test
train.weekly <- tk.weekly %>%
  filter(Time < training.stop.date.weekly)
head(train.weekly, 1)

test.weekly <- tk.weekly %>%
  filter(Time >= training.stop.date.weekly)
head(test.weekly, 1)

# Monthly train/test
train.monthly <- tk.monthly %>%
  filter(Time < training.stop.date.monthly)
head(train.monthly, 1)

test.monthly <- tk.monthly %>%
  filter(Time >= training.stop.date.monthly)
head(test.monthly, 1)

# Add time series signature to train/test sets
# Weekly
train.weekly.augmented <- train.weekly %>%
  tk_augment_timeseries_signature()
head(train.weekly.augmented, 1)

test.weekly.augmented <- test.weekly %>%
  tk_augment_timeseries_signature()
head(test.weekly.augmented, 1)

# Monthly
train.monthly.augmented <- train.monthly %>%
  tk_augment_timeseries_signature()
head(train.monthly.augmented, 1)

test.monthly.augmented <- test.monthly %>%
  tk_augment_timeseries_signature()
head(test.monthly.augmented, 1)

# Make XTS object ####
# Forecast with FPP, will need to convert data to an xts/ts object
  # monthly.rr <- as_tbl_time(readmits, index = Time)
  # monthly.rr <- ta.readmits %>%
  #   collapse_by("monthly") %>%
  #   group_by(Time, add = TRUE) %>%
  #   summarize(
  #     readmit.rate = round(
  #       (sum(READMIT_COUNT)
  #        /
  #        sum(DSCH_COUNT)
  #       )
  #       , 4
  #       ) * 100
  #   )
  # str(monthly.rr)
monthly.rr.ts <- ts(
  tk.monthly$readmit.rate
  , frequency = 12
  , start = c(2001,1)
)
plot.ts(monthly.rr.ts)
class(monthly.rr.ts)
monthly.rr.xts <- as.xts(monthly.rr.ts)
head(monthly.rr.xts)
monthly.rr.sub.xts <- window(monthly.rr.ts, start = c(2001,1), end=c(2018,10))
monthly.rr.sub.xts

# TS components ####
components <- decompose(monthly.rr.sub.xts)
names(components)
components$seasonal
plot(components)

# Get stl object ####
compl <- stl(monthly.rr.sub.xts, s.window = "periodic")
plot(compl)

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
    title = "IP Readmission Forecast - HW"
    , x = ""
    , y = "Readmission Rate"
    , subtitle = "HoltWinters Model - 12 Month forecast with Prediction Intervals"
  ) +
  scale_x_yearmon(n = 12, format = "%Y") +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq()
print(monthly.hw.fcast.plt)

# Monthly HW Errors
monthly.hw.perf <- sw_glance(monthly.fit.hw)
mape.hw.monthly <- monthly.hw.perf$MAPE

# Monthly HW predictions
monthly.hw.pred <- sw_sweep(monthly.hw.fcast) %>%
  filter(sw_sweep(monthly.hw.fcast)$key == 'forecast')
print(monthly.hw.pred)

# S-Naive Model ####
monthly.snaive.fit <- snaive(monthly.rr.sub.xts, h = 12)
monthly.sn.pred <- sw_sweep(monthly.snaive.fit) %>%
  filter(sw_sweep(monthly.snaive.fit)$key == 'forecast')
print(monthly.sn.pred)

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
    title = "IP Readmission Forecast - S-Naive"
    , x = ""
    , y = "Readmission Rate"
    , subtitle = "Seasonal Naive Model - 12 Month forecast with Prediction Intervals"
  ) +
  scale_x_yearmon(n = 12, format = "%Y") +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq() 
print(monthly.snaive.plt)

# Calculate Errors
test.residuals.snaive <- monthly.snaive.fit$residuals
pct.err.snaive <- (test.residuals.snaive / monthly.snaive.fit$fitted) * 100
mape.snaive <- mean(abs(pct.err.snaive), na.rm = TRUE)

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
    title = "Forecast for IP Discharges: 12-Month Forecast"
    , x = ""
    , y = "Discharges"
    , subtitle = "ETS Model - 12 Month forecast with Prediction Intervals"
  ) +
  scale_x_yearmon(
    n = 12
    , format = "%Y"
  ) +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq()
print(monthly.ets.fcast.plt)

# Compare models ####
qqnorm(monthly.hw.fcast$residuals)
qqline(monthly.hw.fcast$residuals)

qqnorm(monthly.snaive.fit$residuals)
qqline(monthly.snaive.fit$residuals)

qqnorm(monthly.ets.fcast$residuals)
qqline(monthly.ets.fcast$residuals)

checkresiduals(monthly.hw.fcast)
checkresiduals(monthly.snaive.fit)
checkresiduals(monthly.ets.fcast)

mape <- c(mape.hw.monthly, mape.snaive, mape.ets)
mape.tbl.row.names <- c(
  "HoltWinters"
  , "Seasonal Naive"
  , "ETS"
)
error.tbl <- data.frame(mape)
rownames(error.tbl) <- mape.tbl.row.names
error.tbl <- tibble:rownames_to_column(error.tbl)
View(error.tbl)

# Pick Model ####
min.error <- head(arrange(error.tbl, error.tbl$mape), 1)
print(min.error)

gridExtra::grid.arrange(
  monthly.hw.fcast.plt
  , monthly.snaive.plt
  , monthly.ets.fcast.plt
  , nrow = 2
  , ncol = 2
)

# 1 Month Pred ####
hw.pred <- head(monthly.ets.pred$value, 1)
hw.pred.lo.95 <- head(monthly.ets.pred$lo.95, 1)
hw.pred.hi.95 <- head(monthly.ets.pred$hi.95, 1)

sn.pred <- head(monthly.sn.pred$value, 1)
sn.pred.lo.95 <- head(monthly.sn.pred$lo.95, 1)
sn.pred.hi.95 <- head(monthly.sn.pred$hi.95, 1)

ets.pred <- head(monthly.ets.pred$value, 1)
ets.pred.lo.95 <- head(monthly.ets.pred$lo.95, 1)
ets.pred.hi.95 <- head(monthly.ets.pred$hi.95, 1)

mod.pred <- c(hw.pred, sn.pred, ets.pred)
mod.pred.lo.95 <- c(hw.pred.lo.95, sn.pred.lo.95, ets.pred.lo.95)
mod.pred.hi.95 <- c(hw.pred.hi.95, sn.pred.hi.95, ets.pred.hi.95)

pred.tbl.row.names <- c(
  "HoltWinters"
  , "Seasonal Naive"
  , "ETS"
)
pred.tbl <- data.frame(mod.pred, mod.pred.lo.95, mod.pred.hi.95)
rownames(pred.tbl) <- pred.tbl.row.names
pred.tbl <- tibble::rownames_to_column(pred.tbl)
pred.tbl

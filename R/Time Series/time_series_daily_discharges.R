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

# Get File ####
fileToLoad <- file.choose(new = TRUE)
discharges <- read.csv(fileToLoad)
rm(fileToLoad)

# Time Aware Tibble ####
# Make a time aware tibble
discharges$Time <- lubridate::mdy(discharges$Time)
ta.discharges <- as_tbl_time(discharges, index = Time)
head(ta.discharges, 5)

#timetk Daily
ta.discharges.ts <- tk_ts(ta.discharges,
              start = 2010,
              frequency = 365
)
class(ta.discharges.ts)

# timetk_index <- tk_index(tk_d, timetk_idx = TRUE)
# head(timetk_index)
# class(timetk_index)
has_timetk_idx(ta.discharges.ts)

# Make Monthly objets
tk.monthly <- ta.discharges %>%
  collapse_by("monthly") %>%
  group_by(Time, add = TRUE) %>%
  summarize(
    cnt = sum(DSCH_COUNT)
    #, cnt.log = log(sum(DSCH_COUNT))
  )
head(tk.monthly)
tail(tk.monthly)

# Get Parameters ####
max.discharges <- max(tk.monthly$cnt)
min.discharges <- min(tk.monthly$cnt)

start.date.monthly <- min(tk.monthly$Time)
end.date.monthly   <- max(tk.monthly$Time)

training.region.monthly <- round(nrow(tk.monthly) * 0.7, 0)
test.region.monthly     <- nrow(tk.monthly) - training.region.monthly

training.stop.date.monthly <- as.Date(max(tk.monthly$Time)) %m-% months(
  as.numeric(test.region.monthly), abbreviate = F)

# Plot intial Data ####
tk.monthly %>%
  ggplot(
    aes(
      x = Time
      , y = cnt
    )
  ) +
  geom_rect(
    xmin = as.numeric(ymd(training.stop.date.monthly))
    , xmax = as.numeric(ymd(end.date.monthly))
    , ymin = (min.discharges * 0.9)
    , ymax = (max.discharges * 1.1)
    , fill = palette_light()[[4]]
    , alpha = 0.01
  ) +
  annotate(
    "text"
    , x = ymd("2012-01-01")
    , y = min.discharges
    , color = palette_light()[[1]]
    , label = "Training Region"
  ) +
  annotate(
    "text"
    , x = ymd("2017-01-01")
    , y = max.discharges
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
    title = "Discharges: Monthly Scale"
    , subtitle = "Source: DSS"
    , caption = paste0(
      "Based on discharges from: "
      , start.date.monthly
      , " through "
      , end.date.monthly
    )
    , y = "Count"
    , x = ""
  ) +
  theme_tq()

# Make XTS object ####
# Forecast with FPP, will need to convert data to an xts/ts object
monthly.rr.ts <- ts(
  tk.monthly$cnt
  , frequency = 12
  , start = c(2001,1)
)
plot.ts(monthly.rr.ts)
class(monthly.rr.ts)
monthly.rr.xts <- as.xts(monthly.rr.ts)
head(monthly.rr.xts)
monthly.rr.sub.xts <- window(monthly.rr.ts, start = c(2001,1), end=c(2018,11))
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
  , beta  = monthly.fit.hw$beta
)
summary(monthly.hw.fcast)

# HW Errors
monthly.hw.perf <- sw_glance(monthly.fit.hw)
mape.hw <- monthly.hw.perf$MAPE

# Monthly HW predictions
monthly.hw.pred <- sw_sweep(monthly.hw.fcast) %>%
  filter(sw_sweep(monthly.hw.fcast)$key == 'forecast')
print(monthly.hw.pred)

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
    title = "Forecast for IP Discharges: 12-Month Forecast"
    , x = ""
    , y = ""
    , subtitle = paste0(
      "HoltWinters Model - 12 Month forecast - MAPE = "
      , round(mape.hw, 2)
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
    title = "Forecast for IP Discharges: 12-Month Forecast"
    , x = ""
    , y = ""
    , subtitle = paste0(
      "S-Naive Model - 12 Month forecast - MAPE = "
      , round(mape.snaive, 2)
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
    , alpha = monthly.ets.fit$par[["alpha"]]
    , beta  = monthly.ets.fit$par[["beta"]]
    , gamma = monthly.ets.fit$par[["gamma"]]
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
    , y = ""
    , subtitle = paste0(
      "ETS Model - 12 Month forecast - MAPE = "
      , round(mape.ets, 2)
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
monthly.rr.ts.diff <- diff(monthly.rr.ts)#, differences = rr.diffs)
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
    title = "Forecast for IP Discharges: 12-Month Forecast"
    , x = ""
    , y = ""
    , subtitle = paste0(
      "Auto Arima Model - 12 Month forecast - MAPE = "
      , round(mape.aa, 2)
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
hw.pred <- head(monthly.ets.pred$value, 1)
hw.pred.lo.95 <- head(monthly.ets.pred$lo.95, 1)
hw.pred.hi.95 <- head(monthly.ets.pred$hi.95, 1)

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


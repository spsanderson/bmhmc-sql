# Lib Load ####
# Time Series analysis on Daily ALOS ELOS
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
# Make a time aware tibble
discharges$Time <- lubridate::mdy(discharges$Time)
ta.discharges <- as_tbl_time(discharges, index = Time)
head(ta.discharges)

min.date  <- min(ta.discharges$Time)
min.year  <- year(min.date)
min.month <- month(min.date)
max.date  <- max(ta.discharges$Time)
max.year  <- year(max.date)
max.month <- month(max.date)

#timetk Daily
ta.discharges.ts <- tk_ts(
  ta.discharges
  , start = c(min.year, min.month)
  , end = c(max.year, max.month)
  , frequency = 365
)
has_timetk_idx(ta.discharges.ts)

# Make Monthly objets
tk.monthly <- ta.discharges %>%
  collapse_by("monthly") %>%
  group_by(Time, add = TRUE) %>%
  summarize(
    cnt = sum(DSCH_COUNT)
    , total.days = sum(SUM_DAYS)
    , total.exp.days = sum(SUM_EXP_DAYS)
    , alos = total.days / cnt
    , elos = total.exp.days / cnt
    , total.excess = total.days - total.exp.days
    , avg.daily.excess = alos - elos
  )
head(tk.monthly, 5)
tail(tk.monthly, 5)

# Get Parameters ####
max.discharges.monthly <- max(tk.monthly$total.excess)
min.discharges.monthly <- min(tk.monthly$total.excess)

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
      , y = total.excess
    )
  ) +
  geom_rect(
    xmin = as.numeric(ymd(training.stop.date.monthly))
    , xmax = as.numeric(ymd(end.date.monthly))
    , ymin = (min.discharges.monthly * 0.9)
    , ymax = (max.discharges.monthly * 1.1)
    , fill = palette_light()[[4]]
    , alpha = 0.01
  ) +
  annotate(
    "text"
    , x = ymd("2015-01-01")
    , y = min.discharges.monthly
    , color = palette_light()[[1]]
    , label = "Training Region"
  ) +
  annotate(
    "text"
    , x = ymd("2018-06-01")
    , y = max.discharges.monthly
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
    title = "Excess Days for IP Discharges: Monthly Scale"
    , subtitle = "Source: DSS"
    , caption = paste0(
      "Based on discharges from: "
      , start.date.monthly
      , " through "
      , end.date.monthly
    )
    , y = "Excess Days"
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
monthly.dsch.ts <- ts(
  tk.monthly$total.excess
  , frequency = 12
  , start = c(min.year, min.month)
  , end   = c(max.year, max.month)
)
plot.ts(monthly.dsch.ts)
class(monthly.dsch.ts)
monthly.dsch.xts <- as.xts(monthly.dsch.ts)
head(monthly.dsch.xts)
monthly.dsch.sub.xts <- window(
  monthly.dsch.ts
  , start = c(min.year, min.month)
  , end = c(max.year, max.month)
  )
monthly.dsch.sub.xts

# TS components ####
monthly.components <- decompose(monthly.dsch.sub.xts)
names(monthly.components)
monthly.components$seasonal
plot(monthly.components)

# Get stl object ####
monthly.compl <- stl(monthly.dsch.sub.xts, s.window = "periodic")
plot(monthly.compl)

# HW Model ####
monthly.fit.hw <- HoltWinters(monthly.dsch.sub.xts)
monthly.fit.hw
monthly.hw.est.params <- sw_tidy(monthly.fit.hw)
plot(monthly.fit.hw)
plot.ts(monthly.fit.hw$fitted)

# Forecast HW ####
monthly.hw.fcast <- hw(
  monthly.dsch.sub.xts
  , h = 12
  , alpha = monthly.fit.hw$alpha
  , gamma = monthly.fit.hw$gamma
  , beta  = monthly.fit.hw$beta
)
summary(monthly.hw.fcast)

# HW Errors
monthly.hw.perf <- sw_glance(monthly.fit.hw)
mape.hw <- monthly.hw.perf$MAPE
model.desc.hw <- monthly.hw.perf$model.desc

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
    title = "Forecast for Excess IP Days: 12-Month Forecast"
    , x = ""
    , y = ""
    , subtitle = paste0(
      "Model Desc - "
      , model.desc.hw
      , "\n"
      , "MAPE = "
      , round(mape.hw, 2)
      , " - Forecast = "
      , round(hw.pred, 0)
    )
  ) +
  scale_x_yearmon(n = 12, format = "%Y") +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq()
print(monthly.hw.fcast.plt)

# S-Naive Model ####
monthly.snaive.fit <- snaive(monthly.dsch.sub.xts, h = 12)
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
    title = "Forecast for Excess IP Days: 12-Month Forecast"
    , x = ""
    , y = ""
    , subtitle = paste0(
      "Model Desc - S-Naive"
      , "\n"
      , "MAPE = "
      , round(mape.snaive, 2)
      , " - Forecast = "
      , round(sn.pred, 0)
    )
  ) +
  scale_x_yearmon(n = 12, format = "%Y") +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq() 
print(monthly.snaive.plt)

# ETS Model #####
monthly.ets.fit <- monthly.dsch.sub.xts %>%
  ets()
summary(monthly.ets.fit)

monthly.ets.ref <- monthly.dsch.sub.xts %>%
  ets(
    ic = "bic"
    , alpha = monthly.ets.fit$par[["alpha"]]
    , beta  = monthly.ets.fit$par[["beta"]]
    , phi   = monthly.ets.fit$par[["phi"]]
    # , gamma = monthly.ets.fit$par[["gamma"]]
  )

# Caclulate errors
mape.ets <- sw_glance(monthly.ets.ref)$MAPE
monthly.ets.ref.model.desc <- sw_glance(monthly.ets.ref)$model.desc

# Forecast ets model
monthly.ets.fcast <- monthly.ets.ref %>%
  forecast(h = 12)

# Tidy Forecast Object
monthly.ets.pred <- sw_sweep(monthly.ets.fcast) %>%
  filter(sw_sweep(monthly.ets.fcast)$key == 'forecast')
print(monthly.ets.pred)
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
    title = "Forecast for Excess IP Days: 12-Month Forecast"
    , x = ""
    , y = ""
    , subtitle = paste0(
      "Model Desc - "
      , monthly.ets.ref.model.desc
      , "\n"
      , "MAPE = "
      , round(mape.ets, 2)
      , " - Forecast = "
      , round(ets.pred, 0)
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
monthly.dsch.ts %>% ur.kpss() %>% summary()
# Is the data stationary after differencing
monthly.dsch.ts %>% diff() %>% ur.kpss() %>% summary()
# How many differences make it stationary
ndiffs(monthly.dsch.ts)
dsch.diffs <- ndiffs(monthly.dsch.ts)
# Seasonal differencing?
nsdiffs(monthly.dsch.ts)
# Re-plot
monthly.dsch.ts.diff <- diff(monthly.dsch.ts)#, differences = rr.diffs)
plot.ts(monthly.dsch.ts.diff)
acf(monthly.dsch.ts.diff, lag.max = 20)
acf(monthly.dsch.ts.diff, plot = F)

# Auto Arima
monthly.aa.fit <- auto.arima(monthly.dsch.ts)
sw_glance(monthly.aa.fit)
monthly.aa.fcast <- forecast(monthly.aa.fit, h = 12)
tail(sw_sweep(monthly.aa.fcast), 12)

# Monthly AA predictions
monthly.aa.pred <- sw_sweep(monthly.aa.fcast) %>%
  filter(sw_sweep(monthly.aa.fcast)$key == 'forecast')
print(monthly.aa.pred)
aa.pred <- head(monthly.aa.pred$value, 1)

# AA Errors
monthly.aa.perf.model.desc <- sw_glance(monthly.aa.fit)$model.desc
mape.aa <- sw_glance(monthly.aa.fit)$MAPE

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
    title = "Forecast for Excess IP Days: 12-Month Forecast"
    , x = ""
    , y = ""
    , subtitle = paste0(
      "Model Desc - "
      , monthly.aa.perf.model.desc
      , "\n"
      , "MAPE = "
      , round(mape.aa, 2)
      , " - Forecast = "
      , round(aa.pred, 0)
    )
  ) +
  scale_x_yearmon(n = 12, format = "%Y") +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq()
print(monthly.aa.fcast.plt)

# Bagged Model ####
monthly.bagged.model <- baggedModel(monthly.dsch.ts)

# Forecast Bagged ETS Model
monthly.bagged.fcast <- forecast(monthly.bagged.model, h = 12)

# Tidy Forecast Object
monthly.bagged.pred <- sw_sweep(monthly.bagged.fcast) %>%
  filter(sw_sweep(monthly.bagged.fcast)$key == 'forecast')
print(monthly.bagged.pred)
bagged.pred <- head(monthly.bagged.pred$value, 1)

# Baggd Model Errors
pct.err.bagged <- (
  monthly.bagged.fcast$residuals / monthly.bagged.fcast$fitted
) * 100
mape.bagged <- mean(abs(pct.err.bagged), na.rm = T)

# Visualize
monthly.bagged.fcast.plt <- sw_sweep(monthly.bagged.fcast) %>%
  ggplot(
    aes(
      x = index
      , y = value
      , color = key
    )
  ) +
  geom_ribbon(
    aes(
      ymin = lo.100
      , ymax = hi.100
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
    title = "Forecast for Excess IP Days: 12-Month Forecast"
    , x = ""
    , y = ""
    , subtitle = paste0(
      "Model Desc - Bagged ETS"
      , "\n"
      , "MAPE = "
      , round(mape.bagged, 2)
      , " - Forecast = "
      , round(bagged.pred, 0)
    )
  ) +
  scale_x_yearmon(
    n = 12
    , format = "%Y"
  ) +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq()
print(monthly.bagged.fcast.plt)

# Prohpet ####
df.ts.monthly.prophet <- tk.monthly %>% select(Time, total.excess)
colnames(df.ts.monthly.prophet) <- c("ds","y")

# Pophet Model
prophet.model <- prophet(df.ts.monthly.prophet)
prophet.future <- make_future_dataframe(
  prophet.model
  , periods = 12
  , freq = "month"
)
tail(prophet.future, 12)

# Prophet Forecast
prophet.forecast <- predict(prophet.model, prophet.future)
prophet.one.month.pred <- tail(
  prophet.forecast[c('ds','yhat','yhat_lower','yhat_upper')]
  , 12
)
prophet.pred <- head(prophet.one.month.pred$yhat, 1)
print(prophet.pred)

prophet.model.plt <- plot(
  prophet.model
  , prophet.forecast
) +
  labs(
    title = "IP Readmit Rate Forecast: 12-Month Forecast"
    , subtitle = paste0(
      "Model Desc - fbProphet"
      , "\n"
      , "Forecast = "
      , round(prophet.pred, 0)
    )
    , x = ""
    , y = ""
  ) +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq()
print(prophet.model.plt)

# Compare models ####
qqnorm(monthly.hw.fcast$residuals)
qqline(monthly.hw.fcast$residuals)

qqnorm(monthly.snaive.fit$residuals)
qqline(monthly.snaive.fit$residuals)

qqnorm(monthly.ets.fcast$residuals)
qqline(monthly.ets.fcast$residuals)

qqnorm(monthly.aa.fcast$residuals)
qqline(monthly.aa.fcast$residuals)

qqnorm(monthly.bagged.fcast$residuals)
qqline(monthly.bagged.fcast$residuals)

checkresiduals(monthly.hw.fcast)
checkresiduals(monthly.snaive.fit)
checkresiduals(monthly.ets.fcast)
checkresiduals(monthly.aa.fcast)
checkresiduals(monthly.bagged.fcast)

# Pick Model ####
gridExtra::grid.arrange(
  monthly.hw.fcast.plt
  , monthly.snaive.plt
  , monthly.ets.fcast.plt
  , monthly.aa.fcast.plt
  , monthly.bagged.fcast.plt
  , prophet.model.plt
  , nrow = 3
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

bagged.pred <- head(monthly.bagged.pred$value, 1)
bagged.pred.lo.100 <- head(monthly.bagged.pred$lo.100, 1)
bagged.pred.hi.10 <- head(monthly.bagged.pred$hi.100, 1)

mod.pred <- c(hw.pred, sn.pred, ets.pred, aa.pred, bagged.pred)
mod.pred.lo.95 <- c(
  hw.pred.lo.95
  , sn.pred.lo.95
  , ets.pred.lo.95
  , aa.pred.lo.95
  , bagged.pred.lo.100
)
mod.pred.hi.95 <- c(
  hw.pred.hi.95
  , sn.pred.hi.95
  , ets.pred.hi.95
  , aa.pred.hi.95
  , bagged.pred.hi.10
)
err.mape <- c(
  mape.hw
  , mape.snaive
  , mape.ets
  , mape.aa
  , mape.bagged
)

pred.tbl.row.names <- c(
  "HoltWinters"
  , "Seasonal Naive"
  , "ETS"
  , "Auto ARIMA"
  , "Bagged ETS"
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

y <- "total.excess"
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
  rename(actual = cnt) %>%
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

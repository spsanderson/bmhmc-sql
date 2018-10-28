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
tk_d <- tk_ts(ta.discharges,
              start = 2010,
              frequency = 365
)
class(tk_d)

# timetk_index <- tk_index(tk_d, timetk_idx = TRUE)
# head(timetk_index)
# class(timetk_index)
has_timetk_idx(tk_d)

tk_qtr <- ta.discharges %>%
  collapse_by("monthly") %>%
  group_by(Time, add = TRUE) %>%
  summarize(
    cnt = sum(DSCH_COUNT)
    #, cnt.log = log(sum(DSCH_COUNT))
  )
head(tk_qtr, 5)

# Get some Params ####
# get max and min discharges
max.discharges <- max(tk_qtr$cnt)
min.discharges <- min(tk_qtr$cnt)
start.date <- min(tk_qtr$Time)
end.date <- max(tk_qtr$Time)
training.region <- round(nrow(tk_qtr) * 0.7, 0)
test.region <- nrow(tk_qtr) - training.region
training.stop.date <- as.Date(max(tk_qtr$Time)) %m-% months(
  as.numeric(test.region), abbreviate = F)

# Plot intial Data ####
tk_qtr %>%
  ggplot(
    aes(
      x = Time
      , y = cnt
    )
  ) +
  geom_rect(
    xmin = as.numeric(ymd(training.stop.date))
    , xmax = as.numeric(ymd(end.date))
    , ymin = (min.discharges * 0.9)
    , ymax = (max.discharges * 1.1)
    , fill = palette_light()[[4]]
    , alpha = 0.01
  ) +
  annotate(
    "text"
    , x = ymd("2012-01-01")
    , y = 1000
    , color = palette_light()[[1]]
    , label = "Training Region"
  ) +
  annotate(
    "text"
    , x = ymd("2017-01-01")
    , y = 1200
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
      , start.date
      , " through "
      , end.date
    )
    , y = "Count"
    , x = ""
  ) +
  theme_tq()

# Train/Test Data Sets ####
# split into training and testing sets
train <- tk_qtr %>%
  filter(Time < training.stop.date)
head(train, 1)

test <- tk_qtr %>%
  filter(Time >= training.stop.date)
head(test, 1)

# Add time series signature to train
train_augmented <- train %>%
  tk_augment_timeseries_signature()
head(train_augmented, 1)

# Add time series signature to test
test_augmented <- test %>%
  tk_augment_timeseries_signature()
head(test_augmented, 2)

# Linear Models of Data ####
# Model using the augmented features
fit <- lm(cnt ~ Time
          # + year
          + quarter
          + month
          + wday
          + qday
          + yday
          + week2
          + week4
          , data = train_augmented)
summary(fit)
plot(fit)

# Visualize the residuals of the training set
# http://www.learnbymarketing.com/tutorials/linear-regression-in-r/
fit %>%
  augment() %>%
  ggplot(aes(x = Time, y = .resid)) +
  geom_hline(yintercept = 0, color = "red") +
  geom_point(color = palette_light()[[1]], alpha = 0.5) +
  geom_smooth(method = "auto") +
  theme_tq() +
  labs(title = "Training Set: lm() Model Residuals"
       , x = ""
       , subtitle = "Model = fit")

# RMSE
sqrt(mean(fit$residuals^2))
sw_glance(fit)

# Linear Model on Test Data ####
# apply the model to the test set
yhat_test_fit <- predict(fit, newdata = test_augmented)
summary(yhat_test_fit)
pred_test_fit <- test %>%
  add_column(yhat = yhat_test_fit) %>%
  mutate(.resid = cnt - yhat)

# Viz Model on Test Data ####
# Model 1 fit
ggplot(aes(x = Time), data = tk_qtr) +
  geom_rect(
    xmin = as.numeric(ymd(training.stop.date))
    , xmax = as.numeric(ymd(end.date))
    , ymin = (min.discharges * 0.9), ymax = (max.discharges * 1.1)
    , fill = palette_light()[[4]]
    , alpha = 0.01
  ) +
  annotate(
    "text"
    , x = ymd("2012-01-01")
    , y = 1000
    , color = palette_light()[[1]]
    , label = "Training Region"
  ) +
  annotate(
    "text"
    , x = ymd("2017-01-01")
    , y = 1200
    , color = palette_light()[[1]]
    , label = "Testing Region"
  ) +
  geom_point(aes(x = Time, y = cnt),
             data = train,
             alpha = 0.5,
             color = palette_light()[[1]]) +
  # pred_test_fit
  geom_point(aes(x = Time, y = cnt),
             data = pred_test_fit,
             alpha = 0.5,
             color = palette_light()[[1]]) +
  geom_point(aes(x = Time, y = yhat),
             data = pred_test_fit,
             alpha = 0.5,
             color = palette_light()[[2]]) +
  geom_line(
    data = tk_qtr
    , aes(
      x = Time
      , y = cnt
    )
    , alpha = 0.5
  ) +
  geom_line(
    data = pred_test_fit
    , aes(
      x = Time
      , y = yhat
    )
    , color = "blue"
  ) +
  labs(title = "Prediction Set"
       , subtitle = "Model B = fit - Predictions in Red"
       , x = ""
       , y = "Discharges") +
  theme_tq()

# Calc Liner Model Test Err #### 
# Model Error
test_residuals_b <- pred_test_fit$.resid
pct_err_b <- test_residuals_b/pred_test_fit$cnt * 100 # percent error

me_b <- mean(test_residuals_b, na.rm = TRUE)
rmse_b <- mean(test_residuals_b^2, na.rm = TRUE)
mae_b <- mean(abs(test_residuals_b), na.rm = TRUE)
mape_b <- mean(abs(pct_err_b), na.rm = TRUE)
mpe_b <- mean(pct_err_b, na.rm = TRUE)

# Viz lm() Test Residuals ####
# Visaulize the residuals of the test set
# Model 
ggplot(aes(x = Time, y = .resid), data = pred_test_fit) +
  geom_hline(yintercept = 0, color = "red") +
  geom_point(color = palette_light()[[1]], alpha = 0.5) +
  geom_smooth() +
  theme_tq() +
  labs(title = "Test Set: lm() Model Residuals", subtitle = "Model B - fit",
       x = "") 

# Forecast lm() ####
# Extract the index
idx <- tk_qtr %>%
  tk_index()

# Get time series summary from index
tk_qtr_summary <- idx %>%
  tk_get_timeseries_summary()

idx_future <- idx %>%
  tk_make_future_timeseries(n_future = 12)

data_future <- idx_future %>%
  tk_get_timeseries_signature() %>%
  rename(Time = index)

pred_future_fit <- predict(fit, newdata = data_future)

qtr_future_fit <- data_future %>%
  select(Time) %>%
  add_column(cnt = pred_future_fit * 1)

# Model
tk_qtr %>%
  ggplot(aes(x = Time, y = cnt)) +
  geom_rect(
    xmin = as.numeric(ymd(training.stop.date))
    , xmax = as.numeric(ymd(end.date))
    , ymin = (min.discharges * 0.9)
    , ymax = (max.discharges * 1.1)
    , fill = palette_light()[[4]]
    , alpha = 0.01
  ) +
  geom_rect(
    xmin = as.numeric(ymd(end.date))
    , xmax = as.numeric(ymd("2019-07-01"))
    , ymin = (min.discharges * 0.9)
    , ymax = (max.discharges * 1.1)
    , fill = palette_light()[[3]], alpha = 0.01) +
  annotate(
    "text"
    , x = ymd("2011-10-01")
    , y = 1000
    , color = palette_light()[[1]], label = "Train Region") +
  annotate(
    "text"
    , x = ymd("2016-12-01")
    , y = 1200
    , color = palette_light()[[1]], label = "Test Region") +
  annotate(
    "text"
    , x = ymd("2019-01-01")
    , y = 1400
    , color = palette_light()[[1]], label = "Forecast Region") +
  geom_point(
    alpha = 0.5
    , color = palette_light()[[1]]) +
  geom_point(
    aes(x = Time, y = cnt)
    , data = qtr_future_fit
    , alpha = 0.5
    , color = palette_light()[[2]]) +
  geom_smooth(
    aes(x = Time, y = cnt)
    , data = qtr_future_fit
    , method = 'auto') +
  labs(title = "Monthly Discharges Dataset: 12-Month Forecast"
       , subtitle = "Model B = fit"
       , x = "") +
  theme_tq()

# Prediction Error of lm() ####
test_resid_sd_b <- sd(test_residuals_b, na.rm = T)

qtr_future_fit <- qtr_future_fit %>%
  mutate(
    lo.95 = cnt - 1.96 * test_resid_sd_b
    , lo.80 = cnt - 1.28 * test_resid_sd_b
    , hi.80 = cnt + 1.28 * test_resid_sd_b
    , hi.95 = cnt + 1.96 * test_resid_sd_b
  )

# plot prediction intervals
lm.fcast.plt <- tk_qtr %>%
  ggplot(aes(x = Time, y = cnt)) +
  geom_point(
    alpha = 0.5
    , color = palette_light()[[1]]) +
  geom_ribbon(
    aes(ymin = lo.95, ymax = hi.95)
    , data = qtr_future_fit
    , fill = "#D5DBFF"
    , color = NA
    , size = 0
  ) +
  geom_ribbon(
    aes(ymin = lo.80, ymax = hi.80)
    , data = qtr_future_fit
    , fill = "#596DD5"
    , color = NA
    , size = 0
    , alpha = 0.8
  ) +
  geom_point(
    aes(x = Time, y = cnt)
    , data = qtr_future_fit
    , alpha = 0.5
    , color = palette_light()[[2]]
  ) +
  geom_smooth(
    aes(x = Time, y = cnt)
    , data = qtr_future_fit
    , method = "loess"
    , color = "white"
  ) +
  labs(
    title = "Forecast for IP Discharges: 12-Month Forecast"
    , x = ""
    , y = "Discharges"
    , subtitle = ("Linear Model - 12 Month forecast with Prediction Intervals")
  ) +
  theme_tq()
print(lm.fcast.plt)

lm.predictions <- qtr_future_fit

# Forecast with FPP ####
# Forecast with FPP, will need to convert data to an xts/ts object
monthly.discharges <- as_tbl_time(discharges, index = Time)
monthly.discharges <- monthly.discharges %>%
  collapse_by("monthly") %>%
  group_by(Time, add = TRUE) %>%
  summarize(
    cnt = sum(DSCH_COUNT)
  )
# # write file out
# write.csv(monthly.discharges, "monthly_discharges.csv", row.names = FALSE)
# # bring file back in
# fileToLoad <- file.choose(new = TRUE)
# monthly.discharges <- read.csv(fileToLoad)
# rm(fileToLoad)
str(monthly.discharges)

# Create ts Object ####
dsch.count <- ts(
  monthly.discharges$cnt
  , frequency = 12
  , start = c(2010,1)
)

plot.ts(dsch.count)
class(dsch.count)

dsch.count.xts <- as.xts(dsch.count)
head(dsch.count.xts)
dsch.count.sub.xts <- window(dsch.count, start = c(2010,1), end = c(2018,9))
dsch.count.sub.xts

# Get time series components ####
components <- decompose(dsch.count.sub.xts)
names(components)
components$seasonal
plot(components)

# Get stl object ####
compl <- stl(dsch.count.sub.xts, s.window = "periodic")
plot(compl)

# Model using HoltWinters ####
dsch.count.predict.hw <- HoltWinters(dsch.count.sub.xts)
dsch.count.predict.hw
sw_glance(dsch.count.predict.hw)
sw_tidy(dsch.count.predict.hw)
plot(dsch.count.predict.hw)
plot.ts(dsch.count.predict.hw$fitted)

# Forecast using hw() ####
fit_hw <- hw(
  dsch.count.sub.xts
  , h = 12
  , alpha = dsch.count.predict.hw$alpha
  , gamma = dsch.count.predict.hw$gamma
  )
summary(fit_hw)

test_residuals_hw <- fit_hw$residuals
pct_err_hw <- (test_residuals_hw / fit_hw$fitted) * 100 # percent error

me_hw   <- mean(test_residuals_hw, na.rm = TRUE)
rmse_hw <- mean(test_residuals_hw^2, na.rm = TRUE)
mae_hw  <- mean(abs(test_residuals_hw), na.rm = TRUE)
mape_hw <- mean(abs(pct_err_hw), na.rm = TRUE)
mpe_hw  <- mean(pct_err_hw, na.rm = TRUE)

# Vis hw() forecast ####
hw.fcast.plt <- sw_sweep(fit_hw) %>%
  ggplot(
    aes(
      x = index
      , y = value
      , color = key)
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
    , subtitle = "HoltWinters Model - 12 Month forecast with Prediction Intervals"
  ) +
  scale_x_yearmon(n = 12, format = "%Y") +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq() 
print(hw.fcast.plt)

hw.predictions <- sw_sweep(fit_hw)
hw.predictions <- hw.predictions %>%
  filter(hw.predictions$key == 'forecast')

# Seasonal Naive Model ####
fit.snaive <- snaive(dsch.count.sub.xts, h = 12)
snaive.predictions <- sw_sweep(fit.snaive) 
snaive.predictions <- snaive.predictions %>%
  filter(snaive.predictions$key == 'forecast')

snaive.fcast.plt <- autoplot(dsch.count.sub.xts) +
  autolayer(snaive(dsch.count.sub.xts, h = 12),
            series = "Seasonal naive", PI = T) +
  ggtitle("Forecasts for IP Discharges") +
  labs(
    title = "Forecast for IP Discharges: 12-Month Forecast"
    , x = ""
    , y = "Discharges"
    , subtitle = "S-Naive Model - 12 Month forecast with Prediction Intervals"
  ) +
  theme(legend.position = "none") +
  guides(colour = guide_legend(title="Forecast"))
print(snaive.fcast.plt)

# Calculate Errors
test_residuals_snaive <- fit.snaive$residuals
pct_err_snaive <- (test_residuals_snaive / fit.snaive$fitted) * 100 # percent error

me_snaive   <- mean(test_residuals_snaive, na.rm = TRUE)
rmse_snaive <- mean(test_residuals_snaive^2, na.rm = TRUE)
mae_snaive  <- mean(abs(test_residuals_snaive), na.rm = TRUE)
mape_snaive <- mean(abs(pct_err_snaive), na.rm = TRUE)
mpe_snaive  <- mean(pct_err_snaive, na.rm = TRUE)

# ETS Model ####
# Sweep ####
#https://cran.r-project.org/web/packages/sweep/vignettes/SW00_Introduction_to_sweep.html
# ETS Model Train ####
fit.ets.train <- dsch.count %>%
  ets()
summary(fit.ets.train)

fit.ets.train.params   <- sw_tidy(fit.ets.train)
fit.ets.train.accuracy <- sw_glance(fit.ets.train)
fit.ets.train.augment  <- sw_augment(fit.ets.train)
fit.ets.train.decomp   <- sw_tidy_decomp(fit.ets.train)
fit.ets.alpha.train    <- fit.ets.train$par[["alpha"]]
fit.ets.gamma.train    <- fit.ets.train$par[["gamma"]]

fit.ets.train.augment %>%
  ggplot(
    aes(
      x = index
      , y = .resid
    )
  ) +
  geom_hline(
    yintercept = 0
    , color = "grey40"
  ) +
  geom_point(
    color = palette_light()[[1]]
    , alpha = 0.5
  ) +
  geom_smooth(
    method = "auto"
  ) +
  scale_x_yearmon(
    n = 8
  ) +
  labs(
    title = "IP Discharges ETS Training Model Residuals"
    , x = ""
    , y = "Residuals"
  ) +
  theme_tq()

fit.ets.train.decomp %>%
  gather(
    key = key
    , value = value
    , -index
  ) %>%
  mutate(
    key = forcats::as_factor(key)
  ) %>%
  ggplot(
    aes(
      x = index
      , y = value
      , group = key
    )
  ) +
  geom_line(
    color = palette_light()[[2]]
  ) +
  geom_ma(
    ma_fun = SMA
    , n = 12
    , size = 1
  ) +
  facet_wrap(
    ~ key
    , scales = "free_y"
  ) +
  scale_x_yearmon(
    n = 8
  ) +
  labs(
    title = "IP Discharges ETS Training Model Decomposition"
    , x = ""
  ) +
  theme_tq() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# ETS Refine Model ####
fit.ets.ref <- dsch.count %>%
  ets(
    ic = "bic"
    , alpha = fit.ets.alpha.train
    , gamma = fit.ets.gamma.train
    )

fit.ets.ref.params   <- sw_tidy(fit.ets.ref)
fit.ets.ref.accuracy <- sw_glance(fit.ets.ref)
fit.ets.ref.augment  <- sw_augment(fit.ets.ref)
fit.ets.ref.decomp   <- sw_tidy_decomp(fit.ets.ref)
augment.fit.ets.ref <- sw_augment(fit.ets.ref)
decomp.fit.ets.ref <- sw_tidy_decomp(fit.ets.ref)

# Calculate Errors
test_residuals_ets <- fit.ets.ref$residuals
pct_err_ets <- (test_residuals_ets / fit.ets.ref$fitted) * 100 # percent error

me_ets   <- mean(test_residuals_ets, na.rm = TRUE)
rmse_ets <- mean(test_residuals_ets^2, na.rm = TRUE)
mae_ets  <- mean(abs(test_residuals_ets), na.rm = TRUE)
mape_ets <- mean(abs(pct_err_ets), na.rm = TRUE)
mpe_ets  <- mean(pct_err_ets, na.rm = TRUE)

augment.fit.ets.ref %>%
  ggplot(
    aes(
      x = index
      , y = .resid
    )
  ) +
  geom_hline(
    yintercept = 0
    , color = "grey40"
  ) +
  geom_point(
    color = palette_light()[[1]]
    , alpha = 0.5
  ) +
  geom_smooth(
    method = "auto"
  ) +
  scale_x_yearmon(
    n = 8
  ) +
  labs(
    title = "IP Discharges ETS Model Residuals"
    , x = ""
    , y = "Residuals"
  ) +
  theme_tq()

decomp.fit.ets.ref %>%
  gather(
    key = key
    , value = value
    , -index
  ) %>%
  mutate(
    key = forcats::as_factor(key)
  ) %>%
  ggplot(
    aes(
      x = index
      , y = value
      , group = key
    )
  ) +
  geom_line(
    color = palette_light()[[2]]
  ) +
  geom_ma(
    ma_fun = SMA
    , n = 12
    , size = 1
  ) +
  facet_wrap(
    ~ key
    , scales = "free_y"
  ) +
  scale_x_yearmon(
    n = 8
  ) +
  labs(
    title = "IP Discharges ETS Decomposition"
    , x = ""
  ) +
  theme_tq() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# Forecast Model ####
fcast.ets <- fit.ets.ref %>%
  forecast(h = 12)

# Tidy Forecast object ####
ets.predictions <- sw_sweep(fcast.ets, fitted = T)
ets.predictions <- ets.predictions %>%
  filter(ets.predictions$key == 'forecast')

# Visualize
ets.fcast.plt <- sw_sweep(fcast.ets) %>%
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
print(ets.fcast.plt)

# Compare Model Errors ####
qqnorm(fit$residuals)
qqline(fit$residuals)

qqnorm(fit_hw$residuals)
qqline(fit_hw$residuals)

qqnorm(fit.snaive$residuals)
qqline(fit.snaive$residuals)

qqnorm(fit.ets.ref$residuals)
qqline(fit.ets.ref$residuals)

checkresiduals(fit.snaive)
checkresiduals(fit_hw)
checkresiduals(fit)
checkresiduals(fit.ets.ref)

me <- c(me_b, me_hw, me_snaive, me_ets)
rmse <- c(rmse_b, rmse_hw, rmse_snaive, rmse_ets)
mae <- c(mae_b, mae_hw, mae_snaive, mae_ets)
mape <- c(mape_b, mape_hw, mape_snaive, mape_ets)
mpe <- c(mpe_b, mpe_hw, mpe_snaive, mpe_ets)

error.tbl.row.names <- c(
  "LM Model"
  , "HoltWinters"
  , "Seasonal Naive"
  , "ETS"
  )
error_tbl <- data.frame(me, rmse, mae, mape, mpe)
rownames(error_tbl) <- error.tbl.row.names
error_tbl <- tibble::rownames_to_column(error_tbl)
error_tbl <- arrange(error_tbl, error_tbl$mape)
error_tbl

# Pick Model ####
head(error_tbl, 1)

print(lm.fcast.plt)
print(snaive.fcast.plt)
print(hw.fcast.plt)
print(ets.fcast.plt)

gridExtra::grid.arrange(
  lm.fcast.plt
  , snaive.fcast.plt
  , hw.fcast.plt
  , ets.fcast.plt
  )

# Predictions 1 Month Out ####
ets.pred <- head(ets.predictions$value, 1)
ets.pred.lo.95 <- head(ets.predictions$lo.95, 1)
ets.pred.hi.95 <- head(ets.predictions$hi.95, 1)

hw.pred  <- head(hw.predictions$value, 1)
hw.pred.lo.95 <- head(hw.predictions$lo.95, 1)
hw.pred.hi.95 <- head(hw.predictions$hi.95, 1)

lm.pred  <- head(lm.predictions$cnt, 1)
lm.pred.lo.95 <- head(lm.predictions$lo.95, 1)
lm.pred.hi.95 <- head(lm.predictions$hi.95, 1)

sn.pred  <- head(snaive.predictions$value, 1)
sn.pred.lo.95 <- head(snaive.predictions$lo.95, 1)
sn.pred.hi.95 <- head(snaive.predictions$hi.95, 1)

mod.pred <- c(ets.pred, hw.pred, lm.pred, sn.pred)
mod.pred.lo.95 <- c(ets.pred.lo.95, hw.pred.lo.95, lm.pred.lo.95, sn.pred.lo.95)
mod.pred.hi.95 <- c(ets.pred.hi.95, hw.pred.hi.95, lm.pred.hi.95, sn.pred.hi.95)

pred.tbl.row.names <- c(
  "ETS"
  , "HoltWinters"
  , "Linear Model"
  , "S-Naive"
)

pred.tbl <- data.frame(mod.pred, mod.pred.lo.95, mod.pred.hi.95)
rownames(pred.tbl) <- pred.tbl.row.names
pred.tbl <- tibble::rownames_to_column(pred.tbl)
pred.tbl

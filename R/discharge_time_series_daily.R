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
ta.discharges

#timetk Daily
tk_d <- tk_ts(ta.discharges,
              start = 2010,
              frequency = 365
)
class(tk_d)

timetk_index <- tk_index(tk_d, timetk_idx = TRUE)
head(timetk_index)
class(timetk_index)
has_timetk_idx(tk_d)

tk_qtr <- ta.discharges %>%
  collapse_by("monthly") %>%
  group_by(Time, add = TRUE) %>%
  summarize(
    cnt = sum(DSCH_COUNT)
  )
tk_qtr

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
train

test <- tk_qtr %>%
  filter(Time >= training.stop.date)
test

# Add time series signature to train
train_augmented <- train %>%
  tk_augment_timeseries_signature()
train_augmented

# Add time series signature to test
test_augmented <- test %>%
  tk_augment_timeseries_signature()
test_augmented

# Linear Models of Data ####
# Model using the augmented features
fit_lm <- lm(cnt ~ ., data = train_augmented)
summary(fit_lm)
plot(fit_lm)

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
fit_lm %>%
  augment() %>%
  ggplot(aes(x = Time, y = .resid)) +
  geom_hline(yintercept = 0, color = "red") +
  geom_point(color = palette_light()[[1]], alpha = 0.5) +
  geom_smooth(method = "auto") +
  theme_tq() +
  labs(title = "Training Set: lm() Model Residuals"
       , x = ""
       , subtitle = "Model = fit_lm")

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
sqrt(mean(fit_lm$residuals^2))
sqrt(mean(fit$residuals^2))

sw_glance(fit_lm)
sw_glance(fit)

# Linear Model on Test Data ####
# apply the model to the test set
yhat_test_fit_lm <- predict(fit_lm, newdata = test_augmented)
summary(yhat_test_fit_lm)
pred_test_fit_lm <- test %>%
  add_column(yhat = yhat_test_fit_lm) %>%
  mutate(.resid = cnt - yhat)

yhat_test_fit <- predict(fit, newdata = test_augmented)
summary(yhat_test_fit)
pred_test_fit <- test %>%
  add_column(yhat = yhat_test_fit) %>%
  mutate(.resid = cnt - yhat)

# Viz Model on Test Data ####
# Model 1 fit_lm
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
  # pred_test_fit_lm - model 1
  geom_point(aes(x = Time, y = cnt),
             data = pred_test_fit_lm,
             alpha = 0.5,
             color = palette_light()[[1]]) +
  geom_point(aes(x = Time, y = yhat),
             data = pred_test_fit_lm,
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
    data = pred_test_fit_lm
    , aes(
      x = Time
      , y = yhat
    )
    , color = "blue"
  ) +
  labs(title = "Prediction Set"
       , subtitle = "Model A = fit_lm - Predictions in Red"
       , x = ""
       , y = "") +
  theme_tq()

# Model 2 fit
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
  # pred_test_fit - model 2
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
       , y = "") +
  theme_tq()

# Calc Liner Model Test Err #### 
# Model A
test_residuals_a <- pred_test_fit_lm$.resid
pct_err_a <- test_residuals_a/pred_test_fit_lm$cnt * 100 # percent error

me_a <- mean(test_residuals_a, na.rm = TRUE)
rmse_a <- mean(test_residuals_a^2, na.rm = TRUE)
mae_a <- mean(abs(test_residuals_a), na.rm = TRUE)
mape_a <- mean(abs(pct_err_a), na.rm = TRUE)
mpe_a <- mean(pct_err_a, na.rm = TRUE)

# Model B
test_residuals_b <- pred_test_fit$.resid
pct_err_b <- test_residuals_b/pred_test_fit$cnt * 100 # percent error

me_b <- mean(test_residuals_b, na.rm = TRUE)
rmse_b <- mean(test_residuals_b^2, na.rm = TRUE)
mae_b <- mean(abs(test_residuals_b), na.rm = TRUE)
mape_b <- mean(abs(pct_err_b), na.rm = TRUE)
mpe_b <- mean(pct_err_b, na.rm = TRUE)

error.tbl.row.names <- c("Model A", "Model B")
me <- c(me_a, me_b)
rmse <- c(rmse_a, rmse_b)
mae <- c(mae_a, mae_b)
mape <- c(mape_a, mape_b)
mpe <- c(mpe_a, mpe_b)

error_tbl <- data.frame(me, rmse, mae, mape, mpe)
rownames(error_tbl) <- error.tbl.row.names
error_tbl

# Viz lm() Test Res ####
# Visaulize the residuals of the test set
# Model A
ggplot(aes(x = Time, y = .resid), data = pred_test_fit_lm) +
  geom_hline(yintercept = 0, color = "red") +
  geom_point(color = palette_light()[[1]], alpha = 0.5) +
  geom_smooth() +
  theme_tq() +
  labs(title = "Test Set: lm() Model Residuals", subtitle = "Model A - fit_lm"
       ,x = "")

# Model B
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

tk_qtr_summary[1:6]
tk_qtr_summary[7:12]

idx_future <- idx %>%
  tk_make_future_timeseries(n_future = 12)

data_future <- idx_future %>%
  tk_get_timeseries_signature() %>%
  rename(Time = index)

pred_future_fit_lm <- predict(fit_lm, newdata = data_future)
pred_future_fit <- predict(fit, newdata = data_future)

qtr_future_fit_lm <- data_future %>%
  select(Time) %>%
  add_column(cnt = pred_future_fit_lm * -1)

qtr_future_fit <- data_future %>%
  select(Time) %>%
  add_column(cnt = pred_future_fit * -1)

# Model A
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
    , xmax = as.numeric(ymd("2019-02-01"))
    , ymin = 0, ymax = 100
    , fill = palette_light()[[3]], alpha = 0.01) +
  annotate(
    "text"
    , x = ymd("2011-10-01")
    , y = 78
    , color = palette_light()[[1]], label = "Train Region") +
  annotate(
    "text"
    , x = ymd("2012-10-01")
    , y = 150
    , color = palette_light()[[1]], label = "Test Region") +
  annotate(
    "text"
    , x = ymd("2013-4-01")
    , y = 150
    , color = palette_light()[[1]], label = "Forecast Region") +
  geom_point(
    alpha = 0.5
    , color = palette_light()[[1]]) +
  geom_point(
    aes(x = Time, y = cnt)
    , data = qtr_future_fit_lm
    , alpha = 0.5
    , color = palette_light()[[2]]) +
  geom_smooth(
    aes(x = Time, y = cnt)
    , data = qtr_future_fit_lm
    , method = 'loess') + 
  labs(title = "Monthly Discharges Dataset: 6-Month Forecast"
       , subtitle = "Model A - fit_lm"
       , x = "") +
  theme_tq()

# Model B
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
  labs(title = "Monthly Discharges Dataset: 6-Month Forecast"
       , subtitle = "Model B = fit"
       , x = "") +
  theme_tq()

# Prediction Error of lm() ####
test_resid_sd_a <- sd(test_residuals_a, na.rm = T)
test_resid_sd_b <- sd(test_residuals_b, na.rm = T)

qtr_future_fit_lm <- qtr_future_fit_lm %>%
  mutate(
    lo.95 = cnt - 1.96 * test_resid_sd_a
    , lo.80 = cnt - 1.28 * test_resid_sd_a
    , hi.80 = cnt + 1.28 * test_resid_sd_a
    , hi.95 = cnt + 1.96 * test_resid_sd_a
  )

qtr_future_fit <- qtr_future_fit %>%
  mutate(
    lo.95 = cnt - 1.96 * test_resid_sd_b
    , lo.80 = cnt - 1.28 * test_resid_sd_b
    , hi.80 = cnt + 1.28 * test_resid_sd_b
    , hi.95 = cnt + 1.96 * test_resid_sd_b
  )

# plot prediction intervals
tk_qtr %>%
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
    title = "Monthly Discharges Dataset: 12-Month Forecast with Prediction Intervals"
    , x = ""
  ) +
  theme_tq()

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
dsch.count.sub.xts <- window(dsch.count, start = c(2010,1), end = c(2018,8))
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
plot(dsch.count.predict.hw)
plot.ts(dsch.count.predict.hw$fitted)
dsch.count.predict.hw$SSE

# Forecast using hw() ####
fit_hw <- hw(
  dsch.count.sub.xts
  , h = 12
  , alpha = dsch.count.predict.hw$alpha
  , gamma = dsch.count.predict.hw$gamma
  )
summary(fit_hw)

# Vis hw() forecast ####
sw_sweep(fit_hw) %>%
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
    title = "IP Discharges: HoltsWinter Filtering Model"
    , x = "Time"
    , y = "Discharges"
    , subtitle = "Regular Time Index"
    ) +
  scale_x_yearmon(n = 12, format = "%Y") +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq() 

plot(fit_hw$residuals)
qqnorm(fit_hw$residuals)
qqline(fit_hw$residuals)

# Seasonal Naive Model ####
fit.snaive <- snaive(dsch.count.sub.xts)
autoplot(dsch.count.sub.xts) +
  autolayer(snaive(dsch.count.sub.xts, h = 12),
            series = "Seasonal naive", PI = T) +
  ggtitle("Forecasts for IP Discharges") +
  guides(colour = guide_legend(title="Forecast"))

checkresiduals(snaive(dsch.count.sub.xts))
checkresiduals(fit_hw)
checkresiduals(fit)


# ETS Model ####
# Sweep ####
#https://cran.r-project.org/web/packages/sweep/vignettes/SW00_Introduction_to_sweep.html
# Plt Data 
head(monthly.discharges, 5)
monthly.discharges %>%
  ggplot(
    aes(
      x = Time
      , y = cnt
    )
  ) +
  geom_line(
    size = 1
    , color = palette_light()[[1]]
  ) +
  geom_smooth(
    method = "auto"
  ) +
  labs(
    title = "IP Discharges"
    , x = "Time"
    , y = "Count"
  ) +
  theme_tq()

# Coerce to ts objects ####
ets.train <- tk_ts(train)
ets.test <- tk_ts(test)
class(ets.train)
class(ets.test)

# ETS Model Train ####
fit.ets.train <- ets.train %>%
  ets()

fit.ets.train.params <- sw_tidy(fit.ets.train)
fit.ets.train.accuracy <- sw_glance(fit.ets.train)
fit.ets.train.augment <- sw_augment(fit.ets.train)
fit.ets.train.decomp <- sw_tidy_decomp(fit.ets)
fit.ets.alpha.train = fit.ets.train$par[["alpha"]]

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

# ETS Model Test ####
fit.ets.test <- ets.test %>%
  ets()

fit.ets.test.params <- sw_tidy(fit.ets.train)
fit.ets.test.accuracy <- sw_glance(fit.ets.train)
fit.ets.test.augment <- sw_augment(fit.ets.train)
fit.ets.test.decomp <- sw_tidy_decomp(fit.ets)
fit.ets.alpha.test = fit.ets.test$par[["alpha"]]

fit.ets.test.augment %>%
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
    title = "IP Discharges ETS Test Model Residuals"
    , x = ""
    , y = "Residuals"
  ) +
  theme_tq()

fit.ets.test.decomp %>%
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
    title = "IP Discharges ETS Testing Model Decomposition"
    , x = ""
  ) +
  theme_tq() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# ETS Refine Model ####
fit.ets <- monthly.discharges.tk.ts %>%
  ets(model = "MAM", ic = "bic", alpha = fit.ets.alpha, gamma = fit.ets.gamma)

sw_tidy(fit.ets)
sw_glance(fit.ets)
sw_augment(fit.ets)
sw_tidy_decomp(fit.ets)
augment.fit.ets.ref <- sw_augment(fit.ets)
decomp.fit.ets.ref <- sw_tidy_decomp(fit.ets)

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
fcast.ets <- fit.ets %>%
  forecast(h = 12)

checkresiduals(fit.ets)

# Tidy Foecast object ####
sw_sweep(fcast.ets, fitted = T)

# Visualize
sw_sweep(fcast.ets) %>%
  ggplot(
    aes(
      x = index
      , y = cnt
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
    title = "IP Discharges ETS Model Forecast"
    , x = ""
    , y = "Discharges"
    , subtitle = "Regular Time Index"
  ) +
  scale_x_yearmon(
    n = 12
    , format = "%Y"
  ) +
  scale_color_tq() +
  scale_fill_tq() +
  theme_tq()

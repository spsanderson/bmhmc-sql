# Lib Load ####
library(xts)
library(fpp)
library(forecast)
library(lubridate)
library(dplyr)

# Data Load ####
file.to.load <- file.choose(new = T)
df <- read.csv(file.to.load)
rm(file.to.load)

# Run time_series_eda file ####
# Run time_series_eda file, after it is done make a new df
df.trans <- df2
df.trans$Time <- lubridate::mdy(df.trans$Time)
head(df.trans)

# Create ts() object ####
# Turn df.trans into a ts object
df.ts <- msts(df.trans, seasonal.periods = c(7,365.25))
fit <- tbats(df.ts)
fc <- forecast(fit)
plot(fc)
class(df.ts)
head(df.ts, 3)
tail(df.ts, 3)

# Time Series Plots ####
# Auto plot
auto.plot <- autoplot(df.ts[,"DSCH_COUNT"]) +
  ggtitle("Discharge Counts by Week") +
  xlab("Year") +
  ylab("Count")
auto.plot  

# ggseasonplot
season.plot <- ggseasonplot(
  df.ts[,"DSCH_COUNT"]
  , year.labels = T
  , year.labels.left = T
  ) +
  ylab("Discharge Count") +
  ggtitle("Discharge Counts by Week")
season.plot

season.polar <- ggseasonplot(
  df.ts[,"DSCH_COUNT"]
  , polar = T
) +
  ylab("Discharge Count") +
  ggtitle("Discharge Counts by Week")
season.polar

# Seasonal Subseries Plots
sub.season.plot <- ggsubseriesplot(df.ts[,"DSCH_COUNT"]) +
  ylab("Discharge Count") +
  ggtitle("Seasonal subseries plot: Discharge Counts")
sub.season.plot

# Auto Correlation
ac.plot <- ggAcf(df.ts[,"DSCH_COUNT"])
ac.plot

# Forecasting Methods ####
df.ts.sub <- window(df.ts, start = c(2010, 1), end = c(2018, 11))
multi.forecast.plot <- autoplot(df.ts.sub[,"DSCH_COUNT"]) +
  autolayer(meanf(df.ts.sub[,"DSCH_COUNT"], h = 12)
            , series = "Mean", PI = F) +
  autolayer(naive(df.ts.sub[,"DSCH_COUNT"], h = 12)
            , series = "Naive", PI = F) +
  autolayer(snaive(df.ts.sub[,"DSCH_COUNT"], h = 12)
            , series = "Seasonal Naive", PI = F) +
  ggtitle("Forecasts for Weekly Discharges") +
  xlab("Week") +
  guides(colour = guide_legend(title = "Forecast"))
multi.forecast.plot  

sres <- residuals(snaive(df.ts[,"DSCH_COUNT"]))
checkresiduals(snaive(df.ts[,"DSCH_COUNT"]))

# Create Test Set
obs <- as.numeric(nrow(df.ts))
train.size <- obs * 0.8
test.size <- obs - train.size
df.ts.train <- head(df.ts, train.size)
df.ts.test <- tail(df.ts, test.size)

df.ts.fit <- snaive(df.ts.train[,"DSCH_COUNT"], h = test.size)

autoplot(df.ts[,"DSCH_COUNT"], start = 2010) +
  autolayer(df.ts.fit, series = "Seasonal Naive", PI = F)

accuracy(f = df.ts.fit, x = df.ts.test[,"DSCH_COUNT"])

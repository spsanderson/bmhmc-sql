# Time Series Analysis on Monthly Discharge Data - Inpatients
library(timetk)
library(sweep)
library(tibbletime)
library(anomalize)
library(xts)
library(ffp)
library(forecast)

fileToLoad <- file.choose(new = TRUE)
monthly.discharges <- read.csv(fileToLoad)
rm(fileToLoad)
str(monthly.discharges)

dsch.count <- ts(
  monthly.discharges$DSCH_COUNT
  , frequency = 12
  , start = c(2010,1)
  )

avg.pmts <- ts(
  monthly.discharges$Avg_Pmts
  , frequency = 12
  , start = c(2010,1)
  , end = c(2018,3)
)

avg.chgs <- ts(
  monthly.discharges$Avg_Chgs
  , frequency = 12
  , start = c(2010,1)
)

plot.ts(dsch.count)
plot.ts(avg.chgs)
plot.ts(avg.pmts)

class(dsch.count)
class(avg.pmts)
class(avg.chgs)

dsch.count
avg.pmts
avg.chgs

# Making a subset using window() of dsch.count
dsch.count2 <- window(dsch.count, start = c(2010, 2), end = c(2014, 2))
dsch.count2

# Convert entire data.frame into a ts object
dsch.count.ts <- ts(monthly.discharges[,-1], start = c(2010,1), frequency = 12)
class(dsch.count.ts)
head(dsch.count.ts)
dsch.count.ts[,"Avg_Chgs"]

dsch.count.xts <- as.xts(dsch.count)
head(dsch.count.xts)
dsch.count.sub.xts <- window(dsch.count, start = c(2010,1), end = c(2018,7))
dsch.count.sub.xts

# Plots
plot.ts(dsch.count)
plot.ts(dsch.count.ts, plot.type = "multiple")
plot.ts(dsch.count.ts, plot.type = "single", col = c("red","blue","green","orange"))
plot.ts(dsch.count.ts[,"Avg_Chgs"])
plot.ts(dsch.count.ts[,"Avg_Pmts"])

components <- decompose(dsch.count.sub.xts)
names(components)
components$seasonal
plot(components)

compl <- stl(dsch.count.sub.xts, s.window = "periodic")
names(compl)
plot(compl)

dsch.count.pre <- HoltWinters(dsch.count)
dsch.count.pre
plot(dsch.count.pre)
dsch.count.pre$SSE

# Make forecasts by using the prediction function within the fpp package
fit <- hw(dsch.count,seasonal="additive", h = 6)
summary(fit)

plot.ts(dsch.count)
lines(fitted(fit), col = "red")
plot(fit)

# using the forecast package
dsch.pre <- forecast(dsch.count.pre, h = 6)
summary(dsch.pre)
plot(dsch.pre)
plot(dsch.pre$residuals)
acf(dsch.pre$residuals, type = "correlation", plot = TRUE, na.action = na.pass)

Box.test(dsch.pre$residuals)

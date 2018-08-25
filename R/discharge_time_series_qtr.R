# Time Series analysis on Quarterly Discharge Data - Inpatients
library(timetk)
library(sweep)
library(tibbletime)
library(anomalize)
library(xts)
library(ffp)
library(forecast)

fileToLoad <- file.choose(new = TRUE)
Qtr.discharges <- read.csv(fileToLoad)
rm(fileToLoad)

#timetk
tk_qd <- tk_ts(Qtr.discharges,
               start = 2010,
               frequency = 4)

# ts
m <- ts(Qtr.discharges$DSCH_COUNT, frequency = 4, start = c(2010,1))
class(m)
head(m)
m
plot(m)
plot.ts(m)

m_ts <- ts(Qtr.discharges[,-1], start = c(2010,1), frequency = 4)
class(m_ts)
head(m_ts)

m.xts <- as.xts(m)
head(m.xts)
plot.xts(m.xts)

m.sub <- window(m, start = c(2010,1), end = c(2018,2))
m.sub
plot(m.sub)

components <- decompose(m.sub)
names(components)
components$seasonal
plot(components)

compl <- stl(m.sub, s.window = "periodic")
names(compl)
plot(compl)

m.pre <- HoltWinters(m)
m.pre
plot(m.pre)
m.pre$SSE

# Make forecasts by using the prediction function within the fpp package

fit <- hw(m,seasonal="additive")
summary(fit)

plot.ts(m)
lines(fitted(fit), col = "red")
plot(fit)


dsch.pre <- forecast(m.pre, h = 4)
summary(dsch.pre)
plot(dsch.pre)
plot(dsch.pre$residuals)
acf(dsch.pre$residuals, type = "correlation", plot = TRUE, na.action = na.pass)

Box.test(dsch.pre$residuals)

# Selecting an ARIMA Model
# First, simulate an ARIMA process and generate ts data
set.seed(123)
ts.sim <- arima.sim(list(order = c(1,1,0), ar = 0.7), n = 100)
plot(ts.sim)
# Take diff of ts
ts.sim.diff <- diff(ts.sim)
plot(ts.sim.diff)
acf(ts.sim.diff)
pacf(ts.sim.diff)

tsdisplay(ts.sim.diff)
ggtsdisplay(ts.sim.diff)

fit <- Arima(ts.sim, order = c(1,1,0))
fit
accuracy(fit)
auto.arima(ts.sim, ic = "bic")
fit2 <- arima(ts.sim)
summary(fit2)

fit.predict <- forecast(fit)
summary(fit.predict)
plot(fit.predict)
acf(fit.predict$residuals)
Box.test(fit.predict$residuals)

tsdiag(fit)
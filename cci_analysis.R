require(quantmod)
require(PerformanceAnalytics)
require(lubridate)
require(tidyverse)

cci <- read.csv("cci30_OHLC.csv", header = TRUE)
str(cci)
cci$Date <- as.Date(cci$Date)
str(cci)
cci_df <- xts(cci[,-1], order.by = as.Date(cci[,1], "%Y/%m/%d"))
str(cci_df)
cci_df$Close <- as.numeric(cci_df$Close)

PerformanceAnalytics::SharpeRatio(cci_df[,4,drop=FALSE])
PerformanceAnalytics::SharpeRatio.annualized(cci_df[,4,drop=FALSE])
PerformanceAnalytics::InformationRatio(cci_df[,"Close", drop = FALSE],
                                       managers[, "SP500 TR", drop=FALSE])

require(coinmarketcapr)
coinmarketcapr::plot_top_5_currencies()

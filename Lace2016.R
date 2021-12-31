library(aod)
library(ggplot2)
library(Rcpp)

LaceData <- read.csv("Lace2016.csv", header = TRUE)
head(LaceData)
summary(LaceData)

InterimPlot <- ggplot(data = LaceData, aes(x = INTERIM))
InterimPlot <- InterimPlot + geom_histogram(
  binwidth = 1, fill = "white", color = "black", boundary = 0
  )


InterimDays <- na.omit(LaceData$INTERIM)
InterimDays <- as.numeric(InterimDays)

n = 50000
mean_alos = rep(NA, n)
for (i in 1:n) {
  samp = sample(InterimDays, 100)
  mean_alos[i] = mean(samp)
}
hist(mean_alos)
mean(mean_alos)

InterimPlot + geom_vline(xintercept = mean(mean_alos))

xtabs(~ readmit_flag + modflaceval, data = LaceData)

LaceData$modflaceval <- factor(LaceData$modflaceval)
MyLogit <- glm(
  readmit_flag ~ modflaceval, data = LaceData,
  family = "binomial"
)

summary(MyLogit)

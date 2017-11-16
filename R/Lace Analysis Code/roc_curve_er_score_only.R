# ROC curve and other analysis for the LACE Tool
# Load in the ROCR library
library(ROCR)
# Import data
lace <- read.csv("lace for R.csv")

# Creat predictions values and performance values
pred <- prediction(lace$LACE.ER.SCORE, lace$FAILURE)
perf <- performance(pred, "tpr", "fpr")
plot(perf, colorize=T, lwd=3, 
     main = 'ROC Curve for LACE ER Score', type='b')
abline(v=0.275, h=0.85)
abline(v=0.325, h=0.95)
AUC <- performance(pred, 'auc')
AUC
#######################################################################
perf <- performance(pred, 'rpp', 'err')
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "phi", 'err')
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "f", "err")
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "f", "ppv")
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "mat", "ppv")
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "npv", "ppv")
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "acc", "phi")
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "lift", "phi")
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "f", "phi")
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "mi", "phi")
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "acc", "mi")
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "fall", "odds")
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "tpr", "lift")
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "fall", "lift")
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "npv", "f")
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "prec", "f")
plot(perf, colorize=T, lwd=2)

perf <- performance(pred, "tpr", "f")
plot(perf, colorize=T, lwd=2)

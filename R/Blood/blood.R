# require the ggplot2 library
library(ggplot2)
library(XLConnect)
library(sqldf)
library(grid)
library(gridExtra)
library(lattice)
library(car)

# read in blood order data from soarian
mdorders <- read.csv("MDORDERS.csv")
summary(mdorders)

# Get a boxplot of the UNITS ordered data
boxplot(mdorders$UNITS,
        main = "Boxplot of Units of Bld Products Ordered from Soarian")
# Get rid of data that falls more than 3 standard deviations out and 
# UNITS > 0
mdord <- mdorders[mdorders$UNITS < 3*sd(mdorders$UNITS) & 
                    mdorders$UNITS > 0,]
summary(mdord)
# Recheck boxplot and look at histogram
boxplot(mdord$UNITS,
        main = "Boxplot of Units of Bld Product Ordered from Soarian")
hist(mdord$UNITS,
     main = "Histogram of Units of Bld Products Ordered from Soarian")

# Segragate the outliers into their own object
mdord_ol <- mdorders[mdorders$UNITS >= 3*sd(mdorders$UNITS),]
# Boxplot all of the outliers
boxplot(mdord_ol$UNITS,
        main = "Boxplot of Outliers")
hist(mdord_ol$UNITS,
     main = "Histogram of Outliers")

#
qplot(UNITS,
      geom = "histogram",
      binwidth = 0.5,
      color = as.factor(UNITS),
      fill = as.factor(UNITS),
      facets = PERFORMING.DEPT ~ .,
      xlim = c(1,4.5),
      data = mdord)

qplot(UNITS,
      geom = "histogram",
      binwidth = 0.5,
      color = as.factor(UNITS),
      fill = as.factor(UNITS),
      facets = SERVICE.DESC ~ .,
      xlim = c(1,4.5),
      data = mdord)

rbc <- read.csv("rbc hgb.csv", header = T)
# get rid of nulls
rbc <- rbc[rbc$Result_Value_After != 'NULL',]

summary(rbc)

rbc$Result_Value_After <- as.numeric(rbc$Result_Value_After)

meanrbc <- mean(rbc$Result_Value_After)
sdrbc <- sd(rbc$Result_Value_After)
rbcul <- meanrbc + 3*sdrbc
data <- rbc[rbc$Result_Value_After < rbcul &
              rbc$Result_Value_After > 0,]
summary(data)

hist(data$Result_Value_Before,
     xlab = "HGB Value Before RBC",
     main = "HGB Values Before RBC Transfuse")
abline(v=7.0, col = "red", lty = 3)

ggplot(data,
       aes(x = Result_Value_Before,
           y = ..count..)) + 
  geom_histogram(binwidth = 0.25,
                 alpha = 0.5,
                 colour = "blue",
                 fill = "blue") + 
  geom_vline(xintercept = 7.0,
             colour = "red",
             linetype = "longdash") + 
  xlab("HGB Result Value Before RBC") +
  labs(title = "HGB Results Before RBC XFUSE")

ggplot(data,
       aes(x = Result_Value_After,
           y = ..count..)) +
  geom_histogram(binwidth = 0.25,
                 alpha = 0.5,
                 colour = "black",
                 fill = "black") +
  geom_vline(xintercept = 7.0,
             colour = "red",
             linetype = "longdash") + 
  xlab("HGB Result After RBC") + 
  labs(title = "HGB Result After RBC XFUSE")

#######################################################################
# Both before and after on same graph
#######################################################################
before <- ggplot(rbc,
                 aes(x = Result_Value_Before,
                     y = ..count..)) +
  geom_histogram(fill = "red",
                 colour = "black",
                 alpha = 0.618) +
  geom_vline(xintercept = 7.0,
             linetype = "dashed",
             colour = "black") + 
  geom_vline(xintercept = 9.0,
             linetype = "solid",
             colour = "black") +
  xlab("HGB Result Before RBC Transfusion") +
  ylab("Frequency") +
  ggtitle("Hemaglobin Results Before RBC Transfusion")
#before

after <- ggplot(rbc,
                aes(x = Result_Value_After,
                    y = ..count..)) +
  geom_histogram(fill = "green",
                 colour = "black",
                 alpha = 0.618) + 
  xlab("HGB Result After RBC Transfusion") +
  ylab("Frequency") +
  ggtitle("Hemaglobin Results Before RBC Transfusion")
#after

grid.arrange(before, after, nrow = 2, ncol = 1)


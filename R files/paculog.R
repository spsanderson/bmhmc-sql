# We will use the ggplot2 library so call it in
library(ggplot2)
# Reading in all of the data
data <- read.csv("Monthly PACU LOG.csv")
summary(data)

# Now we only want data where the condition is I, II or III
data <- data[data$Condition %in% c("I","II","III"),]
summary(data)

# As of now we only want 2014
data <- data[data$Year==2014,]
summary(data)

# Get rid of accounts that have negative LOS as it makes no sense
data <- data[data$LOS.min >=0,]
summary(data)

# Data of those that fall over or under the two hour mark grouped by Month
ggplot(data, 
       aes(x = X2.hrs.and.greater,
           y= ..count..)) +
  geom_histogram(binwidth = 0.5,
                 linetype = "dashed",
                 alpha = 0.5,
                 aes(colour = as.factor(X2.hrs.and.greater),
                     fill = as.factor(X2.hrs.and.greater))) +
  facet_wrap(~Month) +
  xlim(0,1.5) +
  xlab("0 = Under 2 Hours, 1 = Over 2 Hours") +
  ylab("Frequency") + 
  labs(title = "Histogram of Counts of Patients for Two Hours and Greater
       by Month")

# Grouped by Day of Week and Month
ggplot(data,
       aes(x = Weekday,
           y = ..count..)) +
  geom_histogram(binwidth = 0.5,
                 linetype = "dashed",
                 alpha = 0.5,
                 aes(colour = as.factor(X2.hrs.and.greater),
                     fill = as.factor(X2.hrs.and.greater)),
                 position = "dodge") +
  facet_wrap(~Month) +
  xlim(1, 7.5) +
  xlab("0 = Under 2 Hours, 1 = Over 2 Hours") +
  ylab("Frequency") +
  labs(title = "Histogram of Counts of Patients for Two Hours and Greater
       by Month and Weekday")

# Data of those that fall over or under the three hour mark grouped by Month
ggplot(data, 
       aes(x = X3.hrs.and.greater,
           y= ..count..)) +
  geom_histogram(binwidth = 0.5,
                 linetype = "dashed",
                 alpha = 0.5,
                 aes(colour = as.factor(X3.hrs.and.greater),
                     fill = as.factor(X3.hrs.and.greater))) +
  facet_wrap(~Month) +
  xlim(0,1.5) +
  xlab("0 = Under 3 Hours, 1 = Over 3 Hours") +
  ylab("Frequency") + 
  labs(title = "Histogram of Counts of Patients for Three Hours and Greater
       by Month")

# Grouped by Day of Week and Month
ggplot(data,
       aes(x = Weekday,
           y = ..count..)) +
  geom_histogram(binwidth = 0.5,
                 linetype = "dashed",
                 alpha = 0.5,
                 aes(colour = as.factor(X3.hrs.and.greater),
                     fill = as.factor(X3.hrs.and.greater)),
                 position = "dodge") +
  facet_wrap(~Month) +
  xlim(1, 7.5) +
  xlab("0 = Under 3 Hours, 1 = Over 3 Hours") +
  ylab("Frequency") +
  labs(title = "Histogram of Counts of Patients for Three Hours and Greater
       by Month and Weekday")

# Data of those that fall over or under the four hour mark grouped by Month
ggplot(data,
       aes(x = X4.hrs.and.greater,
           y = ..count..)) +
  geom_histogram(binwidth = 0.5,
                 linetype = "dashed",
                 alpha = 0.5,
                 aes(colour = as.factor(X4.hrs.and.greater),
                     fill = as.factor(X4.hrs.and.greater))) +
  facet_wrap(~Month) +
  xlim(0,1.5) +
  xlab("0 = Under 4 Hours, 1 = Over 4 Hours") +
  ylab("Frequency") +
  labs(title = "Histogram of Counts of Patients for Four Hours and Greater
       by Month")

# Grouped by Day of Week and Month
ggplot(data,
       aes(x = Weekday,
           y = ..count..)) +
  geom_histogram(binwidth = 0.5,
                 linetype = "dashed",
                 alpha = 0.5,
                 aes(colour = as.factor(X4.hrs.and.greater),
                     fill = as.factor(X4.hrs.and.greater)),
                 position = "dodge") +
  facet_wrap(~Month) +
  xlim(1, 7.5) +
  xlab("0 = Under 4 Hours, 1 = Over 4 Hours") +
  ylab("Frequency") +
  labs(title = "Histogram of Counts of Patients for Four Hours and Greater
       by Month and Weekday")

# Data of those that fall over or under the eight hour mark grouped by Month
ggplot(data,
       aes(x = X8.hrs.and.greater,
           y = ..count..)) +
  geom_histogram(binwidth = 0.5,
                 linetype = "dashed",
                 alpha = 0.5,
                 aes(colour = as.factor(X8.hrs.and.greater),
                     fill = as.factor(X8.hrs.and.greater))) +
  facet_wrap(~Month) +
  xlim(0,1.5) +
  xlab("0 = Under 4 Hours, 1 = Over 4 Hours") +
  ylab("Frequency") +
  labs(title = "Histogram of Counts of Patients for Eight Hours and Greater
       by Month")

# Grouped by Day of Week and Month
ggplot(data,
       aes(x = Weekday,
           y = ..count..)) +
  geom_histogram(binwidth = 0.5,
                 linetype = "dashed",
                 alpha = 0.5,
                 aes(colour = as.factor(X8.hrs.and.greater),
                     fill = as.factor(X8.hrs.and.greater)),
                 position = "dodge") +
  facet_wrap(~Month) +
  xlim(1, 7.5) +
  xlab("0 = Under 4 Hours, 1 = Over 4 Hours") +
  ylab("Frequency") +
  labs(title = "Histogram of Counts of Patients for Eight Hours and Greater
       by Month and Weekday")

# Data for the Late Code category
ggplot(data,
       aes(x = Late.Code,
           y = ..count..)) +
  geom_histogram(binwidth = 0.5,
                 linetype = "dashed",
                 alpha = 0.5,
                 aes(colour = as.factor(Late.Code),
                     fill = as.factor(Late.Code))) +
  facet_wrap(~Month) +
  xlim(0,8.5) +
  xlab("Zero to Over Eight hours") +
  ylab("Frequency") +
  labs(title = "Histogram of Counts of Patients for Late Codes by Month")

# Grouped by Day of Week and Month
ggplot(data,
       aes(x = Weekday,
           y = ..count..)) +
  geom_histogram(binwidth = 0.5,
                 linetype = "dashed",
                 alpha = 0.5,
                 aes(colour = as.factor(Late.Code),
                     fill = as.factor(Late.Code)),
                 position = "dodge") +
  facet_wrap(~Month) +
  xlim(1, 7.5) +
  xlab("Zero to Eight Hours Late") +
  ylab("Frequency") +
  labs(title = "Histogram of Counts of Patients for Zero to Eight Hours
       Late by Month and Weekday")

# Objects for 2, 3, 4 and 8 hours over
hrs2 <- data[data$LOS.min >= 120,]
hrs3 <- data[data$LOS.min >= 180,]
hrs4 <- data[data$LOS.min >= 240,]
hrs8 <- data[data$LOS.min >= 480,]

# Get densities of objects
hrs2_dens <- density(hrs2$LOS.min)
hrs3_dens <- density(hrs3$LOS.min)
hrs4_dens <- density(hrs4$LOS.min)
hrs8_dens <- density(hrs8$LOS.min)

xlim <- range(hrs2_dens$x, hrs3_dens$x,
              hrs4_dens$x, hrs8_dens$x)
ylim <- range(0, hrs2_dens$y, hrs3_dens$y,
              hrs4_dens$y, hrs8_dens$y)

hrs2_col <- rgb(1,0,0,0.2)
hrs3_col <- rgb(0.2,0,0,0.2)
hrs4_col <- rgb(0,1,0,0.2)
hrs8_col <- rgb(0,0,1,0.2)

plot(hrs2_dens,
     xlim = xlim,
     ylim = ylim,
     xlab = "Two, Three, Four and Eight Hours",
     main = "Distributions for Two, Three, Four and Eight Hours Over",
     panel.first = grid())

polygon(hrs2_dens, density = -1, col = hrs2_col)
polygon(hrs3_dens, density = -1, col = hrs3_col)
polygon(hrs4_dens, density = -1, col = hrs4_col)
polygon(hrs8_dens, density = -1, col = hrs8_col)

legend('topright',
       c("Two Hours", "Three Hours", "Four Hours", "Eight Hours"),
       fill = c(hrs2_col, hrs3_col, hrs4_col, hrs8_col),
       bty = 'n',
       border = NA)

#####
# Load necessary libraries
library(XLConnectJars)
library(XLConnect)
library(lubridate)
library(ggplot2)
library(knitr)
library(grid)
library(gridExtra)
#####
# Load workbook and read in worksheet data
wb   <- loadWorkbook("ATTA.xls")
data <- readWorksheet(wb, sheet = "Sheet1")

#####
# Do a little data exploration via some simple graphics
plot(data$Diff)

# Histogram
# A binwidth of 5 minutes is used since the benchmark is 75 minutes or 
# less this gives 15 bins
ggplot(data,
       aes(x = Diff,
           y = ..count..)) +
  geom_histogram(binwidth = 5) 

# Boxplot
ggplot(data,
       aes(x = Diff,
           y = Diff)) +
  geom_boxplot()
# We can see from these that the data are highly skewed right. Lets try
# to transform the data so that it is a bit more "normal"
data$Transform <- log(data$Diff)
hist(data$Transform)
# Much Much better.

#####
# Now lets classify the outliers, we will do this as 1.5 * the IQR of
# the transformed data column
data$Outlier[data$Transform > 5]  <- 1
data$Outlier[data$Transform <= 5] <- 0
data$HospFlag[data$AdmittingMDSpecialty == "Hospitalist"] <- 1
data$HospFlag[data$AdmittingMDSpecialty != "Hospitalist"] <- 0
# How many outliers do we have?
outliers = sum(data$Outlier)
# How many records in the dataset?
obs = NROW(data)
# How many non outliers in the dataset?
nonoutliers = obs-outliers
outliers/obs # ~ 20%

#####
# Some date formatting
# Year
data$ADT.Year <- year(data$Admit.Decision.Time)
data$ODT.Year <- year(data$Admit.Order.Time)

# Quarter
data$ADT.Quarter <- quarter(data$Admit.Decision.Time)
data$ODT.Quarter <- quarter(data$Admit.Order.Time)

# Month
data$ADT.Month <- month(data$Admit.Decision.Time, label = TRUE)
data$ODT.Month <- month(data$Admit.Order.Time, label = TRUE)

# Week
data$ADT.Week <- week(data$Admit.Decision.Time)
data$ODT.Week <- week(data$Admit.Order.Time)

# Day of week
data$ADT.dow <- wday(data$Admit.Decision.Time, label = TRUE)
data$ODT.dow <- wday(data$Admit.Order.Time, label = TRUE)

# Average time to admit by doctor
data$PhysATTA <- ave(data$Diff, data$AdmittingMD, FUN = mean)

# The benchmark for Admit Decision to Admit Order time is 75 minutes
# The following code will create a column that will tell us if the 
# Diff column is over or under the benchmark time.
data$OU.Indicator[data$Diff > 75]  <- "Over Benchmark"
data$OU.Indicator[data$Diff <= 75] <- "Under Benchmark"
data$OU.AvgInd[data$PhysATTA > 75] <- "Over Benchmark"
data$OU.AvgInd[data$PhysATTA <= 75]<- "Under Benchmark"

# Set a column equal to 1 in order to use the ave function to get the
# count of unique cases per physician
data$count <- 1
data$PhysCount <- ave(data$count, data$AdmittingMD, FUN = sum)

#####
# Make non outlier dataset from the original data set using the Outlier
# column value of 0 as the qualifier.
dataNot <- data[data$Outlier == 0 & data$PhysCount >= 10,]

dataNotforHospitalists <- data[data$Outlier == 0 &
                          data$PhysCount >= 10 &
                          data$HospFlag == 1,]

dataNotforCommunity <- data[data$Outlier == 0 &
                          data$PhysCount >= 10 &
                          data$HospFlag == 0,]

dataOut <- data[data$Outlier == 1 & data$PhysCount >= 10,]

dataOutforHospitalist <- data[data$Outlier == 1 &
                          data$PhysCount >= 10 &
                          data$HospFlag == 1,]

dataOutforCommunity <- data[data$Outlier == 1 &
                        data$PhysCount >= 10 &
                        data$HospFlag == 0,]

# This dataset requires that all those who have less than 10 cases are
# excluded from further analysis.
dataAll <- data[data$PhysCount >= 10,]

# Average time to admit for Hospitalist Group and Community Group only
# for those physicians that had at least 10 cases for the time period
dataAll$HospCommATTA <- ave(dataAll$Diff, 
                            dataAll$HospFlag, 
                            FUN = mean)

dataAllforHospitalist <- data[data$PhysCount >= 10 &
                          data$HospFlag == 1,]

dataAllforCommunity <- data[data$PhysCount >= 10 &
                          data$HospFlag == 0,]

#####
# The following gets the unique doctor along with their individual
# case count and their individual ATTA
MD <- unique(data$AdmittingMD)
PhysATTA <- unique(round(data$PhysATTA, digits = 2))
PhysCount <- unique(data$PhysCount)
unique(paste(MD, " = ", as.character(PhysATTA), sep=""))
unique(paste(MD, " = ", as.character(PhysCount), sep=""))

#####
#Graphics
# This graph will show the ATTA for each Doctor
ggplot(dataAll,
       aes(x = PhysATTA, y = reorder(AdmittingMD, PhysATTA))) +
  geom_point(size = 3) +
  theme_bw() +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(colour = "grey60",
                                          linetype = "dashed"),
        axis.text.y = element_text(size = 9)) +
  geom_vline(xintercept = 75) +
  xlab("Average Time To Admit") +
  ylab("Physician") + 
  ggtitle("Physician has at least 10 cases from 1-1-2014 through 6-31-2014")

# This graph will show the admit count for each physician
ggplot(dataAll,
       aes(x = PhysCount, y = reorder(AdmittingMD, PhysCount))) +
  geom_point(size = 3) +
  theme_bw() +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(colour = "grey60",
                                          linetype = "dashed"),
        axis.text.y = element_text(size = 9)) +
  xlab("Admit Count") +
  ylab("Physician") +
  ggtitle("Physician has at least 10 cases from 1-1-2014 through 6-31-2014")

# This graph shows the ATTA for each Hospitalist
# Get mean Hospitalist time and Community
meanHosp <- round(mean(dataAllforHospitalist$Diff), digits = 2)
meanComm <- round(mean(dataAllforCommunity$Diff), digits = 2)

plt1 <- ggplot(dataAllforHospitalist,
       aes(x = PhysATTA, y = reorder(AdmittingMD, PhysATTA))) +
  geom_point(size = 3,
             aes(colour = OU.AvgInd)) +
  theme_bw() +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(colour = "grey60",
                                          linetype = "dashed"),
        axis.text.y = element_text(size = 9),
        legend.position = "none") +
  geom_vline(xintercept = 75,
             size = 1) +
  geom_vline(xintercept = meanHosp,
             linetype = "dashed",
             colour = "green",
             size = 1) +
  geom_vline(xintercept = meanComm,
             linetype = "dotted",
             colour = "red",
             size = 1) +
  xlab("Average Time To Admit") +
  ylab("Physician")
plt1

# This graph gives the admit count for each hospitalist
plt2 <- ggplot(dataAllforHospitalist,
       aes(x = PhysCount, y = reorder(AdmittingMD, PhysATTA))) +
  geom_point(size = 3,
             aes(colour = OU.AvgInd)) +
  theme_bw() +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(colour = "grey60",
                                          linetype = "dashed"),
        axis.text.y = element_text(size = 9),
        legend.position=c(1, 0.55),
        legend.justification=c(1, 0.5)) +
  xlab("Admit Count") +
  ylab("Physician")
  
grid.arrange(plt1, plt2,
  nrow = 1, ncol = 2,
  main = paste("\n",
    "Sorted by Average Time To Admit - Hospitalists", "\n",
    "Average Time To Admit for Hospitalists = ", 
    as.character(meanHosp))
)

# This graph shows the ATTA for each Community Doctor
plt3 <- ggplot(dataAllforCommunity,
               aes(x = PhysATTA, y = reorder(AdmittingMD, PhysATTA))) +
  geom_point(size = 3,
             aes(colour = OU.AvgInd)) +
  theme_bw() +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(colour = "grey60",
                                          linetype = "dashed"),
        axis.text.y = element_text(size = 9),
        legend.position = "none") +
  geom_vline(xintercept = 75,
             size = 1) +
  geom_vline(xintercept = meanHosp,
             linetype = "dashed",
             colour = "green",
             size = 1) +
  geom_vline(xintercept = meanComm,
             linetype = "dotted",
             colour = "red",
             size = 1) +
  xlab("Average Time To Admit") +
  ylab("Physician")
plt3

# This graph gives the admit count for each Community Doc
plt4 <- ggplot(dataAllforCommunity,
               aes(x = PhysCount, y = reorder(AdmittingMD, PhysATTA))) +
  geom_point(size = 3,
             aes(colour = OU.AvgInd)) +
  theme_bw() +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(colour = "grey60",
                                          linetype = "dashed"),
        axis.text.y = element_text(size = 9),
        legend.position=c(1, 0.55),
        legend.justification=c(1, 0.5)) +
  xlab("Admit Count") +
  ylab("Phsyician")

grid.arrange(plt3, plt4,
  nrow = 1, ncol = 2,
  main = paste("\n",
    "Sorted by Average Time To Admit - Community Doctors", "\n",
    "Average Time To Admit for Community = ",
    as.character(meanComm))
)

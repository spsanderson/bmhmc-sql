require(tidyverse)
require(broom)
require(psych)
require(lubridate)
# Pull in los data csv file
losData <- read.csv("los_data_for_pred.csv",
                 header = TRUE)

# Format date time into POSIXct data type
losData$Adm.Date.Time <- mdy_hm(losData$Adm.Date.Time, quiet = FALSE,
        tz = "UTC", locale = Sys.getlocale("LC_TIME"),
        truncated = 0)

losData$Dsch.Date.Time <- mdy_hm(losData$Dsch.Date.Time, quiet = FALSE,
        tz = "UTC", locale = Sys.getlocale("LC_TIME"),
        truncated = 0)

# Format Admit DateTime to get DOW, Week of Year, Month, Year and Hour
losData$Adm.DOW   <- wday(losData$Adm.Date.Time, label = TRUE, abbr = TRUE)
losData$Adm.Month <- month(losData$Adm.Date.Time, label = TRUE, abbr = TRUE)
losData$Adm.Year  <- year(losData$Adm.Date.Time)
losData$Adm.Hour  <- hour(losData$Adm.Date.Time)
losData$Adm.Week  <- week(losData$Adm.Date.Time)
losData$Dsch.DOW   <- wday(losData$Dsch.Date.Time, label = TRUE, abbr = TRUE)
losData$Dsch.Month <- month(losData$Dsch.Date.Time, label = TRUE, abbr = TRUE)
losData$Dsch.Year  <- year(losData$Dsch.Date.Time)
losData$Dsch.Hour  <- hour(losData$Dsch.Date.Time)
losData$Dsch.Week  <- week(losData$Dsch.Date.Time)

# Data manipulation with dplyr - get geometric mean and sd of los data
losData <- losData%>%
  group_by(LIHN_Service_Line)%>%
  mutate(GeoMean.DaysStay.ByLIHN.SvcLine = round(
    exp(mean(log(Days.Stay))), 2),
    GeoSD.DaysStay.ByLIHN.SvcLine = round(
      exp(sd(log(Days.Stay))), 2)
  )

# Now that we have the geo mean and sd of the los by svc line
# lets get the cuttoffs for each of them defined by 3 x ge.sd
losData <- losData%>%
  group_by(LIHN_Service_Line)%>%
  mutate(LOS_Cutoff = (GeoMean.DaysStay.ByLIHN.SvcLine +
                         3 * GeoMean.DaysStay.ByLIHN.SvcLine))

# Add in log of Days Stay variable
losData <- losData%>%
  group_by(LIHN_Service_Line)%>%
  mutate(logDays.Stay = round(log(Days.Stay), 2))

# Log Total Opportunity Days
losData <- losData%>%
  group_by(LIHN_Service_Line)%>%
  mutate(Total.Log.Opp = logDays.Stay - GeoMean.DaysStay.ByLIHN.SvcLine)

# standard mean days stay by service line
losData <- losData%>%
  group_by(LIHN_Service_Line)%>%
  mutate(MeanLOSbySvcLine = round(mean(Days.Stay), 2))
  
# Keep only those observations that are not outside the cutoff
losDataKeep <- filter(losData, Days.Stay <= LOS_Cutoff)

stats <- boxplot.stats(losDataKeep$Days.Stay)$stats
ggplot(data = losDataKeep,
       mapping = aes(x = LIHN_Service_Line
                     , y = Days.Stay
                     , fill = "blue")) +
  geom_boxplot(fill = "lightblue"
    ,outlier.shape = NA) +
  scale_y_continuous(limits = c(stats[1], stats[5])) +
  theme_light() +
  theme(axis.text.x = element_text(angle = 90)) +
  ylab("Days Stay") +
  xlab("LIHN Service Line") +
  ggtitle("Days Stay w/o Outliers by LIHN Service Line",
          subtitle = "Source: DSS")

ggplot(losDataKeep, aes(x = GeoMean.DaysStay.ByLIHN.SvcLine, 
  y = reorder(LIHN_Service_Line, GeoMean.DaysStay.ByLIHN.SvcLine))) +
  geom_point(size = 3) +
  theme_minimal()

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# 2006 Author Hideaki Shimazaki
# Department of Physics, Kyoto University
# shimazaki at ton.scphys.kyoto-u.ac.jp
# Please feel free to use/modify/distribute this program.
optBin <- function(x){
  
  N <- 2: 100
  C <- numeric(length(N))
  D <- C
  
  for (i in 1:length(N)) {
    D[i] <- diff(range(x))/N[i]
    
    edges = seq(min(x),max(x),length=N[i])
    hp <- hist(x, breaks = edges, plot=FALSE )
    ki <- hp$counts
    
    k <- mean(ki)
    v <- sum((ki-k)^2)/N[i]
    
    C[i] <- (2*k-v)/D[i]^2	#Cost Function
  }
  
  idx <- which.min(C)
  optD <- D[idx]
  
  edges <- seq(min(x),max(x),length=N[idx])
  
  return(edges)
}

n = 5000
mean_alos = rep(NA, n)
sd_alos   = rep(NA, n)
var_alos  = rep(NA, n)
mean_tds  = rep(NA, n)
sd_tds    = rep(NA, n)
var_tds   = rep(NA, n)
for(i in 1:n) {
  samp         <- sample(losData$Days.Stay, 50, replace = TRUE)
  mean_alos[i] <- mean(samp)
  sd_alos[i]   <- sd(samp)
  var_alos[i]  <- var(samp)
  samp1        <- sample(losData$True.Days.Stay, 50, replace = TRUE)
  mean_tds[i]  <- mean(samp1)
  sd_tds[i]    <- sd(samp1)
  var_tds[i]   <- var(samp1)
}
bw <- optBin(mean_alos)
hist(mean_alos, breaks = bw, 
     xlab = "Mean ALOS",
     main = "Mean ALOS")
bw <- optBin(mean_tds)
hist(mean_tds, breaks = bw)
bw <- optBin(sd_alos)
hist(sd_alos, breaks = bw)
bw <- optBin(sd_tds)
hist(sd_tds, breaks = bw)
mean(mean_alos)
mean(mean_tds)
mean(sd_alos)
mean(sd_tds)

svc_line <- losData %>% select(LIHN_Service_Line) %>% distinct()

alos_test <- with(losData, aggregate(Days.Stay
  , by = list(LIHN_Service_Line=LIHN_Service_Line)
  , FUN = mean))

# Make factors our of some of the flags that are numeric
losDataKeep$Senior.Citizen.Flag <- as.factor(losDataKeep$Senior.Citizen.Flag)
losDataKeep$Hospitalist.Flag <- as.factor(losDataKeep$Hospitalist.Flag)
losDataKeep$Readmitted.in.30. <- as.factor(losDataKeep$Readmitted.in.30.)
losDataKeep$Poly.Pharmacy.Flag <- as.factor(losDataKeep$Poly.Pharmacy.Flag)
losDataKeep$High.Risk.Readmit <- as.factor(losDataKeep$High.Risk.Readmit)

require(dplyr, lubridate, ggplot2)

## Load in data from csv file
erdata <- read.csv("Decision to Admit to Admit Order DT.csv", header = TRUE
                   , sep = ",")

## get summary of the data
summary(erdata)
erdata$Arrival.DTime <- mdy_hm(erdata$Arrival.DTime)
erdata$Decision.To.Admit <- mdy_hm(erdata$Decision.To.Admit)
erdata$Admit.Order.Entry.DTime <- mdy_hm(erdata$Admit.Order.Entry.DTime)
erdata$Admit_Confirm <- mdy_hm(erdata$Admit_Confirm)
erdata$DTime.Unit.Sec.States.as.Eff.DTime <- mdy_hm(
  erdata$DTime.Unit.Sec.States.as.Eff.DTime
)
erdata$DTime.Processed.by.System <- mdy_hm(
  erdata$DTime.Processed.by.System
)
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# returns the optimal binwidth for a histogram given certain data
# modified from:
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
    
    C[i] <- (2*k-v)/D[i]^2	# Cost Function
  }
  
  idx <- which.min(C)
  optD <- D[idx]
  
  edges <- seq(min(x),max(x),length=N[idx])
  
  return(edges)
}

## get bootstrapped samples of mean time of arrival to decision to admit time
## in minutes
n = 5000
mean_arr_to_dta = rep(NA, n)
sd_arr_to_dta   = rep(NA, n)
var_arr_to_dta  = rep(NA, n)
for (i in 1:n){
  samp <- sample(erdata$Arrival.To.DTA.Delta.Minutes, 500, replace = TRUE)
  mean_arr_to_dta[i] <- mean(samp)
  sd_arr_to_dta[i]   <- sd(samp)
  var_arr_to_dta[i]  <- var(samp)
}

bw <- optBin(mean_arr_to_dta)
hist(mean_arr_to_dta, breaks = bw, xlab = "Delta in Minutes",
     main = "Mean time from Arrival to Decision to Admit")

## get bootstrapped samples of mean time of decision to admit time to
## Admit Order Entry DTime in minutes
n = 5000
mean_dta_ord_ent = rep(NA, n)
sd_dta_ord_ent   = rep(NA, n)
var_dta_ord_ent  = rep(NA, n)
for (i in 1:n){
  samp <- sample(erdata$DTA.To.AdmOrd.Delta.Minutes, 500, replace = TRUE)
  mean_dta_ord_ent[i] <- mean(samp)
  sd_dta_ord_ent[i]   <- sd(samp)
  var_dta_ord_ent[i]  <- var(samp)
}

bw <- optBin(mean_dta_ord_ent)
hist(mean_dta_ord_ent, breaks = bw, xlab = "Delta in Minutes",
     main = "Mean time from Decision to Admit to Admit Order 
     Entry DTime in Minutes")

## get bootstrapped samples of mean time of Admit Ord Entry to Admit Confirm
## in minutes
n = 5000
mean_ord_ent_confirm = rep(NA, n)
sd_ord_ent_confirm   = rep(NA, n)
var_ord_ent_confirm  = rep(NA, n)
for (i in 1:n){
  samp <- sample(erdata$AdmOrdEnt.To.AdmConfirm.Delta.Minutes, 
                 500, replace = TRUE)
  mean_ord_ent_confirm[i] <- mean(samp)
  sd_ord_ent_confirm[i]   <- sd(samp)
  var_ord_ent_confirm[i]  <- var(samp)
}

bw <- optBin(mean_ord_ent_confirm)
hist(mean_ord_ent_confirm, breaks = bw, xlab = "Delta in Minutes",
     main = "Mean time from Admit Ord Entry to 
     Admit Confirm in Minutes")

## get bootstrapped samples of mean time of Admit Ord Entry to System Processed
## time in minutes
n = 5000
mean_ord_ent_sysprcs = rep(NA, n)
sd_ord_ent_sysprcs   = rep(NA, n)
var_ord_ent_sysprcs  = rep(NA, n)
for (i in 1:n){
  samp <- sample(erdata$AdmOrdEnt.to.SysProc.DT.Delta.Minutes, 
                 500, replace = TRUE)
  mean_ord_ent_sysprcs[i] <- mean(samp)
  sd_ord_ent_sysprcs[i]   <- sd(samp)
  var_ord_ent_sysprcs[i]  <- var(samp)
}

bw <- optBin(mean_ord_ent_sysprcs)
hist(mean_ord_ent_sysprcs, breaks = 30, xlab = "Delta in Minutes",
     main = "Mean time from Admit Ord Entry to 
     System Process DT in Minutes")

# create data by arr_dow and arr_hr factors
erdata_byfactor <- erdata
erdata_byfactor$arrival_dow <- wday(erdata_byfactor$Arrival.DTime, 
                                    label = TRUE)  
erdata_byfactor$arrival_hr <- hour(erdata_byfactor$Arrival.DTime)

ggplot(data = erdata_byfactor, 
         mapping = aes(
           x = arrival_dow
           , y = Arrival.To.DTA.Delta.Minutes
           , group = arrival_dow
           , fill = arrival_dow
           )
  ) +
  geom_boxplot(position = "dodge") +
  guides(fill = guide_legend(title = NULL)) +
  theme_bw() +
  xlab("Arrival Day of Week") +
  ylab("Arrival to Decision to Admit Delta in Minutes") +
  ggtitle("Arrival to Decision to Admit Delta in Minutes\nby Day of Week",
          subtitle = "Source: WellSoft, DSS")

ggplot(data = erdata_byfactor,
       mapping = aes(
         x = arrival_hr
         , y = Arrival.To.DTA.Delta.Minutes
         , group = arrival_hr
       )
  ) +
  geom_boxplot(position = "dodge"
               , fill = "lightblue") +
  guides(fill = guide_legend(title = NULL)) +
  theme_bw() +
  xlab("Arrival Hour") +
  ylab("Arrival to Decision to Admit Delta in Minutes") +
  ggtitle("Arrival to Decision to Admit Delta in Minutes\nby Hour of Day",
          subtitle = "Source: WellSoft, DSS")

ggplot(data = erdata_byfactor,
       mapping = aes(
         x = arrival_hr
         , y = Arrival.To.DTA.Delta.Minutes
         , group = arrival_hr
       )) + 
  geom_boxplot(position = "dodge",
               fill = "lightblue") +
  theme_bw() +
  xlab("Arrival Hour") +
  ylab("Arrival to Decision to Admit Delta in Minutes") +
  ggtitle("Arrival to Decision to Admit Delta in Minutes\n by Hour of Day",
          subtitle = "Source: WellSoft, DSS") +
  facet_grid(arrival_dow ~ .)


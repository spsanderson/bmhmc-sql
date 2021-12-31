require(ggplot2)

## Load in data from csv file
erdata <- read.csv("Decision to Admit to Admit Order DT.csv", header = TRUE
                 , sep = ",")

## get summary of the data
summary(erdata)

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

hist(mean_arr_to_dta, breaks = 30, xlab = "Delta in Minutes",
     main = "Mean time from Arrival to Decision to Admit")

## get bootstrapped samples of mean time of decision to admit time to
## Admit Order Entry DTime in minutes
n = 5000
mean_arr_to_dta = rep(NA, n)
sd_arr_to_dta   = rep(NA, n)
var_arr_to_dta  = rep(NA, n)
for (i in 1:n){
  samp <- sample(erdata$DTA.To.AdmOrd.Delta.Minutes, 500, replace = TRUE)
  mean_arr_to_dta[i] <- mean(samp)
  sd_arr_to_dta[i]   <- sd(samp)
  var_arr_to_dta[i]  <- var(samp)
}

hist(mean_arr_to_dta, breaks = 30, xlab = "Delta in Minutes",
     main = "Mean time from Decision to Admit to Admit Order 
     Entry DTime in Minutes")

## get bootstrapped samples of mean time of Admit Ord Entry to Admit Confirm
## in minutes
n = 5000
mean_arr_to_dta = rep(NA, n)
sd_arr_to_dta   = rep(NA, n)
var_arr_to_dta  = rep(NA, n)
for (i in 1:n){
  samp <- sample(erdata$AdmOrdEnt.To.AdmConfirm.Delta.Minutes, 
                 500, replace = TRUE)
  mean_arr_to_dta[i] <- mean(samp)
  sd_arr_to_dta[i]   <- sd(samp)
  var_arr_to_dta[i]  <- var(samp)
}

hist(mean_arr_to_dta, breaks = 30, xlab = "Delta in Minutes",
     main = "Mean time from Admit Ord Entry to 
     Admit Confirm in Minutes")

## get bootstrapped samples of mean time of Admit Ord Entry to System Processed
## time in minutes
n = 5000
mean_arr_to_dta = rep(NA, n)
sd_arr_to_dta   = rep(NA, n)
var_arr_to_dta  = rep(NA, n)
for (i in 1:n){
  samp <- sample(erdata$AdmOrdEnt.to.SysProc.DT.Delta.Minutes, 
                 500, replace = TRUE)
  mean_arr_to_dta[i] <- mean(samp)
  sd_arr_to_dta[i]   <- sd(samp)
  var_arr_to_dta[i]  <- var(samp)
}

hist(mean_arr_to_dta, breaks = 30, xlab = "Delta in Minutes",
     main = "Mean time from Admit Ord Entry to 
     System Process DT in Minutes")


#########################
#
# Import desired packages
#
#########################
library(ggplot2)
library(lubridate)
library(gridExtra)
library(grid)

##############
#
# read in data
#
#############
episode_data <- read.csv(".csv", header=TRUE)

#####################
#
# get rid of outliers, keep mdc 5, get over under predicted amount
# and get the index of each case.
#
#####################
edata <- episode_data[episode_data$Excluded_Reason 
                      != "Outlier_Episode",]
# Take a look at MDC 5 which has the most cases for the year
mdc5 <- edata[edata$MDC == 5,]

# Create a variable that will tell if the Payment of the Claim is 
# higher or lower than the predicted claim amount
mdc5$ou_pred_anom[(mdc5$Std_Pmt_All_Clm - mdc5$Pred_Amt_Renormal) 
                  > 0] <- "Over Predicted"
mdc5$ou_pred_anom[(mdc5$Std_Pmt_All_Clm - mdc5$Pred_Amt_Renormal) 
                  <= 0] <- "At or Below Pred"

# This gets the difference between the Payment of All claims and the
# predicted value of all the claims        	 
mdc5$ou_pred_diff <- (mdc5$Std_Pmt_All_Clm - mdc5$Pred_Amt_Renormal)

# Get the Index of the case, the Standardized Payment of all claims
# divided by the predicted amount
mdc5$case_index <- (mdc5$Std_Pmt_All_Clm/mdc5$Pred_Amt_Renormal)
mdc5$case_index_ou[mdc5$case_index > 1] <- "Over"
mdc5$case_index_ou[mdc5$case_index <= 1] <- "Under"

############################################
#
# Create Data Frames for Each Dispo Location
#
############################################
mdc5ip <- mdc5[mdc5$OP_StartDate == "" &
               mdc5$DM_StartDate == "" &
               mdc5$HH_StartDate == "" &
               mdc5$HS_StartDate == "" &
               mdc5$SN_StartDate == "",]

ip_keepers <- c("HOSP_EPISODE_COUNT", "HIC_EQ", "case_index",
                "PMT_ALL_CLM", "Std_Pmt_All_Clm", "Pred_Amt_Renormal",
                "IP_StartDate", "IP_EndDate", "IP_std_cost",
                "ou_pred_anom", "ou_pred_diff", "case_index_ou")
mdc5ip <- mdc5ip[ip_keepers]


#### mdc5ip sub-variables
mdc5ip$percent_std_clm <- round(mdc5ip$IP_std_cost / 
                                  mdc5ip$Std_Pmt_All_Clm,
                                digits = 2)
mdc5ip$percent_prd_amt <- round(mdc5ip$IP_std_cost / 
                                  mdc5ip$Pred_Amt_Renormal,
                                digits = 2)
mdc5ip$mean_index   <- mean(mdc5ip$case_index)
mdc5ip$IP_StartDate <- mdy(mdc5ip$IP_StartDate)
mdc5ip$ipmonth <- month(mdc5ip$IP_StartDate, label = TRUE)
mdc5ip$ipweek  <- week(mdc5ip$IP_StartDate)
mdc5ip$ipday   <- day(mdc5ip$IP_StartDate)
mdc5ip$ipwday  <- wday(mdc5ip$IP_StartDate, label = TRUE)

#### get index by month, week, day of month and day of week
mdc5ip$index_month <- ave(mdc5ip$case_index, mdc5ip$ipmonth,
                          FUN = mean)
mdc5ip$index_week  <- ave(mdc5ip$case_index, mdc5ip$ipweek,
                          FUN = mean)
mdc5ip$index_day   <- ave(mdc5ip$case_index, mdc5ip$ipday,
                          FUN = mean)
mdc5ip$index_wday  <- ave(mdc5ip$case_index, mdc5ip$ipwday,
                          FUN = mean)
#### get colours for the groups
mdc5ip$ou_ind_month[mdc5ip$index_month > 1]  <- "Over Index"
mdc5ip$ou_ind_month[mdc5ip$index_month <= 1] <- "Under Index"
mdc5ip$ou_ind_week[mdc5ip$index_week > 1]    <- "Over Index"
mdc5ip$ou_ind_week[mdc5ip$index_week <= 1]   <- "Under Index"
mdc5ip$ou_ind_day[mdc5ip$index_day > 1]      <- "Over Index"
mdc5ip$ou_ind_day[mdc5ip$index_day <= 1]     <- "Under Index"
mdc5ip$ou_ind_wday[mdc5ip$index_wday > 1]    <- "Over Index"
mdc5ip$ou_ind_wday[mdc5ip$index_wday <= 1]   <- "Under Index"

############################
#
# Grap IP only index data
#
############################
plot_ip_ind_month <- ggplot(mdc5ip,
                            aes(x = ipmonth,
                                y = index_month,
                                fill = ou_ind_month)) +
  geom_bar(stat = "identity",
           position = "identity",
           colour = "black",
           alpha = 0.3) + 
  geom_hline(yintercept = mean(mdc5ip$index_month),
             linetype = "dashed",
             size = 0.75,
             colour = "black") + 
  xlab("Month") +
  ylab("Index")
plot_ip_ind_month

plot_ip_ind_week <- ggplot(mdc5ip,
                           aes(x = ipweek,
                               y = index_week,
                               fill = ou_ind_week)) +
  geom_bar(stat = "identity",
           position = "identity",
           colour = "black",
           alpha = 0.3) + 
  geom_hline(yintercept = mean(mdc5ip$index_week),
             linetype = "dashed",
             size = 0.75,
             colour = "black") + 
  xlab("Week of the Year")
plot_ip_ind_week

plot_ip_ind_day <- ggplot(mdc5ip,
                          aes(x = ipday,
                              y = index_day,
                              fill = ou_ind_day)) +
  geom_bar(stat = "identity",
           position = "identity",
           colour = "black",
           alpha = 0.3) + 
  geom_hline(yintercept = mean(mdc5ip$index_day),
             linetype = "dashed",
             size = 0.75,
             colour = "black") +
  xlab("Day of the Month")
plot_ip_ind_day

plot_ip_ind_wday <- ggplot(mdc5ip,
                           aes(x = ipwday,
                               y = index_wday,
                               fill = ou_ind_wday)) + 
  geom_bar(stat = "identity",
           position = "identity",
           colour = "black",
           alpha = 0.3) +
  geom_hline(yintercept = mean(mdc5ip$index_wday),
             linetype = "dashed",
             size = 0.75,
             colour = "black") +
  xlab("Day of the Week")
plot_ip_ind_wday

grid.arrange(plot_ip_ind_month, plot_ip_ind_week,
             plot_ip_ind_day, plot_ip_ind_wday,
             nrow = 2, ncol = 2,
             main = "2012 Inpatients Only 
             MDC 5: Circulatory System Index Cost for MSPB")

#### Histograms of same data
hist_ip_ind_month <- ggplot(mdc5ip,
                            aes(x = index_month,
                                y = ..count..,
                                fill = ou_ind_month)) +
  geom_histogram(binwidth = 1/30,
                 colour = "black",
                 alpha = 0.618) +
  geom_vline(xintercept = mean(mdc5ip$index_month),
             linetype = "dashed") +
  geom_vline(xintercept = 1,
             linetype = "longdash",
             colour = "red") +
  annotate("text", x = 0.8, y = 75,
           label = paste("Mean Monthly Index for 2012 =",
                         round(mean(mdc5ip$index_month),
                               digits = 2))) +
  xlim(0.5, 1) +
  xlab("Histogram of Monthly Index") +
  ylab("Count")
hist_ip_ind_month

hist_ip_ind_week <- ggplot(mdc5ip,
                           aes(x = index_week,
                               y = ..count..,
                               fill = ou_ind_week)) +
  geom_histogram(binwidth = 0.05, colour = "black",
                 alpha = 0.618) + 
  geom_vline(xintercept = mean(mdc5ip$index_week),
             linetype = "dashed") + 
  geom_vline(xintercept = 1,
             linetype = "longdash",
             colour = "red") +
  annotate("text", x = 0.8, y = 60,
           label = paste("Mean Weekly Index for 2012 =",
                         round(mean(mdc5ip$index_week),
                               digits = 2))) +
  xlab("Histogram of Weekly Index") +
  ylab("Count")
hist_ip_ind_week

hist_ip_ind_day <- ggplot(mdc5ip,
                          aes(x = index_day,
                              y = ..count..,
                              fill = ou_ind_day)) +
  geom_histogram(binwidth = 0.05, colour = "black",
                 alpha = 0.618) +
  geom_vline(xintercept = mean(mdc5ip$index_day),
             linetype = "dashed") +
  geom_vline(xintercept = 1,
             linetype = "longdash",
             colour = "red") + 
  annotate("text", x = 0.8, y = 50,
           label = paste("Mean Day of the Month Index for 2012 =",
                         round(mean(mdc5ip$index_day),
                               digits = 2))) +
  xlab("Histogram of Day of the Month Index") +
  ylab("Count")
hist_ip_ind_day

grid.arrange(hist_ip_ind_month, hist_ip_ind_week, hist_ip_ind_day,
             nrow = 3, ncol = 1,
             main = "Histograms of MDC 5: Circulatory System Index Cost
             for Inpatients only 2012")

hist_case_index <- ggplot(mdc5ip,
                          aes(x = case_index,
                              y = ..count..,
                              fill = case_index_ou)) + 
  geom_histogram(colour = "black",
                 alpha = 0.618) +
  geom_vline(xintercept = mean(mdc5ip$case_index),
             linetype = "dashed",
             size = 0.75) + 
  xlab("Case Index") +
  ylab("Count") +
  ggtitle(paste("2012 MDC 5: Circulatory System - Persons with only an Inpatient Stay
          Mean Case Index =",
                round(mean(mdc5ip$case_index),
                      digits = 2)))
hist_case_index
##############################################################
#
# end of inpatient only data
# now to get inpatients that also have some sort of SNF stay
# 
##############################################################
mdc5sn <- mdc5[mdc5$SN_StartDate != "" &
               mdc5$DM_StartDate == "" &
               mdc5$OP_StartDate == "" &
               mdc5$HH_StartDate == "" &
               mdc5$HS_StartDate == ""
               ,]

sn_keepers <- c("HOSP_EPISODE_COUNT", "HIC_EQ", "case_index",
                "PMT_ALL_CLM", "Std_Pmt_All_Clm", "Pred_Amt_Renormal",
                "IP_StartDate", "IP_EndDate", "IP_std_cost",
                "ou_pred_anom", "ou_pred_diff",
                "SN_StartDate", "SN_EndDate", "SN_std_cost",
                "SN_Provider_1", "case_index_ou")

mdc5sn <- mdc5sn[sn_keepers]

#### mdc5sn sub-variables
mdc5sn$percent_ip_clm  <- round(mdc5sn$IP_std_cost / 
                                 mdc5sn$Std_Pmt_All_Clm,
                               digits = 2)
mdc5sn$percent_ip_amt  <- round(mdc5sn$IP_std_cost / 
                                 mdc5sn$Pred_Amt_Renormal,
                               digits = 2)
mdc5sn$percent_sn_clm  <- round(mdc5sn$SN_std_cost / 
                                  mdc5sn$Std_Pmt_All_Clm,
                                digits = 2)
mdc5sn$percent_sn_prd  <- round(mdc5sn$SN_std_cost / 
                                  mdc5sn$Pred_Amt_Renormal,
                                digits = 2)

hist_sn_case_index <- ggplot(mdc5sn,
                             aes(x = case_index,
                                 y = ..count..,
                                 fill = case_index_ou)) + 
  geom_histogram(binwidth = 0.25,
                 colour = "black",
                 alpha = 0.3) +
  geom_vline(xintercept = mean(mdc5ip$case_index),
             linetype = "dashed",
             colour = "green",
             size = 0.75) +
  geom_vline(xintercept = mean((edata$Std_Pmt_All_Clm / 
                                edata$Pred_Amt_Renormal)),
             linetype = "solid",
             colour = "blue",
             size = 0.75) +
  geom_vline(xintercept = mean(mdc5sn$case_index),
             linetype = "longdash",
             colour = "red",
             size = 0.75) +
  xlab("Case Index") +
  ylab("Count") + 
  ggtitle("")
hist_sn_case_index

hist_sn_case_index_facet <- ggplot(mdc5sn,
                             aes(x = case_index,
                                 y = ..count..,
                                 fill = case_index_ou)) + 
  geom_histogram(binwidth = 0.25,
                 colour = "black",
                 alpha = 0.3) +
  geom_vline(xintercept = mean(mdc5ip$case_index),
             linetype = "dashed",
             colour = "green",
             size = 0.75) +
  geom_vline(xintercept = mean((edata$Std_Pmt_All_Clm / 
                                  edata$Pred_Amt_Renormal)),
             linetype = "solid",
             colour = "blue",
             size = 0.75) +
  geom_vline(xintercept = mean(mdc5sn$case_index),
             linetype = "longdash",
             colour = "red",
             size = 0.75) +
  facet_wrap(~ SN_Provider_1) +
  xlab("Case Index") +
  ylab("Count") + 
  ggtitle("")
hist_sn_case_index_facet

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
episode_data <- read.csv("episode_data.csv", header=TRUE)

#####################
#
# get rid of outliers, get over under predicted amount
# and get the index of each case.
#
#####################
edata <- episode_data[episode_data$Excluded_Reason 
                      != "Outlier_Episode",]

edata$ou_pred_anom[(edata$Std_Pmt_All_Clm - edata$Pred_Amt_Renormal)
                   > 0] <- "Over Predicted"
edata$ou_pred_anom[(edata$Std_Pmt_All_Clm - edata$Pred_Amt_Renormal)
                   <= 0] <- "At or Below Pred"
edata$ou_pred_diff <- (edata$Std_Pmt_All_Clm - edata$Pred_Amt_Renormal)
edata$case_index <- (edata$Std_Pmt_All_Clm / edata$Pred_Amt_Renormal)
edata$case_index_ou[edata$case_index > 1] <- "Over"
edata$case_index_ou[edata$case_index <= 1] <- "Under"

# Get those who only have an inpatient stay
ip <- edata[edata$SN_StartDate == "" &
              edata$DM_StartDate == "" &
              edata$HH_StartDate == "" &
              edata$HS_StartDate == "" &
              edata$OP_StartDate == "",]

ip_keepers <- c("HOSP_EPISODE_COUNT", "HIC_EQ", "case_index",
                  "PMT_ALL_CLM", "Std_Pmt_All_Clm", "Pred_Amt_Renormal",
                  "IP_StartDate", "IP_EndDate", "IP_std_cost",
                  "ou_pred_anom", "ou_pred_diff","case_index_ou")

ip <- ip[ip_keepers]

ip$mean_index   <- mean(ip$case_index)
ip$IP_StartDate <- mdy(ip$IP_StartDate)
ip$ipmonth <- month(ip$IP_StartDate, label = TRUE)
ip$ipweek  <- week(ip$IP_StartDate)
ip$ipday   <- day(ip$IP_StartDate)
ip$ipwday  <- wday(ip$IP_StartDate, label = TRUE)

#### get index by month, week, day of month and day of week
ip$index_month <- ave(ip$case_index, ip$ipmonth,
                        FUN = mean)
ip$index_week  <- ave(ip$case_index, ip$ipweek,
                        FUN = mean)
ip$index_day   <- ave(ip$case_index, ip$ipday,
                        FUN = mean)
ip$index_wday  <- ave(ip$case_index, ip$ipwday,
                        FUN = mean)

#### get colours for the groups
ip$ou_ind[ip$case_index > 1] <- "Over Index"
ip$ou_ind[ip$case_index <=1] <- "Under Index"
ip$ou_ind_month[ip$index_month > 1]  <- "Over Index"
ip$ou_ind_month[ip$index_month <= 1] <- "Under Index"
ip$ou_ind_week[ip$index_week > 1]    <- "Over Index"
ip$ou_ind_week[ip$index_week <= 1]   <- "Under Index"
ip$ou_ind_day[ip$index_day > 1]      <- "Over Index"
ip$ou_ind_day[ip$index_day <= 1]     <- "Under Index"
ip$ou_ind_wday[ip$index_wday > 1]    <- "Over Index"
ip$ou_ind_wday[ip$index_wday <= 1]   <- "Under Index"

line1 <- ""
line2 <- paste("Inpatient Only Case Index =",
               round(
                 mean(ip$case_index),
                 digits = 2)
               )

hist_iponly_case_index <- ggplot(ip,
                                 aes(x = case_index,
                                     y = ..count..,
                                     fill = ou_ind)) +
  geom_histogram(binwidth = 0.1,
                 colour = "black",
                 alpha = 0.3) +
  # Mean case index
  geom_vline(xintercept = mean(ip$case_index),
             linetype = "dashed",
             colour = "brown",
             size = 0.75) +
  geom_vline(xintercept = 1.10,
             linetype = "dashed",
             colour = "red",
             size = 1) +
  xlab("Case Index: n = 741") +
  ylab("Count") +
  ggtitle("Clean Inpatients - Average Case Index = Brown Line") +
  theme(plot.title = element_text(size = 10)) +
  theme(legend.position = "none")
hist_iponly_case_index

ip_only_ind_month <- ggplot(ip,
                            aes(x = ipmonth,
                                y = index_month,
                                fill = ou_ind_month)) + 
  geom_bar(stat = "identity",
           position = "identity",
           colour = "black",
           alpha = 0.3) +
  geom_hline(yintercept = mean(ip$case_index),
             linetype = "dashed",
             size = 0.75,
             colour = "black") +
  xlab("Month") + 
  ylab("Count") +
  ggtitle(line2) +
  theme(legend.position = "none")
ip_only_ind_month

ip_only_ind_dow <- ggplot(ip,
                          aes(x = ipwday,
                              y = index_wday,
                              fill = ou_ind_wday)) +
  geom_bar(stat = "identity",
           position = "identity",
           colour = "black",
           alpha = 0.3) +
  geom_hline(yintercept = mean(ip$case_index),
             linetype = "dashed",
             size = 0.75,
             colour = "black") +
  xlab("Day of Week") +
  ylab("Count") +
  ggtitle(line2) +
  theme(legend.position = "none")
ip_only_ind_dow

#####################################################################

####
# Get all IP and SNF Cases
####
ipsn <- edata[edata$SN_StartDate != "" &
                edata$DM_StartDate == "" &
                edata$OP_StartDate == "" &
                edata$HH_StartDate == "" &
                edata$HS_StartDate == ""
              ,]

ipsn_keepers <- c("HOSP_EPISODE_COUNT", "HIC_EQ", "case_index",
                  "PMT_ALL_CLM", "Std_Pmt_All_Clm","Pred_Amt_Renormal",
                  "IP_StartDate", "IP_EndDate", "IP_std_cost",
                  "ou_pred_anom", "ou_pred_diff",
                  "SN_StartDate", "SN_EndDate", "SN_std_cost",
                  "SN_Provider_1", "case_index_ou")

ipsn <- ipsn[ipsn_keepers]

ipsn$mean_index   <- mean(ipsn$case_index)
ipsn$IP_StartDate <- mdy(ipsn$IP_StartDate)
ipsn$ipmonth <- month(ipsn$IP_StartDate, label = TRUE)
ipsn$ipweek  <- week(ipsn$IP_StartDate)
ipsn$ipday   <- day(ipsn$IP_StartDate)
ipsn$ipwday  <- wday(ipsn$IP_StartDate, label = TRUE)

#### get index by month, week, day of month and day of week
ipsn$index_month <- ave(ipsn$case_index, ipsn$ipmonth,
                        FUN = mean)
ipsn$index_week  <- ave(ipsn$case_index, ipsn$ipweek,
                        FUN = mean)
ipsn$index_day   <- ave(ipsn$case_index, ipsn$ipday,
                        FUN = mean)
ipsn$index_wday  <- ave(ipsn$case_index, ipsn$ipwday,
                        FUN = mean)

#### get colours for the groups
ipsn$ou_ind[ipsn$case_index > 1] <- "Over Index"
ipsn$ou_ind[ipsn$case_index <=1] <- "Under Index"
ipsn$ou_ind_month[ipsn$index_month > 1]  <- "Over Index"
ipsn$ou_ind_month[ipsn$index_month <= 1] <- "Under Index"
ipsn$ou_ind_week[ipsn$index_week > 1]    <- "Over Index"
ipsn$ou_ind_week[ipsn$index_week <= 1]   <- "Under Index"
ipsn$ou_ind_day[ipsn$index_day > 1]      <- "Over Index"
ipsn$ou_ind_day[ipsn$index_day <= 1]     <- "Under Index"
ipsn$ou_ind_wday[ipsn$index_wday > 1]    <- "Over Index"
ipsn$ou_ind_wday[ipsn$index_wday <= 1]   <- "Under Index"

line3 <- paste("Patients with SNF Stay, Case Index =",
               round(
                 mean(ipsn$case_index),
                 digits = 2)
               )

hist_ipsn_case_index <- ggplot(ipsn,
                               aes(x = case_index,
                                   y = ..count..,
                                   fill = ou_ind)) +
  geom_histogram(binwidth = 0.1,
                 colour = "black",
                 alpha = 0.3) +
  # Mean case index
  geom_vline(xintercept = mean(ipsn$case_index),
             linetype = "dashed",
             colour = "black",
             size = 0.75) +
  # Mean IP only case index
  geom_vline(xintercept = mean(ip$case_index),
             linetype = "dashed",
             colour = "brown",
             size = 0.75) +
  geom_vline(xintercept = 1.10,
             linetype = "dashed",
             colour = "red",
             size = 1) +
  xlab("Case Index: n = 469") +
  ylab("Count") +
  ggtitle(
    "Inpatients With SNF Stay - Average Case Index = Black Line"
    ) +
  theme(plot.title = element_text(size = 10)) +
  theme(legend.position="none")
hist_ipsn_case_index

ipsn_ind_month <- ggplot(ipsn,
                         aes(x = ipmonth,
                             y = index_month,
                             fill = ou_ind_month)) +
  geom_bar(stat = "identity",
           position = "identity",
           colour = "black",
           alpha = 0.3) +
  geom_hline(yintercept = mean(ipsn$case_index),
             linetype = "dashed",
             size = 0.75,
             colour = "black") +
  xlab("Month") +
  ylab("Case Index") +
  ggtitle() +
  theme(legend.position = "none")
ipsn_ind_month

ipsn_ind_dow <- ggplot(ipsn,
                       aes(x = ipwday,
                           y = index_wday,
                           fill = ou_ind_wday)) +
  geom_bar(stat = "identity",
           position = "identity",
           colour = "black",
           alpha = 0.3) +
  geom_hline(yintercept = mean(ipsn$case_index),
             linetype = "dashed",
             size = 0.75,
             colour = "black") +
  xlab("Day of Week") +
  ylab("Case Index") +
  ggtitle(line3) +
  theme(legend.position = "none")
ipsn_ind_dow


grid.arrange(hist_iponly_case_index, hist_ipsn_case_index,
             nrow = 2, ncol = 1,
             main = paste(line1, "\n", line2, "\n", line3))

grid.arrange(ip_only_ind_month, ipsn_ind_month,
             ip_only_ind_dow, ipsn_ind_dow,
             nrow = 2, ncol = 2)

#####################################################################

####
# IP and Home Health
####
iphh <- edata[edata$HH_StartDate != "" &
              edata$SN_StartDate == "" &
              edata$HS_StartDate == "" &
              edata$OP_StartDate == ""
              ,]

iphh_keepers <- c("HOSP_EPISODE_COUNT", "HIC_EQ", "case_index",
                  "PMT_ALL_CLM", "Std_Pmt_All_Clm","Pred_Amt_Renormal",
                  "IP_StartDate", "IP_EndDate", "IP_std_cost",
                  "ou_pred_anom", "ou_pred_diff",
                  "HH_StartDate", "HH_EndDate", "HH_std_cost",
                  "case_index_ou")

iphh <- iphh[iphh_keepers]

iphh$mean_index   <- mean(iphh$case_index)
iphh$IP_StartDate <- mdy(iphh$IP_StartDate)
iphh$ipmonth <- month(iphh$IP_StartDate, label = TRUE)
iphh$ipweek  <- week(iphh$IP_StartDate)
iphh$ipday   <- day(iphh$IP_StartDate)
iphh$ipwday  <- wday(iphh$IP_StartDate, label = TRUE)

#### get index by month, week, day of month and day of week
iphh$index_month <- ave(iphh$case_index, iphh$ipmonth,
                        FUN = mean)
iphh$index_week  <- ave(iphh$case_index, iphh$ipweek,
                        FUN = mean)
iphh$index_day   <- ave(iphh$case_index, iphh$ipday,
                        FUN = mean)
iphh$index_wday  <- ave(iphh$case_index, iphh$ipwday,
                        FUN = mean)

#### get colours for the groups
iphh$ou_ind[iphh$case_index > 1] <- "Over Index"
iphh$ou_ind[iphh$case_index <=1] <- "Under Index"
iphh$ou_ind_month[iphh$index_month > 1]  <- "Over Index"
iphh$ou_ind_month[iphh$index_month <= 1] <- "Under Index"
iphh$ou_ind_week[iphh$index_week > 1]    <- "Over Index"
iphh$ou_ind_week[iphh$index_week <= 1]   <- "Under Index"
iphh$ou_ind_day[iphh$index_day > 1]      <- "Over Index"
iphh$ou_ind_day[iphh$index_day <= 1]     <- "Under Index"
iphh$ou_ind_wday[iphh$index_wday > 1]    <- "Over Index"
iphh$ou_ind_wday[iphh$index_wday <= 1]   <- "Under Index"

line4 <- paste("Patients with Home Health, Case Index =",
               round(
                 mean(iphh$case_index),
                 digits = 2
                 )
               )

hist_iphh_case_index <- ggplot(iphh,
                               aes(x = case_index,
                                   y = ..count..,
                                   fill = ou_ind)) +
  geom_histogram(binwidth = 0.1,
                 colour = "black",
                 alpha = 0.3) +
  # Mean case index SNF
  geom_vline(xintercept = mean(ipsn$case_index),
             linetype = "dashed",
             colour = "black",
             size = 0.75) +
  # Mean Case Index Home Health
  geom_vline(xintercept = mean(iphh$case_index),
             linetype = "dashed",
             colour = "green",
             size = 0.75) +
  # Mean IP only case index
  geom_vline(xintercept = mean(ip$case_index),
             linetype = "dashed",
             colour = "brown",
             size = 0.75) +
  geom_vline(xintercept = 1.10,
             linetype = "dashed",
             colour = "red",
             size = 1) +
  xlab("Case Index: n = 458") +
  ylab("Count") +
  #ggtitle(paste(line1, "\n",
  #              line2, "\n",
  #              line3, "\n",
  #              line4)) +
  ggtitle(
    "Inpatients With Home Health Stay - Average Case Index = Green Line"
    ) +
  theme(plot.title = element_text(size = 10)) +
  theme(legend.position="none")
hist_iphh_case_index

iphh_ind_month <- ggplot(iphh,
                         aes(x = ipmonth,
                             y = index_month,
                             fill = ou_ind_month)) +
  geom_bar(stat = "identity",
           position = "identity",
           colour = "black", 
           alpha = 0.3) +
  geom_hline(yintercept = mean(iphh$case_index),
             linetype = "dashed",
             size = 0.75,
             colour = "black") +
  xlab("Month") +
  ylab("Case Index") +
  ggtitle(line4)+
  theme(legend.position = "none")
iphh_ind_month

iphh_ind_wday <- ggplot(iphh,
                        aes(x = ipwday,
                            y = index_wday,
                            fill =ou_ind_wday)) +
  geom_bar(stat = "identity",
           position = "identity",
           colour = "black",
           alpha = 0.618) +
  geom_hline(yintercept = mean(iphh$case_index),
             linetype = "dashed",
             size = 0.75,
             colour = "blacK") +
  xlab("Day of Week") +
  ylab("Case Index") +
  ggtitle(line4) +
  theme(legend.position = "none")
iphh_ind_wday

grid.arrange(hist_iponly_case_index,
             hist_ipsn_case_index,
             hist_iphh_case_index,
             nrow = 3, ncol = 1,
             main = paste("\n", 
                          line1, "\n",
                          line2, "\n",
                          line3, "\n",
                          line4)
            )

######################################################################

####
# Durable Medical
####
ipdm <- edata[edata$DM_StartDate != "" &
              edata$SN_StartDate == "" &
              edata$OP_StartDate == "" &
              edata$HH_StartDate == "" &
              edata$HS_StartDate == ""
              ,]

ipdm_keepers <- c("HOSP_EPISODE_COUNT", "HIC_EQ", "case_index",
                  "PMT_ALL_CLM", "Std_Pmt_All_Clm",
                  "Pred_Amt_Renormal",
                  "IP_StartDate", "IP_EndDate", "IP_std_cost",
                  "ou_pred_anom", "ou_pred_diff",
                  "case_index_ou",
                  "DM_StartDate", "DM_EndDate","DM_std_cost")

ipdm <- ipdm[ipdm_keepers]

ipdm$mean_index   <- mean(ipdm$case_index)
ipdm$IP_StartDate <- mdy(ipdm$IP_StartDate)
ipdm$ipmonth <- month(ipdm$IP_StartDate, label = TRUE)
ipdm$ipweek  <- week(ipdm$IP_StartDate)
ipdm$ipday   <- day(ipdm$IP_StartDate)
ipdm$ipwday  <- wday(ipdm$IP_StartDate)

#### get index by month, week, day of month and day of week
ipdm$index_month <- ave(ipdm$case_index, ipdm$ipmonth, FUN = mean)
ipdm$index_week  <- ave(ipdm$case_index, ipdm$ipweek, FUN = mean)
ipdm$index_day   <- ave(ipdm$case_index, ipdm$ipday, FUN = mean)
ipdm$index_wday  <- ave(ipdm$case_index, ipdm$ipwday, FUN = mean)

#### get colours for the groups
ipdm$ou_ind[ipdm$case_index > 1]         <- "Over Index"
ipdm$ou_ind[ipdm$case_index <= 1]        <- "Under Index"
ipdm$ou_ind_month[ipdm$index_month > 1]  <- "Over Index"
ipdm$ou_ind_month[ipdm$index_month <= 1] <- "Under Index"
ipdm$ou_ind_week[ipdm$index_week > 1]    <- "Over Index"
ipdm$ou_ind_week[ipdm$index_week <= 1]   <- "over Index"
ipdm$ou_ind_day[ipdm$index_day > 1]      <- "Over Index"
ipdm$ou_ind_day[ipdm$index_day <= 1]     <- "Under Index"
ipdm$ou_ind_wday[ipdm$index_wday > 1]    <- "Over Index"
ipdm$ou_ind_wday[ipdm$index_wday <= 1]   <- "Under Index"

line5 <- paste("Patients with Durable Medical, Case Index =",
               round(
                 mean(ipdm$case_index),
                 digits = 2
               )
)

hist_ipdm_case_index <- ggplot(ipdm,
                               aes(x = case_index,
                                   y = ..count..,
                                   fill = ou_ind)) +
  geom_histogram(binwidth = 0.1,
                 colour = "black",
                 alpha = 0.3) +
  # Mean Overall Case Index
  geom_vline(xintercept = 1.10,
             linetype = "dashed",
             colour = "red",
             size = 1) +
  # Mean Case Index SNF
  geom_vline(xintercept = mean(ipsn$case_index),
             linetype = "dashed",
             colour = "black",
             size = 0.75) +
  # Mean Case Index Home Health
  geom_vline(xintercept = mean(iphh$case_index),
             linetype = "dashed",
             colour = "green",
             size = 0.75) +
  # Mean IP only case index
  geom_vline(xintercept = mean(ip$case_index),
             linetype = "dashed",
             colour = "brown",
             size = 0.75) +
  # Mean DM case index
  geom_vline(xintercept = mean(ipdm$case_index),
             colour = "purple",
             size = 0.75) +
  xlab("Case Index: n = 258") +
  ylab("Count") +
  ggtitle(
    "Inpatients With Durable Medical - Average Case Index = Purple Line"
          ) +
  theme(plot.title = element_text(size = 10)) +
  theme(legend.position = "none")
hist_ipdm_case_index
  
grid.arrange(hist_iponly_case_index,
             hist_ipsn_case_index,
             hist_iphh_case_index,
             hist_ipdm_case_index,
             nrow = 2, ncol = 2,
             main = paste("\n",
                          line1, "\n",
                          line2, "\n",
                          line3, "\n",
                          line4, "\n",
                          line5)
             )  
  
  
  
  
  
  
######################################################################

####
# Hospice only 6 cases no charts required
####
ipop <- edata[edata$SN_StartDate == "" &
              edata$DM_StartDate == "" &
              edata$OP_StartDate != "" &
              edata$HH_StartDate == "" &
              edata$HS_StartDate == ""
              ,]

ipop_keepers <- c("HOSP_EPISODE_COUNT", "HIC_EQ", "case_index",
                  "PMT_ALL_CLM", "Std_Pmt_All_Clm","Pred_Amt_Renormal",
                  "IP_StartDate", "IP_EndDate", "IP_std_cost",
                  "ou_pred_anom", "ou_pred_diff",
                  "case_index_ou",
                  "OP_StartDate", "OP_EndDate", "OP_std_cost")

ipop <- ipop[ipop_keepers]

ipop$mean_index   <- mean(ipop$case_index)
ipop$IP_StartDate <- mdy(ipop$IP_StartDate)
ipop$ipmonth <- month(ipop$IP_StartDate, label = TRUE)
ipop$ipweek  <- week(ipop$IP_StartDate)
ipop$ipday   <- day(ipop$IP_StartDate)
ipop$ipwday  <- wday(ipop$IP_StartDate, label = TRUE)

#### get index by month, week, day of month and day of week
ipop$index_month <- ave(ipop$case_index, ipop$ipmonth, FUN = mean)
ipop$index_week  <- ave(ipop$case_index, ipop$ipweek, FUN = mean)
ipop$index_day   <- ave(ipop$case_index, ipop$ipday, FUN = mean)
ipop$index_wday  <- ave(ipop$case_index, ipop$ipwday, FUN = mean)

#### get colours for the groups
ipop$ou_ind[ipop$case_index > 1] <- "Over Index"
ipop$ou_ind[ipop$case_index <=1] <- "Under Index"
ipop$ou_ind_month[ipop$index_month > 1]  <- "Over Index"
ipop$ou_ind_month[ipop$index_month <= 1] <- "Under Index"
ipop$ou_ind_week[ipop$index_week > 1]    <- "Over Index"
ipop$ou_ind_week[ipop$index_week <= 1]   <- "Under Index"
ipop$ou_ind_day[ipop$index_day > 1]      <- "Over Index"
ipop$ou_ind_day[ipop$index_day <= 1]     <- "Under Index"
ipop$ou_ind_wday[ipop$index_wday > 1]    <- "Over Index"
ipop$ou_ind_wday[ipop$index_wday <= 1]   <- "Under Index"

line6 <- paste("Patients with Outpatient Time, Case Index =",
               round(
                 mean(ipop$case_index),
                 digits = 2
                 )
               )

hist_ipop_case_index <- ggplot(ipop,
                               aes(x = case_index,
                                   y = ..count..,
                                   fill = ou_ind)) +
  geom_histogram(binwidth = 0.1,
                 colour = "black",
                 alpha = 0.3) +
  # Mean Overall Case Index
  geom_vline(xintercept = 1.10,
             linetype = "dashed",
             colour = "red",
             size = 1) +
  # Mean Case Index SNF
  geom_vline(xintercept = mean(ipsn$case_index),
             linetype = "dashed",
             colour = "black",
             size = 0.75) +
  # Mean Case Index Home Health
  geom_vline(xintercept = mean(iphh$case_index),
             linetype = "dashed",
             colour = "green",
             size = 0.75) +
  # Mean IP only case index
  geom_vline(xintercept = mean(ip$case_index),
             linetype = "dashed",
             colour = "brown",
             size = 0.75) +
  # Mean DM case index
  geom_vline(xintercept = mean(ipdm$case_index),
             colour = "purple",
             size = 1) +
  # Mean OP Case Index
  geom_vline(xintercept = mean(ipop$case_index),
             colour = "pink",
             linetype = "dashed",
             size = 1) +
  xlab("Case Index: n = 409") +
  ylab("Count") +
  ggtitle(
    "Inpatients With Outpatient Activity - Average Case Index = Pink Line"
  ) +
  theme(plot.title = element_text(size = 10)) +
  theme(legend.position = "none")
hist_ipop_case_index















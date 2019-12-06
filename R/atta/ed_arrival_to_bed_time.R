# Lib Load ####
install.load::install_load(
  "tidyverse"
  , "lubridate"
  , "readxl"
)

# Source functions
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\clean_names.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\optimal_bin_size.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\optimal_hist_bin_size.R")


# data to build path where graphs are to be saved
sep <- "/"
wd <- getwd()
year <- "2019"
qtr <- "q2"
graph_path <- paste0(wd,sep,year,sep,qtr,sep)
#print(graph_path)

# Get File ####
file.to.load <- tryCatch(file.choose(new = T), error = function(e)"")
# clean column names - open file and run function
erdata <- read_xlsx(file.to.load, sheet = "data") %>%#sheet = "data") %>%
  clean_names()

# Get summary and glimpse()
summary(erdata)
glimpse(erdata)

# Clean Data ####
# create data by arr_dow and arr_hr factors
# make new df
erdata_byfactor <- erdata

erdata_byfactor$arrival_dow <- wday(erdata_byfactor$arrival_d_time, 
                                    label = TRUE)  

erdata_byfactor$arrival_hr <- hour(erdata_byfactor$arrival_d_time)

erdata_byfactor$dta_dow <- wday(erdata_byfactor$decision_to_admit,
                                label = TRUE)

erdata_byfactor$dta_hr <- hour(erdata_byfactor$decision_to_admit)

# Get patient counts for each adm_provider and each ed_md
erdata_byfactor <- erdata_byfactor %>%
  group_by(edmdid) %>%
  mutate(edmd_pt_count = n_distinct(account))

erdata_byfactor <- erdata_byfactor %>%
  group_by(adm_dr_no) %>%
  mutate(admmd_pt_count = n_distinct(account))

erdata_byfactor$hospitalist_flag <- as.factor(erdata_byfactor$hospitalist_flag)

# get only edmd and admMd with 10 or more accounts
erdata_admmd_overten <- filter(erdata_byfactor, admmd_pt_count >= 10)
erdata_edmd_overten <- filter(erdata_byfactor, edmd_pt_count >= 10)

# Boot Strap ####
## get bootstrapped samples of mean time of arrival to decision to admit time
## in minutes
n = 5000
mean_arr_to_dta = rep(NA, n)
sd_arr_to_dta   = rep(NA, n)
var_arr_to_dta  = rep(NA, n)
for (i in 1:n){
  samp <- sample(
    erdata$arrival_to_dta_delta_minutes
    , 500
    , replace = TRUE
    )
  mean_arr_to_dta[i] <- mean(samp)
  sd_arr_to_dta[i]   <- sd(samp)
  var_arr_to_dta[i]  <- var(samp)
}

bw <- optBin(mean_arr_to_dta)
gName <- paste0(graph_path, "mean_time_from_arrival_to_dta.png")
png(filename = gName)
hist(mean_arr_to_dta, breaks = bw, xlab = "Delta in Minutes",
     main = "Mean time from Arrival to Decision to Admit")
dev.off()

## get bootstrapped samples of mean time of decision to admit time to
## Admit Order Entry DTime in minutes
n = 5000
mean_dta_ord_ent = rep(NA, n)
sd_dta_ord_ent   = rep(NA, n)
var_dta_ord_ent  = rep(NA, n)
for (i in 1:n){
  samp <- sample(
    erdata$dta_to_adm_ord_delta_minutes
    , 500
    , replace = TRUE
    )
  mean_dta_ord_ent[i] <- mean(samp)
  sd_dta_ord_ent[i]   <- sd(samp)
  var_dta_ord_ent[i]  <- var(samp)
}

bw <- optBin(mean_dta_ord_ent)
gName <- paste0(graph_path, "mean_time_dta_to_adm_ord_ent_dtime_in_minutes.png")
png(filename = gName)
hist(mean_dta_ord_ent, breaks = bw, xlab = "Delta in Minutes",
     main = "Mean time from Decision to Admit to Admit Order 
     Entry DTime in Minutes")
dev.off()

## get bootstrapped samples of mean time of Admit Ord Entry to Admit Confirm
## in minutes
n = 5000
mean_ord_ent_confirm = rep(NA, n)
sd_ord_ent_confirm   = rep(NA, n)
var_ord_ent_confirm  = rep(NA, n)
for (i in 1:n){
  samp <- sample(
    erdata$adm_ord_ent_to_adm_confirm_delta_minutes
    , 500
    , replace = TRUE
    )
  mean_ord_ent_confirm[i] <- mean(samp)
  sd_ord_ent_confirm[i]   <- sd(samp)
  var_ord_ent_confirm[i]  <- var(samp)
}

bw <- optBin(mean_ord_ent_confirm)
gName <- paste0(graph_path, "mean_time_from_adm_ord_ent_to_adm_confirm.png")
png(filename = gName)
hist(mean_ord_ent_confirm, breaks = bw, xlab = "Delta in Minutes",
     main = "Mean time from Admit Ord Entry to 
     Admit Confirm in Minutes")
dev.off()

## get bootstrapped samples of mean time of Admit Ord Entry to System Processed
## time in minutes
n = 5000
mean_ord_ent_sysprcs = rep(NA, n)
sd_ord_ent_sysprcs   = rep(NA, n)
var_ord_ent_sysprcs  = rep(NA, n)
for (i in 1:n){
  samp <- sample(
    erdata$adm_ord_ent_to_sys_proc_dt_delta_minutes
    , 500
    , replace = TRUE
    )
  mean_ord_ent_sysprcs[i] <- mean(samp)
  sd_ord_ent_sysprcs[i]   <- sd(samp)
  var_ord_ent_sysprcs[i]  <- var(samp)
}

bw <- optBin(mean_ord_ent_sysprcs)
gName <- paste0(graph_path, "mean_time_from_adm_ord_ent_to_sys_prcs_dt.png")
png(filename = gName)
hist(mean_ord_ent_sysprcs, breaks = bw, xlab = "Delta in Minutes",
     main = "Mean time from Admit Ord Entry to 
     System Process DT in Minutes")
dev.off()

# Viz ####
# boxplots
stats <- boxplot.stats(erdata_byfactor$arrival_to_dta_delta_minutes)$stats
gName <- paste0(graph_path,"arrival_to_dta_delta_minutes_dow.png")
png(filename = gName)
erdata_byfactor %>%
  ggplot(
    mapping = aes(
      x = arrival_dow
      , y = arrival_to_dta_delta_minutes
      , group = arrival_dow
      , fill = arrival_dow
      )
    ) +
  geom_boxplot(
    position = "dodge"
    , outlier.shape = NA
    ) +
  scale_y_continuous(limits = c(stats[1], stats[5])) +
  guides(fill = guide_legend(title = NULL)) +
  theme_bw() +
  xlab("Arrival Day of Week") +
  ylab("Arrival to Decision to Admit Delta in Minutes") +
  labs(
    title = "Arrival to Decision to Admit Delta in Minutes\nby Day of Week",
    subtitle = "Source: WellSoft, DSS"
    )
dev.off()

stats <- boxplot.stats(erdata_byfactor$arrival_to_dta_delta_minutes)$stats
gName <- paste0(graph_path, "arrival_to_dta_delta_minutes_by_hour_of_day.png")
png(filename = gName)
erdata_byfactor %>%
  ggplot(
    mapping = aes(
      x = arrival_hr
      , y = arrival_to_dta_delta_minutes
      , group = arrival_hr
      )
    ) +
  geom_boxplot(
    position = "dodge"
    , fill = "lightblue"
    , outlier.shape = NA
    ) +
  # To turn off the wiskers, just use coef = 0
  scale_y_continuous(limits = c(stats[1], stats[5])) +
  guides(fill = guide_legend(title = NULL)) +
  theme_bw() +
  xlab("Arrival Hour") +
  ylab("Arrival to Decision to Admit Delta in Minutes") +
  labs(
    title = "Arrival to Decision to Admit Delta in Minutes\nby Hour of Day",
    subtitle = "Source: WellSoft, DSS"
    )
dev.off()

stats <- boxplot.stats(erdata_byfactor$arrival_to_dta_delta_minutes)$stats
gName <- paste0(graph_path, "arrival_to_dta_delta_in_minutes_by_hour_of_day.png")
png(filename = gName)
erdata_byfactor %>%
  ggplot(
    mapping = aes(
      x = arrival_hr
      , y = arrival_to_dta_delta_minutes
      , group = arrival_hr
      )
    ) + 
  geom_boxplot(
    position = "dodge"
    , fill = "lightblue"
    , outlier.shape = NA
    ) +
  scale_y_continuous(limits = c(stats[1], stats[5])) +
  theme_bw() +
  xlab("Arrival Hour") +
  ylab("Arrival to Decision to Admit Delta in Minutes") +
  labs(
    title = "Arrival to Decision to Admit Delta in Minutes
          by Hour of Day"
    , subtitle = "Source: WellSoft, DSS"
    ) +
  facet_grid(arrival_dow ~ .)
dev.off()

# use the DTA hour and dow as the x-axis factor for the same data above
stats <- boxplot.stats(
  erdata_byfactor$arrival_to_dta_delta_minutes
)$stats
gName <- paste0(graph_path, "arrival_to_dta_by_adm_dow.png")
png(filename = gName)
erdata_byfactor %>%
  ggplot(
    mapping = aes(
      x = dta_dow
      , y = arrival_to_dta_delta_minutes
      , group = dta_dow
      , fill = dta_dow
      )
    ) +
  geom_boxplot(
    position = "dodge"
    , outlier.shape = NA
    ) +
  scale_y_continuous(limits = c(stats[1], stats[5])) +
  guides(fill = guide_legend(title = NULL)) +
  theme_bw() +
  xlab("Decision to Admit Day of Week") +
  ylab("Arrival to Decision to Admit Delta in Minutes") +
  labs(
    title = "Arrival to Decision to Admit Delta in Minutes\nby Decision to Admit Day of Week",
    subtitle = "Source: WellSoft, DSS"
    )
dev.off()

gName <- paste0(graph_path, "arrival_to_dta_by_dta_hour_of_day.png")
png(filename = gName)
erdata_byfactor %>%
  ggplot(
    mapping = aes(
      x = dta_hr
      , y = arrival_to_dta_delta_minutes
      , group = dta_hr
      )
    ) +
  geom_boxplot(
    position = "dodge"
    , fill = "lightblue"
    , outlier.shape = NA
    ) +
  # To turn off the wiskers, just use coef = 0
  scale_y_continuous(limits = c(stats[1], stats[5])) +
  guides(fill = guide_legend(title = NULL)) +
  theme_bw() +
  xlab("Decision to Admit Hour") +
  ylab("Arrival to Decision to Admit Delta in Minutes") +
  labs(
    title = "Arrival to Decision to Admit Delta in Minutes\nby Decsion to Admit Hour of day",
    subtitle = "Source: WellSoft, DSS"
    )
dev.off()

gName <- paste0(graph_path, "arrival_to_dta_by_dta_hour_of_day_by_dow.png")
png(filename = gName)
erdata_byfactor %>%
  ggplot(
    mapping = aes(
      x = dta_hr
      , y = arrival_to_dta_delta_minutes
      , group = dta_hr
      )
    ) + 
  geom_boxplot(
    position = "dodge"
    , fill = "lightblue"
    , outlier.shape = NA
    ) +
  scale_y_continuous(limits = c(stats[1], stats[5])) +
  theme_bw() +
  xlab("Decision to Admit Hour") +
  ylab("Arrival to Decision to Admit Delta in Minutes") +
  labs(
    title = "Arrival to Decision to Admit Delta in Minutes\nby DTA Hour of Day",
    subtitle = "Source: WellSoft, DSS"
    ) +
  facet_grid(dta_dow ~ .)
dev.off()

# Adm_Md only data, provider must have 10 or more encounters
# Look at Admit Decision to Admit Order DT delta, add the 75 minute bench
erdata_admmd_overten$bench <- 75

erdata_admmd_overten$ou_indicator

erdata_admmd_overten$ou_indicator[
  erdata_admmd_overten$dta_to_adm_ord_delta_minutes > 75] <- 1

erdata_admmd_overten$ou_indicator[
  erdata_admmd_overten$dta_to_adm_ord_delta_minutes <= 75] <- 0

erdata_admmd_overten <- erdata_admmd_overten %>%
  group_by(adm_dr_no) %>%
  mutate(avg_dta_admord = round(mean(dta_to_adm_ord_delta_minutes), 2))

erdata_admmd_overten$AvgInd[
  erdata_admmd_overten$avg_dta_admord > 75
  ] <- 1

erdata_admmd_overten$AvgInd[
  erdata_admmd_overten$avg_dta_admord <= 75
  ] <- 0

gName <- paste0(graph_path, "provider_perf.png")
png(filename = gName, width = 1080, height = 1057)
erdata_admmd_overten %>%
  filter(avg_dta_admord >= 0) %>%
  ggplot(
    mapping = aes(
      x = avg_dta_admord
      , y = reorder(
        adm_dr
        , avg_dta_admord
        )
      )
    ) +
  geom_segment(aes(yend = adm_dr), xend = 0, color = "grey50") +
  geom_point(size = 3, aes(color = hospitalist_flag)) +
  geom_vline(xintercept = erdata_admmd_overten$bench,
             color = "red",
             linetype = "dashed", 
             size = 1) +
  geom_vline(xintercept = mean(
    erdata_admmd_overten$dta_to_adm_ord_delta_minutes),
    color = "black",
    linetype = "dashed",
    size = 1) +
  theme_bw() +
  theme(panel.grid.major.y = element_blank()) +
  ylab("Admitting Dr") + 
  xlab("Average DTA to Admit Order Delta in Minutes") +
  labs(
    title = "Average Decision to Admit to Admit Order Time Delta in Minutes\nby Admitting Provider"
    , subtitle = "Source: WellSoft, DSS - Red Dashed Line is 75 Minutes Benchmark - Black Dashed Line is actual"
    , caption = "Provider must have 10 or more Admits"
    , color = "Hosp/Pvt"
    ) + 
  facet_grid(hospitalist_flag ~ ., scales = "free_y", space = "free_y") +
  theme_light()
dev.off()



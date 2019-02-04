# Bad Debt Survial Analysis
# Lib Load ####
library(survival)
library(KMsurv)
library(nlme)
library(km.ci)
library(survminer)
library(tidyverse)
library(anomalize)
library(funModeling)
library(tibbletime)

# Get File ####
fileToLoad <- file.choose(new = TRUE)
bd.df <- data.table::fread(fileToLoad, sep = "|")
head(bd.df, 5)
tail(bd.df, 5)
bd.df %>% glimpse()

rm(fileToLoad)

# Dedup Data ####
bd.df.dedup <- bd.df %>%
  distinct(
    PtNo_Num
    , .keep_all = T
  )

# IP and OP Tbls ####
bd.ip <- bd.df.dedup %>%
  filter(
    bd.df.dedup$Plm_Pt_Acct_Type == "I"
  )
nrow(bd.ip)

bd.op <- bd.df.dedup %>%
  filter(
    bd.df.dedup$Plm_Pt_Acct_Type == "O"
  )
nrow(bd.op)

# EDA ####
# IP EDA
df_status(bd.ip)
# Row Count
nrow(bd.ip)
# Col Count
ncol(bd.ip)
# Col names
colnames(bd.ip)
# Freq of certain variables minus plot
freq(
  data = bd.ip
  , input = c(
    'Pt_Sex'
    , 'no_of_ins_carriers'
    , 'bd_flag'
    , 'hosp_pvt'
    , 'LIHN_Svc_Line'
    )
  , plot = F
)
# At this point keep certain data need to look at previous
# output from freq() function call
lihn.tbl.ip <- freq(
  data = bd.ip
  , input = 'LIHN_Svc_Line'
  , plot = F
  )
print(lihn.tbl.ip)
lihn.tbl.ip %>% glimpse()

no.ins.carriers.tbl.ip <- freq(
  data = bd.ip
  , input = 'no_of_ins_carriers'
  , plot = F
)
print(no.ins.carriers.tbl.ip)
no.ins.carriers.tbl.ip %>% glimpse()

# Pair down data by dumping variables with very low data
lihn.keep.ip <- lihn.tbl.ip %>%
  filter(cumulative_perc < 96) %>%
  select(LIHN_Svc_Line)

no.ins.keep.ip <- no.ins.carriers.tbl.ip %>%
  filter(cumulative_perc < 96) %>%
  select(no_of_ins_carriers)

# Add keep record columns to bd.ip
bd.ip <- bd.ip %>%
  add_column(
    lihn_keep_flag = ifelse(
      bd.ip$LIHN_Svc_Line %in% lihn.keep.ip$LIHN_Svc_Line
      , 1
      , 999999
    )
  )

bd.ip <- bd.ip %>%
  add_column(
    no_ins_keep_flag = ifelse(
      bd.ip$no_of_ins_carriers %in% no.ins.keep.ip$no_of_ins_carriers
      , 1
      , 999999
    )
  )

bd.ip <- bd.ip %>%
  add_column(
    clean_record = ifelse(
      (
        bd.ip$no_ins_keep_flag == 999999 | 
        bd.ip$lihn_keep_flag == 999999
      )
      , 0
      , 1
    )
  )

bd.ip <- bd.ip %>%
  add_column(
    lihn_line_recode = ifelse(
      bd.ip$LIHN_Svc_Line %in% lihn.keep.ip$LIHN_Svc_Line
      , bd.ip$LIHN_Svc_Line
      , "Other"
    )
  )

bd.ip <- bd.ip %>%
  add_column(
    no_ins_recode = ifelse(
      bd.ip$no_of_ins_carriers %in% no.ins.keep.ip$no_of_ins_carriers
      , bd.ip$no_of_ins_carriers
      , "Other"
    )
  )

freq(
  data = bd.ip
  , input = 'clean_record'
)

# OP EDA
df_status(bd.op)
# Row Count
nrow(bd.op)
# Col Count
ncol(bd.op)
# Col Names
colnames(bd.op)
freq(
  data = bd.op
  , input = c(
    'Pt_Sex'
    , 'no_of_ins_carriers'
    , 'bd_flag'
    , 'hosp_pvt'
    , 'LIHN_Svc_Line'
    )
  , plot = F
  )

# At this point keep certain data need to look at previous
# output from freq() function call
no.ins.carriers.tbl.op <- freq(
  data = bd.op
  , input = 'no_of_ins_carriers'
  , plot = F
)
print(no.ins.carriers.tbl.op)
no.ins.carriers.tbl.op %>% glimpse()

# Pair down data by dumping variables with very low data
no.ins.keep.op <- no.ins.carriers.tbl.op %>%
  filter(cumulative_perc < 96) %>%
  select(no_of_ins_carriers)

# Add keep record columns to bd.op
bd.op <- bd.op %>%
  add_column(
    no_ins_keep_flag = if_else(
      bd.op$no_of_ins_carriers %in% no.ins.keep.op$no_of_ins_carriers
      , 1
      , 999999
    )
  )

bd.op <- bd.op %>%
  add_column(
    clean_record = if_else(
      bd.op$no_ins_keep_flag == 999999
      , 0
      , 1
    )
  )

bd.op <- bd.op %>%
  add_column(
    lihn_line_recode = bd.op$LIHN_Svc_Line
  )

bd.op <- bd.op %>%
  add_column(
    no_ins_recode = ifelse(
      bd.op$no_of_ins_carriers %in% no.ins.keep.op$no_of_ins_carriers
      , bd.op$no_of_ins_carriers
      , "Other"
    )
  )

freq(
  data = bd.op
  , input = 'clean_record'
)

# Clean Tables ####
bd.ip.clean <- bd.ip %>%
  filter(bd.ip$clean_record == 1)

bd.op.clean <- bd.op %>%
  filter(bd.op$clean_record == 1)

nrow(bd.ip)
nrow(bd.ip.clean)
nrow(bd.op)
nrow(bd.op.clean)

# Anomaly level ####
# use IQR method gesd takes to long and may produce no data
# make time aware tibble
bd.ip$dsch_date <- lubridate::ymd(bd.ip$dsch_date)
bd.ip.clean$dsch_date <- lubridate::ymd(bd.ip.clean$dsch_date)
bd.op$dsch_date <- lubridate::ymd(bd.op$dsch_date)
bd.op.clean$dsch_date <- lubridate::ymd(bd.op.clean$dsch_date)

bd.ip.ta <- as_tbl_time(bd.ip, index = dsch_date)
bd.ip.clean.ta <- as_tbl_time(bd.ip.clean, index = dsch_date)
bd.op.ta <- as_tbl_time(bd.op, index = dsch_date)
bd.op.clean.ta <- as_tbl_time(bd.op.clean, index = dsch_date)

# Make df/tibble to anomalize on only records with a bd_flag
bd.ip.ta.bdflag.tbl <- subset(
  bd.ip.ta
  , subset = (
    bd.ip.ta$bd_flag == 1
  )
)
bd.ip.clean.ta.bdflag.tbl <- subset(
  bd.ip.clean.ta
  , subset = (
    bd.ip.clean.ta$bd_flag == 1
  )
)

bd.ip.anomalized <- anomalize(
  data = bd.ip.ta.bdflag.tbl
  , target = days_to_bd
  , method = "iqr"
  , alpha = 0.05
)
freq(data = bd.ip.anomalized, input = "anomaly")

bd.ip.clean.anomalized <- anomalize(
  data = bd.ip.clean.ta.bdflag.tbl
  , target = days_to_bd
  , method = "iqr"
  , alpha = 0.05
)
freq(data = bd.ip.clean.anomalized, input = "anomaly")

bd.op.ta.bdflag.tbl <- subset(
  bd.op.ta
  , subset = (
    bd.op.ta$bd_flag == 1
  )
)

bd.op.clean.ta.bdflab.tbl <- subset(
  bd.op.clean.ta
  , subset = (
    bd.op.clean.ta$bd_flag == 1
  )
)

bd.op.anomalized <- anomalize(
  data = bd.op.ta.bdflag.tbl
  , target = days_to_bd
  , method = "iqr"
  , alpha = 0.05
)
freq(bd.op.anomalized, input = "anomaly")

bd.op.clean.anomalized <- anomalize(
  data = bd.op.clean.ta.bdflab.tbl
  , target = days_to_bd
  , method = "iqr"
  , alpha = 0.05
)
freq(bd.op.clean.anomalized, input = "anomaly")

# Viz Anomalies ####
ggplot(
  bd.ip.anomalized
  , aes(
    x = factor(anomaly)
    , y = days_to_bd
  )
) +
  geom_boxplot() +
  labs(
    title = "Inpatient Full Anomalized"
  )

ggplot(
  bd.ip.clean.anomalized
  , aes(
    x = factor(anomaly)
    , y = days_to_bd
  )
) +
  geom_boxplot() +
  labs(
    title = "Inpatient Clean Anomalized"
  )

ggplot(
  bd.op.anomalized
  , aes(
    x = factor(anomaly)
    , y = days_to_bd
  )
) +
  geom_boxplot() +
  labs(
    title = "Outpatient Full Anomalized"
  )

ggplot(
  bd.op.clean.anomalized
  , aes(
    x = factor(anomaly)
    , y = days_to_bd
  )
) +
  geom_boxplot() +
  labs(
    title = "Outpatient Clean Anomalized"
  )

# Make Model Tables ####
# BD IP Anomalized Full
bd.ip.anomalized.value <- bd.ip.anomalized %>%
  filter(anomaly == "No") %>%
  select(days_to_bd) %>%
  summarise(max(days_to_bd))

bd.ip.anomalized.value <- as.numeric(bd.ip.anomalized.value$`max(days_to_bd)`)

ip.full.model.tbl <- bd.ip.ta %>%
  add_column(
    anomaly = ifelse(
      bd.ip.ta$days_to_bd > bd.ip.anomalized.value
      , 1
      , 0
    )
  )

# BD Anomalized Clean
bd.ip.clean.anomalized.value <- bd.ip.clean.anomalized %>%
  filter(anomaly == "No") %>%
  select(days_to_bd) %>%
  summarise(max(days_to_bd))

bd.ip.clean.anomalized.value <- as.numeric(
  bd.ip.clean.anomalized.value$`max(days_to_bd)`
  )

ip.clean.model.tbl <- bd.ip.clean.ta %>%
  add_column(
    anomaly = ifelse(
      bd.ip.clean.ta$days_to_bd > bd.ip.clean.anomalized.value
      , 1
      , 0
    )
  )

# BD OP Anomalized Full
bd.op.anomalized.value <- bd.op.anomalized %>%
  filter(anomaly == "No") %>%
  select(days_to_bd) %>%
  summarise(max(days_to_bd))
bd.op.anomalized.value <- as.numeric(bd.op.anomalized.value$`max(days_to_bd)`)

# BD OP Anomalized Clean
bd.op.clean.anomalized.value <- bd.op.clean.anomalized %>%
  filter(anomaly == "No") %>%
  select(days_to_bd) %>%
  summarise(max(days_to_bd))
bd.op.clean.anomalized.value <- as.numeric(
  bd.op.clean.anomalized.value$`max(days_to_bd)`
)


bd.ip.clean.anomalized.model.tbl <- bd.ip.clean.ta %>%
  filter(days_to_bd <= bd.ip.clean.anomalized.value)
nrow(bd.ip.clean.anomalized.model.tbl)

bd.op.anomalized.model.tbl <- bd.op.ta %>%
  filter(days_to_bd <= bd.op.anomalized.value)
nrow(bd.op.anomalized.model.tbl)

bd.op.clean.anomalized.model.tbl <- bd.op.clean.ta %>%
  filter(days_to_bd <= bd.op.clean.anomalized.value)
nrow(bd.op.clean.anomalized.model.tbl)

# Survival Model ####
ip.full.anomalized.fit <- survfit(
  Surv(days_to_bd, bd_flag) ~ Pt_Sex
  , data = ip.clean.model.tbl
)
ggsurvplot(
  ip.full.anomalized.fit
  , data = ip.clean.model.tbl
  , conf.int = T
  , pval = T
  , fun = "pct"
  , risk.table = T
  , linetype = "strata"
  , legend = "bottom"
  , legend.title = "Pt Gender"
  , legend.labs = c("F", "M")
)

ip.full.anomalized.hosp.pvt.fit <- survfit(
  Surv(days_to_bd, bd_flag) ~ hosp_pvt
  , data = bd.ip.clean.anomalized.model.tbl
)
ggsurvplot(
  ip.full.anomalized.hosp.pvt.fit
  , data = bd.ip.clean.anomalized.model.tbl
  , conf.int = T
  , pval = T
  , fun = "pct"
  , risk.table = T
  , linetype = "strata"
  , legend = "bottom"
  , legend.title = "Hospitalist/Private"
  , legend.labs = c("Hospitalist", "Private")
  )

ip.full.anomalized.ins.no.fit <- survfit(
  Surv(days_to_bd, bd_flag) ~ no_ins_recode
  , data = bd.ip.anomalized.model.tbl
)
ggsurvplot(
  ip.full.anomalized.ins.no.fit
  , data = bd.ip.anomalized.model.tbl
  , conf.int = T
  , pval = T
  , fun = "pct"
  , risk.table = T
  , linetype = "strata"
  , legend = "bottom"
  , legend.title = "No Ins Carriers"
  , legend.labs = c("1","2","3","Other - 0 or 4")
  )

op.full.anomalized.lihn.fit <- survfit(
  Surv(days_to_bd, bd_flag) ~ lihn_line_recode
  , data = bd.op.anomalized.model.tbl
)
ggsurvplot(
  op.full.anomalized.lihn.fit
  , data = bd.op.anomalized.model.tbl
  , conf.int = F
  , pval = T
  , fun = "pct"
  , risk.table = T
  , linetype = "strata"
  , legend = "bottom"
  , legend.title = "LIHN Svc Line"
  , legend.labs = c(
    "Bariatric Surgery"
    , "Cardiac Cath"
    , "Cataract Removal"
    , "Colonscopy/Endo"
    , "General OP"
    , "Lap Chole"
    , "PTCA"
  )
)

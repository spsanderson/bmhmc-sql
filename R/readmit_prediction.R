# Lib Load ####
library(funModeling)
library(tidyverse)
library(Hmisc)
library(reshape2)
library(caret)
library(minerva)
library(missForest)
library(gridExtra)
library(mice)
library(Lock5Data)
library(corrplot)
library(RColorBrewer)
library(infotheo)

# Get File ####
fileToLoad <- file.choose(new = T)
df <- readxl::read_xlsx(path = fileToLoad, sheet = "data")
df %>% glimpse()

# DF Health ####
df_status(df)
nrow(df)
ncol(df)
colnames(df)

freq(
  data = df
  , input = 'modflaceval'
  , na.rm = T
)

freq(
  data = df
  , input = 'readmit_year'
  , na.rm = T
)

freq(
  data = df
  , input = 'READMIT_FLAG'
  , na.rm = T
)

freq(
  data = df
  , input = 'GENDER'
  , na.rm = T
)
freq(
  data = df
  , input = 'HOSP_PVT'
  , na.rm = T
)
freq(
  data = df
  , input = 'INIT_LIHN_SVC'
  , na.rm = T
)
freq(
  data = df
  , input = 'INIT_HOSP_SVC'
  , na.rm = T
)

describe(df)
correlation_table(data = df, target = 'READMIT_FLAG')
cor(df$modflaceval, df$READMIT_FLAG)
mine(df$AGE_AT_INIT_ADMIT, df$modflaceval)

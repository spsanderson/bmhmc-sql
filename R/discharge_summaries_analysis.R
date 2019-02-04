# Lib Load ####
library(readxl)
library(tidyverse)
library(lubridate)
library(anomalize)
library(tibbletime)
library(funModeling)

# Get File ####
fileToLoad <- file.choose(new = T)
df <- read_xlsx(
  path = fileToLoad
  , sheet = "data"
)

# Time Aware Tibble ####
df.ta <- as_tbl_time(df, index = Dsch_DTime)
head(df.ta, 5)
df.ta %>% glimpse()

# Opt Bin Hist ####
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# 2006 Author Hideaki Shimazaki
# Department of Physics, Kyoto University
# shimazaki at ton.scphys.kyoto-u.ac.jp
# Please feel free to use/modify/distribute this program.
sshist <- function(x){
  
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
  h = hist(x, breaks = edges)
  rug(x)
  
  return(h)
}

# Clean data ####
# Get rid of records with no discharge summary
df.ta.clean <- df.ta %>%
  filter(DSCH_SUMMARY_FLAG == 1)

sshist(df.ta.clean$HRS_DC_to_DCS)

# Anomalize ####
df.ta.clean.anomalized <- anomalize(
  data = df.ta.clean
  , target = HRS_DC_to_DCS
  , method = "gesd"
  , alpha = 0.05
)

freq(
  data = df.ta.clean.anomalized
  , input = "anomaly"
)

ggplot(
  df.ta.clean.anomalized
  , aes(
    x = factor(anomaly)
    , y = HRS_DC_to_DCS
  )
) +
  geom_boxplot()

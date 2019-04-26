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
library(AppliedPredictiveModeling)
library(fitdistrplus)
library(timetk)

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
  , input = 'Hosp_Pvt'
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

num.cols <- sapply(df, is.numeric)
cor.data <- cor(df[, num.cols])
corrplot(cor.data, method = 'color')
mine(df$AGE_AT_INIT_ADMIT, df$modflaceval)

# Bin Size ####
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

# Viz Data ####
# Mean LACE Score of Non Readmits
hist_lace_non_ra <- df%>%
  filter(df$READMIT_FLAG == 0 && df$modflaceval >= 0) %>%
  ggplot(
    aes(
      x = modflaceval
      )
    ) +
  geom_histogram(
    color = "black"
    , fill = "blue"
    , alpha = 0.618
    , binwidth = 1
  ) +
  labs(
    title = "Histogram of LACE Score for Non-Readmits"
    , subtitle = paste(
      "Mean LACE Score = "
      , df %>% 
        filter(READMIT_FLAG == 0 & modflaceval >= 0) %>%
        dplyr::select(modflaceval) %>%
        summarize(round(mean(modflaceval), 2))
    )
    , x = "LACE Score"
    , y = "Count"
    , caption = "READMIT_FLAG = 0 & Total LACE >= 0"
  )
print(hist_lace_non_ra)

# Mean Lace for Readmits
hist_lace_ra <- df %>%
  filter(df$READMIT_FLAG == 1 & df$modflaceval >= 0) %>%
  ggplot(
    aes(
      x = modflaceval
    )
  ) +
  geom_histogram(
    color = "black"
    , fill = "red"
    , alpha = 0.618
    , binwidth = 1
  ) +
  labs(
    title = "Histogram of LACE Score for Readmits"
    , subtitle = paste(
      "Mean LACE Score = "
      , df %>% 
          filter(READMIT_FLAG == 1 & modflaceval >= 0) %>%
          dplyr::select(modflaceval) %>%
          summarize(round(mean(modflaceval), 2))
    )
    , x = "LACE Score"
    , y = "Count"
    , caption = "READMIT_FLAG = 1 & Total LACE >= 0"
  )
print(hist_lace_ra)

hist_lace_both <- df %>% 
  ggplot(
    aes(
      x = modflaceval
      , fill = as.factor(READMIT_FLAG)
      )
    ) +
  stat_density(
    position = "identity"
    , bw = 1
    , alpha = 0.618
    , color = "black"
  ) + 
  labs(
    title = "LACE Score Distributions for Readmits and Non-Readmits"
    , subtitle = paste0(
      "Readmit Mean LACE Score = "
      , df %>% 
        filter(READMIT_FLAG == 1 & modflaceval >= 0) %>%
        dplyr::select(modflaceval) %>%
        summarize(round(mean(modflaceval), 2))
      , "\n"
      , "Non-Readmit Mean LACE Score = "
      , df %>%
        filter(READMIT_FLAG == 0 & modflaceval >= 0) %>%
        dplyr::select(modflaceval) %>%
        summarize(round(mean(modflaceval), 2))
    )
    , x = "LACE Score"
    , y = "Density"
    , fill = "Readmit 0/1"
  ) +
  theme(
    legend.background = element_blank()
    , legend.key = element_blank()
    )
print(hist_lace_both)

hist_lace_boxplot <- ggplot(
  data = df
  , aes(
    x = as.factor(READMIT_FLAG)
    , y = modflaceval
    , fill = as.factor(READMIT_FLAG)
  )
) +
  geom_boxplot(
    outlier.size = 1.5
    , outlier.shape = 21
    , outlier.color =  "red"
    , outlier.fill = "red"
  ) +
  stat_summary(
    fun.y = "mean"
    , geom = "point"
    , shape = 23
    , size = 3
    , fill = "white"
  ) +
  labs(
    title = "Readmit/Non-Readmit LACE Score Boxplot"
    , x = "Readmit/Non-Readmit"
    , y = "LACE Score"
    , fill = "Radmit 0/1"
  ) +
  theme(
    legend.background = element_blank()
    , legend.key = element_blank()
  )
print(hist_lace_boxplot)

gridExtra::grid.arrange(
  hist_lace_non_ra
  , hist_lace_ra
  , hist_lace_both
  , hist_lace_boxplot
  , nrow = 2
  , ncol = 2
)

# Now LACE by Hosp/Pvt
hist_lace_non_ra_hp <- df%>%
  filter(
    df$READMIT_FLAG == 0 &
      df$modflaceval >= 0
    ) %>%
  ggplot(
    aes(
      x = modflaceval
      , fill = Hosp_Pvt
    )
  ) +
  stat_density(
    position = "identity"
    , bw = 1
    , alpha = 0.618
    , color = "black"
  ) +
  labs(
    title = "Histogram of LACE Score for Non-Readmits"
    , subtitle = paste0(
      "Mean LACE Score for Hospitalists = "
      , df %>% 
        filter(
          df$READMIT_FLAG == 0 &
            df$modflaceval >= 0 &
            df$Hosp_Pvt == "HOSPITALIST"
          ) %>%
        dplyr::select(modflaceval) %>%
        summarize(round(mean(modflaceval), 2))
      , "\n"
      , "Mean LACE Score for Private = "
      , df %>% 
        filter(
          df$READMIT_FLAG == 0 &
            df$modflaceval >= 0 &
            df$Hosp_Pvt == "PRIVATE"
        ) %>%
        dplyr::select(modflaceval) %>%
        summarize(round(mean(modflaceval), 2))
    )
    , x = "LACE Score"
    , y = "Count"
    , caption = "READMIT_FLAG = 0 & Total LACE >= 0"
  )
print(hist_lace_non_ra_hp)

# Mean Lace for Readmits
hist_lace_ra_hp <- df %>%
  filter(
    df$READMIT_FLAG == 1 & 
      df$modflaceval >= 0
    ) %>%
  ggplot(
    aes(
      x = modflaceval
      , fill = Hosp_Pvt
    )
  ) +
  stat_density(
    position = "identity"
    , bw = 1
    , alpha = 0.618
    , color = "black"
  ) +
  labs(
    title = "Histogram of LACE Score for Readmits"
    , subtitle = paste0(
      "Mean LACE Score for Hospitalists = "
      , df %>% 
        filter(
          df$READMIT_FLAG == 1 &
            df$modflaceval >= 0 &
            df$Hosp_Pvt == "HOSPITALIST"
        ) %>%
        dplyr::select(modflaceval) %>%
        summarize(round(mean(modflaceval), 2))
      , "\n"
      , "Mean LACE Score for Private = "
      , df %>% 
        filter(
          df$READMIT_FLAG == 1 &
            df$modflaceval >= 0 &
            df$Hosp_Pvt == "PRIVATE"
        ) %>%
        dplyr::select(modflaceval) %>%
        summarize(round(mean(modflaceval), 2))
    )
    , x = "LACE Score"
    , y = "Count"
    , caption = "READMIT_FLAG = 1 & Total LACE >= 0"
  )
print(hist_lace_ra_hp)

hist_lace_boxplot_hp <- ggplot(
  data = df
  , aes(
    x = as.factor(Hosp_Pvt)
    , y = modflaceval
    , fill = as.factor(READMIT_FLAG)
  )
) +
  geom_boxplot(
    outlier.size = 1.5
    , outlier.shape = 21
    , outlier.color =  "red"
    , outlier.fill = "red"
  ) +
  stat_summary(
    fun.y = "mean"
    , geom = "point"
    , shape = 23
    , size = 3
    , fill = "white"
  ) +
  labs(
    title = "Readmit/Non-Readmit LACE Score Boxplot"
    , x = ""
    , y = "LACE Score"
    , fill = "Radmit 0/1"
  ) +
  theme(
    legend.background = element_blank()
    , legend.key = element_blank()
  )
print(hist_lace_boxplot_hp)

gridExtra::grid.arrange(
  hist_lace_non_ra_hp
  , hist_lace_ra_hp
  , hist_lace_boxplot_hp
  , nrow = 2
  , ncol = 2
)



descdist(df$modflaceval)
fit.weibull <- fitdist(df$modflaceval, "weibull")
fit.norm <- fitdist(df$modflaceval, "norm")
plot(fit.weibull)
plot(fit.norm)
fit.weibull$aic
fit.norm$aic

df %>%
  filter(Days_To_Readmit >= 0) %>%
  ggplot(
    aes(
      x = Days_To_Readmit
    )
  ) +
  geom_histogram(
    binwidth = 1
    , fill = "white"
    , color = "black"
  )

df %>%
  filter(READMIT_FLAG == 1 & Days_To_Readmit >= 0) %>%
  ggplot(
    aes(
      x = Days_To_Readmit
      , color = GENDER
    )
  ) +
  stat_ecdf()

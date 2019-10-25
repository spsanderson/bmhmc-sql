# Lib Load ####
install.load::install_load(
  "funModeling"
  , "tidyverse"
  , "Hmisc"
  , "minerva"
  , "missForest"
  , "corrplot"
  , "RColorBrewer"
  , "infotheo"
  , "AppliedPredictiveModeling"
  , "fitdistrplus"
  , "esquisse"
  , "DataExplorer"
  , "mlr"
  , "rJava"
  , "DALEX"
  , "fastDummies"
  , "caTools"
  , "FSelector"
  , "gbm"
)
options(scipen = 999) # prevent printing in scientific notation

# Get File ####
fileToLoad <- file.choose(new = T)
df <- readxl::read_xlsx(path = fileToLoad, sheet = "data")
df %>% glimpse()

# DF Health ####
df_status(df)
nrow(df)
ncol(df)
colnames(df)
plot_missing(df)
#create_report(df)
str(df)
df <- as_tibble(df)

# Change some columns to factor/char
df$med_rec_no <- as.character(df$med_rec_no)
df$Init_Acct <- as.character(df$Init_Acct)
df$Init_Attn_ID <- factor(df$Init_Attn_ID)
df$Init_Attn_Specialty <- factor(df$Init_Attn_Specialty)
df$Init_LIHN_Svc <- factor(df$Init_LIHN_Svc)
df$Init_Hosp_Pvt <- factor(df$Init_Hosp_Pvt)
df$Init_Hosp_Svc <- factor(df$Init_Hosp_Svc)
df$READMIT_FLAG <- factor(df$READMIT_FLAG)
df$Init_Disp <- factor(df$Init_Disp)
df$Age_Bucket <- factor(df$Age_Bucket)
df$Gender <- factor(df$Gender)
df$Has_Diabetes <- factor(df$Has_Diabetes)
str(df)

freq(
  data = df
  , input = 'Init_LACE'
  , na.rm = T
)

freq(
  data = df
  , input = 'Init_Disp'
  , na.rm = T
)

freq(
  data = df
  , input = 'READMIT_FLAG'
  , na.rm = T
)

freq(
  data = df %>% filter(Days_To_Readmit != 'NULL')
  , input = 'Days_To_Readmit'
  , na.rm = T
)

freq(
  data = df
  , input = 'Gender'
  , na.rm = T
)

freq(
  data = df
  , input = 'Init_Hosp_Pvt'
  , na.rm = T
)

freq(
  data = df
  , input = 'Init_LIHN_Svc'
  , na.rm = T
)

freq(
  data = df
  , input = 'Init_Hosp_Svc'
  , na.rm = T
)

freq(
  data = df
  , input = "Age_Bucket"
  , na.rm = T
)

freq(
  data = df
  , input = "Init_ROM"
  , na.rm = T
)

freq(
  data = df
  , input = "Init_SOI"
  , na.rm = T
)

freq(
  data = df
  , input = "Has_Diabetes"
  , na.rm = T
)

freq(
  data = df
  , input = "Init_Attn_Specialty"
  , na.rm = T
)

describe(df)

num.cols <- sapply(df, is.numeric)
cor.data <- cor(df[, num.cols])
corrplot(cor.data, method = 'color')

# Functions ####
# Bin Size functions
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

# Not in Function
'%ni%' <- Negate('%in%')

# Reduce Init_Disp
reduce_dispo_func <- function(dispo){
  dispo <- as.character(dispo)
  if_else(
    dispo %ni% c('AHR','ATE','ATW','ATL','AMA','ATH')
    , 'Other'
    , dispo
    )
}

reduce_hsvc_func <- function(hsvc){
  hsvc <- as.character(hsvc)
  if_else(
    hsvc %ni% c('MED','SDU','PSY','SIC','SUR')
    , 'Other'
    , hsvc
  )
}

reduce_agebucket_func <- function(abucket){
  abucket <- as.character(abucket)
  if_else(
    abucket %ni% c(as.character(seq(1:7)))
    , 'Other'
    , abucket
  )
}

reduce_spclty_func <- function(spclty){
  spclty <- as.character(spclty)
  if_else(
    spclty %ni% c('HOSIM','FAMIP','IMDIM','GSGSG','PSYPS','SURSG')
    , 'Other'
    , spclty
  )
}

reduce_lihn_func <- function(lihn){
  lihn <- as.character(lihn)
  if_else(
    lihn %ni% c(
      'Medical',
      'Surgical',
      'CHF',
      'COPD',
      'Cellulitis',
      'Pneumonia',
      'Major Depression/Bipolar Affective Disorders',
      'MI',
      'GI Hemorrhage',
      'PTCA',
      'CVA',
      'Alcohol Abuse',
      'Schizophrenia',
      'Laparoscopic Cholecystectomy'
    )
    , 'Other'
    , lihn
  )
}

# F1 confusion matrix score
conf_mat_f1_func <- function(model){
  f1 = 2* (
    (
      calculateROCMeasures(model)$measures$ppv * 
        calculateROCMeasures(model)$measures$tpr
    )
    / 
      (
        calculateROCMeasures(model)$measures$ppv + 
          calculateROCMeasures(model)$measures$tpr
      )
  )
  return(f1)
}

# ROC and Threshold V Performance
perf_plots_func <- function(Model1){
  
  # Model name
  mod1 <- deparse(substitute(Model1))

  # Model 1 ROC Plot
  mod1.roc.plt <- plotROCCurves(
    generateThreshVsPerfData(
      Model1
      , measures = list(fpr, tpr)
    )
  ) +
    labs(
      title = paste0(
        "AUC of "
        , mod1
        , " = "
        , round(
          mlr::performance(Model1, mlr::auc)
          , 4
        ) * 100
        , "%"
      )
      , subtitle = paste0(
        "F1 Score = "
        , round(conf_mat_f1_func(Model1), 4)
      )
    ) +
    theme_bw()
  
  # Model 1 Threshold Vs Performance Plot
  mod1.ThresVsPerf.plt <- plotThreshVsPerf(
    generateThreshVsPerfData(
      Model1
      , measures = list(fpr, tpr, mmce)
    )
  )
  
    return(
    gridExtra::grid.arrange(
       nrow = 2
      , mod1.roc.plt
      , mod1.ThresVsPerf.plt
    )
  )
}

# Viz Data ####
# Mean LACE Score of Non Readmits
hist_lace_non_ra <- df%>%
  filter(READMIT_FLAG == "N" && Init_LACE >= 0) %>%
  ggplot(
    aes(
      x = Init_LACE
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
        filter(READMIT_FLAG == 'N' & Init_LACE >= 0) %>%
        dplyr::select(Init_LACE) %>%
        dplyr::summarize(round(mean(Init_LACE), 2))
    )
    , x = "LACE Score"
    , y = "Count"
    , caption = "READMIT_FLAG = N & Total LACE >= 0"
  )
print(hist_lace_non_ra)

# Mean Lace for Readmits
hist_lace_ra <- df %>%
  filter(df$READMIT_FLAG == 'Y' & df$Init_LACE >= 0) %>%
  ggplot(
    aes(
      x = Init_LACE
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
          filter(READMIT_FLAG == 'Y' & Init_LACE >= 0) %>%
          dplyr::select(Init_LACE) %>%
          dplyr::summarize(round(mean(Init_LACE), 2))
    )
    , x = "LACE Score"
    , y = "Count"
    , caption = "READMIT_FLAG = Y & Total LACE >= 0"
  )
print(hist_lace_ra)

hist_lace_both <- df %>% 
  ggplot(
    aes(
      x = Init_LACE
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
        filter(READMIT_FLAG == 'Y' & Init_LACE >= 0) %>%
        dplyr::select(Init_LACE) %>%
        dplyr::summarize(round(mean(Init_LACE), 2))
      , "\n"
      , "Non-Readmit Mean LACE Score = "
      , df %>%
        filter(READMIT_FLAG == 'N' & Init_LACE >= 0) %>%
        dplyr::select(Init_LACE) %>%
        dplyr::summarize(round(mean(Init_LACE), 2))
    )
    , x = "Initial LACE Score"
    , y = "Density"
    , fill = "Readmit N/Y"
  ) +
  theme(
    legend.background = element_blank()
    , legend.key = element_blank()
    ) +
  theme_bw()
print(hist_lace_both)

hist_lace_boxplot <- ggplot(
  data = df
  , aes(
    x = as.factor(READMIT_FLAG)
    , y = Init_LACE
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
    , fill = "Readmit N/Y"
  ) +
  theme(
    legend.background = element_blank()
    , legend.key = element_blank()
  ) +
  theme_bw()
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
    df$READMIT_FLAG == 'N' &
      df$Init_LACE >= 0
    ) %>%
  ggplot(
    aes(
      x = Init_LACE
      , fill = Init_Hosp_Pvt
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
          df$READMIT_FLAG == 'N' &
            df$Init_LACE >= 0 &
            df$Init_Hosp_Pvt == "HOSPITALIST"
          ) %>%
        dplyr::select(Init_LACE) %>%
        dplyr::summarize(round(mean(Init_LACE), 2))
      , "\n"
      , "Mean LACE Score for Private = "
      , df %>% 
        filter(
          df$READMIT_FLAG == 'N' &
            df$Init_LACE >= 0 &
            df$Init_Hosp_Pvt == "PRIVATE"
        ) %>%
        dplyr::select(Init_LACE) %>%
        dplyr::summarize(round(mean(Init_LACE), 2))
    )
    , x = "LACE Score"
    , y = "Count"
    , caption = "READMIT_FLAG = N & Total LACE >= 0"
    , fill = "Hosp/Pvt"
  ) +
  theme(
    legend.background = element_blank()
    , legend.key = element_blank()
  ) +
  theme_bw()
print(hist_lace_non_ra_hp)

# Mean Lace for Readmits
hist_lace_ra_hp <- df %>%
  filter(
    df$READMIT_FLAG == 'Y' & 
      df$Init_LACE >= 0
    ) %>%
  ggplot(
    aes(
      x = Init_LACE
      , fill = Init_Hosp_Pvt
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
          df$READMIT_FLAG == 'Y' &
            df$Init_LACE >= 0 &
            df$Init_Hosp_Pvt == "HOSPITALIST"
        ) %>%
        dplyr::select(Init_LACE) %>%
        dplyr::summarize(round(mean(Init_LACE), 2))
      , "\n"
      , "Mean LACE Score for Private = "
      , df %>% 
        filter(
          df$READMIT_FLAG == 'Y' &
            df$Init_LACE >= 0 &
            df$Init_Hosp_Pvt == "PRIVATE"
        ) %>%
        dplyr::select(Init_LACE) %>%
        dplyr::summarize(round(mean(Init_LACE), 2))
    )
    , x = "LACE Score"
    , y = "Count"
    , caption = "READMIT_FLAG = Y & Total LACE >= 0"
    , fill = "Hosp/Pvt"
  ) +
  theme(
    legend.background = element_blank()
    , legend.key = element_blank()
  ) +
  theme_bw()
print(hist_lace_ra_hp)

hist_lace_boxplot_hp <- ggplot(
  data = df
  , aes(
    x = as.factor(Init_Hosp_Pvt)
    , y = Init_LACE
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
    , fill = "Radmit N/Y"
  ) +
  theme(
    legend.background = element_blank()
    , legend.key = element_blank()
  ) +
  theme_bw()
print(hist_lace_boxplot_hp)

gridExtra::grid.arrange(
  hist_lace_non_ra_hp
  , hist_lace_ra_hp
  , hist_lace_boxplot_hp
  , nrow = 2
  , ncol = 2
)

# Lace Score Distribution Description
descdist(df$Init_LACE)
fit.weibull <- fitdist(df$Init_LACE, "weibull")
fit.norm <- fitdist(df$Init_LACE, "norm")
plot(fit.weibull)
plot(fit.norm)
fit.weibull$aic
fit.norm$aic

# Interim days overall
df %>%
  filter(Days_To_Readmit >= 0) %>%
  ggplot(
    aes(
      x = Days_To_Readmit
    )
  ) +
  geom_histogram(
    binwidth = 1
    , fill = "lightblue"
    , color = "black"
    , alpha = 0.618
  ) +
  theme_bw() +
  labs(
    title = "Histogram of Days from Discharge to Readmit"
    , subtitle = paste0(
      "Avg Days until Readmission: "
      , df %>%
        filter(Days_To_Readmit >= 0) %>%
        dplyr::summarize(round(mean(Days_To_Readmit), 2))
    )
    , x = "Interim Days"
    , y = "Count"
  )

# Interim Days by Hosp/Pvt
df %>%
  filter(Days_To_Readmit >= 0) %>%
  ggplot(
    aes(
      x = Days_To_Readmit
      , fill = Init_Hosp_Pvt
    )
  ) +
  geom_histogram(
    binwidth = 1
    , color = "black"
    , alpha = 0.618
  ) +
  theme_bw() +
  labs(
    title = "Histogram of Days from Discharge to Readmit"
    , subtitle = paste0(
      "Avg Days until Readmit Hospitalist: "
      , df %>%
        filter(Init_Hosp_Pvt == "HOSPITALIST") %>%
        filter(Days_To_Readmit >= 0) %>%
        dplyr::summarize(round(mean(Days_To_Readmit), 2))
      , "\n"
      , "Avg Days unitl Readmit Private: "
      , df %>%
        filter(Init_Hosp_Pvt == 'PRIVATE') %>%
        filter(Days_To_Readmit >= 0) %>%
        dplyr::summarize(round(mean(Days_To_Readmit), 2))
    )
    , x = "Interim Days"
    , y = "Count"
    , fill = 'Hospt / Pvt'
  )

# Interim Days by Hosp/Pvt density plot
df %>%
  filter(Days_To_Readmit >= 0) %>%
  ggplot(
    aes(
      x = Days_To_Readmit
      , fill = Init_Hosp_Pvt
    )
  ) +
  stat_density(
    position = "identity"
    , bw = 1
    , alpha = 0.618
    , color = "black"
  ) +
  theme_bw() +
  labs(
    title = "Histogram of Days from Discharge to Readmit"
    , subtitle = paste0(
      "Avg Days until Readmit Hospitalist: "
      , df %>%
        filter(Init_Hosp_Pvt == "HOSPITALIST") %>%
        filter(Days_To_Readmit >= 0) %>%
        dplyr::summarize(round(mean(Days_To_Readmit), 2))
      , "\n"
      , "Avg Days unitl Readmit Private: "
      , df %>%
        filter(Init_Hosp_Pvt == 'PRIVATE') %>%
        filter(Days_To_Readmit >= 0) %>%
        dplyr::summarize(round(mean(Days_To_Readmit), 2))
    )
    , x = "Interim Days"
    , y = "Count"
    , fill = 'Hospt / Pvt'
  )

df %>%
  filter(READMIT_FLAG == 'Y' & Days_To_Readmit >= 0) %>%
  ggplot(
    aes(
      x = Days_To_Readmit
      , color = Gender
    )
  ) +
  stat_ecdf()

# Pre-Processing ####
# column reductions
df$reduced_dispo <- sapply(df$Init_Disp, reduce_dispo_func)
df$reduced_hsvc <- sapply(df$Init_Hosp_Svc, reduce_hsvc_func)
df$reduced_abucket <- sapply(df$Age_Bucket, reduce_agebucket_func)
df$reduced_spclty <- sapply(df$Init_Attn_Specialty, reduce_spclty_func)
df$reduced_lihn <- sapply(df$Init_LIHN_Svc, reduce_lihn_func)
df$discharge_month <- lubridate::month(df$Init_dsch_date)

# We don't need all columns, drop those not needed
base.mod.df <- df %>%
  dplyr::select(
    -med_rec_no
    , -Init_adm_date
    , -Init_dsch_date
    , -Readmit_Date
    , -Init_Attn_ID
    , -Init_Attn_Name
    , -Init_Attn_Specialty
    , -Init_Disp
    , -Init_Hosp_Svc
    , -Init_LIHN_Svc
    , -Days_To_Readmit
    )
str(base.mod.df)
base.mod.df$reduced_dispo <- factor(base.mod.df$reduced_dispo)
base.mod.df$reduced_hsvc <- factor(base.mod.df$reduced_hsvc)
base.mod.df$reduced_abucket <- factor(base.mod.df$reduced_abucket)
base.mod.df$reduced_spclty <- factor(base.mod.df$reduced_spclty)
base.mod.df$reduced_lihn <- factor(base.mod.df$reduced_lihn)
base.mod.df$discharge_month <- factor(base.mod.df$discharge_month)

df.dummy <- dummy_cols(base.mod.df %>% dplyr::select(-Init_Acct))

nzv.base <- caret::nearZeroVar(base.mod.df, saveMetrics = T)
head(nzv.base, 2)
nzv.dummy <- caret::nearZeroVar(df.dummy, saveMetrics = T)
head(nzv.dummy, 2)

# drop near zero variance columns from df's
# the below may drop all columns, if so then use base.mod.df
base.mod.df.final <- base.mod.df[, -caret::nearZeroVar(base.mod.df)]
df.dummy.final <- df.dummy[, -caret::nearZeroVar(df.dummy)]

# Split Data ####
split <- sample.split(base.mod.df$READMIT_FLAG, SplitRatio = 0.7)
train <- subset(base.mod.df, split == T)
test  <- subset(base.mod.df, split == F)

split.dummy <- sample.split(df.dummy.final$READMIT_FLAG, SplitRatio = 0.7)
train.dummy <- subset(df.dummy.final, split == T)
test.dummy  <- subset(df.dummy.final, split == F)

# Logit Model ####
# Use base data
train.mod <- glm(
  formula = READMIT_FLAG ~ . 
  -Age_Bucket 
  -Age_at_Init_Admit
  #-Gender
  -reduced_abucket
  -reduced_lihn
  -reduced_hsvc
  -Init_Acct
  , family = binomial(link = "logit")
  , data = train
  , maxit = 1000
)
summary(train.mod)
train.mod.aic <- sweep::sw_glance(train.mod)$AIC
print(train.mod.aic)

# Use step()
train.mod.step <- step(object = train.mod, scale = 0, k = 2)
summary(train.mod.step)
train.mod.step.aic <- sweep::sw_glance(train.mod.step)$AIC
print(train.mod.step.aic)

# Use dummied data
train.mod.dummied <- glm(
  formula = READMIT_FLAG ~ .
  , family = binomial(link = "logit")
  , data = train.dummy
  , maxit = 1000
)
summary(train.mod.dummied)
train.mod.dummied.aic <- sweep::sw_glance(train.mod.dummied)$AIC
print(train.mod.dummied.aic)

# Train Confusion Matrix
test$predicted.readmit <- predict(
  train.mod.step
  , newdata = test
  , type = 'response'
)
conf.mat <- as.matrix(table(test$READMIT_FLAG, test$predicted.readmit > 0.5))
model.acc <- (conf.mat[1,1]+conf.mat[2,2])/sum(conf.mat)
model.recall <- conf.mat[1,1]/(conf.mat[1,1]+conf.mat[1,2])
model.precision <-  conf.mat[1,1]/(conf.mat[1,1]+conf.mat[2,1])


test.dummy$predicted.readmit <- predict(
  train.mod.dummied
  , newdata = test.dummy
  , type = 'response'
  )
# conf.mat <- as.matrix(
#   table(
#     test.dummy$READMIT_FLAG, test.dummy$predicted.readmit > 0.5
#     )
#   )
# model.acc <- (conf.mat[1,1]+conf.mat[2,2])/sum(conf.mat)
# model.recall <- conf.mat[1,1]/(conf.mat[1,1]+conf.mat[1,2])
# model.precision <-  conf.mat[1,1]/(conf.mat[1,1]+conf.mat[2,1])

# Use MLR ####
# convert test/train to pure data.frame
glimpse(test)
test$predicted.readmit <- NULL

train.df <- data.frame(train)
test.df <- data.frame(test)
str(train.df)
str(test.df)

# Make classif tasks
trainTask <- makeClassifTask(
  data = train.df %>% dplyr::select(-Init_Acct)
  , target = "READMIT_FLAG"
  , positive = "Y"
  )
testTask <- makeClassifTask(
  data = test.df %>% dplyr::select(-Init_Acct)
  , target = "READMIT_FLAG"
  , positive = "Y"
  )

# Check trainTask and testTask
trainTask <- smote(trainTask, rate = 6) #standardizes data
testTask <- smote(testTask, rate = 6)
table(getTaskTargets(trainTask))

# Feature importance
lm.feat <- generateFilterValuesData(
  trainTask
  , method = c(
    "FSelector_information.gain"
    , "FSelector_chi.squared"
  )
)
plotFilterValues(lm.feat)

# MLR Logit ####
logistic.learner <- makeLearner(
  'classif.logreg'
  , predict.type = 'prob'
)
plotLearnerPrediction(logistic.learner, trainTask)

# Cross Validate
logistic.cv <- crossval(
  learner = logistic.learner
  , task = trainTask
  , iters = ncol(train)
  , stratify = T
  , measures = acc
  , show.info = T
)
logistic.cv$aggr
logistic.cv$measures.test

# train model
logistic.train.model <- train(logistic.learner, trainTask)
getLearnerModel(logistic.train.model)
plotLearningCurve(
  generateLearningCurveData(
    logistic.learner
    , trainTask
    )
  )

# predict on test
logistic.test.model <- predict(logistic.train.model, testTask)
plotResiduals(logistic.test.model)

# Create submission file
logistic.test.model$data$response
submit <- data.frame(
  logistic.test.model$data
)
head(submit, 5)
table(submit$truth, submit$response)

# confusion matrix
calculateConfusionMatrix(logistic.test.model)
calculateROCMeasures(logistic.test.model)
conf_mat_f1_func(logistic.test.model)

perf_plots_func(
  Model1 = logistic.test.model
)

# Tree Model ####
makeatree <- makeLearner(
  'classif.rpart'
  , predict.type = 'prob'
)
plotLearnerPrediction(makeatree, trainTask)

# Cross Validate
tree.cv <- makeResampleDesc(
  "CV"
  , iters = 3
)

# grid search hyper-parameter tuning
tree.gs <- makeParamSet(
  makeIntegerParam('minsplit', lower = 5, upper = 50)
  , makeIntegerParam('minbucket', lower = 5, upper = 50)
  , makeNumericParam('cp', lower = 0.001, upp = 0.2)
)

# Grid search
tree.gscontrol <- makeTuneControlGrid()

# Tupe hyper-parameters
tree.tune <- tuneParams(
  learner = makeatree
  , resampling = tree.cv
  , task = trainTask
  , par.set = tree.gs
  , control = tree.gscontrol
)

tree.tune$x
tree.tune$y

# Use hyper-parameters for modeling
tree.model <- setHyperPars(makeatree, par.vals = tree.tune$x)

# Train the model
tree.model.training <- train(tree.model, trainTask)
getLearnerModel(tree.model.training)
plotLearningCurve(
  generateLearningCurveData(
    tree.model
    , trainTask
  )
)

# Predictions
tree.model.predictions <- predict(
  tree.model.training
  , testTask
  )
plotResiduals(tree.model.predictions)

# Submit file
tree.submit <- data.frame(
  tree.model.predictions$data
)
head(tree.submit, 5)
table(tree.submit$truth, tree.submit$response)

# Tree confusion matrix
calculateConfusionMatrix(tree.model.predictions)
calculateROCMeasures(tree.model.predictions)
conf_mat_f1_func(tree.model.predictions)

perf_plots_func(
  Model1 = tree.model.predictions
)

# Random forest ####
getParamSet("classif.randomForest")

# Make learner
rf.learner <- makeLearner(
  "classif.randomForest"
  , predict.type = "prob"
  , par.vals = list(
    ntree = 200
    , mtry = 3
  )
)
rf.learner$par.vals <- list(importance = T)
plotLearnerPrediction(rf.learner, trainTask)

# Get hyper-parameter tuning
rf.param <- makeParamSet(
  makeIntegerParam("ntree", lower = 50, upper = 500)
  , makeIntegerParam('mtry', lower = 3, upper = 10)
  , makeIntegerParam('nodesize', lower = 10, upper = 50)
)

# RF gs control
rf.control <- makeTuneControlRandom(maxit = 50L)

# set cv
rf.cv <- makeResampleDesc("CV", iters = 3L)

# hyper-parameter tuning
parallelMap::parallelStartSocket(
  4
  , level = "mlr.tuneParams"
)

rf.tune <- tuneParams(
  learner = rf.learner
  , resampling = rf.cv
  , task = trainTask
  , par.set = rf.param
  , control = rf.control
)

parallelMap::parallelStop()

# Check CV Acc
rf.tune$y
rf.tune$x

# use hyper-parameters for model
rf.tree <- setHyperPars(rf.learner, par.vals = rf.tune$x)

# train model
rf.train.mod <- train(rf.tree, trainTask)
getLearnerModel(rf.train.mod)
plotLearningCurve(
  generateLearningCurveData(
    rf.tree
    , trainTask
    )
  )

# predictions
rf.pred.mod <- predict(rf.train.mod, testTask)
plotResiduals(rf.pred.mod)

# create submit file
rf.submit <- data.frame(
  rf.pred.mod$data
)
head(rf.submit, 5)
table(rf.submit$truth, rf.submit$response)

# Confusion matrix
calculateConfusionMatrix(rf.pred.mod)
calculateROCMeasures(rf.pred.mod)
conf_mat_f1_func(rf.pred.mod)

perf_plots_func(
  Model1 = rf.pred.mod
)

# SVM to slow####
getParamSet("classif.ksvm")
train.ksvm <- makeLearner("classif.ksvm", predict.type = 'response')

# Set parameters
train.ksvm.ps <- makeParamSet(
  makeDiscreteParam("C", values = 2^c(-8,-4,-2,0)) # cost parms
  , makeDiscreteParam("sigma", values = 2^c(-8,-4,0,4)) # RBF kernal parameter
)

# specify search function
train.ctrl <- makeTuneControlGrid()

# set cv
kvsm.cv <- makeResampleDesc("CV", iters = ncol(base.mod.df))

# tune model
parallelMap::parallelStartSocket(
  4
  , level = "mlr.tuneParams"
)

res <- tuneParams(
  train.ksvm
  , task = trainTask
  , resampling = kvsm.cv
  , par.set = train.ksvm.ps
  , control = train.ctrl
  , measures = acc
)

res.smote <- tuneParames(
  train.ksvm
  , task = trainTaskSmote
  , resampling = kvsm.cv
  , par.set = train.ksvm.ps
  , control = train.ctrl
  , measures = acc
)

parallelMap::parallelStop()

# Check CV Acc
res$y


# Set Hyper-parameters
kvsm.set.hp <- setHyperPars(train.ksvm, par.vals = res$x)

# Train 
par.svm <- train(train.ksvm, testTask)

# Prediction
predict.ksvm <- predict(par.svm, testTask)

# Create submission file
ksvm.submit <- data.frame(
  predict.ksvm$data
)
head(ksvm.submit)
table(ksvm.submit$truth, ksvm.submit$response)

# confusion matrix
calculateConfusionMatrix(predict.ksvm)
calculateROCMeasures(predict.ksvm)

# GBM ####
getParamSet('classif.gbm')
gbm.learner <- makeLearner(
  'classif.gbm'
  , predict.type = 'prob'
  )
plotLearnerPrediction(gbm.learner, trainTask)

# Tune model
gbm.tune.ctl <- makeTuneControlRandom(maxit = 50L)

# Cross validation
gbm.cv <- makeResampleDesc("CV", iters = 3L)

# Grid search - Hyper-parameter space
gbm.par <- makeParamSet(
  makeDiscreteParam('distribution', values = 'bernoulli')
  , makeIntegerParam('n.trees', lower = 10, upper = 1000)
  , makeIntegerParam('interaction.depth', lower = 2, upper = 10)
  , makeIntegerParam('n.minobsinnode', lower = 10, upper = 80)
  , makeNumericParam('shrinkage', lower = 0.01, upper = 1)
)

# Tune Hyper-parameters
parallelMap::parallelStartSocket(
  4
  , level = "mlr.tuneParams"
  )
gbm.tune <- tuneParams(
  learner = gbm.learner
  , task = trainTask
  , resampling = gbm.cv
  , measures = acc
  , par.set = gbm.par
  , control = gbm.tune.ctl
)
parallelMap::parallelStop()

# Check CV acc
gbm.tune$y
gbm.tune$x

# Set hyper-parameters
gbm.ps <- setHyperPars(
  learner = gbm.learner
  , par.vals = gbm.tune$x
)

# Train gbm
gbm.train <- train(gbm.ps, testTask)
plotLearningCurve(
  generateLearningCurveData(
    gbm.learner
    , testTask
    )
  )

# Predict
gbm.pred <- predict(gbm.train, testTask)
plotResiduals(gbm.pred)

# Create submission file
gbm.submit <- data.frame(
  gbm.pred$data
)
head(gbm.submit, 5)
table(gbm.submit$truth, gbm.submit$response)

# Confusion Matrix
calculateConfusionMatrix(gbm.pred)
calculateROCMeasures(gbm.pred)
conf_mat_f1_func(gbm.pred)

perf_plots_func(
  Model1 = gbm.pred
)

# nnet poor perf ####
getParamSet("classif.nnet")

nnet.learner <- makeLearner(
  'classif.nnet'
  , predict.type = 'prob'
)

# Cross Validate
nnet.cv <- makeResampleDesc("CV", iters = 3L)

# HP Tuning set
nnet.ps <- makeParamSet(
  makeDiscreteParam("size", values = seq(1, 10, by = 1))
  , makeDiscreteParam("decay", values = seq(0, 0.1, by = 0.005))
)

# Grid Search
nnet.gsctrl <- makeTuneControlGrid()

# Tune hyper-parameters
parallelMap::parallelStartSocket(
  4
  , level = "mlr.tuneParams"
)

nnet.tune <- tuneParams(
  learner = nnet.learner
  , resampling = nnet.cv
  , task = trainTask
  , par.set = nnet.ps
  , control = nnet.gsctrl
)

parallelMap::parallelStop()

# Check CV acc
nnet.tune$x
nnet.tune$y

# Use HP for modeling
nnet.model <- setHyperPars(
  nnet.learner
  , par.vals = nnet.tune$x
  )

# Train the nnet models
nnet.model.train <- mlr::train(nnet.model, trainTask)
getLearnerModel(nnet.model.train)
plotLearningCurve(
  generateLearningCurveData(
    nnet.model
    , trainTask
  )
)

# Predictions
nnet.model.predictions <- predict(
  nnet.model.train
  , testTask
)
plotResiduals(nnet.model.predictions)

# Submit file
nnet.submit <- data.frame(
  nnet.model.predictions$data
)
head(nnet.submit, 5)
table(nnet.submit$truth, nnet.submit$response)

# nnet confusion matrix
calculateConfusionMatrix(nnet.model.predictions)
calculateROCMeasures(nnet.model.predictions)
conf_mat_f1_func(nnet.model.predictions)

perf_plots_func(
  Model1 = nnet.model.predictions
)

# ada model to slow ####
getParamSet("classif.ada")

# Make learner
ada.learner <- makeLearner(
  'classif.ada'
  , predict.type = 'prob'
)

# Cross validate
ada.cv <- makeResampleDesc(
  "CV"
  , iters = 3L
)

# HP Param Set
ada.ps <- makeParamSet(
  makeIntegerParam('minsplit', lower = 5, upper = 50)
  , makeIntegerParam('minbucket', lower = 5, upper = 50)
  , makeNumericParam('cp', lower = 0.001, upp = 0.2)
)
  
# gs control
ada.ctrl <- makeTuneControlGrid()

# Tune model
parallelMap::parallelStartSocket(
  cpu = 5
  , level = "mlr.tuneParams"
)

ada.tune <- tuneParams(
  learner = ada.learner
  , task = trainTask
  , resampling = ada.cv
  , control = ada.ctrl
  , par.set = ada.ps
  , measures = acc
)

parallelMap::parallelStop()

# Check CV Acc
ada.tune$x
ada.tune$y

# Use hyper-parameters for modeling
ada.model <- setHyperPars(ada.learner, par.vals = ada.tune$x)

# Train the model
ada.model.training <- train(ada.model, trainTask)
getLearnerModel(ada.model.training)
plotLearningCurve(
  generateLearningCurveData(
    ada.model
    , trainTask
  )
)

# Predictions
ada.model.predictions <- predict(
  ada.model.training
  , testTask
)
plotResiduals(ada.model.predictions)

# Submit file
ada.submit <- data.frame(
  ada.model.predictions$data
)
head(ada.submit, 5)
table(ada.submit$truth, ada.submit$response)

# Tree confusion matrix
calculateConfusionMatrix(ada.model.predictions)
calculateROCMeasures(ada.model.predictions)
conf_mat_f1_func(ada.model.predictions)

perf_plots_func(
  Model1 = ada.model.predictions
)

# All F1 Scores ####
cat(
  paste0(
    "Logit Model Acc = "
    , round(model.acc, 4)
    , "\n"
    , "Logit Model Recall = "
    , round(model.recall, 4)
    , "\n"
    , "Logit Model Precision = "
    , round(model.precision, 4)
    , "\n"
    , "MLR Logit Model Acc = "
    , round(calculateROCMeasures(logistic.test.model)$measures$acc, 4)
    , "\n"
    , "MLR Logit Model Recall = "
    , round(calculateROCMeasures(logistic.test.model)$measures$tpr, 4)
    , "\n"
    , "MLR Logit Model Precision = "
    , round(calculateROCMeasures(logistic.test.model)$measures$ppv, 4)
    , "\n"
    , "Tree Model Acc = "
    , round(calculateROCMeasures(tree.model.predictions)$measures$acc, 4)
    , "\n"
    , "Tree Model Recall = "
    , round(calculateROCMeasures(tree.model.predictions)$measures$tpr, 4)
    , "\n"
    , "Tree Model Precision = "
    , round(calculateROCMeasures(tree.model.predictions)$measures$ppv, 4)
    , "\n"
    , "Random Forest Model Acc = "
    , round(calculateROCMeasures(rf.pred.mod)$measures$acc, 4)
    , "\n"
    , "Random Forest Model Recall = "
    , round(calculateROCMeasures(rf.pred.mod)$measures$tpr, 4)
    , "\n"
    , "Random Forest Model Precision = "
    , round(calculateROCMeasures(rf.pred.mod)$measures$ppv, 4)
    , "\n"
    , "GBM Model Acc = "
    , round(calculateROCMeasures(gbm.pred)$measures$acc, 4)
    , "\n"
    , "GBM Model Recall = "
    , round(calculateROCMeasures(gbm.pred)$measures$tpr, 4)
    , "\n"
    , "GBM Model Precision = "
    , round(calculateROCMeasures(gbm.pred)$measures$ppv, 4)
  )
)

# Plot Learning Curve Data ####
plotLearningCurve(
  generateLearningCurveData(
    learners = c(
      "classif.gbm"
      , "classif.ada"
    ),
    task = trainTaskSmote,
    percs = seq(0.1, 1, by = 0.2),
    measures = list(tp, fp, fn, tn),
    resampling = makeResampleDesc(method = "CV", iters = 5),
  )
)

rin2 <- makeResampleDesc(method = "CV", iters = 5, predict = "both")
plotLearningCurve(
  generateLearningCurveData(
    learners = c(
      "classif.gbm"
      , "classif.ada"
    ),
    task = trainTaskSmote,
    percs = seq(0.1, 1, by = 0.2),
    measures = list(acc, setAggregation(acc, train.mean)),
    resampling = rin2
  )
)

# Generate gbm predictions
# Lib Load ####
install.load::install_load(
  "tidyverse"
  , "mlr"
  , "rJava"
  , "DALEX"
  , "FSelector"
  , "gbm"
  , "fitdistrplus"
)
options(scipen = 999) # prevent printing in scientific notation

# Get File ####
fileToLoad <- file.choose(new = T)
df <- readxl::read_xlsx(path = fileToLoad, sheet = "data")
df %>% glimpse()

# DF Health ####
nrow(df)
ncol(df)
colnames(df)
DataExplorer::plot_missing(df)
str(df)

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

# Functions ####
# Bin Size functions
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\optimal_bin_size.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\optimal_hist_bin_size.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\readmit_pred_functions.R")

# Not in Function
'%ni%' <- Negate('%in%')

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

gridExtra::grid.arrange(
  hist_lace_non_ra
  , hist_lace_ra
  , hist_lace_both
  , hist_lace_boxplot
  , nrow = 2
  , ncol = 2
)

rm(
  list = c(
    "hist_lace_ra"
    ,"hist_lace_both"
    ,"hist_lace_boxplot"
    ,"hist_lace_non_ra"
    )
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

gridExtra::grid.arrange(
  hist_lace_non_ra_hp
  , hist_lace_ra_hp
  , hist_lace_boxplot_hp
  , nrow = 2
  , ncol = 2
)

rm(
  list = c(
    "hist_lace_non_ra_hp"
    , "hist_lace_ra_hp"
    , "hist_lace_boxplot_hp"
  )
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

# Split Data ####
split <- caTools::sample.split(base.mod.df$READMIT_FLAG, SplitRatio = 0.7)
train <- subset(base.mod.df, split == T)
test  <- subset(base.mod.df, split == F)

# Make Tasks ####
glimpse(test)

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
trainTask <- smote(trainTask, rate = 6)
testTask <- smote(testTask, rate = 6)

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

perf_plots_func(Model = gbm.pred)

# Save Model ####
# Save the model to disk
saveRDS(
  object = gbm.train
  , file = "gbm_pred.rds"
  )

# DALEX ####
custom_predict <- function(object, newdata){
  pred <- predict(
    object
    , newdata = newdata
    )
  response <- pred$data$response
  return(response)
}
explainer_gbm <- DALEX::explain(
  gbm.train
  , data = train.df %>% dplyr::select(-Init_Acct)
  , y = train.df$READMIT_FLAG
  , predict_function = custom_predict
  , label = "gbm"
  )

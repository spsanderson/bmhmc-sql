# Start ####
install.load::install_load(
  "tidyverse"
  , "mlr"
  , "rJava"
  , "FSelector"
  , "gbm"
  , "dplyr"
)
options(scipen = 999) # prevent printing in scientific notation

# Prod testing ####
gbm_readmit_model <- readRDS("gbm_pred.rds")
print(gbm_readmit_model)
new.file <- file.choose(new = T)
df <- readxl::read_xlsx(new.file, sheet = "data")
print(df)

# Functions ####
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
    , -Init_Attn_ID
    , -Init_Attn_Name
    , -Init_Attn_Specialty
    , -Init_Disp
    , -Init_Hosp_Svc
    , -Init_LIHN_Svc
    , -READMIT_FLAG
    , -Readmit_Date
    , -Days_To_Readmit
  )
str(base.mod.df)
base.mod.df$reduced_dispo <- factor(base.mod.df$reduced_dispo)
base.mod.df$reduced_hsvc <- factor(base.mod.df$reduced_hsvc)
base.mod.df$reduced_abucket <- factor(base.mod.df$reduced_abucket)
base.mod.df$reduced_spclty <- factor(base.mod.df$reduced_spclty)
base.mod.df$reduced_lihn <- factor(base.mod.df$reduced_lihn)
base.mod.df$discharge_month <- factor(base.mod.df$discharge_month)

base.mod.df <- as.data.frame(base.mod.df)

# Run Model ####
prod_predictions <- predict(
  gbm_readmit_model
  , newdata = base.mod.df
  )

# Join Pred to data ####
# first add sequential number column called id to base.mod.df
base.mod.df <- base.mod.df %>% 
  cbind(
    base.mod.df
    , prob.n = prod_predictions$data$prob.N
    , prob.y = prod_predictions$data$prob.Y
    , resp = prod_predictions$data$response
  )
print(base.mod.df)
base.mod.df %>% glimpse()

table(base.mod.df$resp)

pred.data <- prod_predictions$data
head(pred.data)

n <- pred.data %>% 
  filter(response == "N") %>% 
  dplyr::select(
    Response = response
    , Probability = prob.N
    )

y <- pred.data %>% 
  filter(response == "Y") %>%
  dplyr::select(
    Response = response
    , Probability = prob.Y
    )

l <- union_all(n, y)

l %>% ggplot(
  aes(
    Probability
    , fill = Response
  )
) + 
  geom_density(
    alpha = 0.2
  ) +
  theme_minimal()